import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceData {
  final String name; // nombre visible
  final String id; // remoteId.str
  final ble.BluetoothDevice device; // instancia BLE
  const DeviceData({
    required this.name,
    required this.id,
    required this.device,
  });
}

class ConfiguracionBluetoothController extends ChangeNotifier {
  // ===== Config =====
  static const String setupPin = '9459'; // PIN fijo
  static const List<String> authCharCandidates = [
    'ff01',
    'fff1',
    'ffe1',
    'ffd1',
  ];

  // Tiempos de escaneo cíclico
  static const Duration _scanOn = Duration(seconds: 5); // tiempo escaneando
  static const Duration _scanOff = Duration(seconds: 2); // pausa entre ciclos
  static const int _maxMissedCycles = 2; // ciclos sin ver -> remover

  // Estado
  final List<DeviceData> dispositivosEncontrados = [];
  final Map<String, int> _missedById = {}; // id -> ciclos perdidos
  DeviceData? selectedDevice;
  DeviceData? connectedDeviceData;

  bool showPin = false;
  bool estadoConectando = false;
  bool? ultimoResultadoConexion;
  String pinIngresado = '';

  // Escaneo
  StreamSubscription<List<ble.ScanResult>>? _scanSub;
  Timer? _cycleTimer;
  bool _isCycling = false;
  bool _disposed = false;

  // ─────────── UI
  void seleccionar(DeviceData d) {
    selectedDevice = d;
    notifyListeners();
  }

  void togglePinVisibility(DeviceData d) {
    if (selectedDevice?.id != d.id) selectedDevice = d;
    showPin = !showPin;
    notifyListeners();
  }

  void ingresarNumero(String n) {
    if (pinIngresado.length < setupPin.length) {
      pinIngresado += n;
      notifyListeners();
    }
  }

  void borrarPin() {
    if (pinIngresado.isNotEmpty) {
      pinIngresado = pinIngresado.substring(0, pinIngresado.length - 1);
      notifyListeners();
    }
  }

  // ─────────── Escaneo BLE (cíclico)
  Future<void> iniciarEscaneo() async {
    ultimoResultadoConexion = null;
    showPin = false;
    selectedDevice = null;
    pinIngresado = '';
    dispositivosEncontrados.clear();
    _missedById.clear();
    notifyListeners();

    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    if (Platform.isAndroid) {
      await Permission.location.request();
    }

    await _detenerEscaneoInterno();
    _isCycling = true;
    _cicloEscaneo(); // inicia el bucle
  }

  /// Fuerza un ciclo inmediato (útil para pull-to-refresh)
  Future<void> refrescarAhora() async {
    if (!_isCycling) {
      _isCycling = true;
      await _cicloEscaneo();
    }
  }

  Future<void> _cicloEscaneo() async {
    if (_disposed || !_isCycling) return;

    // 1) Preparar listener de resultados
    final vistosEnEsteCiclo = <String>{};
    await _detenerEscaneoInterno(); // por si había algo viejo

    _scanSub = ble.FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final visibleName =
        r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName;
        final lower = visibleName.toLowerCase();

        if (lower.contains('btpw')) {
          final id = r.device.remoteId.str;
          vistosEnEsteCiclo.add(id);

          // si es nuevo, lo agregamos
          final exists = dispositivosEncontrados.any((e) => e.id == id);
          if (!exists) {
            final pretty = visibleName.isNotEmpty ? visibleName : 'btpw';
            dispositivosEncontrados.add(
              DeviceData(name: pretty, id: id, device: r.device),
            );
            _missedById[id] = 0;
            notifyListeners();
          } else {
            // si ya estaba, reseteamos su contador de "no visto"
            _missedById[id] = 0;
          }
        }
      }
    });

    // 2) Empezar a escanear por _scanOn
    await ble.FlutterBluePlus.startScan(timeout: _scanOn);
    // Nota: el timeout de startScan ya parará el escaneo al cumplirse _scanOn

    // 3) Cerrar listener de este ciclo
    await _scanSub?.cancel();
    _scanSub = null;

    // 4) Incrementar "missed" de los que no vimos y eliminar los que excedan
    for (final dev in List<DeviceData>.from(dispositivosEncontrados)) {
      if (!vistosEnEsteCiclo.contains(dev.id)) {
        final missed = (_missedById[dev.id] ?? 0) + 1;
        _missedById[dev.id] = missed;
        if (missed >= _maxMissedCycles) {
          dispositivosEncontrados.removeWhere((d) => d.id == dev.id);
        }
      }
    }
    if (!_disposed) notifyListeners();

    // 5) Pausa entre ciclos y repetir
    if (_isCycling && !_disposed) {
      _cycleTimer?.cancel();
      _cycleTimer = Timer(_scanOff, _cicloEscaneo);
    }
  }

  Future<void> _detenerEscaneoInterno() async {
    _cycleTimer?.cancel();
    _cycleTimer = null;
    try {
      await ble.FlutterBluePlus.stopScan();
    } catch (_) {}
    await _scanSub?.cancel();
    _scanSub = null;
  }

  Future<void> detenerEscaneo() async {
    _isCycling = false;
    await _detenerEscaneoInterno();
  }

  // ─────────── Conexión + Autenticación (PIN)
  Future<void> enviarPinYConectar(BuildContext context) async {
    if (selectedDevice == null) return;

    if (pinIngresado != setupPin) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("PIN incorrecto")));
      return;
    }

    estadoConectando = true;
    ultimoResultadoConexion = null;
    notifyListeners();

    try {
      await detenerEscaneo();

      final device = selectedDevice!.device;

      if (device.connectionState != ble.BluetoothConnectionState.connected) {
        await device.connect(timeout: const Duration(seconds: 10));
      }

      final services = await device.discoverServices();

      ble.BluetoothCharacteristic? authChar;
      for (final s in services) {
        for (final c in s.characteristics) {
          final cu = c.uuid.toString().toLowerCase();
          final matchesCandidate = authCharCandidates.any(
                (frag) => cu.contains(frag),
          );
          final canWrite =
              c.properties.write || c.properties.writeWithoutResponse;
          if (matchesCandidate && canWrite) {
            authChar = c;
            break;
          }
        }
        if (authChar != null) break;
      }

      if (authChar == null) {
        debugPrint(
          '⚠️ No se encontró característica de autenticación. Servicios detectados:',
        );
        for (final s in services) {
          debugPrint('  • Service: ${s.uuid}');
          for (final c in s.characteristics) {
            debugPrint(
              '    ↳ Char: ${c.uuid} '
                  '(write=${c.properties.write}, '
                  'writeNR=${c.properties.writeWithoutResponse}, '
                  'notify=${c.properties.notify})',
            );
          }
        }
        await device.disconnect();
        estadoConectando = false;
        ultimoResultadoConexion = false;
        notifyListeners();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se encontró característica de autenticación."),
          ),
        );
        return;
      }

      await authChar.write(
        pinIngresado.codeUnits,
        withoutResponse: !authChar.properties.write,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedInitialConfig', true);

      connectedDeviceData = DeviceData(
        name: selectedDevice!.name,
        id: selectedDevice!.id,
        device: device,
      );

      estadoConectando = false;
      ultimoResultadoConexion = true;
      notifyListeners();
    } catch (e) {
      estadoConectando = false;
      ultimoResultadoConexion = false;
      notifyListeners();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error de conexión BLE: $e")));
    } finally {
      // Si quieres reanudar el escaneo de fondo (para detectar otros BTPW)
      if (!_disposed) {
        _isCycling = true;
        _cicloEscaneo();
      }
    }
  }

  // ─────────── Ciclo de vida
  Future<void> cancelarTodo() async {
    await detenerEscaneo();
  }

  @override
  void dispose() {
    _disposed = true;
    cancelarTodo();
    super.dispose();
  }
}