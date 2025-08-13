import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pw/widgets/header_menu_back_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/drawerMenuWidget.dart';
import '../Controller/ConfiguracionBluetoothController.dart';
import '../Controller/idioma_controller.dart';
import '../localization/app_localization.dart';

class AcercadeScreen extends StatelessWidget {
  const AcercadeScreen({Key? key}) : super(key: key);

  /// Retorna la ruta del botón localizada según el idioma
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
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(textScaleFactor: 1.0),
      child: ChangeNotifierProvider(
        create: (_) => ConfiguracionBluetoothController(),
        builder: (context, _) {
          return Consumer<IdiomaController>(
            builder: (context, idiomaCtrl, __) {
              final code = idiomaCtrl.locale.languageCode;
              final localizer = AppLocalizations.of(context)!;

              return Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                drawer: const AppDrawer(),
                body: Stack(
                  children: [
                    // Header
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: HeaderMenuBackWidget(),
                    ),

                    // Contenido
                    Positioned(
                      top: mq.size.height * 0.18,
                      left: 27,
                      right: 27,
                      bottom: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título
                          Center(
                            child: Text(
                              localizer.translate('acerca_de'),
                              style: TextStyle(
                                fontFamily: 'PWSeriesFont',
                                fontSize: 27,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),
                          Divider(
                            thickness: 2,
                            color: Theme.of(context).dividerColor,
                          ),
                          const SizedBox(height: 15),

                          // Texto
                          Text(
                            localizer.translate('desarrollado_por'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Logo
                          Center(
                            child: Image.asset(
                              'assets/images/desarrollado_por/byg.png',
                              width: mq.size.width * 0.7,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const Spacer(),

                          // Botón WhatsApp
                          Center(
                            child: GestureDetector(
                              onTap: () => _launchWhatsApp(context),
                              child: Image.asset(
                                _localizedButton('contactanos', code),
                                width: mq.size.width * 0.7,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Versión
                          Center(
                            child: Text(
                              "${localizer.translate('version')} 1.0.2",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Función corregida para redirigir a WhatsApp
  Future<void> _launchWhatsApp(BuildContext context) async {
    final localizer = AppLocalizations.of(context)!;
    const phone = '573160101123';
    final message = Uri.encodeComponent(
      'Hola, Vengo de la Aplicación Pw Series.',
    );
    final url = Uri.parse("https://wa.me/$phone?text=$message");

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizer.translate('whatsapp_error'))),
      );
    }
  }


}
