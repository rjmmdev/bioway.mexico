import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_manager.dart';

/// Servicio de autenticación que trabaja con múltiples proyectos Firebase
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  
  AuthService._();
  
  final FirebaseManager _firebaseManager = FirebaseManager.instance;
  
  /// Obtener el usuario actual
  User? get currentUser => _firebaseManager.auth?.currentUser;
  
  /// Stream de cambios de autenticación
  Stream<User?> get authStateChanges => 
      _firebaseManager.auth?.authStateChanges() ?? Stream.value(null);
  
  /// Verificar si hay un usuario autenticado
  bool get isAuthenticated => currentUser != null;
  
  /// Iniciar sesión con email y contraseña
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
    required String project,
  }) async {
    try {
      // Asegurarse de que estamos en el proyecto correcto
      await _firebaseManager.initializeFirebase(project);
      
      final auth = _firebaseManager.auth;
      if (auth == null) {
        throw Exception('Firebase Auth no inicializado');
      }
      
      return await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }
  
  /// Registrar nuevo usuario
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String project,
  }) async {
    try {
      // Asegurarse de que estamos en el proyecto correcto
      await _firebaseManager.initializeFirebase(project);
      
      final auth = _firebaseManager.auth;
      if (auth == null) {
        throw Exception('Firebase Auth no inicializado');
      }
      
      return await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }
  
  /// Cerrar sesión
  Future<void> signOut() async {
    await _firebaseManager.signOutAndClear();
  }
  
  /// Enviar email de restablecimiento de contraseña
  Future<void> sendPasswordResetEmail({
    required String email,
    required String project,
  }) async {
    try {
      // Asegurarse de que estamos en el proyecto correcto
      await _firebaseManager.initializeFirebase(project);
      
      final auth = _firebaseManager.auth;
      if (auth == null) {
        throw Exception('Firebase Auth no inicializado');
      }
      
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error al enviar email: $e');
    }
  }
  
  /// Actualizar perfil del usuario
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }
    
    try {
      await user.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  /// Cambiar contraseña
  Future<void> updatePassword(String newPassword) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }
    
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  /// Reautenticar usuario (necesario antes de operaciones sensibles)
  Future<void> reauthenticate({
    required String email,
    required String password,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }
    
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  /// Eliminar cuenta de usuario
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }
    
    try {
      await user.delete();
      await _firebaseManager.signOutAndClear();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  /// Manejar excepciones de Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No se encontró un usuario con ese correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'invalid-email':
        return 'El correo no es válido';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'requires-recent-login':
        return 'Necesitas volver a iniciar sesión';
      default:
        return e.message ?? 'Error de autenticación';
    }
  }
}