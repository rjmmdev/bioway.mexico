import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_config.dart';

/// Gestor centralizado para manejar múltiples proyectos de Firebase
class FirebaseManager {
  static final FirebaseManager _instance = FirebaseManager._internal();
  factory FirebaseManager() => _instance;
  FirebaseManager._internal();

  /// Mapa de instancias de Firebase por plataforma
  final Map<FirebasePlatform, FirebaseApp?> _firebaseApps = {};
  
  /// Plataforma actualmente activa
  FirebasePlatform? _currentPlatform;
  
  /// Obtiene la plataforma actualmente activa
  FirebasePlatform? get currentPlatform => _currentPlatform;
  
  /// Obtiene la app de Firebase actual
  FirebaseApp? get currentApp => _currentPlatform != null 
      ? _firebaseApps[_currentPlatform] 
      : null;

  /// Inicializa Firebase para una plataforma específica
  Future<FirebaseApp> initializeForPlatform(FirebasePlatform platform) async {
    debugPrint('🔥 Inicializando Firebase para: ${platform.name}');
    
    // Si ya existe una instancia para esta plataforma, retornarla
    if (_firebaseApps.containsKey(platform) && _firebaseApps[platform] != null) {
      debugPrint('✅ Firebase ya inicializado para ${platform.name}');
      _currentPlatform = platform;
      return _firebaseApps[platform]!;
    }

    try {
      // Obtener la configuración para la plataforma
      final options = FirebaseConfig.getOptionsForPlatform(platform);
      
      // Verificar si ya existe una app con este nombre
      FirebaseApp? app;
      try {
        app = Firebase.app(platform.name);
        debugPrint('📱 App Firebase existente encontrada para ${platform.name}');
      } catch (e) {
        // No existe, crear nueva
        app = await Firebase.initializeApp(
          name: platform.name,
          options: options,
        );
        debugPrint('✨ Nueva app Firebase creada para ${platform.name}');
      }
      
      // Guardar la referencia
      _firebaseApps[platform] = app;
      _currentPlatform = platform;
      
      debugPrint('✅ Firebase inicializado correctamente para ${platform.name}');
      return app;
    } catch (e) {
      debugPrint('❌ Error al inicializar Firebase para ${platform.name}: $e');
      rethrow;
    }
  }

  /// Cambia la plataforma activa
  Future<void> switchToPlatform(FirebasePlatform platform) async {
    if (_currentPlatform == platform) {
      debugPrint('⚡ Ya estás en la plataforma ${platform.name}');
      return;
    }

    // Si la plataforma no está inicializada, inicializarla
    if (!_firebaseApps.containsKey(platform) || _firebaseApps[platform] == null) {
      await initializeForPlatform(platform);
    } else {
      _currentPlatform = platform;
      debugPrint('🔄 Cambiado a plataforma ${platform.name}');
    }
  }

  /// Limpia todos los recursos
  Future<void> dispose() async {
    _firebaseApps.clear();
    _currentPlatform = null;
  }

  /// Verifica si una plataforma está inicializada
  bool isPlatformInitialized(FirebasePlatform platform) {
    return _firebaseApps.containsKey(platform) && _firebaseApps[platform] != null;
  }

  /// Obtiene la app de Firebase para una plataforma específica
  FirebaseApp? getAppForPlatform(FirebasePlatform platform) {
    return _firebaseApps[platform];
  }
}

/// Enumeración de las plataformas disponibles
enum FirebasePlatform {
  ecoce('ECOCE'),
  bioway('BioWay');

  final String name;
  const FirebasePlatform(this.name);
}