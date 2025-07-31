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
  
  // Cache temporal para ubicaciones de usuarios (userId -> path)
  static final Map<String, String> _userPathCache = {};
  
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
      case 'M': // Maestro
        return 'ecoce_profiles/maestro/usuarios';
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
      case 'M': // Maestro
        return _profilesCollection.doc('maestro').collection('usuarios');
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
        case 'M':
          prefix = 'M'; // Maestro
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

  // Método createOrigenProfile eliminado - Usar solo el flujo de solicitudes
  
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
    List<String>? actividadesAutorizadas,
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
      
      // Debug: imprimir documentos recibidos
      print('Documentos recibidos en createAccountRequest:');
      documentos?.forEach((key, value) {
        print('  $key: ${value != null ? 'URL presente' : 'null'}');
      });
      
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
          'ecoce_opinion_cumplimiento': documentos?['opinion_cumplimiento'],
          'ecoce_ramir': documentos?['ramir'],
          'ecoce_plan_manejo': documentos?['plan_manejo'],
          'ecoce_licencia_ambiental': documentos?['licencia_ambiental'],
          'ecoce_act_autorizadas': actividadesAutorizadas ?? [],
          'ecoce_dim_cap': dimensionesCapacidad,
          'ecoce_peso_cap': pesoCapacidad,
        },
        'estado': 'pendiente',
        'fecha_solicitud': FieldValue.serverTimestamp(),
        'fecha_revision': null,
        'revisado_por': null,
        'comentarios_revision': null,
      };
      
      // Debug: verificar que los documentos estén en solicitudData
      print('Documentos en solicitudData:');
      final datosPerfilDebug = solicitudData['datos_perfil'] as Map<String, dynamic>;
      ['ecoce_const_sit_fis', 'ecoce_comp_domicilio', 'ecoce_banco_caratula', 'ecoce_ine',
       'ecoce_opinion_cumplimiento', 'ecoce_ramir', 'ecoce_plan_manejo', 'ecoce_licencia_ambiental'].forEach((field) {
        print('  $field: ${datosPerfilDebug[field] != null ? 'URL presente' : 'null'}');
      });

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
      
      // Debug: verificar documentos antes de guardar
      print('📋 Documentos en perfil aprobado:');
      ['ecoce_const_sit_fis', 'ecoce_comp_domicilio', 'ecoce_banco_caratula', 'ecoce_ine',
       'ecoce_opinion_cumplimiento', 'ecoce_ramir', 'ecoce_plan_manejo', 'ecoce_licencia_ambiental'].forEach((field) {
        print('  $field: ${datosPerfil[field] != null ? 'URL presente' : 'null'}');
      });
      
      // Obtener la subcolección según el tipo
      final subcollection = _getProfileSubcollection(tipoActor, subtipo);
      
      // Guardar SOLO en la subcolección correspondiente (sin crear índice)
      await subcollection.doc(userId).set(datosPerfil);
      
      // Crear índice en la colección principal para búsquedas rápidas
      final indexData = {
        'id': userId,
        'path': '${getProfileCollectionPath(tipoActor, subtipo)}/$userId',
        'folio': folio,
        'nombre': datosPerfil['ecoce_nombre'],
        'email': datosPerfil['ecoce_correo_contacto'],
        'tipo_actor': tipoActor,
        'subtipo': subtipo,
        'aprobado': true,
        'fecha_aprobacion': Timestamp.fromDate(DateTime.now()),
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      
      // Guardar el índice usando el folio como ID del documento
      await _profilesCollection.doc(folio).set(indexData);
      
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
        'ecoce_ine',
        'ecoce_opinion_cumplimiento',
        'ecoce_ramir',
        'ecoce_plan_manejo',
        'ecoce_licencia_ambiental'
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

  // Obtener perfil por ID (busca directamente en las subcarpetas)
  Future<EcoceProfileModel?> getProfile(String userId) async {
    try {
      // Lista de todas las subcolecciónes posibles
      final subcollections = [
        'origen/centro_acopio',
        'origen/planta_separacion',
        'reciclador/usuarios',
        'transformador/usuarios',
        'transporte/usuarios',
        'laboratorio/usuarios',
        'maestro/usuarios',
      ];
      
      // Buscar en cada subcolección hasta encontrar el usuario
      for (final subcollection in subcollections) {
        try {
          final doc = await _profilesCollection
              .doc(subcollection.split('/')[0])
              .collection(subcollection.split('/')[1])
              .doc(userId)
              .get();
          
          if (doc.exists) {
            return EcoceProfileModel.fromFirestore(doc);
          }
        } catch (e) {
          // Continuar con la siguiente subcolección
          continue;
        }
      }
      
      // Si no se encontró en ninguna subcolección, el usuario no existe
      return null;
    } catch (e) {
      return null;
    }
  }

  // Actualizar perfil completo (busca directamente en subcarpetas)
  Future<void> updateProfileData(String userId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      
      // Lista de todas las subcolecciónes posibles
      final subcollections = [
        'origen/centro_acopio',
        'origen/planta_separacion',
        'reciclador/usuarios',
        'transformador/usuarios',
        'transporte/usuarios',
        'laboratorio/usuarios',
        'maestro/usuarios',
      ];
      
      // Buscar en cada subcolección hasta encontrar el usuario
      bool updated = false;
      for (final subcollection in subcollections) {
        try {
          final docRef = _profilesCollection
              .doc(subcollection.split('/')[0])
              .collection(subcollection.split('/')[1])
              .doc(userId);
          
          final doc = await docRef.get();
          if (doc.exists) {
            await docRef.update(data);
            updated = true;
            break;
          }
        } catch (e) {
          // Continuar con la siguiente subcolección
          continue;
        }
      }
      
      // Si no se encontró en subcolecciónes, el usuario no existe
      if (!updated) {
        throw Exception('Usuario no encontrado');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Verificar si el email ya está registrado (busca en todas las subcarpetas)
  Future<bool> isEmailRegistered(String email) async {
    try {
      // Lista de todas las subcolecciónes posibles
      final subcollections = [
        'origen/centro_acopio',
        'origen/planta_separacion',
        'reciclador/usuarios',
        'transformador/usuarios',
        'transporte/usuarios',
        'laboratorio/usuarios',
        'maestro/usuarios',
      ];
      
      // Buscar en cada subcolección
      for (final subcollection in subcollections) {
        try {
          final query = await _profilesCollection
              .doc(subcollection.split('/')[0])
              .collection(subcollection.split('/')[1])
              .where('ecoce_correo_contacto', isEqualTo: email)
              .limit(1)
              .get();
          
          if (query.docs.isNotEmpty) {
            return true;
          }
        } catch (e) {
          // Continuar con la siguiente subcolección
          continue;
        }
      }
      
      // Si no se encontró en ninguna subcolección, el email no está registrado
      return false;
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
      // 1. Buscar el perfil - primero en caché, luego en Firestore
      Map<String, dynamic>? profileData;
      DocumentSnapshot? profileDoc;
      String? profilePath;
      
      // Verificar caché primero
      if (_userPathCache.containsKey(userId)) {
        profilePath = _userPathCache[userId];
        final doc = await _firestore.doc(profilePath!).get();
        if (doc.exists) {
          profileDoc = doc;
          profileData = doc.data() as Map<String, dynamic>;
        } else {
          // Si no existe, limpiar del caché
          _userPathCache.remove(userId);
          profilePath = null;
        }
      }
      
      // Si no se encontró en caché, buscar en todas las rutas
      if (profileData == null) {
        // Lista de todas las rutas posibles de perfiles
        final possiblePaths = [
          'ecoce_profiles/origen/centro_acopio/$userId',
          'ecoce_profiles/origen/planta_separacion/$userId',
          'ecoce_profiles/reciclador/usuarios/$userId',
          'ecoce_profiles/transformador/usuarios/$userId',
          'ecoce_profiles/transporte/usuarios/$userId',
          'ecoce_profiles/laboratorio/usuarios/$userId',
          'ecoce_profiles/maestro/usuarios/$userId',
        ];
        
        // Buscar en PARALELO en todas las rutas posibles
        final futures = possiblePaths.map((path) => _firestore.doc(path).get());
        final results = await Future.wait(futures);
        
        // Encontrar el documento que existe
        for (int i = 0; i < results.length; i++) {
          if (results[i].exists) {
            profileDoc = results[i];
            profileData = results[i].data() as Map<String, dynamic>;
            profilePath = possiblePaths[i];
            // Guardar en caché para futuras búsquedas
            _userPathCache[userId] = profilePath;
            break;
          }
        }
      }
      
      // Si no se encontró en las rutas directas, buscar en el índice antiguo
      if (profileData == null) {
        final indexDoc = await _profilesCollection.doc(userId).get();
        if (indexDoc.exists) {
          final indexData = indexDoc.data() as Map<String, dynamic>;
          profilePath = indexData['path'] as String?;
          
          if (profilePath != null) {
            final doc = await _firestore.doc(profilePath).get();
            if (doc.exists) {
              profileDoc = doc;
              profileData = doc.data() as Map<String, dynamic>;
            }
          }
        }
      }
      
      if (profileData == null) {
        throw Exception('Usuario no encontrado en ninguna colección');
      }
      
      // 2. Preparar todas las operaciones de eliminación
      final List<Future<void>> deletionTasks = [];
      
      // Eliminar archivos de Storage (puede ser lento)
      deletionTasks.add(_deleteUserStorageFiles(userId, profileData));
      
      // Eliminar el documento de la subcolección
      if (profilePath != null) {
        deletionTasks.add(_firestore.doc(profilePath).delete());
      }
      
      // Eliminar el índice si existe
      deletionTasks.add(
        _profilesCollection.doc(userId).delete().catchError((e) {
          // Si no existe el índice, no es un error crítico
          print('Índice no encontrado para eliminar: $e');
        })
      );
      
      // Buscar y eliminar solicitudes aprobadas
      deletionTasks.add(
        _solicitudesCollection
            .where('usuario_creado_id', isEqualTo: userId)
            .where('estado', isEqualTo: 'aprobada')
            .get()
            .then((query) async {
              final batch = _firestore.batch();
              for (final doc in query.docs) {
                batch.delete(doc.reference);
              }
              if (query.docs.isNotEmpty) {
                await batch.commit();
              }
            })
      );
      
      // Registrar en audit log
      deletionTasks.add(
        _firestore.collection('audit_logs').add({
          'action': 'user_deleted',
          'userId': userId,
          'userFolio': profileData['ecoce_folio'] ?? 'SIN FOLIO',
          'userName': profileData['ecoce_nombre'] ?? 'Sin nombre',
          'deletedBy': deletedBy,
          'deletedAt': FieldValue.serverTimestamp(),
        })
      );
      
      // Marcar para eliminación en Auth
      deletionTasks.add(
        _firestore.collection('users_pending_deletion').doc(userId).set({
          'userId': userId,
          'userEmail': profileData['ecoce_correo_contacto'] ?? 'unknown',
          'requestedBy': deletedBy,
          'requestedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
          'userFolio': profileData['ecoce_folio'] ?? 'SIN FOLIO',
          'userName': profileData['ecoce_nombre'] ?? 'Sin nombre',
        })
      );
      
      // 3. Ejecutar todas las operaciones en PARALELO
      await Future.wait(deletionTasks);
      
      // 4. Limpiar el usuario del caché
      _userPathCache.remove(userId);
      
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
        'ecoce_opinion_cumplimiento',
        'ecoce_ramir',
        'ecoce_plan_manejo',
        'ecoce_licencia_ambiental',
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
  
  // Procesar y eliminar usuarios pendientes de eliminación
  Future<void> processPendingDeletions() async {
    try {
      // Obtener usuarios pendientes de eliminación
      final pendingDeletions = await _firestore
          .collection('users_pending_deletion')
          .where('status', isEqualTo: 'pending')
          .limit(10) // Procesar en lotes para evitar timeout
          .get();
      
      if (pendingDeletions.docs.isEmpty) {
        return;
      }
      
      final batch = _firestore.batch();
      
      for (final doc in pendingDeletions.docs) {
        final data = doc.data();
        final userId = data['userId'] as String;
        
        try {
          // Intentar eliminar el usuario de Firebase Auth
          // NOTA: Esto requerirá el Admin SDK o una Cloud Function
          // Por ahora, solo actualizamos el estado
          
          // Actualizar estado a procesando
          batch.update(doc.reference, {
            'status': 'processing',
            'processedAt': FieldValue.serverTimestamp(),
          });
          
          // TODO: Aquí es donde se llamaría a la Cloud Function para eliminar el usuario
          // await _deleteUserFromAuth(userId);
          
          // Si la eliminación es exitosa, eliminar el registro
          batch.delete(doc.reference);
          
        } catch (e) {
          // Si falla, marcar como error
          batch.update(doc.reference, {
            'status': 'error',
            'error': e.toString(),
            'errorAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      await batch.commit();
    } catch (e) {
      print('Error procesando eliminaciones pendientes: $e');
    }
  }
  
  // Limpiar registros antiguos de users_pending_deletion
  Future<void> cleanupPendingDeletions() async {
    try {
      // Eliminar registros con más de 30 días
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final oldRecords = await _firestore
          .collection('users_pending_deletion')
          .where('requestedAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();
      
      if (oldRecords.docs.isEmpty) {
        return;
      }
      
      // Eliminar en lotes
      final batch = _firestore.batch();
      for (final doc in oldRecords.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('Eliminados ${oldRecords.docs.length} registros antiguos de users_pending_deletion');
    } catch (e) {
      print('Error limpiando registros antiguos: $e');
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
  
  // Obtener datos completos del perfil directamente de Firebase
  Future<Map<String, dynamic>> getProfileDataAsMap(String userId) async {
    try {
      // Lista de todas las subcolecciones posibles
      final subcollections = [
        'origen/centro_acopio',
        'origen/planta_separacion',
        'reciclador/usuarios',
        'transformador/usuarios',
        'transporte/usuarios',
        'laboratorio/usuarios',
        'maestro/usuarios',
      ];
      
      // Buscar en cada subcolección hasta encontrar el usuario
      for (final subcollection in subcollections) {
        try {
          final doc = await _profilesCollection
              .doc(subcollection.split('/')[0])
              .collection(subcollection.split('/')[1])
              .doc(userId)
              .get();
          
          if (doc.exists) {
            return doc.data() as Map<String, dynamic>;
          }
        } catch (e) {
          continue;
        }
      }
      
      // Si no se encontró, devolver un mapa vacío
      return {};
    } catch (e) {
      return {};
    }
  }
  
  // Obtener TODOS los perfiles del sistema sin filtrar (para administración)
  Future<List<EcoceProfileModel>> getAllProfiles() async {
    try {
      List<EcoceProfileModel> allProfiles = [];
      final processedIds = <String>{};
      
      // Primero buscar en el índice de ecoce_profiles
      final indexQuery = await _profilesCollection.get();
      
      for (final indexDoc in indexQuery.docs) {
        try {
          final indexData = indexDoc.data() as Map<String, dynamic>?;
          if (indexData != null && indexData['path'] != null) {
            final profileDoc = await _firestore.doc(indexData['path'] as String).get();
            if (profileDoc.exists) {
              final profile = EcoceProfileModel.fromFirestore(profileDoc);
              allProfiles.add(profile);
              processedIds.add(profile.id);
              // Guardar en caché la ubicación del usuario
              _userPathCache[profile.id] = profileDoc.reference.path;
            }
          }
        } catch (e) {
          // Continuar si hay error procesando un documento del índice
          continue;
        }
      }
      
      // Luego buscar en las subcolecciones (para usuarios que no estén en el índice)
      final subcollections = [
        'origen/centro_acopio',
        'origen/planta_separacion',
        'reciclador/usuarios',
        'transformador/usuarios',
        'transporte/usuarios',
        'laboratorio/usuarios',
        'maestro/usuarios',
      ];
      
      // Buscar en cada subcolección sin filtrar por estado
      for (final subcollection in subcollections) {
        try {
          final query = await _profilesCollection
              .doc(subcollection.split('/')[0])
              .collection(subcollection.split('/')[1])
              .get();
          
          for (final doc in query.docs) {
            try {
              // Evitar duplicados
              if (processedIds.contains(doc.id)) continue;
              
              final profile = EcoceProfileModel.fromFirestore(doc);
              allProfiles.add(profile);
              processedIds.add(profile.id);
              // Guardar en caché la ubicación del usuario
              _userPathCache[profile.id] = doc.reference.path;
            } catch (e) {
              // Continuar si hay error parseando un documento
              continue;
            }
          }
        } catch (e) {
          // Continuar con la siguiente subcolección si hay error
          continue;
        }
      }
      
      // Ordenar por fecha de registro (descendente - más recientes primero)
      allProfiles.sort((a, b) {
        return b.ecoceFechaReg.compareTo(a.ecoceFechaReg);
      });
      
      return allProfiles;
    } catch (e) {
      // Log: Error al obtener todos los perfiles: $e
      return [];
    }
  }
  
  // Obtener TODOS los perfiles activos del sistema (busca directamente en subcarpetas)
  Future<List<EcoceProfileModel>> getAllActiveProfiles() async {
    try {
      List<EcoceProfileModel> allProfiles = [];
      
      // Lista de todas las subcolecciónes posibles
      final subcollections = [
        'origen/centro_acopio',
        'origen/planta_separacion',
        'reciclador/usuarios',
        'transformador/usuarios',
        'transporte/usuarios',
        'laboratorio/usuarios',
        'maestro/usuarios',
      ];
      
      // Buscar en cada subcolección
      for (final subcollection in subcollections) {
        try {
          final query = await _profilesCollection
              .doc(subcollection.split('/')[0])
              .collection(subcollection.split('/')[1])
              .where('ecoce_estatus_aprobacion', isEqualTo: 1)
              .get();
          
          for (final doc in query.docs) {
            try {
              final profile = EcoceProfileModel.fromFirestore(doc);
              allProfiles.add(profile);
              // Guardar en caché la ubicación del usuario
              _userPathCache[profile.id] = doc.reference.path;
            } catch (e) {
              // Continuar si hay error parseando un documento
              continue;
            }
          }
        } catch (e) {
          // Continuar con la siguiente subcolección si hay error
          continue;
        }
      }
      
      // No buscar en la colección principal - todos los usuarios están en subcarpetas
      
      // Ordenar por fecha de registro (descendente - más recientes primero)
      allProfiles.sort((a, b) {
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
  
  // Obtener perfil por folio (busca primero en el índice)
  Future<EcoceProfileModel?> getProfileByFolio(String folio) async {
    try {
      print('🔍 Buscando perfil por folio: $folio');
      
      // Primero buscar en el índice de ecoce_profiles
      final indexDoc = await _profilesCollection.doc(folio).get();
      
      if (indexDoc.exists) {
        print('✅ Encontrado en índice: $folio');
        final indexData = indexDoc.data() as Map<String, dynamic>?;
        if (indexData != null && indexData['path'] != null) {
          // Obtener el perfil completo usando el path
          final profileDoc = await _firestore.doc(indexData['path'] as String).get();
          if (profileDoc.exists) {
            return EcoceProfileModel.fromFirestore(profileDoc);
          }
        }
      } else {
        print('❌ No encontrado en índice, buscando en subcolecciones...');
      }
      
      // Si no se encontró en el índice, buscar en las subcolecciones (para usuarios antiguos)
      final subcollections = [
        'origen/centro_acopio',
        'origen/planta_separacion',
        'reciclador/usuarios',
        'transformador/usuarios',
        'transporte/usuarios',
        'laboratorio/usuarios',
        'maestro/usuarios',
      ];
      
      // Buscar en cada subcolección
      for (final subcollection in subcollections) {
        try {
          final query = await _profilesCollection
              .doc(subcollection.split('/')[0])
              .collection(subcollection.split('/')[1])
              .where('ecoce_folio', isEqualTo: folio)
              .limit(1)
              .get();
          
          if (query.docs.isNotEmpty) {
            return EcoceProfileModel.fromFirestore(query.docs.first);
          }
        } catch (e) {
          // Continuar con la siguiente subcolección
          continue;
        }
      }
      
      // Si no se encontró en subcolecciónes, el perfil no existe
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
  
  // MÉTODO TEMPORAL: Migrar usuarios existentes a la nueva estructura
  // Este método solo debe ejecutarse una vez para migrar usuarios antiguos
  Future<void> migrateExistingUsersToSubcollections() async {
    try {
      print('Iniciando migración de usuarios existentes...');
      
      // Obtener todos los documentos de la colección principal
      final allDocs = await _profilesCollection.get();
      int migrated = 0;
      int skipped = 0;
      int errors = 0;
      
      for (final doc in allDocs.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final userId = doc.id;
          
          // Verificar si es un perfil antiguo (tiene campos de perfil directamente)
          if (data.containsKey('ecoce_nombre') && data.containsKey('ecoce_tipo_actor')) {
            // Es un perfil antiguo, necesita migración
            String? tipoActor = data['ecoce_tipo_actor'] as String?;
            final subtipo = data['ecoce_subtipo'] as String?;
            
            // Manejar casos especiales
            if (tipoActor == null || tipoActor.isEmpty) {
              // Intentar determinar el tipo por el folio
              final folio = data['ecoce_folio'] as String? ?? '';
              if (folio.startsWith('A')) {
                tipoActor = 'O';
                data['ecoce_subtipo'] = 'A';
              } else if (folio.startsWith('P')) {
                tipoActor = 'O';
                data['ecoce_subtipo'] = 'P';
              } else if (folio.startsWith('R')) {
                tipoActor = 'R';
              } else if (folio.startsWith('T')) {
                tipoActor = 'T';
              } else if (folio.startsWith('V')) {
                tipoActor = 'V';
              } else if (folio.startsWith('L')) {
                tipoActor = 'L';
              } else if (folio.startsWith('M')) {
                tipoActor = 'M';
              } else {
                print('No se pudo determinar el tipo para: ${data['ecoce_nombre']} (${folio})');
                errors++;
                continue;
              }
            }
            
            // Obtener la subcolección correspondiente
            final subcollection = _getProfileSubcollection(tipoActor, subtipo);
            final collectionPath = getProfileCollectionPath(tipoActor, subtipo);
            
            // Verificar si ya existe en la subcolección
            final existingDoc = await subcollection.doc(userId).get();
            if (existingDoc.exists) {
              print('Usuario ya existe en subcolección, actualizando índice: ${data['ecoce_nombre']}');
              // Si ya existe, solo actualizar el índice
            } else {
              // Asegurar que todos los campos requeridos estén presentes
              data['ecoce_tipo_actor'] = tipoActor;
              if (tipoActor == 'O' && subtipo != null) {
                data['ecoce_subtipo'] = subtipo;
              }
              
              // Copiar el perfil a la subcolección
              await subcollection.doc(userId).set(data);
            }
            
            // Actualizar el documento principal para que sea un índice
            final indexData = {
              'id': userId,
              'path': getProfileCollectionPath(tipoActor, subtipo)! + '/$userId',
              'folio': data['ecoce_folio'],
              'nombre': data['ecoce_nombre'],
              'email': data['ecoce_correo_contacto'],
              'tipo_actor': tipoActor,
              'subtipo': subtipo,
              'aprobado': (data['ecoce_estatus_aprobacion'] ?? 1) == 1,
              'fecha_aprobacion': data['ecoce_fecha_aprobacion'],
              'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            };
            
            // Reemplazar el documento con el índice
            await _profilesCollection.doc(userId).set(indexData);
            
            migrated++;
            print('Migrado usuario: ${data['ecoce_nombre']} (${data['ecoce_folio']}) -> ${tipoActor}/${subtipo ?? 'usuarios'}');
          } else if (data.containsKey('path')) {
            // Ya es un índice, no necesita migración
            skipped++;
          }
        } catch (e) {
          print('Error migrando documento ${doc.id}: $e');
          errors++;
        }
      }
      
      print('Migración completada: $migrated usuarios migrados, $skipped ya estaban migrados, $errors errores');
    } catch (e) {
      print('Error en migración: $e');
      rethrow;
    }
  }
  
  // Método de diagnóstico para analizar la estructura de perfiles
  Future<Map<String, dynamic>> analyzeProfileStructure() async {
    try {
      print('\n=== ANÁLISIS DE ESTRUCTURA DE PERFILES ===\n');
      
      final stats = {
        'indices_limpios': 0,
        'indices_con_datos_extra': 0,
        'perfiles_completos_en_principal': 0,
        'documentos_huerfanos': 0,
        'usuarios_en_subcollecciones': 0,
        'detalles': <String, dynamic>{},
      };
      
      // Paso 1: Obtener todos los usuarios en subcolecciones
      final validUsersInSubcollections = <String, String>{}; // userId -> path
      
      final subcollections = [
        'origen/centro_acopio',
        'origen/planta_separacion',
        'reciclador/usuarios',
        'transformador/usuarios',
        'transporte/usuarios',
        'laboratorio/usuarios',
        'maestro/usuarios',
      ];
      
      for (final subcollection in subcollections) {
        try {
          final query = await _profilesCollection.doc(subcollection.split('/')[0])
              .collection(subcollection.split('/')[1])
              .get();
          
          for (final doc in query.docs) {
            validUsersInSubcollections[doc.id] = 'ecoce_profiles/$subcollection/${doc.id}';
            stats['usuarios_en_subcollecciones'] = (stats['usuarios_en_subcollecciones'] as int) + 1;
          }
        } catch (e) {
          print('Error revisando subcolección $subcollection: $e');
        }
      }
      
      // Paso 2: Analizar documentos en la colección principal
      final allDocs = await _profilesCollection.get();
      
      for (final doc in allDocs.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = doc.id;
        
        // Saltar documentos de estructura
        if (['origen', 'reciclador', 'transformador', 'transporte', 'laboratorio', 'maestro'].contains(userId)) {
          continue;
        }
        
        final detalles = <String, dynamic>{
          'id': userId,
          'tiene_path': data.containsKey('path'),
          'tiene_nombre': data.containsKey('ecoce_nombre'),
          'tiene_folio': data.containsKey('ecoce_folio'),
          'campos_totales': data.keys.length,
          'campos': data.keys.toList(),
        };
        
        if (validUsersInSubcollections.containsKey(userId)) {
          // Usuario existe en subcolección
          if (data.containsKey('path')) {
            // Es un índice
            final expectedFields = ['id', 'path', 'folio', 'nombre', 'email', 'tipo', 'subtipo', 'aprobado', 'createdAt', 'updatedAt'];
            final hasOnlyIndexFields = data.keys.every((key) => expectedFields.contains(key));
            
            if (hasOnlyIndexFields) {
              stats['indices_limpios'] = (stats['indices_limpios'] as int) + 1;
              detalles['tipo'] = 'índice_limpio';
            } else {
              stats['indices_con_datos_extra'] = (stats['indices_con_datos_extra'] as int) + 1;
              detalles['tipo'] = 'índice_con_datos_extra';
              detalles['campos_extra'] = data.keys.where((key) => !expectedFields.contains(key)).toList();
            }
          } else if (data.containsKey('ecoce_nombre')) {
            stats['perfiles_completos_en_principal'] = (stats['perfiles_completos_en_principal'] as int) + 1;
            detalles['tipo'] = 'perfil_completo_duplicado';
          }
        } else {
          // Usuario no existe en subcolección
          stats['documentos_huerfanos'] = (stats['documentos_huerfanos'] as int) + 1;
          detalles['tipo'] = 'huerfano';
        }
        
        (stats['detalles'] as Map<String, dynamic>)[userId] = detalles;
      }
      
      // Imprimir resumen
      print('=== RESUMEN DEL ANÁLISIS ===');
      print('Usuarios en subcolecciones: ${stats['usuarios_en_subcollecciones']}');
      print('Índices limpios: ${stats['indices_limpios']}');
      print('Índices con datos extra: ${stats['indices_con_datos_extra']}');
      print('Perfiles completos duplicados: ${stats['perfiles_completos_en_principal']}');
      print('Documentos huérfanos: ${stats['documentos_huerfanos']}');
      print('============================\n');
      
      // Imprimir detalles de problemas
      if ((stats['indices_con_datos_extra'] as int) > 0) {
        print('\n=== ÍNDICES CON DATOS EXTRA ===');
        (stats['detalles'] as Map<String, dynamic>).forEach((userId, detalles) {
          if (detalles['tipo'] == 'índice_con_datos_extra') {
            print('Usuario: $userId');
            print('  Campos extra: ${detalles['campos_extra']}');
          }
        });
      }
      
      if ((stats['perfiles_completos_en_principal'] as int) > 0) {
        print('\n=== PERFILES COMPLETOS DUPLICADOS ===');
        (stats['detalles'] as Map<String, dynamic>).forEach((userId, detalles) {
          if (detalles['tipo'] == 'perfil_completo_duplicado') {
            print('Usuario: $userId');
            print('  Total de campos: ${detalles['campos_totales']}');
          }
        });
      }
      
      return stats;
    } catch (e) {
      print('Error en análisis: $e');
      rethrow;
    }
  }

  // Limpiar usuarios duplicados y reorganizar los que están fuera de sus carpetas
  Future<Map<String, int>> cleanupDuplicateProfiles() async {
    try {
      print('Iniciando limpieza de perfiles duplicados...');
      
      // Paso 1: Obtener todos los usuarios que existen en subcolecciónes
      final validUsersInSubcollections = <String>{}; // Set de IDs de usuarios válidos
      
      // Revisar todas las subcolecciónes posibles
      final subcollections = [
        'origen/centro_acopio',
        'origen/planta_separacion',
        'reciclador/usuarios',
        'transformador/usuarios',
        'transporte/usuarios',
        'laboratorio/usuarios',
        'maestro/usuarios',
      ];
      
      print('Buscando usuarios en subcolecciónes...');
      for (final subcollection in subcollections) {
        try {
          final query = await _profilesCollection.doc(subcollection.split('/')[0])
              .collection(subcollection.split('/')[1])
              .get();
          
          for (final doc in query.docs) {
            validUsersInSubcollections.add(doc.id);
            print('Usuario encontrado en $subcollection: ${doc.id}');
          }
        } catch (e) {
          print('Error revisando subcolección $subcollection: $e');
        }
      }
      
      print('Total de usuarios válidos en subcolecciónes: ${validUsersInSubcollections.length}');
      
      // Paso 2: Revisar todos los documentos en la colección principal
      final allDocs = await _profilesCollection.get();
      int cleaned = 0;
      int keptIndices = 0;
      int errors = 0;
      
      print('\nRevisando ${allDocs.docs.length} documentos en la colección principal...');
      
      for (final doc in allDocs.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final userId = doc.id;
          
          // Saltar documentos de estructura (origen, reciclador, etc.)
          if (['origen', 'reciclador', 'transformador', 'transporte', 'laboratorio', 'maestro'].contains(userId)) {
            print('Saltando documento de estructura: $userId');
            continue;
          }
          
          // Si el usuario existe en una subcolección
          if (validUsersInSubcollections.contains(userId)) {
            // Determinar qué tipo de documento es
            final hasPath = data.containsKey('path');
            final hasProfileFields = data.containsKey('ecoce_nombre') || 
                                   data.containsKey('ecoce_folio') || 
                                   data.containsKey('ecoce_rfc') || 
                                   data.containsKey('ecoce_tel_contacto') ||
                                   data.containsKey('ecoce_calle') ||
                                   data.containsKey('ecoce_lista_materiales');
            
            // Campos válidos para un índice limpio
            final validIndexFields = ['id', 'path', 'folio', 'nombre', 'email', 'tipo', 'subtipo', 
                                    'tipo_actor', 'aprobado', 'fecha_aprobacion', 'createdAt', 'updatedAt'];
            final hasOnlyIndexFields = data.keys.every((key) => validIndexFields.contains(key));
            
            if (hasPath && hasOnlyIndexFields && !hasProfileFields) {
              // Es un índice limpio, mantenerlo
              keptIndices++;
              print('Manteniendo índice limpio para: $userId');
            } else {
              // Es un perfil completo O un índice con datos extra
              // En ambos casos, necesitamos limpiarlo
              print('Detectado documento con datos extra o perfil completo: $userId');
              print('  Tiene path: $hasPath, Tiene campos de perfil: $hasProfileFields');
              print('  Campos encontrados: ${data.keys.toList()}');
              
              // Eliminar el documento actual
              await _profilesCollection.doc(userId).delete();
              cleaned++;
              
              // Si tenía path, recrear como índice limpio
              if (hasPath) {
                try {
                  final profilePath = data['path'] as String;
                  final profileDoc = await _firestore.doc(profilePath).get();
                  
                  if (profileDoc.exists) {
                    final profileData = profileDoc.data() as Map<String, dynamic>;
                    
                    // Crear índice limpio
                    final cleanIndex = {
                      'id': userId,
                      'path': profilePath,
                      'folio': profileData['ecoce_folio'] ?? data['ecoce_folio'] ?? data['folio'] ?? 'PENDIENTE',
                      'nombre': profileData['ecoce_nombre'] ?? data['ecoce_nombre'] ?? data['nombre'] ?? '',
                      'email': profileData['ecoce_correo_contacto'] ?? data['ecoce_correo_contacto'] ?? data['email'] ?? '',
                      'tipo': profileData['ecoce_tipo_actor'] ?? data['ecoce_tipo_actor'] ?? data['tipo'] ?? '',
                      'subtipo': profileData['ecoce_subtipo'] ?? data['ecoce_subtipo'] ?? data['subtipo'] ?? '',
                      'aprobado': (profileData['ecoce_estatus_aprobacion'] ?? data['ecoce_estatus_aprobacion'] ?? 1) == 1,
                      'createdAt': data['createdAt'] ?? Timestamp.fromDate(DateTime.now()),
                      'updatedAt': Timestamp.fromDate(DateTime.now()),
                    };
                    
                    // Recrear el índice limpio
                    await _profilesCollection.doc(userId).set(cleanIndex);
                    print('RECREADO índice limpio para: ${cleanIndex['nombre']} (${cleanIndex['folio']})');
                  }
                } catch (e) {
                  print('Error recreando índice para $userId: $e');
                  errors++;
                }
              } else {
                // Era un perfil completo sin path (duplicado puro)
                print('ELIMINADO perfil completo duplicado: ${data['ecoce_nombre'] ?? 'sin nombre'} (${data['ecoce_folio'] ?? 'sin folio'})');
              }
            }
          } else {
            // El usuario NO existe en ninguna subcolección
            if (data.containsKey('path') || data.containsKey('ecoce_nombre')) {
              // Es un documento huérfano, eliminarlo
              await _profilesCollection.doc(userId).delete();
              cleaned++;
              print('ELIMINADO documento huérfano: $userId');
            }
          }
        } catch (e) {
          print('Error procesando documento ${doc.id}: $e');
          errors++;
        }
      }
      
      print('\n=== RESUMEN DE LIMPIEZA ===');
      print('Usuarios válidos en subcolecciónes: ${validUsersInSubcollections.length}');
      print('Índices válidos mantenidos: $keptIndices');
      print('Documentos eliminados: $cleaned');
      print('Errores: $errors');
      print('========================\n');
      
      // Retornar resumen
      return {
        'usuarios_validos': validUsersInSubcollections.length,
        'indices_mantenidos': keptIndices,
        'documentos_eliminados': cleaned,
        'errores': errors,
      };
    } catch (e) {
      print('Error en limpieza: $e');
      rethrow;
    }
  }
  
  // Crear índices faltantes para usuarios aprobados
  Future<Map<String, dynamic>> createMissingIndexes() async {
    final results = {
      'created': 0,
      'existing': 0,
      'errors': 0,
    };

    try {
      // Obtener todos los usuarios aprobados de todas las subcolecciones
      final subcolections = [
        'ecoce_profiles/origen/centro_acopio',
        'ecoce_profiles/origen/planta_separacion',
        'ecoce_profiles/reciclador/usuarios',
        'ecoce_profiles/transformador/usuarios',
        'ecoce_profiles/transporte/usuarios',
        'ecoce_profiles/laboratorio/usuarios',
      ];

      for (final path in subcolections) {
        final collection = _firestore.collection(path);
        final querySnapshot = await collection
            .where('ecoce_estatus_aprobacion', isEqualTo: 1)
            .get();

        for (final doc in querySnapshot.docs) {
          try {
            final userData = doc.data();
            final folio = userData['ecoce_folio'] as String?;
            
            if (folio == null || folio.isEmpty) {
              print('Usuario sin folio: ${doc.id}');
              results['errors'] = (results['errors'] ?? 0) + 1;
              continue;
            }

            // Verificar si ya existe el índice
            final indexDoc = await _profilesCollection.doc(folio).get();
            
            if (indexDoc.exists) {
              results['existing'] = (results['existing'] ?? 0) + 1;
              continue;
            }

            // Determinar tipo de actor y subtipo
            String tipoActor = 'Desconocido';
            String? subtipo;
            
            if (path.contains('origen')) {
              tipoActor = 'O';
              subtipo = path.contains('centro_acopio') ? 'A' : 'P';
            } else if (path.contains('reciclador')) {
              tipoActor = 'R';
            } else if (path.contains('transformador')) {
              tipoActor = 'T';
            } else if (path.contains('transporte')) {
              tipoActor = 'V';
            } else if (path.contains('laboratorio')) {
              tipoActor = 'L';
            }

            // Crear el índice
            final indexData = {
              'id': doc.id,
              'path': '$path/${doc.id}',
              'folio': folio,
              'nombre': userData['ecoce_nombre'] ?? userData['nombre'] ?? 'Sin nombre',
              'email': userData['ecoce_correo_contacto'] ?? userData['email'] ?? '',
              'tipo_actor': tipoActor,
              'subtipo': subtipo,
              'aprobado': true,
              'fecha_aprobacion': userData['ecoce_fecha_aprobacion'] ?? Timestamp.fromDate(DateTime.now()),
              'createdAt': userData['createdAt'] ?? Timestamp.fromDate(DateTime.now()),
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            };

            await _profilesCollection.doc(folio).set(indexData);
            results['created'] = (results['created'] ?? 0) + 1;
            
            print('Índice creado para: $folio');
          } catch (e) {
            print('Error procesando usuario ${doc.id}: $e');
            results['errors'] = (results['errors'] ?? 0) + 1;
          }
        }
      }

      return results;
    } catch (e) {
      print('Error en createMissingIndexes: $e');
      rethrow;
    }
  }
}