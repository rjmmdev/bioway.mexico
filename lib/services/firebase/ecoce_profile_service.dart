import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/ecoce/ecoce_profile_model.dart';
import '../document_service.dart';
import 'firebase_manager.dart';

class EcoceProfileService {
  final FirebaseManager _firebaseManager = FirebaseManager();
  final DocumentService _documentService = DocumentService();
  
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
      
  // Colección de solicitudes de cuentas
  CollectionReference get _solicitudesCollection => 
      _firestore.collection('solicitudes_cuentas');
      
  // Obtener la ruta de la colección como string
  String? getProfileCollectionPath(String? tipoActor, String? subtipo) {
    if (tipoActor == null) return null;
    
    switch (tipoActor) {
      case 'O': // Origen (Acopiador o Planta de Separación)
      case 'A': // A veces viene como A
        if (subtipo == 'A') {
          return 'ecoce_profiles/origen/centro_acopio';
        } else if (subtipo == 'P') {
          return 'ecoce_profiles/origen/planta_separacion';
        }
        return 'ecoce_profiles/origen/usuarios';
      case 'R': // Reciclador
        return 'ecoce_profiles/reciclador/usuarios';
      case 'T': // Transformador
        return 'ecoce_profiles/transformador/usuarios';
      case 'V': // Transporte/Vehicular
        return 'ecoce_profiles/transporte/usuarios';
      case 'L': // Laboratorio
        return 'ecoce_profiles/laboratorio/usuarios';
      default:
        return 'ecoce_profiles/otros/usuarios';
    }
  }
  
  // Obtener la subcolección según el tipo de usuario
  CollectionReference _getProfileSubcollection(String tipoActor, String? subtipo) {
    // Mapear tipos de actor a sus colecciones
    switch (tipoActor) {
      case 'O': // Origen (Acopiador o Planta de Separación)
      case 'A': // A veces viene como A
        if (subtipo == 'A') {
          return _profilesCollection.doc('origen').collection('centro_acopio');
        } else if (subtipo == 'P') {
          return _profilesCollection.doc('origen').collection('planta_separacion');
        }
        return _profilesCollection.doc('origen').collection('usuarios');
      case 'R': // Reciclador
        return _profilesCollection.doc('reciclador').collection('usuarios');
      case 'T': // Transformador
        return _profilesCollection.doc('transformador').collection('usuarios');
      case 'V': // Transporte/Vehicular
        return _profilesCollection.doc('transporte').collection('usuarios');
      case 'L': // Laboratorio
        return _profilesCollection.doc('laboratorio').collection('usuarios');
      default:
        return _profilesCollection.doc('otros').collection('usuarios');
    }
  }
  
  // Método mantenido por compatibilidad - redirige al método genérico
  Future<String> createOrigenAccountRequest({
    required String email,
    required String password,
    required String subtipo,
    required String nombre,
    required String rfc,
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
    return createAccountRequest(
      tipoUsuario: 'origen',
      email: email,
      password: password,
      subtipo: subtipo,
      nombre: nombre,
      rfc: rfc,
      nombreContacto: nombreContacto,
      telefonoContacto: telefonoContacto,
      telefonoEmpresa: telefonoEmpresa,
      calle: calle,
      numExt: numExt,
      cp: cp,
      estado: estado,
      municipio: municipio,
      colonia: colonia,
      referencias: referencias,
      materiales: materiales,
      transporte: transporte,
      linkRedSocial: linkRedSocial,
      dimensionesCapacidad: dimensionesCapacidad,
      pesoCapacidad: pesoCapacidad,
      documentos: documentos,
      linkMaps: linkMaps,
      latitud: latitud,
      longitud: longitud,
    );
  }

  // Generar folio único según el subtipo para usuarios origen
  Future<String> _generateFolio(String tipoActor, String? subtipo) async {
    String prefix;
    
    if (tipoActor == 'O' && subtipo != null) {
      // Para usuarios origen, usar el subtipo como prefijo
      switch (subtipo) {
        case 'A':
          prefix = 'A'; // Acopiador
          break;
        case 'P':
          prefix = 'P'; // Planta de Separación
          break;
        default:
          prefix = 'O';
      }
    } else {
      // Para otros tipos de usuario, usar el tipo de actor
      switch (tipoActor) {
        case 'R':
          prefix = 'R';
          break;
        case 'T':
          prefix = 'T';
          break;
        case 'V':
          prefix = 'V'; // Transportista
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
    }

    try {
      // Para usuarios origen, buscar por el prefijo del folio
      // Para otros tipos, buscar por tipo de actor
      QuerySnapshot query;
      
      if (tipoActor == 'O') {
        // Buscar folios que empiecen con el prefijo específico (A o P)
        query = await _profilesCollection
            .where('ecoce_folio', isGreaterThanOrEqualTo: prefix)
            .where('ecoce_folio', isLessThan: '${prefix}z')
            .orderBy('ecoce_folio', descending: true)
            .limit(1)
            .get();
      } else {
        // Buscar por tipo de actor para otros tipos
        query = await _profilesCollection
            .where('ecoce_tipo_actor', isEqualTo: tipoActor)
            .orderBy('ecoce_folio', descending: true)
            .limit(1)
            .get();
      }

      int nextNumber = 1;
      if (query.docs.isNotEmpty) {
        final lastFolio = query.docs.first.data() as Map<String, dynamic>;
        final folioStr = lastFolio['ecoce_folio'] as String;
        // Extraer el número del folio (ej: A0000001 -> 1)
        final numberStr = folioStr.replaceAll(RegExp(r'[^0-9]'), '');
        if (numberStr.isNotEmpty) {
          nextNumber = int.parse(numberStr) + 1;
        }
      }

      return '$prefix${nextNumber.toString().padLeft(7, '0')}';
    } catch (e) {
      // Si hay error (por ejemplo, índice no creado), usar número aleatorio
      final randomNumber = DateTime.now().millisecondsSinceEpoch % 1000000;
      return '$prefix${randomNumber.toString().padLeft(7, '0')}';
    }
  }

  // Crear perfil de usuario Origen (Acopiador o Planta de Separación)
  Future<EcoceProfileModel> createOrigenProfile({
    required String email,
    required String password,
    required String subtipo, // 'A' (Acopiador) o 'P' (Planta de Separación)
    required String nombre,
    required String rfc,
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

      // No generar folio al registrar - se asignará al aprobar
      final folio = 'PENDIENTE';

      // Usar el linkMaps proporcionado o generar uno simple si no se proporciona
      final finalLinkMaps = linkMaps ?? 'https://maps.google.com/?q=$calle+$numExt,$colonia,$municipio,$estado,$cp';

      // Crear modelo de perfil
      final profile = EcoceProfileModel(
        id: userId,
        ecoceTipoActor: 'O', // Todos los origen son tipo 'O'
        ecoceSubtipo: subtipo, // 'A' para Acopiador, 'P' para Planta
        ecoceNombre: nombre,
        ecoceFolio: folio, // Se asignará folio real al aprobar
        ecoceRfc: rfc,
        ecoceNombreContacto: nombreContacto,
        ecoceCorreoContacto: email,
        ecoceTelContacto: telefonoContacto,
        ecoceTelEmpresa: telefonoEmpresa,
        ecoceCalle: calle,
        ecoceNumExt: numExt,
        ecoceCp: cp,
        ecoceEstado: estado,
        ecoceMunicipio: municipio,
        ecoceColonia: colonia,
        ecoceRefUbi: referencias,
        ecoceLinkMaps: finalLinkMaps,
        ecocePoligonoLoc: null, // Se asignará posteriormente
        ecoceLatitud: latitud,
        ecoceLongitud: longitud,
        ecoceFechaReg: DateTime.now(),
        ecoceListaMateriales: materiales,
        ecoceTransporte: transporte,
        ecoceLinkRedSocial: linkRedSocial,
        ecoceConstSitFis: documentos?['const_sit_fis'],
        ecoceCompDomicilio: documentos?['comp_domicilio'],
        ecoceBancoCaratula: documentos?['banco_caratula'],
        ecoceIne: documentos?['ine'],
        ecoceDimCap: dimensionesCapacidad,
        ecocePesoCap: pesoCapacidad,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Guardar perfil en Firestore
      await _profilesCollection.doc(userId).set(profile.toFirestore());

      // Actualizar displayName del usuario
      await userCredential.user!.updateDisplayName(nombre);

      return profile;
    } catch (e) {
      rethrow;
    }
  }
  
  // Crear solicitud de cuenta genérica para cualquier tipo de usuario (sin crear usuario en Auth)
  Future<String> createAccountRequest({
    required String tipoUsuario, // 'origen', 'reciclador', 'transformador', 'transportista', 'laboratorio'
    required String email,
    required String password,
    required String subtipo, // 'A' (Acopiador) o 'P' (Planta de Separación)
    required String nombre,
    required String rfc,
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

      // Verificar si el email ya existe en solicitudes pendientes
      final existingSolicitud = await _solicitudesCollection
          .where('email', isEqualTo: email)
          .where('estado', isEqualTo: 'pendiente')
          .limit(1)
          .get();
          
      if (existingSolicitud.docs.isNotEmpty) {
        throw 'Ya existe una solicitud pendiente con este correo electrónico';
      }

      // Usar el linkMaps proporcionado o generar uno simple si no se proporciona
      final finalLinkMaps = linkMaps ?? 'https://maps.google.com/?q=$calle+$numExt,$colonia,$municipio,$estado,$cp';
      
      // Generar ID único para la solicitud
      final solicitudId = _solicitudesCollection.doc().id;

      // Determinar el tipo de actor según el tipo de usuario
      String tipoActor;
      switch (tipoUsuario) {
        case 'origen':
          tipoActor = 'O';
          break;
        case 'reciclador':
          tipoActor = 'R';
          break;
        case 'transformador':
          tipoActor = 'T';
          break;
        case 'transportista':
          tipoActor = 'V';
          break;
        case 'laboratorio':
          tipoActor = 'L';
          break;
        default:
          tipoActor = 'O';
      }
      
      // Crear documento de solicitud
      final solicitudData = {
        'id': solicitudId,
        'tipo': tipoUsuario,
        'subtipo': subtipo,
        'email': email,
        'password': password, // En producción, esto debería estar encriptado
        'datos_perfil': {
          'ecoce_tipo_actor': tipoActor,
          'ecoce_subtipo': subtipo,
          'ecoce_nombre': nombre,
          'ecoce_folio': 'PENDIENTE',
          'ecoce_rfc': rfc,
          'ecoce_nombre_contacto': nombreContacto,
          'ecoce_correo_contacto': email,
          'ecoce_tel_contacto': telefonoContacto,
          'ecoce_tel_empresa': telefonoEmpresa,
          'ecoce_calle': calle,
          'ecoce_num_ext': numExt,
          'ecoce_cp': cp,
          'ecoce_estado': estado,
          'ecoce_municipio': municipio,
          'ecoce_colonia': colonia,
          'ecoce_ref_ubi': referencias,
          'ecoce_link_maps': finalLinkMaps,
          'ecoce_poligono_loc': null,
          'ecoce_latitud': latitud,
          'ecoce_longitud': longitud,
          'ecoce_lista_materiales': materiales,
          'ecoce_transporte': transporte,
          'ecoce_link_red_social': linkRedSocial,
          'ecoce_const_sit_fis': documentos?['const_sit_fis'],
          'ecoce_comp_domicilio': documentos?['comp_domicilio'],
          'ecoce_banco_caratula': documentos?['banco_caratula'],
          'ecoce_ine': documentos?['ine'],
          'ecoce_dim_cap': dimensionesCapacidad,
          'ecoce_peso_cap': pesoCapacidad,
        },
        'estado': 'pendiente',
        'fecha_solicitud': FieldValue.serverTimestamp(),
        'fecha_revision': null,
        'revisado_por': null,
        'comentarios_revision': null,
      };

      // Guardar solicitud en Firestore
      await _solicitudesCollection.doc(solicitudId).set(solicitudData);
      
      return solicitudId;
    } catch (e) {
      rethrow;
    }
  }
  
  // Obtener solicitudes pendientes
  Future<List<Map<String, dynamic>>> getPendingSolicitudes() async {
    try {
      final query = await _solicitudesCollection
          .where('estado', isEqualTo: 'pendiente')
          .orderBy('fecha_solicitud', descending: true)
          .get();
      
      return query.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['solicitud_id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Verificar estado de solicitud por email antes de hacer login
  Future<Map<String, dynamic>?> checkAccountRequestStatus(String email) async {
    try {
      // Buscar en solicitudes pendientes o aprobadas
      final query = await _solicitudesCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
          
      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data() as Map<String, dynamic>;
        data['solicitud_id'] = query.docs.first.id;
        return data;
      }
      
      return null;
    } catch (e) {
      // Log error
      return null;
    }
  }
  
  // Actualizar perfil de usuario
  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    try {
      // Agregar timestamp de actualización
      updates['updatedAt'] = FieldValue.serverTimestamp();
      
      // Actualizar en la colección principal
      await _profilesCollection.doc(userId).update(updates);
      
      // Si hay cambios en los campos principales, actualizar también en el índice
      final profile = await getProfile(userId);
      if (profile != null) {
        final collectionPath = getProfileCollectionPath(
          profile.ecoceTipoActor, 
          profile.ecoceSubtipo
        );
        
        if (collectionPath != null) {
          await FirebaseFirestore.instance
              .collection(collectionPath)
              .doc(userId)
              .update(updates);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Aprobar solicitud y crear usuario
  Future<void> approveSolicitud({
    required String solicitudId,
    required String approvedById,
    String? comments,
  }) async {
    try {
      // Obtener datos de la solicitud
      final solicitudDoc = await _solicitudesCollection.doc(solicitudId).get();
      if (!solicitudDoc.exists) {
        throw Exception('Solicitud no encontrada');
      }
      
      final solicitudData = solicitudDoc.data() as Map<String, dynamic>;
      final datosPerfil = solicitudData['datos_perfil'] as Map<String, dynamic>;
      
      // Crear usuario en Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: solicitudData['email'],
        password: solicitudData['password'],
      );
      
      final userId = userCredential.user!.uid;
      
      // Generar folio según tipo y subtipo
      final tipoActor = datosPerfil['ecoce_tipo_actor'];
      final subtipo = datosPerfil['ecoce_subtipo'];
      final folio = await _generateFolio(tipoActor, subtipo);
      
      // Actualizar datos del perfil con el folio real
      datosPerfil['ecoce_folio'] = folio;
      datosPerfil['id'] = userId;
      datosPerfil['ecoce_estatus_aprobacion'] = 1;
      datosPerfil['ecoce_fecha_aprobacion'] = Timestamp.fromDate(DateTime.now());
      datosPerfil['ecoce_aprobado_por'] = approvedById;
      datosPerfil['ecoce_comentarios_revision'] = comments;
      datosPerfil['createdAt'] = Timestamp.fromDate(DateTime.now());
      datosPerfil['updatedAt'] = Timestamp.fromDate(DateTime.now());
      
      // Crear perfil en la colección principal
      await _profilesCollection.doc(userId).set(datosPerfil);
      
      // Actualizar nombre del usuario
      await userCredential.user!.updateDisplayName(datosPerfil['ecoce_nombre']);
      
      // Actualizar estado de la solicitud
      await _solicitudesCollection.doc(solicitudId).update({
        'estado': 'aprobada',
        'fecha_revision': FieldValue.serverTimestamp(),
        'revisado_por': approvedById,
        'comentarios_revision': comments,
        'usuario_creado_id': userId,
        'folio_asignado': folio,
      });
    } catch (e) {
      rethrow;
    }
  }
  
  // Rechazar solicitud y eliminar de base de datos
  Future<void> rejectSolicitud({
    required String solicitudId,
    required String rejectedById,
    required String reason,
  }) async {
    try {
      // Primero obtener la solicitud para limpiar archivos si existen
      final solicitudDoc = await _solicitudesCollection.doc(solicitudId).get();
      
      if (solicitudDoc.exists) {
        final solicitudData = solicitudDoc.data() as Map<String, dynamic>;
        final datosPerfil = solicitudData['datos_perfil'] as Map<String, dynamic>?;
        
        // Limpiar archivos de Storage si existen
        if (datosPerfil != null) {
          await _deleteStorageFiles(solicitudId, datosPerfil);
        }
        
        // Eliminar el documento de la solicitud
        await _solicitudesCollection.doc(solicitudId).delete();
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Eliminar archivos de Storage asociados a una solicitud
  Future<void> _deleteStorageFiles(String solicitudId, Map<String, dynamic> datosPerfil) async {
    try {
      final storage = FirebaseStorage.instanceFor(app: _firebaseManager.currentApp!);
      
      // Lista de posibles campos de documentos
      final documentFields = [
        'ecoce_const_sit_fis',
        'ecoce_comp_domicilio', 
        'ecoce_banco_caratula',
        'ecoce_ine'
      ];
      
      for (final field in documentFields) {
        final url = datosPerfil[field] as String?;
        if (url != null && url.startsWith('http')) {
          try {
            // Obtener referencia desde la URL
            final ref = storage.refFromURL(url);
            await ref.delete();
          } catch (e) {
            // Continuar si falla eliminar un archivo
            // Log: Error al eliminar archivo $field: $e
          }
        }
      }
      
      // También intentar eliminar la carpeta completa de la solicitud
      try {
        final folderRef = storage.ref().child('solicitudes/$solicitudId');
        final items = await folderRef.listAll();
        
        // Eliminar todos los archivos en la carpeta
        for (final item in items.items) {
          await item.delete();
        }
      } catch (e) {
        // No es crítico si falla
        // Log: Error al eliminar carpeta de solicitud: $e
      }
    } catch (e) {
      // No lanzar error si falla la limpieza de archivos
      // Log: Error general al limpiar archivos: $e
    }
  }

  // Obtener perfil por ID (busca primero en índice y luego en subcolección)
  Future<EcoceProfileModel?> getProfile(String userId) async {
    try {
      // Primero buscar en el índice principal
      final indexDoc = await _profilesCollection.doc(userId).get();
      if (!indexDoc.exists) return null;
      
      final indexData = indexDoc.data() as Map<String, dynamic>;
      final profilePath = indexData['path'] as String?;
      
      if (profilePath != null) {
        // Obtener el documento desde la subcolección
        final profileDoc = await _firestore.doc(profilePath).get();
        if (profileDoc.exists) {
          return EcoceProfileModel.fromFirestore(profileDoc);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Actualizar perfil completo
  Future<void> updateProfileData(String userId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      
      // Primero obtener la ruta del perfil desde el índice
      final indexDoc = await _profilesCollection.doc(userId).get();
      if (!indexDoc.exists) throw Exception('Usuario no encontrado');
      
      final indexData = indexDoc.data() as Map<String, dynamic>;
      final profilePath = indexData['path'] as String?;
      
      if (profilePath != null) {
        // Actualizar el documento en la subcolección
        await _firestore.doc(profilePath).update(data);
        
        // Si se actualiza el nombre, actualizar también en el índice
        if (data.containsKey('ecoce_nombre')) {
          await _profilesCollection.doc(userId).update({
            'nombre': data['ecoce_nombre'],
            'updatedAt': data['updatedAt'],
          });
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Verificar si el email ya está registrado
  Future<bool> isEmailRegistered(String email) async {
    try {
      // Check if user exists in Firestore instead of using deprecated method
      final query = await _profilesCollection
          .where('ecoce_correo_contacto', isEqualTo: email)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
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
      // Primero obtener el perfil para conocer su tipo y subtipo
      final profileDoc = await _profilesCollection.doc(profileId).get();
      if (!profileDoc.exists) {
        throw Exception('Perfil no encontrado');
      }
      
      final profileData = profileDoc.data() as Map<String, dynamic>;
      final tipoActor = profileData['ecoce_tipo_actor'] as String;
      final subtipo = profileData['ecoce_subtipo'] as String?;
      
      // Generar el folio secuencial al momento de aprobar
      final folio = await _generateFolio(tipoActor, subtipo);
      
      // Actualizar el perfil con el folio y estado aprobado
      await _profilesCollection.doc(profileId).update({
        'ecoce_folio': folio,
        'ecoce_estatus_aprobacion': 1,
        'ecoce_fecha_aprobacion': Timestamp.fromDate(DateTime.now()),
        'ecoce_aprobado_por': approvedById,
        'ecoce_comentarios_revision': comments,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
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
      rethrow;
    }
  }

  // Eliminar perfil completo y sus datos asociados
  Future<void> deleteUserCompletely({
    required String userId,
    required String deletedBy,
  }) async {
    try {
      // 1. Obtener la ruta del perfil desde el índice
      final indexDoc = await _profilesCollection.doc(userId).get();
      if (!indexDoc.exists) {
        throw Exception('Usuario no encontrado');
      }
      
      final indexData = indexDoc.data() as Map<String, dynamic>;
      final profilePath = indexData['path'] as String?;
      
      // 2. Obtener el perfil completo para acceder a los documentos
      Map<String, dynamic>? profileData;
      if (profilePath != null) {
        final profileDoc = await _firestore.doc(profilePath).get();
        if (profileDoc.exists) {
          profileData = profileDoc.data() as Map<String, dynamic>;
        }
      }
      
      // 3. Eliminar archivos de Storage si existen
      if (profileData != null) {
        await _deleteUserStorageFiles(userId, profileData);
      }
      
      // 4. Eliminar el documento de la subcolección
      if (profilePath != null) {
        await _firestore.doc(profilePath).delete();
      }
      
      // 5. Eliminar el índice
      await _profilesCollection.doc(userId).delete();
      
      // 6. Eliminar completamente la solicitud correspondiente en solicitudes_cuentas
      // Buscar solicitudes aprobadas con este userId
      final solicitudQuery = await _solicitudesCollection
          .where('usuario_creado_id', isEqualTo: userId)
          .where('estado', isEqualTo: 'aprobada')
          .get();
      
      // Eliminar completamente las solicitudes
      for (final doc in solicitudQuery.docs) {
        await doc.reference.delete();
      }
      
      // 7. Registrar la eliminación en un log de auditoría
      await _firestore.collection('audit_logs').add({
        'action': 'user_deleted',
        'userId': userId,
        'userFolio': indexData['folio'] ?? profileData?['ecoce_folio'] ?? 'SIN FOLIO',
        'userName': indexData['nombre'] ?? profileData?['ecoce_nombre'] ?? 'Sin nombre',
        'deletedBy': deletedBy,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      
      // 8. Marcar el usuario para eliminación en Firebase Auth
      // IMPORTANTE: La eliminación real del usuario de Firebase Auth requiere Firebase Admin SDK
      // que solo puede ejecutarse en un entorno seguro del servidor (Cloud Functions)
      // 
      // Por ahora, creamos un documento en una colección especial para que una Cloud Function
      // procese la eliminación del usuario de Authentication
      await _firestore.collection('users_pending_deletion').doc(userId).set({
        'userId': userId,
        'userEmail': profileData?['ecoce_correo_contacto'] ?? indexData['email'] ?? 'unknown',
        'requestedBy': deletedBy,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'userFolio': indexData['folio'] ?? profileData?['ecoce_folio'] ?? 'SIN FOLIO',
        'userName': indexData['nombre'] ?? profileData?['ecoce_nombre'] ?? 'Sin nombre',
      });
      
      // El usuario no podrá acceder al sistema aunque exista en Auth porque:
      // 1. No tiene perfil en ecoce_profiles
      // 2. No tiene solicitud aprobada
      // 3. La Cloud Function lo eliminará de Auth cuando se ejecute
      
    } catch (e) {
      rethrow;
    }
  }
  
  // Eliminar archivos de Storage de un usuario
  Future<void> _deleteUserStorageFiles(String userId, Map<String, dynamic> profileData) async {
    try {
      final storage = FirebaseStorage.instanceFor(app: _firebaseManager.currentApp);
      
      // Lista de campos que contienen URLs de documentos
      final documentFields = [
        'ecoce_const_sit_fis',
        'ecoce_comp_domicilio',
        'ecoce_banco_caratula',
        'ecoce_ine',
      ];
      
      for (final field in documentFields) {
        final url = profileData[field];
        if (url != null && url is String && url.isNotEmpty) {
          try {
            // Extraer la ruta del archivo desde la URL
            final uri = Uri.parse(url);
            final pathSegments = uri.pathSegments;
            if (pathSegments.isNotEmpty) {
              // Construir la ruta del archivo
              final filePath = pathSegments.skip(pathSegments.indexOf('o') + 1).join('/');
              final decodedPath = Uri.decodeComponent(filePath);
              
              // Eliminar el archivo
              await storage.ref(decodedPath).delete();
            }
          } catch (e) {
            // Continuar si falla la eliminación de un archivo específico
            // Log: Error al eliminar archivo $field: $e
          }
        }
      }
    } catch (e) {
      // No lanzar excepción si falla la eliminación de archivos
      // Log: Error al eliminar archivos de Storage: $e
    }
  }

  // Obtener estadísticas de perfiles
  Future<Map<String, int>> getProfileStatistics() async {
    try {
      // Contar solicitudes pendientes
      final pendingQuery = await _solicitudesCollection
          .where('estado', isEqualTo: 'pendiente')
          .get();
      final pending = pendingQuery.docs.length;
      
      // Contar usuarios aprobados desde el índice
      final approvedQuery = await _profilesCollection
          .where('aprobado', isEqualTo: true)
          .get();
      final approved = approvedQuery.docs.length;
      
      // Las rechazadas se eliminan, así que siempre es 0
      final rejected = 0;
      
      return {
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'total': pending + approved,
      };
    } catch (e) {
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
      return false;
    }
  }
  
  // Obtener perfiles aprobados (desde todas las subcolecciones)
  Future<List<EcoceProfileModel>> getApprovedProfiles() async {
    try {
      // Buscar en el índice principal usuarios aprobados
      final indexQuery = await _profilesCollection
          .where('aprobado', isEqualTo: true)
          .orderBy('fecha_aprobacion', descending: true)
          .get();
      
      List<EcoceProfileModel> profiles = [];
      
      // Para cada entrada en el índice, obtener el perfil completo
      for (final indexDoc in indexQuery.docs) {
        final indexData = indexDoc.data() as Map<String, dynamic>;
        final profilePath = indexData['path'] as String?;
        
        if (profilePath != null) {
          final profileDoc = await _firestore.doc(profilePath).get();
          if (profileDoc.exists) {
            profiles.add(EcoceProfileModel.fromFirestore(profileDoc));
          }
        }
      }
      
      return profiles;
    } catch (e) {
      return [];
    }
  }
  
  // Obtener perfiles rechazados (ya no aplica con la nueva estructura)
  // Los perfiles rechazados se eliminan, no se guardan
  Future<List<EcoceProfileModel>> getRejectedProfiles() async {
    return []; // Las solicitudes rechazadas se eliminan completamente
  }
  
  // Obtener solicitudes aprobadas
  Future<List<Map<String, dynamic>>> getApprovedSolicitudes() async {
    try {
      final query = await _solicitudesCollection
          .where('estado', isEqualTo: 'aprobada')
          .orderBy('fecha_revision', descending: true)
          .get();
      
      return query.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['solicitud_id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Obtener solicitudes rechazadas
  Future<List<Map<String, dynamic>>> getRejectedSolicitudes() async {
    try {
      final query = await _solicitudesCollection
          .where('estado', isEqualTo: 'rechazada')
          .orderBy('fecha_revision', descending: true)
          .get();
      
      return query.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['solicitud_id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Obtener perfiles por tipo específico
  Future<List<EcoceProfileModel>> getProfilesByType(String tipoActor, {String? subtipo}) async {
    try {
      final subcollection = _getProfileSubcollection(tipoActor, subtipo);
      final query = await subcollection
          .where('ecoce_estatus_aprobacion', isEqualTo: 1)
          .orderBy('ecoce_fecha_aprobacion', descending: true)
          .get();
      
      return query.docs
          .map((doc) => EcoceProfileModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Obtener TODOS los perfiles activos del sistema
  Future<List<EcoceProfileModel>> getAllActiveProfiles() async {
    try {
      // Obtener todos los documentos de la colección principal ecoce_profiles
      final query = await _profilesCollection.get();
      
      List<EcoceProfileModel> allProfiles = [];
      
      for (final doc in query.docs) {
        Map<String, dynamic>? data;
        try {
          // Intentar obtener como perfil directo (usuarios antiguos)
          data = doc.data() as Map<String, dynamic>;
          
          // Si tiene los campos de perfil directamente, es un usuario antiguo
          if (data.containsKey('ecoce_nombre') && data.containsKey('ecoce_folio')) {
            final profile = EcoceProfileModel.fromFirestore(doc);
            allProfiles.add(profile);
          } 
          // Si no, podría ser un índice que apunta a una subcolección
          else if (data.containsKey('path')) {
            final profilePath = data['path'] as String;
            final profileDoc = await _firestore.doc(profilePath).get();
            if (profileDoc.exists) {
              final profile = EcoceProfileModel.fromFirestore(profileDoc);
              allProfiles.add(profile);
            }
          }
        } catch (e) {
          // Continuar con el siguiente documento si hay error
          // En producción, considerar usar un sistema de logging como Firebase Crashlytics
          // Por ahora, solo continuamos con el siguiente documento
          continue;
        }
      }
      
      // Ordenar por fecha de registro o nombre
      allProfiles.sort((a, b) {
        // Ordenar por fecha de registro (descendente - más recientes primero)
        return b.ecoceFechaReg.compareTo(a.ecoceFechaReg);
      });
      
      return allProfiles;
    } catch (e) {
      // Log: Error al obtener todos los perfiles: $e
      return [];
    }
  }
  
  // Obtener todos los perfiles de origen (centros de acopio y plantas de separación)
  Future<List<EcoceProfileModel>> getOrigenProfiles() async {
    try {
      List<EcoceProfileModel> profiles = [];
      
      // Obtener centros de acopio
      final acopioQuery = await _profilesCollection
          .doc('origen')
          .collection('centro_acopio')
          .where('ecoce_estatus_aprobacion', isEqualTo: 1)
          .get();
      
      profiles.addAll(acopioQuery.docs
          .map((doc) => EcoceProfileModel.fromFirestore(doc)));
      
      // Obtener plantas de separación
      final plantaQuery = await _profilesCollection
          .doc('origen')
          .collection('planta_separacion')
          .where('ecoce_estatus_aprobacion', isEqualTo: 1)
          .get();
      
      profiles.addAll(plantaQuery.docs
          .map((doc) => EcoceProfileModel.fromFirestore(doc)));
      
      // Ordenar por fecha de aprobación
      profiles.sort((a, b) => (b.ecoceFechaAprobacion ?? DateTime.now())
          .compareTo(a.ecoceFechaAprobacion ?? DateTime.now()));
      
      return profiles;
    } catch (e) {
      return [];
    }
  }
  
  // Subir documentos de una solicitud y actualizar URLs en Firestore
  Future<bool> uploadAndUpdateSolicitudDocuments({
    required String solicitudId,
    required Map<String, PlatformFile?> documents,
    Function(String, double)? onProgress,
  }) async {
    try {
      // Subir todos los documentos
      final uploadedUrls = await _documentService.uploadSolicitudDocuments(
        solicitudId: solicitudId,
        documents: documents,
        onProgress: onProgress,
      );
      
      // Filtrar solo las URLs válidas
      final validUrls = <String, dynamic>{};
      uploadedUrls.forEach((key, url) {
        if (url != null && url.isNotEmpty) {
          validUrls['datos_perfil.ecoce_$key'] = url;
        }
      });
      
      // Si hay URLs válidas, actualizar el documento
      if (validUrls.isNotEmpty) {
        await _solicitudesCollection.doc(solicitudId).update(validUrls);
        // Documentos actualizados exitosamente en la solicitud
        return true;
      }
      
      return false;
    } catch (e) {
      // Log: Error al subir documentos: $e
      return false;
    }
  }
  
  // Obtener solicitud por ID
  Future<Map<String, dynamic>?> getSolicitudById(String solicitudId) async {
    try {
      final doc = await _solicitudesCollection.doc(solicitudId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['solicitud_id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      // Log: Error al obtener solicitud: $e
      return null;
    }
  }
  
  // Obtener perfil por folio
  Future<EcoceProfileModel?> getProfileByFolio(String folio) async {
    try {
      // Buscar en el índice principal por folio
      final query = await _profilesCollection
          .where('folio', isEqualTo: folio)
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) return null;
      
      final indexDoc = query.docs.first;
      final indexData = indexDoc.data() as Map<String, dynamic>;
      final profilePath = indexData['path'] as String?;
      
      if (profilePath != null) {
        // Obtener el perfil completo de la subcolección
        final profileDoc = await _firestore.doc(profilePath).get();
        if (profileDoc.exists) {
          return EcoceProfileModel.fromFirestore(profileDoc);
        }
      }
      
      return null;
    } catch (e) {
      // Log: Error al obtener perfil por folio: $e
      return null;
    }
  }
  
  // Obtener correo electrónico por folio (útil para login)
  Future<String?> getEmailByFolio(String folio) async {
    try {
      final profile = await getProfileByFolio(folio);
      return profile?.ecoceCorreoContacto;
    } catch (e) {
      // Log: Error al obtener correo por folio: $e
      return null;
    }
  }
}