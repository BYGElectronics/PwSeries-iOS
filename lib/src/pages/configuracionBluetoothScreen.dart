// lib/src/pages/configuracionBluetoothScreen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pw/widgets/header_widget_back.dart';

import '../../widgets/TecladoPinWidget.dart';
// import '../../widgets/header_widget.dart'; // <- no se usa, lo quité
import '../Controller/ConfiguracionBluetoothController.dart';
import 'package:shared_preferences/shared_preferences.dart';


const kIsPinConfiguredKey = 'is_pin_configured_ok';
const kSavedDeviceIdKey   = 'saved_btpw_id';
const kSavedDeviceNameKey = 'saved_btpw_name';

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

class _ConfiguracionBluetoothView extends StatefulWidget {
  const _ConfiguracionBluetoothView({Key? key}) : super(key: key);

  @override
  State<_ConfiguracionBluetoothView> createState() =>
      _ConfiguracionBluetoothViewState();
}

class _ConfiguracionBluetoothViewState
    extends State<_ConfiguracionBluetoothView> {
  Timer? _timeoutTimer;
  bool _timeoutElapsed = false; // tras 10s, cambia el mensaje

  @override
  void initState() {
    super.initState();
    _startTimeout();
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      setState(() => _timeoutElapsed = true);
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  bool _isBtpwName(String? name) {
    final n = (name ?? '').trim();
    return n.toUpperCase().contains('BTPW');
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final controller = context.watch<ConfiguracionBluetoothController>();

    // Filtra SOLO dispositivos BTPW
    final btpwList = controller.dispositivosEncontrados.where((d) {
      try {
        return _isBtpwName(d.name);
      } catch (_) {
        return false;
      }
    }).toList();

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
                // ⚓️ TÍTULO FIJO
                Center(
                  child: Text(
                    'DISPOSITIVOS DISPONIBLES',
                    style: TextStyle(
                      fontFamily: 'PWSeriesFont',
                      fontSize: w * 0.054,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Divider(thickness: 2, color: theme.dividerColor),
                SizedBox(height: h * 0.01),

                // ↓ SOLO cambia esta zona (mensaje/lista + update)
                Expanded(
                  child: btpwList.isEmpty
                      ? LayoutBuilder(
                    builder: (context, c) => Center(
                      // Bloque centrado siempre, con adaptación de tamaño
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              // límite de ancho para que FittedBox pueda escalar hacia abajo
                              maxWidth: c.maxWidth * 0.9,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _timeoutElapsed
                                    ? 'No hay Dispositivo BTPW disponibles...'
                                    : 'Buscando dispositivos...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: w * 0.05,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Imagen "update.png" (reintento)
                          GestureDetector(
                            onTap: () {
                              setState(() => _timeoutElapsed = false);
                              _startTimeout();
                              context
                                  .read<ConfiguracionBluetoothController>()
                                  .iniciarEscaneo();
                            },
                            child: Image.asset(
                              'assets/images/update.png', // ajusta el path si es otro
                              width: w * 0.15,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      : ListView(
                    children: btpwList
                        .where((d) =>
                    controller.selectedDevice == null ||
                        controller.selectedDevice!.id == d.id)
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
                                        color: theme
                                            .textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    SizedBox(height: h * 0.001),
                                    Text(
                                      d.id, // antes: d.address
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
                                Text(
                                  controller.pinIngresado
                                      .replaceAll(RegExp(r'.'), '•'),
                                  style: TextStyle(
                                    fontSize: w * 0.08,
                                    letterSpacing: w * 0.01,
                                    color: theme
                                        .textTheme.bodyLarge?.color,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: h * 0.01),

                                SizedBox(
                                  height: h * 0.70,
                                  child: TecladoPinWidget(
                                      onPinComplete: (pin) async {
                                        controller.pinIngresado = pin;
                                        await controller.enviarPinYConectar(context);

                                        if (controller.ultimoResultadoConexion == true) {
                                          final prefs = await SharedPreferences.getInstance();
                                          final String deviceId   = d.id;   // la MAC/RemoteId del item 'd'
                                          final String deviceName = d.name;

                                          await prefs.setBool(kIsPinConfiguredKey, true);
                                          await prefs.setString(kSavedDeviceIdKey, deviceId);
                                          await prefs.setString(kSavedDeviceNameKey, deviceName);

                                          if (context.mounted) {
                                            Navigator.of(context).pushNamedAndRemoveUntil(
                                              '/control',
                                                  (route) => false,
                                              arguments: {'deviceId': deviceId}, // pasa la MAC a /control
                                            );
                                          }
                                        }
                                      }

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
