// lib/src/pages/control_screen.dart
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../Controller/bluetooth_helper.dart';
import 'package:pw/src/Controller/control_controller.dart';
import 'package:pw/widgets/header_menu_widget.dart';
import '../../widgets/drawerMenuWidget.dart';
import '../../widgets/tecladoPwWidget.dart';
import '../Controller/estatus.dart';
import '../Controller/idioma_controller.dart';

class ControlScreen extends StatefulWidget {
  final BluetoothDevice? connectedDevice;
  final ControlController? controller;
  final String? savedDeviceId; // 👈 nuevo

  const ControlScreen({
    Key? key,
    this.connectedDevice,
    this.controller,
    this.savedDeviceId,
  }) : super(key: key);

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen>
    with WidgetsBindingObserver {
  late final ControlController _controller; // ✅ se asigna una sola vez
  VoidCallback? _bondListener;
  bool _resumeAuto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ✅ Asignar SOLO una vez
    _controller = widget.controller ?? ControlController();

    // Si ya haces startPolling en el provider con lazy:false, puedes omitir esta línea.
    context.read<EstadoSistemaController>().startPolling(const Duration(seconds: 1));

    if (widget.connectedDevice != null) {
      _controller.setDevice(widget.connectedDevice!);
      _controller.setDeviceBond(widget.connectedDevice!);
      _controller.startBatteryStatusMonitoring();
      _controller.requestSystemStatus();
    } else if ((widget.savedDeviceId ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final ok = await _controller.conectarPorId(context, widget.savedDeviceId!);
        if (ok && _controller.connectedDevice != null) {
          _controller.setDeviceBond(_controller.connectedDevice!);
          _controller.startBatteryStatusMonitoring();
          _controller.requestSystemStatus();
        } else {
          _controller.conectarManualBLE(context, silent: true);
        }
      });
    } else {
      _controller.conectarManualBLE(context);
    }

    // Auto–conectar A2DP y marcar reanudación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoConnectA2dp();
      _resumeAuto = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_bondListener != null) {
      _controller.shouldSetup.removeListener(_bondListener!);
      _bondListener = null;
    }
    _controller.stopBondMonitoring();
    _controller.stopBatteryStatusMonitoring();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _disconnectAll();
    }

    if (state == AppLifecycleState.resumed && _resumeAuto) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoConnectA2dp());
    }

    if (state == AppLifecycleState.resumed) {
      if (!_controller.isBleConnected.value) {
        _controller.conectarManualBLE(context, silent: true);
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller.disconnectDevice();
    }
  }

  void _disconnectAll() {
    _controller.disconnectDevice();
    BluetoothHelper.disconnectBluetoothAudio();
  }

  void _autoConnectA2dp() {
    BluetoothHelper.connectBluetoothAudio().then((ok) {
      if (!ok && Platform.isAndroid) {
        AndroidIntent(action: 'android.settings.BLUETOOTH_SETTINGS').launch();
      }
    });
  }

  String _localizedButton(String name, String code) {
    const folder = "assets/images/Botones";
    switch (code) {
      case 'es': return "$folder/Espanol/$name.png";
      case 'en': return "$folder/Ingles/${name}_1.png";
      case 'pt': return "$folder/Portugues/${name}_3.png";
      case 'fr': return "$folder/Frances/${name}_2.png";
      default:   return "$folder/Espanol/$name.png";
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final fw = w * 0.85;
    final fh = fw * 0.5;

    return Scaffold(
      drawer: const AppDrawer(),
      body: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            top: 0, left: 0, right: 0,
            child: HeaderMenuWidget(),
          ),
          Positioned(
            top: h * 0.22,
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isBleConnected,
              builder: (_, bleConnected, __) => Image.asset(
                bleConnected
                    ? "assets/images/iconos/iconoBtOn.png"
                    : "assets/images/iconos/iconoBtOff.png",
                width: 60, height: 60,
              ),
            ),
          ),

          // Fondo centrado
          Positioned(
            top: (h - fh) / 2,
            left: (w - fw) / 2,
            child: SizedBox(
              width: fw,
              height: fh,
              child: Image.asset(
                "assets/images/tecladoPw/fondo/fondoPrincipal.png",
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Teclado
          Positioned(
            top: h * 0.42,
            child: TecladoPW(
              estaConectado: _controller.isBleConnected,
              controller: _controller,
              fondoWidth: fw,
              fondoHeight: fh,
            ),
          ),

          // Botón conectar/desconectar
          Positioned(
            bottom: 75,
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isBleConnected,
              builder: (_, bleConnected, __) => Consumer<IdiomaController>(
                builder: (context, idioma, _) {
                  final code = idioma.locale.languageCode;
                  final name = bleConnected ? "desconectar" : "conectar";
                  final assetPath = _localizedButton(name, code);
                  return GestureDetector(
                    onTap: () {
                      if (bleConnected) {
                        _controller.disconnectDevice();
                        BluetoothHelper.disconnectBluetoothAudio();
                      } else {
                        _controller.conectarManualBLE(context).then((okBle) {
                          if (okBle && widget.connectedDevice != null) {
                            _controller.setDeviceBond(widget.connectedDevice!);
                            _controller.startBatteryStatusMonitoring();
                            _controller.requestSystemStatus();
                          } else {
                            BluetoothHelper.connectBluetoothAudio().then((okClassic) {
                              if (!okClassic && Platform.isAndroid) {
                                AndroidIntent(action: 'android.settings.BLUETOOTH_SETTINGS').launch();
                              }
                            });
                          }
                        });
                      }
                    },
                    child: Image.asset(assetPath, width: w * 0.75),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
