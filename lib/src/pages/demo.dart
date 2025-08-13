import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pw/widgets/DemoWidget.dart';
import 'package:pw/widgets/header_menu_back_widget.dart';
import 'package:pw/src/Controller/control_controller.dart';
import '../../widgets/drawerMenuWidget.dart';

class DemoScreen extends StatefulWidget {
  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> with WidgetsBindingObserver {
  late ControlController _controller;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _controller = Provider.of<ControlController>(context, listen: false);

      // 🔴 Desconecta BLE y Classic al entrar
      debugPrint("🔧 Entrando a DEMO: desconectando BT");
      await _controller.disconnectBtClassic(); // Desconecta Classic si está activo
      await _controller.disconnectDevice(); // Desconecta BLE si está activo
    });
  }

  @override
  void dispose() {
    debugPrint("🔁 Saliendo de DEMO: reconectando BT si aplica");

    _controller.tryReconnectClassic(); // Reconecta Classic si hay MAC registrada
    _controller.conectarManualBLE(context, silent: true); // Reconecta BLE en segundo plano

    super.dispose();
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
            top: 0,
            left: 0,
            right: 0,
            child: HeaderMenuBackWidget(),
          ),

          Positioned(
            top: h * 0.40,
            child: Image.asset(
              "assets/images/tecladoPw/fondo/fondoPrincipal.png",
              width: fw,
              height: fh,
              fit: BoxFit.contain,
            ),
          ),

          Positioned(
            top: h * 0.70,
            child: SizedBox(
              width: fw,
              height: fh,
              child: Center(
                child: Text(
                  'DEMO',
                  style: TextStyle(
                    fontSize: 90,
                    fontFamily: 'PWSeriesFont',
                    color: const Color(0xFF0075BE),
                    letterSpacing: 5,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: h * 0.42,
            child: Demowidget(fondoWidth: fw, fondoHeight: fh),
          ),
        ],
      ),
    );
  }
}
