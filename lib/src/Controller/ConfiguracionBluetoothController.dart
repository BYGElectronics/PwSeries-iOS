import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'control_controller.dart';

class DeviceData {
  final String name;
  final String address;
  final bool isBLE;
  int missedScans;

  DeviceData({
    required this.name,
    required this.address,
    required this.isBLE,
    this.missedScans = 0,
  });
}

class ConfiguracionBluetoothController extends ChangeNotifier {
  List<DeviceData> dispositivosEncontrados = [];
  StreamSubscription<List<ble.ScanResult>>? _scanSubscription;
  Timer? _scanTimer;

  final String pinMask = "9459";
  final String pinReal = "1865";

  String pinIngresado = "";
  DeviceData? selectedDevice;
  DeviceData? dispositivoConectando;

  ConfiguracionBluetoothController() {
    _inicializarBluetooth();
  }

  Future<void> _inicializarBluetooth() async {
    if (!Platform.isAndroid) return;

    final estado = await FlutterBluetoothSerial.instance.state;
    if (estado != BluetoothState.STATE_ON) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }

    if (await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetoothConnect.request();
      if (await Permission.bluetoothConnect.isDenied) return;
    }

    // ✅ Solicita permiso de ubicación en Android 12 o inferior
    if (Platform.isAndroid && int.tryParse(Platform.version.split('.').first) != null) {
      final version = int.parse(Platform.version.split('.').first);
      if (version <= 12) {
        await Permission.locationWhenInUse.request();
      }
    }

    final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
    for (var d in bonded) {
      if ((d.name ?? '').toLowerCase().contains("btpw")) {
        final auto = DeviceData(
          name: d.name!,
          address: d.address,
          isBLE: false,
        );
        dispositivosEncontrados.add(auto);
        if (dispositivosEncontrados.length == 1) {
          selectedDevice = auto;
        }
        break;
      }
    }

    notifyListeners();
    _iniciarEscaneoPeriodico();
  }

  void togglePinVisibility(DeviceData device) {
    if (selectedDevice?.address == device.address) {
      selectedDevice = null;
      pinIngresado = "";
    } else {
      selectedDevice = device;
      pinIngresado = "";
    }
    notifyListeners();
  }

  void agregarDigito(String d) {
    if (pinIngresado.length < 6) {
      pinIngresado += d;
      notifyListeners();
    }
  }

  void borrarPin() {
    if (pinIngresado.isNotEmpty) {
      pinIngresado = pinIngresado.substring(0, pinIngresado.length - 1);
      notifyListeners();
    }
  }

  Future<void> enviarPinYConectar(BuildContext context) async {
    if (selectedDevice == null) return;

    if (pinIngresado != pinMask) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PIN incorrecto")),
      );
      _reiniciarEmparejamiento();
      return;
    }

    final mac = selectedDevice!.address;
    dispositivoConectando = selectedDevice;
    notifyListeners();

    final okBond = await _pairClassic(mac);
    if (!okBond) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error emparejando Classic")),
      );
      _reiniciarEmparejamiento();
      return;
    }

    final conectado = await estaConectado(mac);
    if (!conectado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se logró conectar al dispositivo")),
      );
      _reiniciarEmparejamiento();
      return;
    }

    if (context.mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/control',
        arguments: {
          'device': selectedDevice,
          'controller': ControlController(),
        },
      );
    }
  }

  Future<bool> estaConectado(String mac) async {
    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      return devices.any((d) => d.address == mac);
    } catch (e) {
      debugPrint("Error verificando conexión: $e");
      return false;
    }
  }

  Future<bool> _pairClassic(String mac) async {
    try {
      final bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      final yaEmparejado = bondedDevices.any((d) => d.address == mac);

      if (yaEmparejado) {
        debugPrint("ℹ️ Dispositivo $mac ya estaba emparejado.");
        return true;
      }

      final success = await FlutterBluetoothSerial.instance.bondDeviceAtAddress(
        mac,
        pin: pinReal,
      );

      debugPrint(success == true
          ? "✅ Emparejamiento exitoso con $mac"
          : "⚠️ No se pudo emparejar con $mac");

      return success == true;
    } catch (e) {
      if (e.toString().contains("pairing request handler already registered")) {
        debugPrint("ℹ️ Dispositivo $mac ya emparejado (detected by exception).");
        return true;
      }

      debugPrint("❌ Error bond Classic: $e");
      return false;
    }
  }

  void _reiniciarEmparejamiento() {
    pinIngresado = "";
    selectedDevice = null;
    dispositivoConectando = null;
    notifyListeners();
    _iniciarEscaneoPeriodico();
  }

  void _iniciarEscaneoPeriodico() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _escanearYActualizarDispositivos();
    });
    _escanearYActualizarDispositivos();
  }

  Future<void> _escanearYActualizarDispositivos() async {
    if (!await Permission.bluetoothScan.isGranted) return;

    final nuevos = <DeviceData>[];

    if (Platform.isAndroid) {
      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      nuevos.addAll(
        bonded
            .where((d) => (d.name ?? "").toLowerCase().contains("btpw"))
            .map((d) => DeviceData(name: d.name!, address: d.address, isBLE: false)),
      );
    }

    await ble.FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    final encontradosBLE = <DeviceData>[];

    _scanSubscription = ble.FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        final name = r.device.name;
        final id = r.device.remoteId.id;
        if (name.toLowerCase().contains("btpw") &&
            !encontradosBLE.any((e) => e.address == id)) {
          encontradosBLE.add(DeviceData(name: name, address: id, isBLE: true));
        }
      }
    });

    await ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    await Future.delayed(const Duration(seconds: 5));
    await ble.FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();

    nuevos.addAll(encontradosBLE);

    final direcciones = nuevos.map((d) => d.address).toSet();
    for (var old in dispositivosEncontrados) {
      old.missedScans += direcciones.contains(old.address) ? 0 : 1;
    }
    for (var n in nuevos) {
      if (!dispositivosEncontrados.any((d) => d.address == n.address)) {
        dispositivosEncontrados.add(n);
      }
    }
    dispositivosEncontrados.removeWhere((d) => d.missedScans >= 3);

    notifyListeners();
  }

  void _cancelarEscaneo() {
    _scanSubscription?.cancel();
    ble.FlutterBluePlus.stopScan();
    _scanTimer?.cancel();
  }

  @override
  void dispose() {
    _cancelarEscaneo();
    super.dispose();
  }
}
