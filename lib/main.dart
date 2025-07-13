import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'utils/colors.dart';

void main() {
  // Asegurar que los widgets estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar la orientación de la app (solo vertical)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configurar el estilo de la barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const BioWayApp());
}

class BioWayApp extends StatelessWidget {
  const BioWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BioWay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Colores principales
        primarySwatch: Colors.green,
        primaryColor: BioWayColors.primaryGreen,

        // Color de fondo por defecto
        scaffoldBackgroundColor: Colors.white,

        // Configuración de AppBar
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: BioWayColors.darkGreen),
          titleTextStyle: TextStyle(
            color: BioWayColors.darkGreen,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),

        // Configuración de botones elevados
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: BioWayColors.primaryGreen,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Configuración de botones con borde
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: BioWayColors.primaryGreen,
            side: const BorderSide(
              color: BioWayColors.primaryGreen,
              width: 2,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Configuración de campos de texto
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: BioWayColors.primaryGreen,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: BioWayColors.error,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),

        // Configuración de texto
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: BioWayColors.darkGreen,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: BioWayColors.darkGrey,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: BioWayColors.darkGrey,
          ),
          labelLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: BioWayColors.darkGreen,
          ),
        ),

        // Configuración de la fuente
        fontFamily: 'Roboto',

        // Usar Material 3
        useMaterial3: true,

        // Configuración de colores
        colorScheme: ColorScheme.fromSeed(
          seedColor: BioWayColors.primaryGreen,
          primary: BioWayColors.primaryGreen,
          secondary: BioWayColors.mediumGreen,
          error: BioWayColors.error,
          surface: Colors.white,
        ),
      ),

      // Pantalla inicial
      home: const SplashScreen(),
    );
  }
}