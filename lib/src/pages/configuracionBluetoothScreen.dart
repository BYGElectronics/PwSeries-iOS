// lib/src/pages/configuracionBluetoothScreen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pw/widgets/header_widget_back.dart';

import '../../widgets/TecladoPinWidget.dart';
import '../../widgets/header_widget.dart';
import '../Controller/ConfiguracionBluetoothController.dart';

class ConfiguracionBluetoothScreen extends StatelessWidget {
  const ConfiguracionBluetoothScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ConfiguracionBluetoothController>(
      create: (_) => ConfiguracionBluetoothController()..iniciarEscaneo(),
      child: const _ConfiguracionBluetoothView(),
    );
  }
}

class _ConfiguracionBluetoothView extends StatelessWidget {
  const _ConfiguracionBluetoothView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final controller = context.watch<ConfiguracionBluetoothController>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Cabecera fija
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWidgetBack(),
          ),

          // Contenido principal
          Positioned(
            top: h * 0.18,
            left: w * 0.05,
            right: w * 0.05,
            bottom: h * 0.05,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'DISPOSITIVOS DISPONIBLES',
                    style: TextStyle(
                      fontFamily: 'PWSeriesFont',
                      fontSize: w * 0.054,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                Divider(thickness: 2, color: theme.dividerColor),
                SizedBox(height: h * 0.01),

                // Lista o mensaje de búsqueda
                Expanded(
                  child: controller.dispositivosEncontrados.isEmpty
                      ? Center(
                    child: Text(
                      'Buscando dispositivos...',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: w * 0.05,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  )
                      : ListView(
                    children: controller.dispositivosEncontrados
                        .where(
                          (d) =>
                      controller.selectedDevice == null ||
                          controller.selectedDevice!.id == d.id,
                    )
                        .map((d) {
                      final showPin =
                          controller.selectedDevice?.id == d.id;
                      final isConnecting = controller.estadoConectando &&
                          controller.selectedDevice?.id == d.id;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fila del dispositivo
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'PWSeriesFont',
                                        fontSize: w * 0.05,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textTheme.bodyLarge
                                            ?.color,
                                      ),
                                    ),
                                    SizedBox(height: h * 0.001),
                                    Text(
                                      d.id, // <-- antes: d.address
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        fontSize: w * 0.020,
                                        color: theme.hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: isConnecting
                                    ? null
                                    : () => controller
                                    .togglePinVisibility(d),
                                child: Image.asset(
                                  isConnecting
                                      ? 'assets/images/Botones/Espanol/conectando.png'
                                      : 'assets/images/Botones/Espanol/conectar.png',
                                  width: w * 0.4,
                                  height: h * 0.04,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),

                          // Teclado de PIN (solo si se seleccionó este dispositivo)
                          if (showPin) ...[
                            SizedBox(height: h * 0.02),
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              children: [
                                // Mostrar PIN ingresado como ••••
                                Text(
                                  controller.pinIngresado.replaceAll(
                                    RegExp(r'.'),
                                    '•',
                                  ),
                                  style: TextStyle(
                                    fontSize: w * 0.08,
                                    letterSpacing: w * 0.01,
                                    color:
                                    theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                SizedBox(height: h * 0.01),

                                // Teclado numérico
                                SizedBox(
                                  height: h * 0.70,
                                  child: TecladoPinWidget(
                                    onPinComplete: (pin) async {
                                      // 1) Guardar PIN en el controlador
                                      controller.pinIngresado = pin;

                                      // 2) Intentar conectar con el PIN (BLE + auth)
                                      await controller
                                          .enviarPinYConectar(context);

                                      // 3) Si todo OK, ir al Control
                                      if (controller
                                          .ultimoResultadoConexion ==
                                          true) {
                                        if (context.mounted) {
                                          Navigator.of(context)
                                              .pushReplacementNamed(
                                            '/control',
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                          SizedBox(height: h * 0.02),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
