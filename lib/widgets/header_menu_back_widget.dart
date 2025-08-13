// lib/widgets/header_widget.dart
import 'package:flutter/material.dart';

class HeaderMenuBackWidget extends StatelessWidget {
  const HeaderMenuBackWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener dimensiones de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final headerHeight = screenHeight * 0.15;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return SizedBox(
      width: screenWidth,
      height: headerHeight,
      child: Stack(
        children: [
          // Fondo del header
          Image.asset(
            'assets/images/header/header.png',
            width: screenWidth,
            height: headerHeight,
            fit: BoxFit.cover,
          ),

          // Botón menú hamburguesa (izquierda)
          Positioned(
            left: 8,
            top: statusBarHeight + 8,
            child: Builder(
              builder:
                  (ctx) => IconButton(
                    icon: const Icon(Icons.menu, size: 32, color: Colors.white),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
            ),
          ),

          // Botón volver (derecha)
          Positioned(
            right: 5,
            top: statusBarHeight + 8,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_circle_left_rounded,
                size: 40,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).maybePop();
              },
            ),
          ),

          // (Opcional) logo o texto centrado
          // Positioned.fill(
          //   child: Center(
          //     child: Text(
          //       'PW series',
          //       style: TextStyle(
          //         color: Colors.white,
          //         fontSize: headerHeight * 0.3,
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
