// lib/src/pages/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kIsPinConfiguredKey = 'is_pin_configured_ok';
const kSavedDeviceIdKey   = 'saved_btpw_id';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Espera al primer frame para asegurar que el splash pinte
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Precarga de la imagen (opcional, ayuda a evitar parpadeos)
      await precacheImage(
        const AssetImage('assets/images/splash_screens/SPLASH.png'),
        context,
      );
      _boot();
    });
  }

  Future<void> _boot() async {
    // Pequeño delay opcional para que el splash se vea
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || _navigated) return;

    final prefs = await SharedPreferences.getInstance();
    final isPinConfigured = prefs.getBool(kIsPinConfiguredKey) ?? false;
    final savedId = prefs.getString(kSavedDeviceIdKey);

    _navigated = true;

    if (isPinConfigured) {
      // ✅ Ir a /control y, si hay MAC guardada, pasarla como argumento
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/control',
            (route) => false,
        arguments: (savedId != null && savedId.isNotEmpty)
            ? {'deviceId': savedId}
            : null,
      );
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // 🔒 desactiva "back" mientras se muestra el splash
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black, // fallback por si el asset tarda
        body: const SizedBox.expand(child: _SplashImage()),
      ),
    );
  }
}

class _SplashImage extends StatelessWidget {
  const _SplashImage();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/splash_screens/SPLASH.png',
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (ctx, err, st) => const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Icon(Icons.error, color: Colors.red, size: 48),
        ),
      ),
    );
  }
}
