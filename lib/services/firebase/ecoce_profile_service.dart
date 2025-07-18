import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/ecoce/ecoce_profile_model.dart';
import 'firebase_manager.dart';

class EcoceProfileService {
  final FirebaseManager _firebaseManager = FirebaseManager();
  
  FirebaseFirestore get _firestore {
    final app = _firebaseManager.currentApp;
    if (app == null) throw Exception('Firebase no inicializado para ECOCE');
    return FirebaseFirestore.instanceFor(app: app);
  }

  FirebaseAuth get _auth {
    final app = _firebaseManager.currentApp;
    if (app == null) throw Exception('Firebase no inicializado para ECOCE');
    return FirebaseAuth.instanceFor(app: app);
  }

  // Colección principal de perfiles ECOCE
  CollectionReference get _profilesCollection => 
      _firestore.collection('ecoce_profiles');

  // Generar folio único según el tipo de actor
  Future<String> _generateFolio(String tipoActor) async {
    String prefix;
    switch (tipoActor) {
      case 'A':
        prefix = 'A';
        break;
      case 'P':
        prefix = 'PS'; // Planta de Separación
        break;
      case 'R':
        prefix = 'R';
        break;
      case 'T':
        prefix = 'T';
        break;
      case 'V':
        prefix = 'TR'; // Transportista
        break;
      case 'L':
        prefix = 'L';
        break;
      case 'D':
        prefix = 'D';
        break;
      default:
        prefix = 'X';
    }

    // Obtener el último folio del tipo
    final query = await _profilesCollection
        .where('ecoce_tipo_actor', isEqualTo: tipoActor)
        .orderBy('ecoce_folio', descending: true)
        .limit(1)
        .get();

    int nextNumber = 1;
    if (query.docs.isNotEmpty) {
      final lastFolio = query.docs.first.data() as Map<String, dynamic>;
      final folioStr = lastFolio['ecoce_folio'] as String;
      // Extraer el número del folio (ej: A0000001 -> 1)
      final numberStr = folioStr.replaceAll(RegExp(r'[^0-9]'), '');
      nextNumber = int.parse(numberStr) + 1;
    }

    return '$prefix${nextNumber.toString().padLeft(7, '0')}';
  }

  // Crear perfil de usuario Origen (Acopiador o Planta de Separación)
  Future<EcoceProfileModel> createOrigenProfile({
    required String email,
    required String password,
    required String tipoActor, // 'A' o 'P'
    required String nombre,
    String? rfc,
    required String nombreContacto,
    required String telefonoContacto,
    required String telefonoEmpresa,
    required String calle,
    required String numExt,
    required String cp,
    String? estado,
    String? municipio,
    String? colonia,
    String? referencias,
    required List<String> materiales,
    required bool transporte,
    String? linkRedSocial,
    Map<String, double>? dimensionesCapacidad,
    double? pesoCapacidad,
    Map<String, String?>? documentos,
    String? linkMaps,
    double? latitud,
    double? longitud,
  }) async {
    try {
      // Inicializar Firebase para ECOCE si no está inicializado
      if (_firebaseManager.currentApp == null) {
        await _firebaseManager.initializeForPlatform(FirebasePlatform.ecoce);
      }

      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Generar folio único
      final folio = await _generateFolio(tipoActor);

      // Usar el linkMaps proporcionado o generar uno simple si no se proporciona
      final finalLinkMaps = linkMaps ?? 'https://maps.google.com/?q=$calle+$numExt,$colonia,$municipio,$estado,$cp';

      // Crear modelo de perfil
      final profile = EcoceProfileModel(
        id: userId,
        ecoce_tipo_actor: tipoActor,
        ecoce_nombre: nombre,
        ecoce_folio: folio,
        ecoce_rfc: rfc,
        ecoce_nombre_contacto: nombreContacto,
        ecoce_correo_contacto: email,
        ecoce_tel_contacto: telefonoContacto,
        ecoce_tel_empresa: telefonoEmpresa,
        ecoce_calle: calle,
        ecoce_num_ext: numExt,
        ecoce_cp: cp,
        ecoce_estado: estado,
        ecoce_municipio: municipio,
        ecoce_colonia: colonia,
        ecoce_ref_ubi: referencias,
        ecoce_link_maps: finalLinkMaps,
        ecoce_poligono_loc: null, // Se asignará posteriormente
        ecoce_latitud: latitud,
        ecoce_longitud: longitud,
        ecoce_fecha_reg: DateTime.now(),
        ecoce_lista_materiales: materiales,
        ecoce_transporte: transporte,
        ecoce_link_red_social: linkRedSocial,
        ecoce_const_sit_fis: documentos?['const_sit_fis'],
        ecoce_comp_domicilio: documentos?['comp_domicilio'],
        ecoce_banco_caratula: documentos?['banco_caratula'],
        ecoce_ine: documentos?['ine'],
        ecoce_dim_cap: dimensionesCapacidad,
        ecoce_peso_cap: pesoCapacidad,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Guardar perfil en Firestore
      await _profilesCollection.doc(userId).set(profile.toFirestore());

      // Actualizar displayName del usuario
      await userCredential.user!.updateDisplayName(nombre);

      return profile;
    } catch (e) {
      print('Error al crear perfil Origen: $e');
      rethrow;
    }
  }

  // Obtener perfil por ID
  Future<EcoceProfileModel?> getProfile(String userId) async {
    try {
      final doc = await _profilesCollection.doc(userId).get();
      if (!doc.exists) return null;
      
      return EcoceProfileModel.fromFirestore(doc);
    } catch (e) {
      print('Error al obtener perfil: $e');
      return null;
    }
  }

  // Actualizar perfil
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _profilesCollection.doc(userId).update(data);
    } catch (e) {
      print('Error al actualizar perfil: $e');
      rethrow;
    }
  }

  // Verificar si el email ya está registrado
  Future<bool> isEmailRegistered(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print('Error al verificar email: $e');
      return false;
    }
  }

  // Subir documento
  Future<String> uploadDocument(String userId, String documentType, String filePath) async {
    // Aquí se implementaría la lógica para subir archivos a Firebase Storage
    // Por ahora retornamos una URL simulada
    return 'https://firebasestorage.googleapis.com/v0/b/trazabilidad-ecoce.appspot.com/o/documents%2F$userId%2F$documentType?alt=media';
  }

  // Obtener perfiles pendientes de aprobación
  Future<List<EcoceProfileModel>> getPendingProfiles() async {
    try {
      final query = await _profilesCollection
          .where('ecoce_estatus_aprobacion', isEqualTo: 0)
          .orderBy('ecoce_fecha_reg', descending: true)
          .get();
      
      return query.docs
          .map((doc) => EcoceProfileModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error al obtener perfiles pendientes: $e');
      return [];
    }
  }

  // Aprobar perfil
  Future<void> approveProfile({
    required String profileId,
    required String approvedById,
    String? comments,
  }) async {
    try {
      await _profilesCollection.doc(profileId).update({
        'ecoce_estatus_aprobacion': 1,
        'ecoce_fecha_aprobacion': Timestamp.fromDate(DateTime.now()),
        'ecoce_aprobado_por': approvedById,
        'ecoce_comentarios_revision': comments,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error al aprobar perfil: $e');
      rethrow;
    }
  }

  // Rechazar perfil
  Future<void> rejectProfile({
    required String profileId,
    required String rejectedById,
    required String reason,
  }) async {
    try {
      await _profilesCollection.doc(profileId).update({
        'ecoce_estatus_aprobacion': 2,
        'ecoce_fecha_aprobacion': Timestamp.fromDate(DateTime.now()),
        'ecoce_aprobado_por': rejectedById,
        'ecoce_comentarios_revision': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error al rechazar perfil: $e');
      rethrow;
    }
  }

  // Eliminar perfil rechazado y sus datos asociados
  Future<void> deleteRejectedProfile(String profileId) async {
    try {
      // Obtener el perfil para tener el email
      final profileDoc = await _profilesCollection.doc(profileId).get();
      if (!profileDoc.exists) return;
      
      final profileData = profileDoc.data() as Map<String, dynamic>;
      final email = profileData['ecoce_correo_contacto'] as String?;
      
      // Eliminar el perfil de Firestore
      await _profilesCollection.doc(profileId).delete();
      
      // Eliminar el usuario de Auth si existe
      if (email != null) {
        try {
          // Obtener el usuario por email
          final methods = await _auth.fetchSignInMethodsForEmail(email);
          if (methods.isNotEmpty) {
            // Nota: Para eliminar un usuario de Auth, necesitamos que esté autenticado
            // o usar el Admin SDK desde un backend
            // Por ahora solo marcamos el perfil como eliminado
            print('Usuario de Auth encontrado pero no se puede eliminar desde el cliente');
          }
        } catch (e) {
          print('Error al verificar usuario en Auth: $e');
        }
      }
      
      // TODO: Eliminar archivos de Storage asociados al usuario
      // Esto requeriría implementar la lógica de Storage
      
    } catch (e) {
      print('Error al eliminar perfil rechazado: $e');
      rethrow;
    }
  }

  // Obtener estadísticas de perfiles
  Future<Map<String, int>> getProfileStatistics() async {
    try {
      final allProfiles = await _profilesCollection.get();
      
      int pending = 0;
      int approved = 0;
      int rejected = 0;
      
      for (final doc in allProfiles.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['ecoce_estatus_aprobacion'] ?? 0;
        
        switch (status) {
          case 0:
            pending++;
            break;
          case 1:
            approved++;
            break;
          case 2:
            rejected++;
            break;
        }
      }
      
      return {
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'total': allProfiles.docs.length,
      };
    } catch (e) {
      print('Error al obtener estadísticas: $e');
      return {
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'total': 0,
      };
    }
  }

  // Verificar si un usuario está aprobado
  Future<bool> isUserApproved(String userId) async {
    try {
      final profile = await getProfile(userId);
      return profile?.isApproved ?? false;
    } catch (e) {
      print('Error al verificar aprobación: $e');
      return false;
    }
  }
}