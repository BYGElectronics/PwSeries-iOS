import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class Demowidget extends StatefulWidget {
  final double fondoWidth;
  final double fondoHeight;

  const Demowidget({
    Key? key,
    required this.fondoWidth,
    required this.fondoHeight,
  }) : super(key: key);

  @override
  State<Demowidget> createState() => _DemowidgetState();
}

class _DemowidgetState extends State<Demowidget> {
  // Players
  final AudioPlayer _sirenaPlayer = AudioPlayer();
  final AudioPlayer _auxPlayer = AudioPlayer();
  final AudioPlayer _wailPlayer = AudioPlayer();
  final AudioPlayer _hornPlayer = AudioPlayer();
  final AudioPlayer _pttPlayer = AudioPlayer();
  final AudioPlayer _intercomPlayer = AudioPlayer();

  // Para reanudar después de Horn
  String? _reanudarLuego; // 'sirena' | 'aux' | null

  // Audios disponibles (se reproducen por índice numérico)
  final List<String> _tonos = const [
    'audios/sirena/Sirena1.mp3',
    'audios/sirena/Sirena2.mp3',
    'audios/sirena/Sirena3.mp3',
    'audios/sirena/Sirena4.mp3',
    'audios/sirena/Sirena5.mp3',
  ];

  // Índices (representación numérica de audio)
  int _sirenaIndex = 0;
  int _auxIndex = 1; // arranca distinto a sirena

  // Estados
  bool _sirenaActiva = false;
  bool _auxActiva = false;

  final Map<AudioPlayer, StreamSubscription<void>> _onCompleteSubs = {};

  @override
  void initState() {
    super.initState();
    _setPlayersContext();
  }

  Future<void> _setPlayersContext() async {
    final context = AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    );

    for (final p in [
      _sirenaPlayer,
      _auxPlayer,
      _wailPlayer,
      _hornPlayer,
      _pttPlayer,
      _intercomPlayer,
    ]) {
      await p.setAudioContext(context);
    }
  }

  // Utilidades de audio
  Future<void> _playLoop(AudioPlayer p, String assetPath) async {
    await p.stop();
    await p.setReleaseMode(ReleaseMode.loop);
    await p.play(AssetSource(assetPath));
  }

  Future<void> _stop(AudioPlayer p) async {
    await p.stop();
  }

  Future<void> _pressHoldStart(AudioPlayer p, String assetPath) async {
    await p.stop();
    await p.setReleaseMode(ReleaseMode.loop);
    await p.play(AssetSource(assetPath));
  }

  Future<void> _pressHoldEnd(AudioPlayer p) async {
    await p.stop();
    await _onCompleteSubs[p]?.cancel();
    _onCompleteSubs.remove(p);
  }

  // ─────────────────────────────────────────────
  // Sirena (toggle)
  // ─────────────────────────────────────────────
  Future<void> _toggleSirena() async {
    if (_sirenaActiva) {
      setState(() => _sirenaActiva = false);
      debugPrint("🎛️ Sirena -> INACTIVA");
      await _stop(_sirenaPlayer);
    } else {
      setState(() {
        _sirenaActiva = true;
        if (_auxActiva) {
          _auxActiva = false;
          _stop(_auxPlayer);
          debugPrint("🎛️ Auxiliar -> INACTIVO (por activación de Sirena)");
        }
      });
      debugPrint("🎛️ Sirena -> ACTIVA (índice: $_sirenaIndex)");

      // Evitar que Sirena y Aux queden con el mismo NÚMERO
      if (_sirenaIndex == _auxIndex) {
        _auxIndex = (_sirenaIndex + 1) % _tonos.length;
        debugPrint("↪️ Ajuste: Aux pasa a índice $_auxIndex por conflicto con Sirena");
      }

      await _playLoop(_sirenaPlayer, _tonos[_sirenaIndex]);
    }
  }

  // Cambiar tono de Sirena (avanza número)
  Future<void> _nextSirenaTone() async {
    _sirenaIndex = (_sirenaIndex + 1) % _tonos.length;
    debugPrint("🔁 Sirena cambia a índice: $_sirenaIndex");

    // Si ahora coincide con Aux → mover Aux al siguiente número
    if (_sirenaIndex == _auxIndex) {
      _auxIndex = (_auxIndex + 1) % _tonos.length;
      debugPrint("↪️ Ajuste: Aux pasa a índice $_auxIndex por conflicto con Sirena");
      if (_auxActiva) {
        await _playLoop(_auxPlayer, _tonos[_auxIndex]);
      }
    }

    if (_sirenaActiva) {
      await _playLoop(_sirenaPlayer, _tonos[_sirenaIndex]);
    }
    setState(() {});
  }

  // ─────────────────────────────────────────────
  // Aux (toggle)
  // ─────────────────────────────────────────────
  Future<void> _toggleAux() async {
    if (_auxActiva) {
      setState(() => _auxActiva = false);
      debugPrint("🎛️ Auxiliar -> INACTIVO");
      await _stop(_auxPlayer);
      return;
    }

    // Activar Aux y desactivar Sirena
    setState(() {
      _auxActiva = true;
      if (_sirenaActiva) {
        _sirenaActiva = false;
        _stop(_sirenaPlayer);
        debugPrint("🎛️ Sirena -> INACTIVA (por activación de Auxiliar)");
      }
    });
    debugPrint("🎛️ Auxiliar -> ACTIVO (índice: $_auxIndex)");

    // Solo si el NÚMERO guardado en Aux es el mismo que Sirena, Aux avanza
    if (_auxIndex == _sirenaIndex) {
      _auxIndex = (_auxIndex + 1) % _tonos.length;
      debugPrint("↪️ Aux cambia a índice $_auxIndex por conflicto con Sirena");
    }

    await _playLoop(_auxPlayer, _tonos[_auxIndex]);
  }

  // Cambio MANUAL de audio de Aux (persiste el número salvo conflicto puntual)
  Future<void> _nextAuxToneManual() async {
    _auxIndex = (_auxIndex + 1) % _tonos.length;
    debugPrint("🔁 Aux cambia MANUALMENTE a índice: $_auxIndex");

    // Si coincide con Sirena en ese momento → forzar siguiente
    if (_auxIndex == _sirenaIndex) {
      _auxIndex = (_auxIndex + 1) % _tonos.length;
      debugPrint("↪️ Aux ajustado a índice $_auxIndex por conflicto con Sirena");
    }

    if (_auxActiva) {
      await _playLoop(_auxPlayer, _tonos[_auxIndex]);
    }
    setState(() {});
  }

  // ─────────────────────────────────────────────
  // Wail (press & hold)
  //   - Si Sirena o Aux están activos: NO suena; cambia de tono.
  //   - Si ambos inactivos: suena mientras esté presionado.
  // ─────────────────────────────────────────────
  Future<void> _onWailPress() async {
    debugPrint("▶️ Wail PRESIONADO");
    if (_sirenaActiva) {
      await _nextSirenaTone();
      return;
    }
    if (_auxActiva) {
      await _nextAuxToneManual();
      return;
    }
    // Ninguno activo → Wail suena mientras esté presionado
    await _pressHoldStart(_wailPlayer, 'audios/wail/Wail.mp3');
  }

  Future<void> _onWailRelease() async {
    debugPrint("⏹ Wail LIBERADO");
    // Solo se detiene si estaba sonando (caso ambos inactivos)
    await _pressHoldEnd(_wailPlayer);
  }

  // ─────────────────────────────────────────────
  // Horn (press & hold) — pausa lo actual y reanuda al soltar
  // ─────────────────────────────────────────────
  Future<void> _onHornPress() async {
    debugPrint("▶️ Horn PRESIONADO");

    if (_sirenaActiva) {
      _reanudarLuego = 'sirena';
      await _stop(_sirenaPlayer);
      debugPrint("⏸️ Sirena pausada por Horn");
    } else if (_auxActiva) {
      _reanudarLuego = 'aux';
      await _stop(_auxPlayer);
      debugPrint("⏸️ Aux pausado por Horn");
    } else {
      _reanudarLuego = null;
    }

    await _pressHoldStart(_hornPlayer, 'audios/horn/Horn_Americano.mp3');
  }

  Future<void> _onHornRelease() async {
    debugPrint("⏹ Horn LIBERADO");
    await _pressHoldEnd(_hornPlayer);

    if (_reanudarLuego == 'sirena' && _sirenaActiva) {
      await _playLoop(_sirenaPlayer, _tonos[_sirenaIndex]);
      debugPrint("▶️ Reanudada Sirena (índice: $_sirenaIndex)");
    } else if (_reanudarLuego == 'aux' && _auxActiva) {
      await _playLoop(_auxPlayer, _tonos[_auxIndex]);
      debugPrint("▶️ Reanudado Aux (índice: $_auxIndex)");
    }
    _reanudarLuego = null;
  }

  // No disponible (Inter / PTT)
  void _showNotAvailable() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Esta función no está disponible en el Demo'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    for (final s in _onCompleteSubs.values) {
      s.cancel();
    }
    _onCompleteSubs.clear();

    for (final p in [
      _sirenaPlayer,
      _auxPlayer,
      _wailPlayer,
      _hornPlayer,
      _pttPlayer,
      _intercomPlayer,
    ]) {
      p.dispose();
    }
    super.dispose();
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final fw = widget.fondoWidth;
    final fh = widget.fondoHeight;

    return Column(
      children: [
        // Fila superior: Wail | Sirena (toggle) | Inter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPressHoldButton(
              assetOn: "assets/images/tecladoPw/botones/On/wailOn.png",
              assetOff: "assets/images/tecladoPw/botones/On/wailOn.png",
              onPress: _onWailPress,
              onRelease: _onWailRelease,
              width: fw * 0.25,
              height: fh * 0.35,
            ),
            _buildToggleButton(
              assetOn: "assets/images/tecladoPw/botones/On/sirenaOn.png",
              assetOff: "assets/images/tecladoPw/botones/On/sirenaOn.png",
              isActive: _sirenaActiva,
              onToggle: _toggleSirena,
              width: fw * 0.40,
              height: fh * 0.40,
            ),
            _buildSimpleButton(
              asset: "assets/images/tecladoPw/botones/Off/interOff.png",
              onTap: _showNotAvailable,
              width: fw * 0.25,
              height: fh * 0.35,
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Fila inferior: Horn | Aux (toggle) | PTT
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPressHoldButton(
              assetOn: "assets/images/tecladoPw/botones/On/hornOn.png",
              assetOff: "assets/images/tecladoPw/botones/On/hornOn.png",
              onPress: _onHornPress,
              onRelease: _onHornRelease,
              width: fw * 0.25,
              height: fh * 0.35,
            ),
            _buildToggleButton(
              assetOn: "assets/images/tecladoPw/botones/On/auxOn.png",
              assetOff: "assets/images/tecladoPw/botones/On/auxOn.png",
              isActive: _auxActiva,
              onToggle: _toggleAux,
              width: fw * 0.35,
              height: fh * 0.30,
            ),
            _buildPressHoldButton(
              assetOn: "assets/images/tecladoPw/botones/Off/pttOff.png",
              assetOff: "assets/images/tecladoPw/botones/Off/pttOff.png",
              onPress: _showNotAvailable,
              onRelease: () {},
              width: fw * 0.25,
              height: fh * 0.35,
            ),
          ],
        ),
      ],
    );
  }

  // Helpers UI
  Widget _buildSimpleButton({
    required String asset,
    required VoidCallback onTap,
    double width = 100,
    double height = 70,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        asset,
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildPressHoldButton({
    required String assetOn,
    required String assetOff,
    required VoidCallback onPress,
    required VoidCallback onRelease,
    double width = 100,
    double height = 70,
  }) {
    return GestureDetector(
      onTapDown: (_) => onPress(),
      onTapUp: (_) => onRelease(),
      onTapCancel: () => onRelease(),
      child: Image.asset(
        assetOn, // si quieres variar la imagen al presionar, puedes animarlo
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildToggleButton({
    required String assetOn,
    required String assetOff,
    required bool isActive,
    required Future<void> Function() onToggle,
    double width = 100,
    double height = 70,
  }) {
    return GestureDetector(
      onTap: () async => onToggle(),
      child: Image.asset(
        isActive ? assetOn : assetOff,
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}
