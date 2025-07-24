import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/bioway/bioway_user.dart';

class BioWayAuthService {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  FirebaseAuth get auth {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  // Obtener usuario actual
  Future<BioWayUser?> get currentUser async {
    final user = auth.currentUser;
    if (user == null) return null;
    
    try {
      // Buscar datos en Firestore
      final userDoc = await firestore
          .collection('bioway_users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        return BioWayUser.fromMap(userDoc.data()!, user.uid);
      }
      
      return null;
    } catch (e) {
      print('Error al obtener usuario actual: $e');
      return null;
    }
  }

  // Iniciar sesión
  Future<BioWayUser?> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      // Validación simple
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Correo y contraseña son requeridos');
      }

      // Iniciar sesión con Firebase
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Buscar datos adicionales en Firestore
        final userDoc = await firestore
            .collection('bioway_users')
            .doc(credential.user!.uid)
            .get();

        if (userDoc.exists) {
          return BioWayUser.fromMap(userDoc.data()!, credential.user!.uid);
        } else {
          // Si no existe en Firestore, retornar null
          // El usuario debe completar su registro
          return null;
        }
      }

      throw Exception('Credenciales incorrectas');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No existe una cuenta con este correo');
      } else if (e.code == 'wrong-password') {
        throw Exception('Contraseña incorrecta');
      } else if (e.code == 'invalid-email') {
        throw Exception('El correo no es válido');
      } else if (e.code == 'user-disabled') {
        throw Exception('Esta cuenta ha sido deshabilitada');
      }
      throw Exception('Error al iniciar sesión: ${e.message}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }


  // Cerrar sesión
  Future<void> cerrarSesion() async {
    try {
      await auth.signOut();
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  // Stream de estado de autenticación
  Stream<BioWayUser?> get authStateChanges {
    return auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      // Buscar datos adicionales en Firestore
      try {
        final userDoc = await firestore
            .collection('bioway_users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          return BioWayUser.fromMap(userDoc.data()!, user.uid);
        }
      } catch (e) {
        print('Error al obtener datos del usuario: $e');
      }

      // Retornar usuario básico si no se encuentran datos
      return BioWayUser(
        uid: user.uid,
        email: user.email ?? '',
        nombre: 'Usuario BioWay',
        tipoUsuario: 'brindador',
        fechaRegistro: DateTime.now(),
      );
    });
  }

  // Crear cuenta sin datos completos (solo email y contraseña)
  Future<String> crearCuenta({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Enviar correo de verificación
        await credential.user!.sendEmailVerification();
        return credential.user!.uid;
      }
      
      throw Exception('No se pudo crear la cuenta');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('La contraseña es muy débil');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Este correo ya está registrado');
      } else if (e.code == 'invalid-email') {
        throw Exception('El correo no es válido');
      }
      throw Exception('Error al crear cuenta: ${e.message}');
    } catch (e) {
      throw Exception('Error al crear cuenta: ${e.toString()}');
    }
  }

  // Verificar si el correo ha sido verificado
  Future<bool> verificarCorreo() async {
    try {
      await auth.currentUser?.reload();
      return auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      return false;
    }
  }

  // Reenviar correo de verificación
  Future<void> reenviarCorreoVerificacion() async {
    try {
      await auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw Exception('Error al enviar correo de verificación: ${e.toString()}');
    }
  }

  // Completar registro de Brindador después de verificación
  Future<void> completarRegistroBrindador({
    required String userId,
    required String nombre,
    required String telefono,
    required double latitud,
    required double longitud,
    required String direccion,
  }) async {
    try {
      await firestore.collection('bioway_users').doc(userId).set({
        'email': auth.currentUser?.email ?? '',
        'nombre': nombre,
        'telefono': telefono,
        'tipoUsuario': 'brindador',
        'ubicacion': GeoPoint(latitud, longitud),
        'direccion': direccion,
        'fechaRegistro': FieldValue.serverTimestamp(),
        'bioCoins': 0,
        'nivel': 'BioBaby',
        'estadoResiduo': '0',
        'totalResiduosBrindados': 0,
        'totalKgReciclados': 0.0,
        'totalCO2Evitado': 0.0,
        'notificacionesActivas': true,
        'isPremium': false,
        'fechaPremium': null,
        'diasConsecutivosReciclando': 0,
        'nivelReconocimiento': null,
        'estadisticasAmbientales': {},
      });
    } catch (e) {
      throw Exception('Error al completar registro: ${e.toString()}');
    }
  }

  // Completar registro de Recolector después de verificación
  Future<void> completarRegistroRecolector({
    required String userId,
    required String nombre,
    required String telefono,
    String? empresa,
  }) async {
    try {
      await firestore.collection('bioway_users').doc(userId).set({
        'email': auth.currentUser?.email ?? '',
        'nombre': nombre,
        'telefono': telefono,
        'tipoUsuario': 'recolector',
        'empresa': empresa,
        'fechaRegistro': FieldValue.serverTimestamp(),
        'bioCoins': 0,
        'nivel': 'BioBaby',
        'verificado': false,
        'totalResiduosRecolectados': 0,
        'totalKgReciclados': 0.0,
        'totalCO2Evitado': 0.0,
        'notificacionesActivas': true,
      });
    } catch (e) {
      throw Exception('Error al completar registro: ${e.toString()}');
    }
  }

  // Completar registro de Centro de Acopio después de verificación
  Future<void> completarRegistroCentroAcopio({
    required String userId,
    required String nombre,
    required String telefono,
    required double latitud,
    required double longitud,
    required String direccion,
    String? nombreCentro,
    String? horarioApertura,
    String? horarioCierre,
    List<String>? diasOperacion,
  }) async {
    try {
      await firestore.collection('bioway_users').doc(userId).set({
        'email': auth.currentUser?.email ?? '',
        'nombre': nombre,
        'telefono': telefono,
        'tipoUsuario': 'centro_acopio',
        'nombreCentro': nombreCentro ?? nombre,
        'ubicacion': GeoPoint(latitud, longitud),
        'direccion': direccion,
        'fechaRegistro': FieldValue.serverTimestamp(),
        'bioCoins': 0,
        'nivel': 'Centro Activo',
        'totalResiduosRecibidos': 0,
        'totalKgReciclados': 0.0,
        'totalCO2Evitado': 0.0,
        'notificacionesActivas': true,
        'horarioApertura': horarioApertura ?? '08:00',
        'horarioCierre': horarioCierre ?? '18:00',
        'diasOperacion': diasOperacion ?? ['Lun', 'Mar', 'Mie', 'Jue', 'Vie'],
        'materialesAceptados': [],
      });
    } catch (e) {
      throw Exception('Error al completar registro: ${e.toString()}');
    }
  }
}