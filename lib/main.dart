import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'utils/colors.dart';

// Screens - Origen
import 'screens/ecoce/origen/origen_inicio_screen.dart';
import 'screens/ecoce/origen/origen_lotes_screen.dart';
import 'screens/ecoce/origen/origen_crear_lote_screen.dart';

// Screens - Reciclador
import 'screens/ecoce/reciclador/reciclador_inicio.dart';
import 'screens/ecoce/reciclador/reciclador_administracion_lotes.dart';
import 'screens/ecoce/reciclador/reciclador_escaneo_qr.dart';
import 'screens/ecoce/reciclador/reciclador_documentacion.dart';

// Screens - Transporte
import 'screens/ecoce/transporte/transporte_inicio_screen.dart';
import 'screens/ecoce/transporte/transporte_entregar_screen.dart';
import 'screens/ecoce/transporte/transporte_ayuda_screen.dart';
import 'screens/ecoce/transporte/transporte_perfil_screen.dart';

// Screens - Shared
import 'screens/ecoce/shared/ecoce_perfil_screen.dart';
import 'screens/ecoce/shared/ecoce_ayuda_screen.dart';

// Screens - Transformador
import 'screens/ecoce/transformador/transformador_inicio_screen.dart';
import 'screens/ecoce/transformador/transformador_produccion_screen.dart';
import 'screens/ecoce/transformador/transformador_recibir_lote_screen.dart';
import 'screens/ecoce/transformador/transformador_documentacion_screen.dart';

// Screens - Laboratorio
import 'screens/ecoce/laboratorio/laboratorio_inicio.dart';
import 'screens/ecoce/laboratorio/laboratorio_gestion_muestras.dart';

// Screens - Maestro
import 'screens/ecoce/maestro/maestro_unified_screen.dart';

void main() async {
  // Asegurar que los widgets estén inicializados
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase NO se inicializa aquí
  // Se inicializará dinámicamente según la plataforma seleccionada
  // Ver FirebaseManager para más detalles
  
  // Desactivar animaciones del teclado
  SystemChannels.textInput.invokeMethod('TextInput.setClientFeatures', <String, dynamic>{
    'enableAnimations': false,
  });

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
      title: 'BioWay México',
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
          fillColor: Colors.white.withValues(alpha: 0.9),
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
      
      // Rutas de navegación
      routes: {
        // Rutas de Origen (Acopiador)
        '/origen_inicio': (context) => const OrigenInicioScreen(),
        '/origen_lotes': (context) => const OrigenLotesScreen(),
        '/origen_ayuda': (context) => const EcoceAyudaScreen(),
        '/origen_crear_lote': (context) => const OrigenCrearLoteScreen(),
        '/origen_perfil': (context) => const EcocePerfilScreen(),
        
        // Rutas de Reciclador
        '/reciclador_inicio': (context) => const RecicladorInicio(),
        '/reciclador_lotes': (context) => const RecicladorAdministracionLotes(),
        '/reciclador_escaneo': (context) => const RecicladorEscaneoQR(),
        '/reciclador_ayuda': (context) => const EcoceAyudaScreen(),
        '/reciclador_perfil': (context) => const EcocePerfilScreen(),
        '/reciclador_documentacion': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return RecicladorDocumentacion(lotId: args?['lotId'] ?? 'UNKNOWN');
        },
        
        // Rutas de Transporte
        '/transporte_inicio': (context) => const TransporteInicioScreen(),
        '/transporte_entregar': (context) => const TransporteEntregarScreen(),
        '/transporte_ayuda': (context) => const TransporteAyudaScreen(),
        '/transporte_perfil': (context) => const TransportePerfilScreen(),
        
        // Rutas de Transformador
        '/transformador_inicio': (context) => const TransformadorInicioScreen(),
        '/transformador_produccion': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return TransformadorProduccionScreen(
            initialTab: args?['initialTab'] as int?,
          );
        },
        '/transformador_ayuda': (context) => const EcoceAyudaScreen(),
        '/transformador_perfil': (context) => const EcocePerfilScreen(),
        '/transformador_recibir_lote': (context) => const TransformadorRecibirLoteScreen(),
        '/transformador_documentacion': (context) => const TransformadorDocumentacionScreen(),
        
        // Rutas de Planta de Separación
        '/planta_separacion_perfil': (context) => const EcocePerfilScreen(),
        '/planta_separacion_ayuda': (context) => const EcoceAyudaScreen(),
        
        // Rutas de Laboratorio
        '/laboratorio_inicio': (context) {
          // Importar la pantalla dinámicamente para evitar problemas de importación circular
          return const LaboratorioInicioScreen();
        },
        '/laboratorio_muestras': (context) => const LaboratorioGestionMuestras(),
        '/laboratorio_perfil': (context) => const EcocePerfilScreen(),
        '/laboratorio_ayuda': (context) => const EcoceAyudaScreen(),
        
        // Rutas de Maestro - Solo dashboard para gestión de usuarios
        '/maestro_dashboard': (context) {
          // Importar la pantalla dinámicamente para evitar problemas de importación circular
          return const MaestroUnifiedScreen();
        },
      },
    );
  }
}
