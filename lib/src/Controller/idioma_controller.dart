import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IdiomaController extends ChangeNotifier {
  Locale _locale = const Locale('es'); // Español por defecto

  Locale get locale => _locale;

  IdiomaController() {
    _cargarIdiomaInicial();
  }

  /// Cambiar idioma manualmente y guardar preferencia
  Future<void> cambiarIdioma(String codigoIdioma) async {
    _locale = Locale(codigoIdioma);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('idiomaSeleccionado', codigoIdioma);
  }

  /// Cargar idioma desde almacenamiento o sistema
  Future<void> _cargarIdiomaInicial() async {
    final prefs = await SharedPreferences.getInstance();
    final idiomaGuardado = prefs.getString('idiomaSeleccionado');

    if (idiomaGuardado != null) {
      _locale = Locale(idiomaGuardado);
    } else {
      final sistema =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final soportados = ['es', 'en', 'fr', 'pt'];

      _locale =
          soportados.contains(sistema)
              ? Locale(sistema)
              : const Locale('es'); // predeterminado
    }

    notifyListeners();
  }
}
