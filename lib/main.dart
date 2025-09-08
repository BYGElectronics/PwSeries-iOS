// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // no se usa aquí

// CONTROLADORES
import 'package:pw/src/Controller/control_controller.dart';
import 'package:pw/src/Controller/estatus.dart';
import 'package:pw/src/Controller/home_controller.dart';
import 'package:pw/src/Controller/config_controller.dart';
import 'package:pw/src/Controller/idioma_controller.dart';
import 'package:pw/src/Controller/pttController.dart';
import 'package:pw/src/Controller/text_size_controller.dart';
import 'package:pw/src/Controller/theme_controller.dart';
import 'package:pw/src/localization/app_localization.dart';

// PANTALLAS
import 'package:pw/src/pages/acercaDe.dart';
import 'package:pw/src/pages/conexionPw.dart';
import 'package:pw/src/pages/configAvanzadaScreen.dart';
import 'package:pw/src/pages/configTecladoScreen.dart';
import 'package:pw/src/pages/configuracionBluetoothScreen.dart';
import 'package:pw/src/pages/controlConfig.dart';
import 'package:pw/src/pages/control_screen.dart';
import 'package:pw/src/pages/darkModeScreen.dart';
import 'package:pw/src/pages/demo.dart';
import 'package:pw/src/pages/demoConfigInicial.dart';
import 'package:pw/src/pages/splashScreenConfirmation.dart';
import 'package:pw/src/pages/splashScreenDenegate.dart';
import 'package:pw/src/pages/splash_screen.dart';
import 'package:pw/src/pages/home_screen.dart';
import 'package:pw/src/pages/idioma_screen.dart';
import 'package:pw/src/pages/text_size_screen.dart';

/// Instancia única de ControlController que se compartirá globalmente
final ControlController _controlController = ControlController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.microphone.request();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IdiomaController()),
        ChangeNotifierProvider(create: (_) => TextSizeController()),
        ChangeNotifierProvider(create: (_) => ConfigController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider<EstadoSistemaController>(
          lazy: false,
          create: (_) {
            final estadoCtrl = EstadoSistemaController();
            estadoCtrl.startPolling(const Duration(seconds: 1));
            return estadoCtrl;
          },
        ),
        ChangeNotifierProvider<ControlController>.value(
          value: _controlController,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// La aplicación principal
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final idiomaController = Provider.of<IdiomaController>(context);
    final textSizeController = Provider.of<TextSizeController>(context);
    final themeController = Provider.of<ThemeController>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // =============================
      //   LOCALIZACIÓN / IDIOMA
      // =============================
      locale: idiomaController.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      // =============================
      //      TEMAS Y ESTILOS
      // =============================
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        textTheme: Theme.of(context).textTheme.apply(
          fontSizeFactor: textSizeController.textScaleFactor,
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        textTheme: Theme.of(context).textTheme.apply(
          fontSizeFactor: textSizeController.textScaleFactor,
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      themeMode: themeController.themeMode,

      // =============================
      //   FORZAR ESCALA DE TEXTO
      // =============================
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },

      // =============================
      //        RUTAS / ROUTES
      // =============================
      initialRoute: '/',
      routes: {
        "/": (context) => const SplashScreen(),
        "/home": (context) => HomeScreen(
          toggleTheme: () => themeController.toggleDarkMode(true),
          themeMode: themeController.themeMode,
        ),
        "/idioma": (context) => const IdiomaScreen(),
        "/configuracionBluetooth": (context) => const ConfiguracionBluetoothScreen(),
        "/configAvanzada": (context) => const ConfigAvanzadaScreen(),
        "/configTeclado": (context) => ConfigTecladoScreen(controller: _controlController),
        "/themeConfig": (context) => const ThemeScreen(),
        "/splash_denegate": (context) => const SplashConexionDenegateScreen(),
        "/textSize": (context) => const TextSizeScreen(),
        "/acercaDe": (context) => const AcercadeScreen(),
        "/conexionPw": (context) => const ConexionpwScreen(),
        "/demo": (context) => DemoScreen(),
        "/demoConfig": (context) => DemoScreenConfigInicial(),
        "/splash_confirmacion": (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return SplashConexionScreen(
            device: args['device'] as BluetoothDevice,
            controller: args['controller'] as ControlController,
          );
        },

        // ✅ Acepta 'device' o 'deviceId' y pasa 'savedDeviceId' a ControlScreen
        "/control": (context) {
          final settings = ModalRoute.of(context)!.settings;
          final args = settings.arguments;

          BluetoothDevice? device = _controlController.connectedDevice;
          String? deviceId;

          if (args is Map<String, dynamic>) {
            if (args['device'] is BluetoothDevice) {
              device = args['device'] as BluetoothDevice;
            }
            if (args['deviceId'] is String) {
              deviceId = args['deviceId'] as String;
            }
          }

          return ControlScreen(
            connectedDevice: device,
            controller: _controlController,
            // 👇 nuevo parámetro en ControlScreen para reconectar por MAC
            savedDeviceId: deviceId,
          );
        },

        "/controlConfig": (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ControlConfigScreen(
            connectedDevice: args['device'] as BluetoothDevice,
            controller: _controlController,
          );
        },
      },
    );
  }
}
