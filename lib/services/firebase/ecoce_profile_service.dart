import 'package:flutter/foundation.dart';
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
  
  // Obtener la ruta completa del perfil
  String _getProfilePath(String tipoActor, String? subtipo, String userId) {
    // Mapear tipos de actor a sus rutas
    switch (tipoActor) {
      case 'O': // Origen (Acopiador o Planta de Separación)
      case 'A': // A veces viene como A
        if (subtipo == 'A') {
          return 'ecoce_profiles/origen/centro_acopio/$userId';
        } else if (subtipo == 'P') {
          return 'ecoce_profiles/origen/planta_separacion/$userId';
        }
        return 'ecoce_profiles/origen/usuarios/$userId';
      case 'R': // Reciclador
        return 'ecoce_profiles/reciclador/usuarios/$userId';
      case 'T': // Transformador
        return 'ecoce_profiles/transformador/usuarios/$userId';
      case 'V': // Transporte/Vehicular
        return 'ecoce_profiles/transporte/usuarios/$userId';
      case 'L': // Laboratorio
        return 'ecoce_profiles/laboratorio/usuarios/$userId';
      case 'M': // Maestro
        return 'ecoce_profiles/maestro/usuarios/$userId';
      default:
        return 'ecoce_profiles/otros/usuarios/$userId';
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

  // Generar folio secuencial según el subtipo para usuarios origen
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
      // Buscar en TODAS las subcolecciones para obtener el último folio
      List<String> allFolios = [];
      
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
      
      // Buscar en cada subcolección folios que empiecen con el prefijo
      for (final subcollection in subcollections) {
        try {
          final query = await _profilesCollection
              .doc(subcollection.split('/')[0])
              .collection(subcollection.split('/')[1])
              .where('ecoce_folio', isGreaterThanOrEqualTo: prefix)
              .where('ecoce_folio', isLessThan: '${prefix}z')
              .orderBy('ecoce_folio', descending: true)
              .limit(5) // Obtener los últimos 5 para asegurar
              .get();
          
          for (final doc in query.docs) {
            final data = doc.data();
            final folio = data['ecoce_folio'] as String?;
            if (folio != null && folio.startsWith(prefix)) {
              allFolios.add(folio);
            }
          }
        } catch (e) {
          // Continuar con la siguiente subcolección si hay error
          continue;
        }
      }
      
      // También buscar en solicitudes aprobadas para evitar duplicados
      // NOTA: Simplificamos la consulta para evitar requerir índices compuestos
      try {
        final solicitudesQuery = await _solicitudesCollection
            .where('estado', isEqualTo: 'aprobada')
            .get();
        
        // Filtrar localmente los folios que coinciden con el prefijo
        for (final doc in solicitudesQuery.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final folio = data['folio_asignado'] as String?;
            if (folio != null && folio.startsWith(prefix)) {
              allFolios.add(folio);
            }
          }
        }
      } catch (e) {
        // Ignorar error si la colección no existe
        debugPrint('Error buscando folios en solicitudes: $e');
      }
      
      // Encontrar el número más alto de folios con formato correcto
      int maxNumber = 0;
      final validFolios = <String>[];
      
      for (final folio in allFolios) {
        // Verificar que el folio tenga el formato correcto: Letra + 7 dígitos
        if (folio.length == 8 && folio.startsWith(prefix)) {
          // Extraer solo los números después del prefijo
          final numberPart = folio.substring(1);
          final number = int.tryParse(numberPart);
          
          // Solo considerar folios con formato válido (7 dígitos numéricos)
          if (number != null && numberPart.length == 7) {
            validFolios.add(folio);
            if (number > maxNumber) {
              maxNumber = number;
            }
          }
        }
      }
      
      // El próximo número es el máximo + 1
      final nextNumber = maxNumber + 1;
      final newFolio = '$prefix${nextNumber.toString().padLeft(7, '0')}';
      
      debugPrint('Folios encontrados: ${allFolios.join(', ')}');
      debugPrint('Folios válidos: ${validFolios.join(', ')}');
      debugPrint('Número más alto: $maxNumber');
      debugPrint('Generando nuevo folio: $newFolio');
      
      return newFolio;
    } catch (e) {
      // Si hay error general, empezar desde 1
      debugPrint('Error generando folio secuencial: $e');
      debugPrint('Generando folio inicial: ${prefix}0000001');
      return '${prefix}0000001';
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
    Map<String, Map<String, dynamic>>? documentosInfo,
    String? usuarioId, // ID del usuario ya creado en Auth
  }) async {
    try {
      // Inicializar Firebase para ECOCE si no está inicializado
      if (_firebaseManager.currentApp == null) {
        await _firebaseManager.initializeForPlatform(FirebasePlatform.ecoce);
      }

      // Intentar verificar si el email ya existe en solicitudes pendientes
      try {
        final existingSolicitud = await _solicitudesCollection
            .where('email', isEqualTo: email)
            .where('estado', isEqualTo: 'pendiente')
            .limit(1)
            .get();
            
        if (existingSolicitud.docs.isNotEmpty) {
          throw 'Ya existe una solicitud pendiente con este correo electrónico';
        }
      } catch (e) {
        // Si falla la verificación por permisos, continuar de todos modos
        // Esto puede ocurrir cuando el usuario no está autenticado
        debugPrint('No se pudo verificar duplicados de email: $e');
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
      debugPrint('Documentos recibidos en createAccountRequest:');
      documentos?.forEach((key, value) {
        debugPrint('  $key: ${value != null ? 'URL presente (${value.substring(0, 50)}...)' : 'null'}');
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
          'ecoce_folio': 'PENDIENTE', // NO se asigna folio hasta la aprobación
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
        'documentos_pendientes': documentosInfo ?? {}, // Información de documentos pendientes
        'estado': 'pendiente',
        'fecha_solicitud': FieldValue.serverTimestamp(),
        'fecha_revision': null,
        'revisado_por': null,
        'comentarios_revision': null,
      };
      
      // Debug: verificar que los documentos estén en solicitudData
      debugPrint('Documentos en solicitudData:');
      final datosPerfilDebug = solicitudData['datos_perfil'] as Map<String, dynamic>;
      ['ecoce_const_sit_fis', 'ecoce_comp_domicilio', 'ecoce_banco_caratula', 'ecoce_ine',
       'ecoce_opinion_cumplimiento', 'ecoce_ramir', 'ecoce_plan_manejo', 'ecoce_licencia_ambiental'].forEach((field) {
        debugPrint('  $field: ${datosPerfilDebug[field] != null ? 'URL presente' : 'null'}');
      });

      // El usuario ya fue creado en Auth antes de llamar este método
      // Solo necesitamos guardar el ID en la solicitud
      if (usuarioId != null) {
        solicitudData['usuario_creado_id'] = usuarioId;
        solicitudData['auth_creado'] = true;
        debugPrint('✅ Usuario ya creado en Auth con ID: $usuarioId');
      } else {
        // Si por alguna razón no se pasó el usuarioId, marcar como no creado
        solicitudData['auth_creado'] = false;
        debugPrint('⚠️ ADVERTENCIA: No se recibió usuarioId');
      }
      
      // Guardar solicitud en Firestore (con o sin usuario Auth creado)
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
  
  // Actualizar solicitud con el ID del usuario (para solicitudes antiguas)
  Future<void> updateSolicitudWithUserId({
    required String solicitudId,
    required String userId,
  }) async {
    try {
      await _solicitudesCollection.doc(solicitudId).update({
        'usuario_creado_id': userId,
        'auth_creado': true,
        'actualizado_manualmente': true,
        'fecha_actualizacion_manual': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Solicitud actualizada con usuario_creado_id: $userId');
    } catch (e) {
      debugPrint('❌ Error actualizando solicitud: $e');
      rethrow;
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
  
  // Aprobar solicitud (el usuario ya existe en Auth)
  Future<void> approveSolicitud({
    required String solicitudId,
    required String approvedById,
    String? comments,
  }) async {
    String? userId;
    String? folio;
    Map<String, dynamic>? datosPerfil;
    
    try {
      // Obtener datos de la solicitud
      final solicitudDoc = await _solicitudesCollection.doc(solicitudId).get();
      if (!solicitudDoc.exists) {
        throw Exception('Solicitud no encontrada');
      }
      
      final solicitudData = solicitudDoc.data() as Map<String, dynamic>;
      datosPerfil = solicitudData['datos_perfil'] as Map<String, dynamic>;
      
      // Verificar si el usuario ya fue creado en Auth
      final authCreado = solicitudData['auth_creado'] ?? false;
      userId = solicitudData['usuario_creado_id'] as String?;
      
      // Si no hay usuario_creado_id pero auth_creado es true, intentar buscar por email
      if (userId == null && authCreado) {
        final email = solicitudData['email'] as String?;
        if (email != null) {
          try {
            final userByEmail = await _auth.fetchSignInMethodsForEmail(email);
            if (userByEmail.isNotEmpty) {
              // El usuario existe, pero necesitamos su ID
              // En este caso, pediremos al maestro que proporcione el ID manualmente
              debugPrint('⚠️ Usuario existe en Auth pero no se guardó el ID. Email: $email');
              throw Exception('El usuario existe en Auth pero no se guardó su ID. Por favor, obtenga el UID del usuario desde Firebase Console > Authentication y actualice manualmente la solicitud.');
            }
          } catch (e) {
            debugPrint('Error verificando usuario por email: $e');
          }
        }
      }
      
      // Si no hay usuario_creado_id, verificar si podemos encontrar el usuario por otros medios
      if (userId == null) {
        // Para solicitudes antiguas, podríamos no tener el ID guardado
        final email = solicitudData['email'] as String?;
        if (email != null) {
          debugPrint('🔍 Intentando verificar si el usuario $email existe en Auth...');
          try {
            // Verificar si el email tiene métodos de inicio de sesión
            final methods = await _auth.fetchSignInMethodsForEmail(email);
            if (methods.isNotEmpty) {
              // El usuario existe pero no tenemos su ID
              debugPrint('✅ Usuario encontrado en Auth pero sin ID guardado');
              debugPrint('📋 Por favor, actualice manualmente el campo usuario_creado_id en la solicitud');
              throw Exception(
                'Usuario encontrado en Auth pero sin ID en la solicitud.\n\n' +
                'Para solucionarlo:\n' +
                '1. Vaya a Firebase Console > Authentication\n' +
                '2. Busque el usuario con email: $email\n' +
                '3. Copie su UID\n' +
                '4. En Firestore, actualice esta solicitud agregando:\n' +
                '   usuario_creado_id: [UID copiado]\n' +
                '   auth_creado: true'
              );
            } else {
              debugPrint('❌ Usuario NO encontrado en Auth');
              throw Exception('El usuario no fue creado en Auth durante el registro. No se puede aprobar.');
            }
          } catch (e) {
            if (e.toString().contains('Usuario encontrado')) {
              rethrow;
            }
            debugPrint('Error verificando usuario: $e');
            throw Exception('No se pudo verificar si el usuario existe en Auth. Error: $e');
          }
        } else {
          throw Exception('No se encontró email en la solicitud.');
        }
      }
      
      // Generar folio según tipo y subtipo
      final tipoActor = datosPerfil!['ecoce_tipo_actor'] as String?;
      final subtipo = datosPerfil['ecoce_subtipo'] as String?;
      if (tipoActor == null) {
        throw Exception('Tipo de actor no especificado en la solicitud');
      }
      folio = await _generateFolio(tipoActor, subtipo);
      
      // IMPORTANTE: Actualizar la solicitud - ahora es seguro porque el maestro
      // está autenticado y tiene permisos, no hay cambio de sesión
      await _solicitudesCollection.doc(solicitudId).update({
        'estado': 'aprobada',
        'fecha_revision': FieldValue.serverTimestamp(),
        'aprobado_por': approvedById,
        'comentarios_revision': comments,
        'folio_asignado': folio,
        'procesando': false,
      });
      
      // Actualizar datos del perfil con el folio real
      datosPerfil!['ecoce_folio'] = folio;
      datosPerfil['id'] = userId;
      datosPerfil['ecoce_estatus_aprobacion'] = 1;
      datosPerfil['ecoce_fecha_aprobacion'] = Timestamp.fromDate(DateTime.now());
      datosPerfil['ecoce_aprobado_por'] = approvedById;
      datosPerfil['ecoce_comentarios_revision'] = comments;
      datosPerfil['createdAt'] = Timestamp.fromDate(DateTime.now());
      datosPerfil['updatedAt'] = Timestamp.fromDate(DateTime.now());
      
      // IMPORTANTE: Agregar el ID del usuario a la solicitud en datos_perfil
      // para que las reglas puedan verificar la relación
      datosPerfil['usuario_creado_id'] = userId;
      
      // Debug: verificar documentos antes de guardar
      debugPrint('📋 Documentos en perfil aprobado:');
      ['ecoce_const_sit_fis', 'ecoce_comp_domicilio', 'ecoce_banco_caratula', 'ecoce_ine',
       'ecoce_opinion_cumplimiento', 'ecoce_ramir', 'ecoce_plan_manejo', 'ecoce_licencia_ambiental'].forEach((field) {
        debugPrint('  $field: ${datosPerfil!.containsKey(field) && datosPerfil[field] != null ? 'URL presente' : 'null'}');
      });
      
      // Obtener la subcolección según el tipo
      final subcollection = _getProfileSubcollection(tipoActor, subtipo);
      
      // Guardar en la subcolección correspondiente
      await subcollection.doc(userId).set(datosPerfil!);
      
      // NO eliminar la solicitud inmediatamente - mantenerla como registro histórico
      // Esto también evita problemas de permisos
      // Si necesitas ocultarla, usar el campo 'estado' = 'aprobada' como filtro
      
      // Registrar la aprobación en el audit log
      await _firestore.collection('audit_logs').add({
        'action': 'account_approved',
        'solicitudId': solicitudId,
        'userId': userId,
        'userEmail': solicitudData['email'],
        'userFolio': folio,
        'userName': datosPerfil!['ecoce_nombre'],
        'approvedBy': approvedById,
        'approvedAt': FieldValue.serverTimestamp(),
        'comments': comments,
      });
      
      debugPrint('Usuario aprobado exitosamente: ${datosPerfil['ecoce_nombre'] ?? 'Sin nombre'} con folio: $folio');
    } catch (e) {
      // Si hay error, intentar revertir los cambios
      try {
        if (folio != null) {
          // Revertir la actualización de la solicitud
          await _solicitudesCollection.doc(solicitudId).update({
            'estado': 'pendiente',
            'fecha_revision': null,
            'aprobado_por': null,
            'comentarios_revision': null,
            'folio_asignado': null,
            'procesando': false,
          });
        }
        
        // Si se creó el índice, eliminarlo
        if (userId != null) {
          await _profilesCollection.doc(userId).delete();
          
          // También intentar eliminar el perfil si se creó
          if (datosPerfil != null) {
            final tipoActor = datosPerfil['ecoce_tipo_actor'] as String?;
            final subtipo = datosPerfil['ecoce_subtipo'] as String?;
            if (tipoActor != null) {
              final subcollection = _getProfileSubcollection(tipoActor, subtipo);
              await subcollection.doc(userId).delete();
            }
          }
        }
      } catch (cleanupError) {
        debugPrint('Error al revertir cambios: $cleanupError');
      }
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
        
        // Verificar si se creó usuario en Auth
        final authCreado = solicitudData['auth_creado'] ?? false;
        final userId = solicitudData['usuario_creado_id'] as String?;
        
        // Si se creó usuario en Auth, marcarlo para eliminación
        if (authCreado && userId != null) {
          // Marcar el usuario para eliminación (Cloud Function lo eliminará)
          await _firestore.collection('users_pending_deletion').doc(userId).set({
            'userId': userId,
            'userEmail': solicitudData['email'],
            'requestedBy': rejectedById,
            'requestedAt': FieldValue.serverTimestamp(),
            'status': 'pending',
            'reason': 'solicitud_rechazada',
            'rejectionReason': reason,
          });
          
          debugPrint('⚠️ Usuario $userId marcado para eliminación de Auth');
        }
        
        // Limpiar archivos de Storage si existen
        if (datosPerfil != null) {
          await _deleteStorageFiles(solicitudId, datosPerfil);
        }
        
        // Eliminar el documento de la solicitud
        await _solicitudesCollection.doc(solicitudId).delete();
        
        // Registrar en audit log
        await _firestore.collection('audit_logs').add({
          'action': 'account_rejected',
          'solicitudId': solicitudId,
          'userEmail': solicitudData['email'],
          'userName': datosPerfil?['ecoce_nombre'] ?? 'Sin nombre',
          'rejectedBy': rejectedById,
          'rejectedAt': FieldValue.serverTimestamp(),
          'reason': reason,
        });
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

  // Obtener perfil por ID (busca directamente en subcarpetas)
  Future<EcoceProfileModel?> getProfile(String userId) async {
    try {
      // Primero verificar si es un usuario maestro
      final maestroDoc = await _firestore
          .collection('maestros')
          .doc(userId)
          .get();
          
      if (maestroDoc.exists) {
        final maestroData = maestroDoc.data()!;
        // Crear perfil maestro con estructura simplificada
        return EcoceProfileModel(
          id: userId,
          ecoceTipoActor: 'M',
          ecoceNombre: maestroData['nombre'] ?? 'Administrador ECOCE',
          ecoceCorreoContacto: maestroData['email'] ?? '',
          ecoceFolio: 'M0000001',
          ecoceRfc: 'XAXX010101000',
          ecoceNombreContacto: maestroData['nombre'] ?? 'Administrador',
          ecoceTelContacto: '5551234567',
          ecoceTelEmpresa: '5551234567',
          ecoceCalle: 'Sistema ECOCE',
          ecoceNumExt: 'N/A',
          ecoceCp: '00000',
          ecoceEstado: 'CDMX',
          ecoceMunicipio: 'Sistema',
          ecoceColonia: 'Sistema',
          ecoceListaMateriales: [],
          ecoceEstatusAprobacion: 1,
          ecoceFechaReg: maestroData['created_at']?.toDate() ?? DateTime.now(),
          createdAt: maestroData['created_at']?.toDate() ?? DateTime.now(),
          updatedAt: maestroData['updated_at']?.toDate() ?? DateTime.now(),
        );
      }
      
      // Buscar directamente en subcarpetas
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
      
      // Si no se encontró en ninguna parte, el usuario no existe
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
      final tipoActor = profileData['ecoce_tipo_actor'] as String?;
      final subtipo = profileData['ecoce_subtipo'] as String?;
      
      if (tipoActor == null) {
        throw Exception('Tipo de actor no encontrado en el perfil');
      }
      
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
      debugPrint('🗑️ Iniciando eliminación de usuario: $userId');
      debugPrint('🔑 Eliminado por: $deletedBy');
      
      // Verificar que el usuario que elimina es maestro
      final maestroDoc = await _firestore.collection('maestros').doc(deletedBy).get();
      if (!maestroDoc.exists) {
        throw Exception('El usuario que intenta eliminar no está configurado como maestro');
      }
      debugPrint('✅ Usuario maestro verificado');
      
      // 1. Buscar el perfil - primero en caché, luego en Firestore
      Map<String, dynamic>? profileData;
      String? profilePath;
      
      // Verificar caché primero
      if (_userPathCache.containsKey(userId)) {
        profilePath = _userPathCache[userId];
        final doc = await _firestore.doc(profilePath!).get();
        if (doc.exists) {
          profileData = doc.data() as Map<String, dynamic>;
        } else {
          // Si no existe, limpiar del caché
          _userPathCache.remove(userId);
          profilePath = null;
        }
      }
      
      // Si no se encontró en caché, buscar en todas las rutas
      if (profileData == null) {
        debugPrint('📂 Perfil no encontrado en caché, buscando en todas las rutas...');
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
            profileData = results[i].data() as Map<String, dynamic>;
            profilePath = possiblePaths[i];
            debugPrint('✅ Perfil encontrado en: $profilePath');
            // Guardar en caché para futuras búsquedas
            _userPathCache[userId] = profilePath;
            break;
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
      
      // Marcar para eliminación en Auth - LA CLOUD FUNCTION SE ACTIVARÁ AUTOMÁTICAMENTE
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
      
      // 5. Intentar eliminar el usuario de Auth directamente (si es posible)
      try {
        // NOTA: Esto solo funcionará si usamos Admin SDK
        // En producción, la Cloud Function se encargará de esto
        await _auth.currentUser?.delete();
      } catch (e) {
        // Ignorar error - la Cloud Function se encargará
        debugPrint('No se pudo eliminar directamente de Auth (esperado): $e');
      }
      
      // El usuario será eliminado de Auth por la Cloud Function
      // Mientras tanto, no podrá acceder porque no tiene perfil
      
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
      debugPrint('Error procesando eliminaciones pendientes: $e');
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
      debugPrint('Eliminados ${oldRecords.docs.length} registros antiguos de users_pending_deletion');
    } catch (e) {
      debugPrint('Error limpiando registros antiguos: $e');
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
      
      // Contar usuarios aprobados directamente desde subcarpetas
      int approved = 0;
      
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
          final query = await _profilesCollection
              .doc(subcollection.split('/')[0])
              .collection(subcollection.split('/')[1])
              .where('ecoce_estatus_aprobacion', isEqualTo: 1)
              .get();
          approved += query.docs.length;
        } catch (e) {
          continue;
        }
      }
      
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
  
  // Alias method for getProfile to match the expected name
  Future<EcoceProfileModel?> getProfileByUserId(String userId) async {
    return getProfile(userId);
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
      List<EcoceProfileModel> profiles = [];
      
      final subcollections = [
        'origen/centro_acopio',
        'origen/planta_separacion',
        'reciclador/usuarios',
        'transformador/usuarios',
        'transporte/usuarios',
        'laboratorio/usuarios',
        'maestro/usuarios',
      ];
      
      // Buscar en cada subcolección usuarios aprobados
      for (final subcollection in subcollections) {
        try {
          final query = await _profilesCollection
              .doc(subcollection.split('/')[0])
              .collection(subcollection.split('/')[1])
              .where('ecoce_estatus_aprobacion', isEqualTo: 1)
              .orderBy('ecoce_fecha_aprobacion', descending: true)
              .get();
          
          for (final doc in query.docs) {
            profiles.add(EcoceProfileModel.fromFirestore(doc));
          }
        } catch (e) {
          continue;
        }
      }
      
      // Ordenar todos los perfiles por fecha de aprobación
      profiles.sort((a, b) => (b.ecoceFechaAprobacion ?? DateTime.now())
          .compareTo(a.ecoceFechaAprobacion ?? DateTime.now()));
      
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
      
      // Buscar en cada subcolección sin filtrar por estado
      for (final subcollection in subcollections) {
        try {
          final query = await _profilesCollection
              .doc(subcollection.split('/')[0])
              .collection(subcollection.split('/')[1])
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
  
  // Obtener perfil por folio (busca directamente en subcarpetas)
  Future<EcoceProfileModel?> getProfileByFolio(String folio) async {
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
}
