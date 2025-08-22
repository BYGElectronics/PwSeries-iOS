import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:io' show Platform;

class PttAudioController {
  final StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>();

  bool _isRecorderInitialized = false;
  BluetoothConnection? classicConnection;

  /// Inicializa el grabador y escucha el audio
  Future<void> init() async {}

  /// Permite inyectar la conexión Bluetooth Classic desde fuera
  void setClassicConnection(BluetoothConnection connection) {
    if (Platform.isAndroid) {
      classicConnection = connection;
    }
  }
}
