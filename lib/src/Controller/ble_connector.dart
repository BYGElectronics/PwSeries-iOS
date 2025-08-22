// lib/src/services/ble_connector.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:pw/src/Controller/preferred_device_storage.dart';

typedef OnConnected = Future<void> Function(ble.BluetoothDevice dev, ble.BluetoothCharacteristic writeChar);
typedef OnDisconnected = void Function();

class BleConnector {
  final PreferredDeviceStorage storage;
  final OnConnected onConnected;
  final OnDisconnected? onDisconnected;


  BleConnector({
    required this.storage,
    required this.onConnected,
    this.onDisconnected,
  });

  bool _manualDisconnect = false;
  bool _userRequestedDisconnect = false;
  bool _isConnecting = false;
  StreamSubscription<ble.BluetoothConnectionState>? _connStateSub;

  Future<void> userDisconnect(ble.BluetoothDevice? current) async {
    _userRequestedDisconnect = true;
    _manualDisconnect = true;
    await _connStateSub?.cancel();
    _connStateSub = null;
    if (current != null) {
      try { await current.disconnect(); } catch (_) {}
    }
    onDisconnected?.call();
  }

  Future<bool> connectPreferred(BuildContext context, {Duration timeout = const Duration(seconds: 12), bool silent = false}) async {
    if (_isConnecting) return false;
    _isConnecting = true;

    final preferredId = await storage.getPreferredId();
    if (preferredId == null) {
      _isConnecting = false;
      if (!silent && context.mounted) {
        Navigator.pushReplacementNamed(context, '/splash_denegate');
      }
      return false;
    }

    _manualDisconnect = false;
    _userRequestedDisconnect = false;

    ble.BluetoothDevice dev = ble.BluetoothDevice.fromId(preferredId);

    // Intento directo
    try {
      if (dev.connectionState != ble.BluetoothConnectionState.connected) {
        await dev.connect(timeout: const Duration(seconds: 8));
      }
    } catch (_) {
      // Escaneo focalizado al ID
      final completer = Completer<ble.BluetoothDevice>();
      final sub = ble.FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          if (r.device.remoteId.str == preferredId) {
            if (!completer.isCompleted) completer.complete(r.device);
          }
        }
      });

      try {
        await ble.FlutterBluePlus.startScan(timeout: timeout);
        dev = await completer.future.timeout(timeout);
      } catch (_) {
        try { await ble.FlutterBluePlus.stopScan(); } catch (_) {}
        try { await sub.cancel(); } catch (_) {}
        _isConnecting = false;
        if (!silent && context.mounted) {
          Navigator.pushReplacementNamed(context, '/splash_denegate');
        }
        return false;
      } finally {
        try { await ble.FlutterBluePlus.stopScan(); } catch (_) {}
        try { await sub.cancel(); } catch (_) {}
      }

      try {
        if (dev.connectionState != ble.BluetoothConnectionState.connected) {
          await dev.connect(timeout: const Duration(seconds: 8));
        }
      } catch (_) {
        _isConnecting = false;
        if (!silent && context.mounted) {
          Navigator.pushReplacementNamed(context, '/splash_denegate');
        }
        return false;
      }
    }

    // Descubrir servicios y tomar ff01
    try {
      await dev.discoverServices();
      ble.BluetoothCharacteristic? writeChar;
      for (final s in dev.servicesList) {
        for (final c in s.characteristics) {
          if (c.uuid.toString().toLowerCase().contains('ff01')) {
            writeChar = c;
            break;
          }
        }
        if (writeChar != null) break;
      }

      if (writeChar == null) {
        _isConnecting = false;
        if (!silent && context.mounted) {
          Navigator.pushReplacementNamed(context, '/splash_denegate');
        }
        return false;
      }

      // Callbacks hacia el controller
      await onConnected(dev, writeChar);

      // Listener controlado de reconexión
      await _connStateSub?.cancel();
      _connStateSub = dev.connectionState.listen((s) async {
        if (s == ble.BluetoothConnectionState.disconnected) {
          onDisconnected?.call();
          // Reintento SOLO si no fue pedido por el usuario
          if (!_manualDisconnect && !_userRequestedDisconnect) {
            await connectPreferred(context, silent: true);
          }
        }
      });

      _isConnecting = false;
      if (!silent && context.mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/splash_confirmacion',
          arguments: {'device': dev},
        );
      }
      return true;
    } catch (_) {
      _isConnecting = false;
      if (!silent && context.mounted) {
        Navigator.pushReplacementNamed(context, '/splash_denegate');
      }
      return false;
    }
  }
}
