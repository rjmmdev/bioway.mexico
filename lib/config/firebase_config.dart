import 'package:firebase_core/firebase_core.dart';

/// Configuración para manejar múltiples proyectos Firebase
class FirebaseConfig {
  // Nombres de los proyectos Firebase
  static const String ecoceProject = 'ecoce';
  static const String biowayProject = 'bioway';
  
  // Proyecto activo actual
  static String? _currentProject;
  static String? get currentProject => _currentProject;
  
  /// Opciones de Firebase para ECOCE
  static const FirebaseOptions ecoceOptions = FirebaseOptions(
    apiKey: 'YOUR_ECOCE_API_KEY',
    appId: 'YOUR_ECOCE_APP_ID',
    messagingSenderId: 'YOUR_ECOCE_SENDER_ID',
    projectId: 'trazabilidad-ecoce',
    authDomain: 'trazabilidad-ecoce.firebaseapp.com',
    storageBucket: 'trazabilidad-ecoce.appspot.com',
    measurementId: 'YOUR_ECOCE_MEASUREMENT_ID',
    // iOS
    iosBundleId: 'com.biowaymexico.app',
    // Android ya está configurado en google-services.json
  );
  
  /// Opciones de Firebase para BioWay
  static const FirebaseOptions biowayOptions = FirebaseOptions(
    apiKey: 'YOUR_BIOWAY_API_KEY',
    appId: 'YOUR_BIOWAY_APP_ID',
    messagingSenderId: 'YOUR_BIOWAY_SENDER_ID',
    projectId: 'bioway-mexico',
    authDomain: 'bioway-mexico.firebaseapp.com',
    storageBucket: 'bioway-mexico.appspot.com',
    measurementId: 'YOUR_BIOWAY_MEASUREMENT_ID',
    // iOS
    iosBundleId: 'com.biowaymexico.app',
  );
  
  /// Obtener las opciones de Firebase según el proyecto
  static FirebaseOptions getOptions(String projectName) {
    switch (projectName) {
      case ecoceProject:
        return ecoceOptions;
      case biowayProject:
        return biowayOptions;
      default:
        throw Exception('Proyecto Firebase no válido: $projectName');
    }
  }
  
  /// Establecer el proyecto activo
  static void setCurrentProject(String projectName) {
    if (projectName != ecoceProject && projectName != biowayProject) {
      throw Exception('Proyecto Firebase no válido: $projectName');
    }
    _currentProject = projectName;
  }
  
  /// Verificar si hay un proyecto activo
  static bool get hasActiveProject => _currentProject != null;
  
  /// Limpiar el proyecto activo (al cerrar sesión)
  static void clearCurrentProject() {
    _currentProject = null;
  }
}