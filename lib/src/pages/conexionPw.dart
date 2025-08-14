import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pw/widgets/header_menu_back_widget.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;

import '../../widgets/drawerMenuWidget.dart';
import '../../widgets/header_menu_widget.dart';
import '../localization/app_localization.dart';

class ConexionpwScreen extends StatelessWidget {
  const ConexionpwScreen({Key? key}) : super(key: key);

  Future<void> _olvidarPW(BuildContext context) async {
    // 1) Desconectar BLE (cualquier dispositivo conectado)
    try {
      final List<ble.BluetoothDevice> devices =
          await ble.FlutterBluePlus.connectedDevices;
      for (final d in devices) {
        try {
          await d.disconnect();
        } catch (_) {}
      }
    } catch (_) {
      // Ignorar errores de desconexión
    }

    // 2) Borrar bandera de configuración inicial
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasCompletedInitialConfig');

    // 3) Enviar a configuración inicial
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/configuracionBluetooth', // <- volver al flujo de PIN/config
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);

    return MediaQuery(
      data: mq.copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        drawer: const AppDrawer(),
        body: Stack(
          children: [
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: HeaderMenuBackWidget(),
            ),
            Positioned(
              top: mq.size.height * 0.18,
              left: 27,
              right: 27,
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      localizer.translate('conexion_pw'),
                      style: TextStyle(
                        fontFamily: 'PWSeriesFont',
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(thickness: 2, color: Theme.of(context).dividerColor),
                  const SizedBox(height: 24),

                  // Botón único: Olvidar PW
                  Center(
                    child: SizedBox(
                      width: mq.size.width * 0.6,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _olvidarPW(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0075BE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          localizer.translate('olvidar_pw'),
                          style: const TextStyle(
                            fontFamily: 'PWSeriesFont',
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
