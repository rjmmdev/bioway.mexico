import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../config/firebase_config.dart';

/// Manager para manejar múltiples instancias de Firebase
class FirebaseManager {
  static FirebaseManager? _instance;
  static FirebaseManager get instance => _instance ??= FirebaseManager._();
  
  FirebaseManager._();
  
  // Apps de Firebase
  FirebaseApp? _ecoceApp;
  FirebaseApp? _biowayApp;
  
  // Servicios actuales
  FirebaseAuth? _currentAuth;
  FirebaseFirestore? _currentFirestore;
  FirebaseStorage? _currentStorage;
  FirebaseAnalytics? _currentAnalytics;
  
  // Getters para los servicios actuales
  FirebaseAuth? get auth => _currentAuth;
  FirebaseFirestore? get firestore => _currentFirestore;
  FirebaseStorage? get storage => _currentStorage;
  FirebaseAnalytics? get analytics => _currentAnalytics;
  
  /// Inicializar Firebase con el proyecto especificado
  Future<void> initializeFirebase(String projectName) async {
    try {
      // Si ya está inicializado el mismo proyecto, no hacer nada
      if (FirebaseConfig.currentProject == projectName && _hasCurrentServices()) {
        print('Firebase ya inicializado para $projectName');
        return;
      }
      
      // Limpiar servicios anteriores si cambiamos de proyecto
      if (FirebaseConfig.currentProject != null && 
          FirebaseConfig.currentProject != projectName) {
        await _clearCurrentServices();
      }
      
      // Establecer el proyecto actual
      FirebaseConfig.setCurrentProject(projectName);
      
      // Inicializar la app correspondiente
      FirebaseApp app;
      
      switch (projectName) {
        case FirebaseConfig.ecoceProject:
          app = await _initializeEcoceApp();
          break;
        case FirebaseConfig.biowayProject:
          app = await _initializeBiowayApp();
          break;
        default:
          throw Exception('Proyecto no válido: $projectName');
      }
      
      // Configurar los servicios para la app actual
      _setupServices(app);
      
      print('Firebase inicializado correctamente para $projectName');
      
    } catch (e) {
      print('Error al inicializar Firebase: $e');
      rethrow;
    }
  }
  
  /// Inicializar app de ECOCE
  Future<FirebaseApp> _initializeEcoceApp() async {
    if (_ecoceApp != null) {
      return _ecoceApp!;
    }
    
    // Verificar si ya existe una app con este nombre
    try {
      _ecoceApp = Firebase.app(FirebaseConfig.ecoceProject);
      return _ecoceApp!;
    } catch (e) {
      // Si no existe, crearla
      _ecoceApp = await Firebase.initializeApp(
        name: FirebaseConfig.ecoceProject,
        options: FirebaseConfig.ecoceOptions,
      );
      return _ecoceApp!;
    }
  }
  
  /// Inicializar app de BioWay
  Future<FirebaseApp> _initializeBiowayApp() async {
    if (_biowayApp != null) {
      return _biowayApp!;
    }
    
    // Verificar si ya existe una app con este nombre
    try {
      _biowayApp = Firebase.app(FirebaseConfig.biowayProject);
      return _biowayApp!;
    } catch (e) {
      // Si no existe, crearla
      _biowayApp = await Firebase.initializeApp(
        name: FirebaseConfig.biowayProject,
        options: FirebaseConfig.biowayOptions,
      );
      return _biowayApp!;
    }
  }
  
  /// Configurar los servicios para la app especificada
  void _setupServices(FirebaseApp app) {
    _currentAuth = FirebaseAuth.instanceFor(app: app);
    _currentFirestore = FirebaseFirestore.instanceFor(app: app);
    _currentStorage = FirebaseStorage.instanceFor(app: app);
    _currentAnalytics = FirebaseAnalytics.instanceFor(app: app);
    
    // Configurar Firestore
    _currentFirestore!.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  
  /// Verificar si hay servicios actuales configurados
  bool _hasCurrentServices() {
    return _currentAuth != null && 
           _currentFirestore != null && 
           _currentStorage != null && 
           _currentAnalytics != null;
  }
  
  /// Limpiar los servicios actuales
  Future<void> _clearCurrentServices() async {
    // Cerrar sesión si hay usuario activo
    if (_currentAuth?.currentUser != null) {
      await _currentAuth!.signOut();
    }
    
    // Limpiar referencias
    _currentAuth = null;
    _currentFirestore = null;
    _currentStorage = null;
    _currentAnalytics = null;
  }
  
  /// Cambiar entre proyectos Firebase
  Future<void> switchProject(String projectName) async {
    if (FirebaseConfig.currentProject == projectName) {
      print('Ya estás en el proyecto $projectName');
      return;
    }
    
    print('Cambiando de ${FirebaseConfig.currentProject} a $projectName');
    await initializeFirebase(projectName);
  }
  
  /// Cerrar sesión y limpiar el proyecto actual
  Future<void> signOutAndClear() async {
    await _clearCurrentServices();
    FirebaseConfig.clearCurrentProject();
  }
  
  /// Obtener el proyecto actual
  String? get currentProject => FirebaseConfig.currentProject;
  
  /// Verificar si un proyecto está activo
  bool get hasActiveProject => FirebaseConfig.hasActiveProject;
}