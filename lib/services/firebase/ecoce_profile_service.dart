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

      // Generar link de Google Maps (simplificado)
      final linkMaps = 'https://maps.google.com/?q=$calle+$numExt,$colonia,$municipio,$estado,$cp';

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
        ecoce_link_maps: linkMaps,
        ecoce_poligono_loc: null, // Se asignará posteriormente
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
}