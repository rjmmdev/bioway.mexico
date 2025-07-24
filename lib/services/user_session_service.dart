import 'package:firebase_auth/firebase_auth.dart';
import '../models/ecoce/ecoce_profile_model.dart';
import 'firebase/ecoce_profile_service.dart';
import 'firebase/auth_service.dart';

/// Servicio singleton para manejar la sesión del usuario actual
class UserSessionService {
  static final UserSessionService _instance = UserSessionService._internal();
  factory UserSessionService() => _instance;
  UserSessionService._internal();
  
  final EcoceProfileService _profileService = EcoceProfileService();
  final AuthService _authService = AuthService();
  
  // Perfil del usuario actual en caché
  EcoceProfileModel? _currentUserProfile;
  
  // Stream controller para cambios en el perfil
  Stream<User?> get authStateChanges => _authService.authStateChanges;
  
  /// Obtener el perfil del usuario actual
  Future<EcoceProfileModel?> getCurrentUserProfile({bool forceRefresh = false}) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _currentUserProfile = null;
        return null;
      }
      
      // Si tenemos el perfil en caché y no forzamos actualización, retornarlo
      if (_currentUserProfile != null && 
          _currentUserProfile!.id == currentUser.uid && 
          !forceRefresh) {
        return _currentUserProfile;
      }
      
      // Cargar perfil desde Firebase
      final profile = await _profileService.getProfile(currentUser.uid);
      _currentUserProfile = profile;
      return profile;
    } catch (e) {
      // Log error
      return null;
    }
  }
  
  /// Actualizar datos del perfil del usuario actual
  Future<bool> updateCurrentUserProfile(Map<String, dynamic> updates) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;
      
      await _profileService.updateProfile(currentUser.uid, updates);
      
      // Recargar perfil actualizado
      await getCurrentUserProfile(forceRefresh: true);
      return true;
    } catch (e) {
      // Log error
      return false;
    }
  }
  
  /// Limpiar sesión (llamar al cerrar sesión)
  void clearSession() {
    _currentUserProfile = null;
  }
  
  /// Obtener información rápida del usuario actual
  String? get currentUserName => _currentUserProfile?.ecoceNombre;
  String? get currentUserFolio => _currentUserProfile?.ecoceFolio;
  String? get currentUserEmail => _currentUserProfile?.ecoceCorreoContacto;
  String? get currentUserType => _currentUserProfile?.tipoActorLabel;
  bool get isLoggedIn => _authService.currentUser != null;
  
  /// Verificar si el usuario actual es de un tipo específico
  bool isUserType(String tipoActor) {
    return _currentUserProfile?.ecoceTipoActor == tipoActor;
  }
  
  /// Obtener tipo de usuario para navegación
  String? getUserNavigationType() {
    if (_currentUserProfile == null) return null;
    
    switch (_currentUserProfile!.ecoceTipoActor) {
      case 'O':
        return _currentUserProfile!.ecoceSubtipo == 'A' ? 'acopiador' : 'planta';
      case 'R':
        return 'reciclador';
      case 'T':
        return 'transformador';
      case 'V':
        return 'transportista';
      case 'L':
        return 'laboratorio';
      default:
        return null;
    }
  }
  
  /// Obtener datos del usuario como mapa (para compatibilidad)
  Map<String, dynamic>? getUserData() {
    if (_currentUserProfile == null) return null;
    
    return {
      'nombre': _currentUserProfile!.ecoceNombre,
      'folio': _currentUserProfile!.ecoceFolio,
      'email': _currentUserProfile!.ecoceCorreoContacto,
      'tipo': _currentUserProfile!.tipoActorLabel,
      'tipoActor': _currentUserProfile!.ecoceTipoActor,
    };
  }
  
  /// Propiedad userData para compatibilidad con código antiguo
  Map<String, dynamic>? get userData => getUserData();

  /// Obtener perfil completo del usuario para acceder a todos los campos
  Future<Map<String, dynamic>?> getUserProfile() async {
    final profile = await getCurrentUserProfile();
    if (profile == null) return null;
    
    // Convertir el modelo a mapa completo con todos los campos
    return {
      'id': profile.id,
      'nombre': profile.ecoceNombre,
      'folio': profile.ecoceFolio,
      'email': profile.ecoceCorreoContacto,
      'tipo': profile.tipoActorLabel,
      'tipoActor': profile.ecoceTipoActor,
      'subtipo': profile.ecoceSubtipo,
      'direccion': '${profile.ecoceCalle} ${profile.ecoceNumExt}${profile.ecoceNumInt != null ? ' Int. ${profile.ecoceNumInt}' : ''}, ${profile.ecoceColonia ?? ''}, ${profile.ecoceMunicipio ?? ''}, ${profile.ecoceEstado ?? ''}, CP ${profile.ecoceCp}'.trim(),
      'telefono': profile.ecoceTelefono,
      'rfc': profile.ecoceRfc,
      'nombreComercial': profile.ecoceNombreComercial,
      'razonSocial': profile.ecoceRazonSocial,
      'estado': profile.ecoceEstado,
      'ciudad': profile.ecoceCiudad,
      'cp': profile.ecoceCp,
      // Agregar más campos según sea necesario
    };
  }
}