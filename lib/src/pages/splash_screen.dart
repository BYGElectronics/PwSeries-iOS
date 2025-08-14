// lib/src/pages/splash_screen.dart

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// Clave única para saber si el PIN ya se estableció correctamente.
/// En tu flujo de configuración, cuando el PIN quede OK:
///   final prefs = await SharedPreferences.getInstance();
///   await prefs.setBool(kIsPinConfiguredKey, true);
const String kIsPinConfiguredKey = 'is_pin_configured_ok';

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Si por alguna razón se ejecuta en otra plataforma, simplemente continúa (no hace conexiones).
    unawaited(_boot());
  }

  Future<void> _boot() async {
    // 1) Pequeño delay para mostrar el splash (opcional)
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    // 2) Leer bandera de PIN desde preferencias
    final prefs = await SharedPreferences.getInstance();
    final bool isPinConfigured = prefs.getBool(kIsPinConfiguredKey) ?? false;

    // 3) Decidir navegación SIN iniciar ninguna conexión
    if (!mounted) return;
    if (isPinConfigured) {
      // PIN OK → ir a control
      _goTo('/control');
    } else {
      // PIN NO configurado → ir a configuración inicial
      _goTo('/home');
    }
  }

  void _goTo(String routeName) {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    // UI de splash full-screen
    return Scaffold(
      body: Center(
        child: Image.asset(
          "assets/images/splash_screens/splash_screen.png",
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (ctx, error, stack) => Container(
            color: Colors.black,
            child: const Icon(Icons.error, color: Colors.red, size: 48),
          ),
        ),
      ),
    );
  }
}
