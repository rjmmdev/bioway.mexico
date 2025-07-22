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
  BioWayUser? get currentUser {
    final user = auth.currentUser;
    if (user == null) return null;
    
    // Por ahora retornamos un usuario de prueba
    return BioWayUser(
      uid: user.uid,
      email: user.email ?? '',
      nombre: 'Usuario BioWay',
      tipoUsuario: 'brindador',
      fechaRegistro: DateTime.now(),
    );
  }

  // Iniciar sesión
  Future<BioWayUser?> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      // Por ahora, simulamos el login sin Firebase real
      // ya que BioWay puede no tener proyecto Firebase configurado
      
      // Validación simple
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Correo y contraseña son requeridos');
      }

      // Simulamos usuarios de prueba
      if (email == 'brindador@test.com' && password == '123456') {
        return BioWayUser(
          uid: 'test_brindador_uid',
          email: email,
          nombre: 'Brindador Test',
          tipoUsuario: 'brindador',
          fechaRegistro: DateTime.now(),
        );
      } else if (email == 'recolector@test.com' && password == '123456') {
        return BioWayUser(
          uid: 'test_recolector_uid',
          email: email,
          nombre: 'Recolector Test',
          tipoUsuario: 'recolector',
          fechaRegistro: DateTime.now(),
        );
      }

      // Si no coincide con usuarios de prueba, intentar con Firebase
      try {
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
            // Si no existe en Firestore, crear usuario por defecto
            return BioWayUser(
              uid: credential.user!.uid,
              email: credential.user!.email ?? '',
              nombre: 'Usuario BioWay',
              tipoUsuario: 'brindador',
              fechaRegistro: DateTime.now(),
            );
          }
        }
      } catch (e) {
        // Si Firebase falla, lanzar error
        throw Exception('Error al iniciar sesión: ${e.toString()}');
      }

      throw Exception('Credenciales incorrectas');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Registrar Brindador
  Future<void> registrarBrindador({
    required String email,
    required String password,
    required String nombre,
    required String direccion,
    required String numeroExterior,
    required String codigoPostal,
    required String estado,
    required String municipio,
    required String colonia,
  }) async {
    try {
      // Por ahora, simulamos el registro sin Firebase real
      print('Registrando brindador: $email');
      print('Nombre: $nombre');
      print('Dirección: $direccion $numeroExterior');
      print('CP: $codigoPostal');
      print('Estado: $estado, Municipio: $municipio, Colonia: $colonia');

      // Intentar crear usuario en Firebase
      try {
        final credential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (credential.user != null) {
          // Guardar datos adicionales en Firestore
          await firestore.collection('bioway_users').doc(credential.user!.uid).set({
            'email': email,
            'nombre': nombre,
            'tipoUsuario': 'brindador',
            'direccion': direccion,
            'numeroExterior': numeroExterior,
            'codigoPostal': codigoPostal,
            'estado': estado,
            'municipio': municipio,
            'colonia': colonia,
            'fechaRegistro': FieldValue.serverTimestamp(),
            'bioCoins': 0,
            'nivel': 'BioBaby',
            'estadoResiduo': '0',
            'totalResiduosBrindados': 0,
            'totalKgReciclados': 0.0,
            'totalCO2Evitado': 0.0,
            'notificacionesActivas': true,
          });
        }
      } catch (e) {
        // Si Firebase no está configurado, solo simular éxito
        if (e.toString().contains('firebase_core')) {
          print('Firebase no configurado, simulando registro exitoso');
          return;
        }
        throw e;
      }
    } catch (e) {
      throw Exception('Error al registrar brindador: ${e.toString()}');
    }
  }

  // Registrar Recolector
  Future<void> registrarRecolector({
    required String email,
    required String password,
    required String nombre,
    String? empresa,
  }) async {
    try {
      // Por ahora, simulamos el registro sin Firebase real
      print('Registrando recolector: $email');
      print('Nombre: $nombre');
      print('Empresa: ${empresa ?? "Ninguna"}');

      // Intentar crear usuario en Firebase
      try {
        final credential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (credential.user != null) {
          // Guardar datos adicionales en Firestore
          await firestore.collection('bioway_users').doc(credential.user!.uid).set({
            'email': email,
            'nombre': nombre,
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
        }
      } catch (e) {
        // Si Firebase no está configurado, solo simular éxito
        if (e.toString().contains('firebase_core')) {
          print('Firebase no configurado, simulando registro exitoso');
          return;
        }
        throw e;
      }
    } catch (e) {
      throw Exception('Error al registrar recolector: ${e.toString()}');
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
}