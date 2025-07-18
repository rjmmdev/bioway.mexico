import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_manager.dart';

/// Servicio de autenticación que maneja múltiples proyectos Firebase
class AuthService {
  final FirebaseManager _firebaseManager = FirebaseManager();
  
  /// Obtiene la instancia de FirebaseAuth para la plataforma actual
  FirebaseAuth get _auth {
    final app = _firebaseManager.currentApp;
    if (app == null) {
      throw Exception('Firebase no inicializado. Llame a initializeForPlatform primero.');
    }
    return FirebaseAuth.instanceFor(app: app);
  }
  
  /// Obtiene la instancia de Firestore para la plataforma actual
  FirebaseFirestore get _firestore {
    final app = _firebaseManager.currentApp;
    if (app == null) {
      throw Exception('Firebase no inicializado. Llame a initializeForPlatform primero.');
    }
    return FirebaseFirestore.instanceFor(app: app);
  }

  /// Usuario actual
  User? get currentUser => _auth.currentUser;
  
  /// Stream de cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Inicializa Firebase para una plataforma específica
  Future<void> initializeForPlatform(FirebasePlatform platform) async {
    await _firebaseManager.initializeForPlatform(platform);
  }

  /// Login con email y contraseña
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Registro con email y contraseña
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Guardar datos del usuario en Firestore
  Future<void> saveUserData({
    required String uid,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set(
        {
          ...userData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Error al guardar datos del usuario: $e');
    }
  }

  /// Obtener datos del usuario desde Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      throw Exception('Error al obtener datos del usuario: $e');
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Restablecer contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Manejo de errores de autenticación
  Exception _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return Exception('No existe un usuario con este correo electrónico.');
        case 'wrong-password':
          return Exception('Contraseña incorrecta.');
        case 'email-already-in-use':
          return Exception('Este correo ya está registrado.');
        case 'invalid-email':
          return Exception('Correo electrónico inválido.');
        case 'weak-password':
          return Exception('La contraseña es muy débil.');
        case 'network-request-failed':
          return Exception('Error de conexión. Verifica tu internet.');
        default:
          return Exception('Error de autenticación: ${error.message}');
      }
    }
    return Exception('Error inesperado: $error');
  }

  /// Obtiene la plataforma actualmente activa
  FirebasePlatform? get currentPlatform => _firebaseManager.currentPlatform;
}