import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pw/src/Controller/idioma_controller.dart';

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

  /// Carga imagen traducida como en control_screen.dart
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

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double headerHeight = (screenHeight * 0.15).clamp(80.0, 150.0);
    final double buttonConfigWidthRatio = 1.0;
    final double buttonConfigHeightRatio = 0.07;
    final double buttonWidth = screenWidth * buttonConfigWidthRatio;
    final double buttonHeight = screenHeight * buttonConfigHeightRatio;
    final double buttonDemoWidth = screenWidth * 0.23;
    final double buttonDemoHeight = screenHeight * 0.15;
    final double horizontalPadding = screenWidth * 0.1;

    final String rutaConfig = _localizedButton("configInicial", idioma);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: headerHeight,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/header/header.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          // Botón configuración inicial (centrado)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/configuracionBluetooth');
                },
                child: Container(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: Image.asset(
                    rutaConfig,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(child: Text('Error al cargar imagen')),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Botón demo (esquina inferior derecha)
          Positioned(
            bottom: screenHeight * 0.05,
            right: horizontalPadding * 0.5,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/demoConfig');
              },
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildDemoImage(buttonDemoWidth, buttonDemoHeight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoImage(double width, double height) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: width,
        maxHeight: height,
      ),
      child: Image.asset(
        'assets/images/demo/demo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Center(child: Text('Error al cargar imagen')),
          );
        },
      ),
    );
  }
}
