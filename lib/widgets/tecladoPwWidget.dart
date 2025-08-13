// lib/widgets/tecladoPwWidget.dart

import 'package:flutter/material.dart';
import '../src/Controller/control_controller.dart';

class TecladoPW extends StatelessWidget {
  final ValueNotifier<bool> estaConectado;
  final ControlController controller;
  final double fondoWidth;
  final double fondoHeight;

  const TecladoPW({
    Key? key,
    required this.estaConectado,
    required this.controller,
    required this.fondoWidth,
    required this.fondoHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: estaConectado,
      builder: (context, conectado, child) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPressHoldButton(
                  assetOn: "assets/images/tecladoPw/botones/On/wailOn.png",
                  assetOff: "assets/images/tecladoPw/botones/Off/wailOff.png",
                  onPress: () => controller.pressWailApp(),
                  onRelease: () => controller.releaseWailApp(),
                  enabled: conectado,
                  width: fondoWidth * 0.25,
                  height: fondoHeight * 0.35,
                ),
                _buildSimpleButton(
                  asset: conectado
                      ? "assets/images/tecladoPw/botones/On/sirenaOn.png"
                      : "assets/images/tecladoPw/botones/Off/sirenaOff.png",
                  onTap: conectado
                      ? controller.activateSiren
                      : () => _showNoConnectionAlert(context),
                  width: fondoWidth * 0.40,
                  height: fondoHeight * 0.40,
                ),
                _buildSimpleButton(
                  asset: "assets/images/tecladoPw/botones/Off/interOff.png",
                  onTap: conectado
                      ? controller.activateInter
                      : () => _showNoConnectionAlert(context),
                  width: fondoWidth * 0.25,
                  height: fondoHeight * 0.35,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPressHoldButton(
                  assetOn: "assets/images/tecladoPw/botones/On/hornOn.png",
                  assetOff: "assets/images/tecladoPw/botones/Off/hornOff.png",
                  onPress: () => controller.pressHornApp(),
                  onRelease: () => controller.releaseHornApp(),
                  enabled: conectado,
                  width: fondoWidth * 0.25,
                  height: fondoHeight * 0.35,
                ),
                _buildSimpleButton(
                  asset: conectado
                      ? "assets/images/tecladoPw/botones/On/auxOn.png"
                      : "assets/images/tecladoPw/botones/Off/auxOff.png",
                  onTap: conectado
                      ? controller.activateAux
                      : () => _showNoConnectionAlert(context),
                  width: fondoWidth * 0.35,
                  height: fondoHeight * 0.30,
                ),
                _buildPressHoldButton(
                  assetOn: "assets/images/tecladoPw/botones/On/pttOn.png",
                  assetOff: "assets/images/tecladoPw/botones/Off/pttOff.png",
                  onPress: () => controller.togglePTT(forceOn: true),
                  onRelease: () => controller.togglePTT(forceOn: false),
                  enabled: conectado,
                  width: fondoWidth * 0.25,
                  height: fondoHeight * 0.35,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSimpleButton({
    required String asset,
    required VoidCallback onTap,
    double width = 100,
    double height = 70,
  }) => GestureDetector(
    onTap: onTap,
    child: Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
    ),
  );

  Widget _buildPressHoldButton({
    required String assetOn,
    required String assetOff,
    required VoidCallback onPress,
    required VoidCallback onRelease,
    required bool enabled,
    double width = 100,
    double height = 70,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        if (enabled) onPress();
      },
      onTapUp: (_) {
        if (enabled) onRelease();
      },
      onTapCancel: () {
        if (enabled) onRelease();
      },
      child: Image.asset(
        enabled ? assetOn : assetOff,
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }

  void _showNoConnectionAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❗ Debes conectar al dispositivo PW primero'),
      ),
    );
  }
}
