import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pw/src/Controller/idioma_controller.dart';

import '../../widgets/header_widget.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const HomeScreen({
    super.key,
    required this.toggleTheme,
    required this.themeMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
    final idioma = Provider.of<IdiomaController>(context).locale.languageCode;

    final size = MediaQuery.of(context).size;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Padding lateral razonable
    final double horizontalPadding = math.max(screenWidth * 0.06, 16);

    // Tamaños máximos del botón (nunca se deforma)
    final double maxButtonWidth = math.min(
      screenWidth * 0.80,
      520,
    ); // tope absoluto
    final double maxButtonHeight = math.min(screenHeight * 0.18, 180);

    final String rutaConfig = _localizedButton("configInicial", idioma);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned(top: 0, left: 0, right: 0, child: HeaderWidget()),

          // Botón configuración inicial (centrado, HD, sin deformar)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: GestureDetector(
                onTap:
                    () =>
                        Navigator.pushNamed(context, '/configuracionBluetooth'),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxButtonWidth,
                    maxHeight: maxButtonHeight,
                  ),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final targetWidthPx =
                          (c.maxWidth * dpr).round(); // para HD
                      return FittedBox(
                        fit: BoxFit.contain, // NO deforma
                        child: Image.asset(
                          rutaConfig,
                          // Decodifica a la resolución óptima del dispositivo
                          cacheWidth: targetWidthPx > 0 ? targetWidthPx : null,
                          filterQuality: FilterQuality.high,
                          isAntiAlias: true,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: c.maxWidth,
                              height: c.maxHeight,
                              color: Colors.grey[300],
                              alignment: Alignment.center,
                              child: const Text('Error al cargar imagen'),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Botón demo (esquina inferior derecha) — sin cambios
          Positioned(
            bottom: screenHeight * 0.05,
            right: horizontalPadding * 0.5,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/demoConfig'),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildDemoImage(screenWidth * 0.23, screenHeight * 0.23),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoImage(double width, double height) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, maxHeight: height),
      child: Image.asset(
        'assets/images/demo/demo.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: const Text('Error al cargar imagen'),
          );
        },
      ),
    );
  }
}
