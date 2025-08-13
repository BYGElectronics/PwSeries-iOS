import 'package:flutter/material.dart';

class HeaderWidgetBack extends StatelessWidget {
  const HeaderWidgetBack({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener dimensiones de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calcular altura del header responsiva
    final headerHeight = screenHeight * 0.15;

    return SizedBox(
      width: screenWidth,
      height: headerHeight,
      child: Stack(
        children: [
          Image.asset(
            'assets/images/header/header.png',
            width: screenWidth,
            height: headerHeight,
            fit: BoxFit.cover,
          ),
          Positioned(
            right: 4,
            top: headerHeight * 0.31,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_circle_left_rounded, // Flecha más recta y moderna
                color: Colors.white,
                size: 40, // Más grande
                weight: 800, // Disponible solo en versiones recientes de Flutter
              ),
              onPressed: () {
                Navigator.of(context).maybePop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
