import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:pw/widgets/DemoWidget.dart';
import 'package:pw/widgets/header_widget_back.dart';
import '../../widgets/header_widget.dart';
import '../Controller/bluetooth_helper.dart';
import 'package:pw/src/Controller/control_controller.dart';
import 'package:pw/widgets/header_menu_widget.dart';
import '../../widgets/drawerMenuWidget.dart';
import '../../widgets/tecladoPwWidget.dart';
import '../Controller/estatus.dart';
import '../Controller/idioma_controller.dart';

class DemoScreenConfigInicial extends StatefulWidget {
  @override
  State<DemoScreenConfigInicial> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreenConfigInicial> with WidgetsBindingObserver {
  late ControlController _controller;

  @override
  void initState() {
    super.initState();

    // Ejecutar tras construir el contexto
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _controller = Provider.of<ControlController>(context, listen: false);
      await _controller.disconnectClassic(); // desconecta el Classic al entrar
    });
  }

  @override
  void dispose() {
    _controller.tryReconnectClassic(); // reconecta al salir del demo
    super.dispose();
  }

  String _localizedButton(String name, String code) {
    const folder = "assets/images/Botones";
    switch (code) {
      case 'es':
        return "$folder/Espanol/$name.png";
      case 'en':
        return "$folder/Ingles/${name}_1.png";
      case 'pt':
        return "$folder/Portugues/${name}_3.png";
      case 'fr':
        return "$folder/Frances/${name}_2.png";
      default:
        return "$folder/Espanol/$name.png";
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
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWidgetBack(),
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
                    letterSpacing: 0,
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
