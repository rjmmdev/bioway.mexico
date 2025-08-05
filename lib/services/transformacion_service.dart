import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lotes/transformacion_model.dart';
import '../models/lotes/sublote_model.dart';
import '../models/lotes/lote_unificado_model.dart';
import 'user_session_service.dart';
import 'firebase/auth_service.dart';
import 'firebase/firebase_manager.dart';
import 'muestra_laboratorio_service.dart';

/// Servicio para manejar las transformaciones de lotes en el reciclador
class TransformacionService {
  final UserSessionService _userSession = UserSessionService();
  final AuthService _authService = AuthService();
  final FirebaseManager _firebaseManager = FirebaseManager();
  
  // Obtener Firestore de la instancia correcta de Firebase
  FirebaseFirestore get _firestore {
    // Obtener la misma instancia que usa AuthService
    final app = _firebaseManager.currentApp;
    if (app != null) {
      return FirebaseFirestore.instanceFor(app: app);
    }
    return FirebaseFirestore.instance;
  }
  
  /// Crea una nueva transformación con múltiples lotes
  Future<String> crearTransformacion({
    required List<LoteUnificadoModel> lotes,
    required double mermaProceso,
    String? procesoAplicado,
    String? observaciones,
  }) async {
    print('[TransformacionService] Iniciando creación de transformación');
    print('[TransformacionService] Número de lotes: ${lotes.length}');
    print('[TransformacionService] Merma proceso: $mermaProceso');
    
    try {
      // Primero intentar obtener el perfil del usuario para asegurar que está cargado
      print('[TransformacionService] Cargando perfil del usuario...');
      final userProfile = await _userSession.getCurrentUserProfile(forceRefresh: false);
      
      if (userProfile == null) {
        print('[TransformacionService] No se pudo cargar el perfil, intentando forzar recarga...');
        final refreshedProfile = await _userSession.getCurrentUserProfile(forceRefresh: true);
        if (refreshedProfile == null) {
          throw Exception('No se pudo cargar el perfil del usuario. Por favor cierra sesión y vuelve a iniciar.');
        }
      }
      
      // Ahora obtener los datos del usuario
      var userData = _userSession.getUserData();
      if (userData == null || userData['uid'] == null) {
        throw Exception('Datos del usuario incompletos. Por favor cierra sesión y vuelve a iniciar.');
      }
      
      print('[TransformacionService] Usuario autenticado - UID: ${userData['uid']}');
      print('[TransformacionService] Usuario folio: ${userData['folio']}');
      
      // Usar el UID del userData que ya está validado
      final authUid = userData['uid'] as String;
      
      print('[TransformacionService] userData uid: ${userData['uid']}');
      print('[TransformacionService] userData folio: ${userData['folio']}');
      
      // Verificar que tenemos el uid
      if (userData['uid'] == null) {
        throw Exception('No se pudo obtener el ID del usuario');
      }
      
      // Validar que todos los lotes pueden ser transformados
      for (final lote in lotes) {
        if (!lote.puedeSerTransformado) {
          throw Exception('El lote ${lote.id} no puede ser transformado');
        }
      }
      
      // Calcular peso total y crear lotes de entrada
      double pesoTotal = 0;
      List<LoteEntrada> lotesEntrada = [];
      
      for (final lote in lotes) {
        final peso = lote.pesoActual;
        pesoTotal += peso;
        
        lotesEntrada.add(LoteEntrada(
          loteId: lote.id,
          peso: peso,
          porcentaje: 0, // Se calculará después
          tipoMaterial: lote.datosGenerales.tipoMaterial,
        ));
      }
      
      // Calcular porcentajes
      for (int i = 0; i < lotesEntrada.length; i++) {
        lotesEntrada[i] = LoteEntrada(
          loteId: lotesEntrada[i].loteId,
          peso: lotesEntrada[i].peso,
          porcentaje: (lotesEntrada[i].peso / pesoTotal) * 100,
          tipoMaterial: lotesEntrada[i].tipoMaterial,
        );
      }
      
      // Calcular composición de materiales y material predominante
      Map<String, double> composicionMateriales = {};
      for (final lote in lotesEntrada) {
        final material = lote.tipoMaterial;
        composicionMateriales[material] = (composicionMateriales[material] ?? 0) + lote.porcentaje;
      }
      
      // Determinar material predominante
      String materialPredominante = 'Mixto';
      double porcentajeMaximo = 0;
      
      // Si hay un solo material con 100%, usarlo
      if (composicionMateriales.length == 1) {
        materialPredominante = composicionMateriales.keys.first;
      } else {
        // Buscar el material con mayor porcentaje
        composicionMateriales.forEach((material, porcentaje) {
          if (porcentaje > porcentajeMaximo) {
            porcentajeMaximo = porcentaje;
            materialPredominante = material;
          }
        });
        
        // Si el material predominante tiene más del 70%, usarlo, sino "Mixto"
        if (porcentajeMaximo < 70) {
          // Construir descripción de composición mixta
          List<String> composicionTexto = [];
          composicionMateriales.forEach((material, porcentaje) {
            composicionTexto.add('$material ${porcentaje.toStringAsFixed(1)}%');
          });
          materialPredominante = composicionTexto.join(', ');
        }
      }
      
      // Crear el documento de transformación
      final transformacionRef = _firestore.collection('transformaciones').doc();
      final transformacionId = transformacionRef.id;
      
      final transformacion = TransformacionModel(
        id: transformacionId,
        tipo: 'agrupacion_reciclador',
        fechaInicio: DateTime.now(),
        estado: 'en_proceso',
        lotesEntrada: lotesEntrada,
        pesoTotalEntrada: pesoTotal,
        pesoDisponible: pesoTotal - mermaProceso,
        mermaProceso: mermaProceso,
        sublotesGenerados: [],
        documentosAsociados: {},
        usuarioId: authUid, // Usar siempre el UID de Firebase Auth
        usuarioFolio: userData['folio'] ?? '',
        procesoAplicado: procesoAplicado,
        observaciones: observaciones,
        materialPredominante: materialPredominante,
      );
      
      print('[TransformacionService] Transformación creada en memoria');
      print('[TransformacionService] Convirtiendo transformación a Map');
      
      final transformacionMap = transformacion.toMap();
      print('[TransformacionService] Map de transformación creado exitosamente');
      print('[TransformacionService] usuario_id en el mapa: ${transformacionMap['usuario_id']}');
      print('[TransformacionService] Tipo de usuario_id: ${transformacionMap['usuario_id'].runtimeType}');
      // Verificar con Firebase directamente
      final app = _firebaseManager.currentApp;
      final firebaseAuth = app != null ? FirebaseAuth.instanceFor(app: app) : FirebaseAuth.instance;
      final firebaseUser = firebaseAuth.currentUser;
      
      print('[TransformacionService] Firebase Auth directo UID: ${firebaseUser?.uid}');
      print('[TransformacionService] AuthService currentUser UID: ${_authService.currentUser?.uid}');
      print('[TransformacionService] ¿UIDs coinciden con Firebase directo?: ${transformacionMap['usuario_id'] == firebaseUser?.uid}');
      print('[TransformacionService] ¿UIDs coinciden con AuthService?: ${transformacionMap['usuario_id'] == _authService.currentUser?.uid}');
      
      // Verificar una vez más que el usuario_id está presente
      if (transformacionMap['usuario_id'] == null || transformacionMap['usuario_id'].toString().isEmpty) {
        throw Exception('usuario_id no está presente en los datos de la transformación');
      }
      
      // DEBUG: Imprimir todo el mapa para verificar estructura
      print('[TransformacionService] Mapa completo a guardar:');
      transformacionMap.forEach((key, value) {
        print('[TransformacionService]   $key: $value (${value.runtimeType})');
      });
      
      // Usar transacción para asegurar consistencia
      await _firestore.runTransaction((transaction) async {
        print('[TransformacionService] Iniciando transacción');
        print('[TransformacionService] Documento a crear: transformaciones/${transformacionRef.id}');
        // Crear la transformación
        transaction.set(transformacionRef, transformacionMap);
        
        // Marcar cada lote como consumido
        for (final lote in lotes) {
          final loteRef = _firestore
              .collection('lotes')
              .doc(lote.id)
              .collection('datos_generales')
              .doc('info');  // Usar 'info' - este es el documento correcto para datos_generales
              
          // Usar set con merge para crear el documento si no existe
          transaction.set(loteRef, {
            'consumido_en_transformacion': true,
            'transformacion_id': transformacionId,
            'fecha_consumido': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      });
      
      return transformacionId;
    } catch (e) {
      print('[TransformacionService] ERROR COMPLETO: $e');
      
      // Verificar si es un error de permisos específico
      if (e.toString().contains('permission-denied')) {
        print('[TransformacionService] Error de permisos detectado');
        print('[TransformacionService] Verifica que las reglas de Firebase permitan escribir en transformaciones');
        print('[TransformacionService] Usuario actual UID: ${_authService.currentUser?.uid ?? "No disponible"}');
        
        throw Exception('Error de permisos: No tienes permiso para crear transformaciones. '
                       'Por favor contacta al administrador para verificar las reglas de seguridad.');
      }
      
      throw Exception('Error al crear transformación: $e');
    }
  }
  
  /// Crea un sublote a partir de una transformación
  Future<String> crearSublote({
    required String transformacionId,
    required double peso,
  }) async {
    try {
      final userData = _userSession.getUserData();
      if (userData == null) throw Exception('Usuario no autenticado');
      
      // Obtener la transformación
      final transformacionDoc = await _firestore
          .collection('transformaciones')
          .doc(transformacionId)
          .get();
          
      if (!transformacionDoc.exists) {
        throw Exception('Transformación no encontrada');
      }
      
      final transformacion = TransformacionModel.fromFirestore(transformacionDoc);
      
      // Validar peso disponible
      if (peso > transformacion.pesoDisponible) {
        throw Exception('Peso solicitado ($peso kg) excede el peso disponible (${transformacion.pesoDisponible} kg)');
      }
      
      // Calcular composición del sublote
      final composicion = <String, ComposicionLote>{};
      
      for (final loteEntrada in transformacion.lotesEntrada) {
        final pesoAportado = peso * (loteEntrada.porcentaje / 100);
        
        composicion[loteEntrada.loteId] = ComposicionLote(
          pesoAportado: pesoAportado,
          porcentaje: loteEntrada.porcentaje,
          tipoMaterial: loteEntrada.tipoMaterial,
        );
      }
      
      // Crear el sublote
      final subloteRef = _firestore.collection('sublotes').doc();
      final subloteId = subloteRef.id;
      
      final sublote = SubloteModel(
        id: subloteId,
        tipo: 'derivado',
        transformacionOrigen: transformacionId,
        peso: peso,
        composicion: composicion,
        procesoActual: 'reciclador',
        qrCode: 'SUBLOTE-$subloteId',
        fechaCreacion: DateTime.now(),
        creadoPor: userData['uid'],
        creadoPorFolio: userData['folio'] ?? '',
        estadoActual: 'activo',
        historialProcesos: ['reciclador'],
      );
      
      // Obtener material predominante para guardarlo en el mapa
      final materialPredominante = sublote.materialPredominante;
      
      // Usar transacción para actualizar transformación y crear sublote
      await _firestore.runTransaction((transaction) async {
        // Crear el sublote con material predominante
        final subloteMap = sublote.toMap();
        subloteMap['material_predominante'] = materialPredominante;
        transaction.set(subloteRef, subloteMap);
        
        // Actualizar la transformación
        transaction.update(
          _firestore.collection('transformaciones').doc(transformacionId),
          {
            'peso_disponible': FieldValue.increment(-peso),
            'sublotes_generados': FieldValue.arrayUnion([subloteId]),
          },
        );
        
        // IMPORTANTE: Crear entrada en lotes para que el sublote sea visible
        // Crear estructura de lote unificado para el sublote
        final loteRef = _firestore.collection('lotes').doc(subloteId);
        
        // Crear datos generales
        transaction.set(
          loteRef.collection('datos_generales').doc('info'),
          {
            'id': subloteId,
            'qr_code': 'SUBLOTE-$subloteId',
            'tipo_lote': 'derivado',
            'tipo_material': materialPredominante,
            'peso_original': peso,
            'proceso_actual': 'reciclador',
            'creado_por': userData['uid'],
            'creado_por_folio': userData['folio'] ?? '',
            'fecha_creacion': FieldValue.serverTimestamp(),
            'activo': true,
            'consumido_en_transformacion': false,
            'transformacion_origen': transformacionId,
            'composicion': composicion.map((k, v) => MapEntry(k, {
              'peso_aportado': v.pesoAportado,
              'porcentaje': v.porcentaje,
              'tipo_material': v.tipoMaterial,
            })),
          },
        );
        
        // Crear proceso reciclador
        transaction.set(
          loteRef.collection('reciclador').doc('data'),
          {
            'usuario_id': userData['uid'],
            'usuario_folio': userData['folio'] ?? '',
            'fecha_entrada': FieldValue.serverTimestamp(),
            'peso_entrada': peso,
            'tipo_proceso': 'sublote_generado',
            'estado': 'activo',
            'transformacion_origen': transformacionId,
          },
        );
      });
      
      return subloteId;
    } catch (e) {
      throw Exception('Error al crear sublote: $e');
    }
  }
  
  /// Obtiene una transformación por ID
  Future<TransformacionModel?> obtenerTransformacion(String transformacionId) async {
    try {
      final doc = await _firestore
          .collection('transformaciones')
          .doc(transformacionId)
          .get();
          
      if (!doc.exists) return null;
      
      return TransformacionModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Error al obtener transformación: $e');
    }
  }
  
  /// Obtiene una transformación por ID (alias para compatibilidad)
  Future<TransformacionModel?> obtenerTransformacionPorId(String transformacionId) async {
    return obtenerTransformacion(transformacionId);
  }
  
  /// Stream de transformaciones del usuario actual
  /// NOTA: Si se usa la misma cuenta (email/password) en múltiples dispositivos,
  /// el UID será el mismo y se verán las mismas transformaciones
  Stream<List<TransformacionModel>> obtenerTransformacionesUsuario() {
    final userData = _userSession.getUserData();
    if (userData == null) return Stream.value([]);
    
    // Debug: Imprimir el UID del usuario actual
    print('=== DEBUG TRANSFORMACIONES ===');
    print('Usuario actual UID: ${userData['uid']}');
    print('Usuario actual Folio: ${userData['folio']}');
    print('Usuario actual Nombre: ${userData['nombre']}');
    
    return _firestore
        .collection('transformaciones')
        .where('usuario_id', isEqualTo: userData['uid'])
        .snapshots()
        .map((snapshot) {
          print('Transformaciones encontradas: ${snapshot.docs.length}');
          
          // Ordenar manualmente para evitar requerir índice
          final transformaciones = snapshot.docs
              .map((doc) {
                final trans = TransformacionModel.fromFirestore(doc);
                print('Transformación ID: ${trans.id}, Usuario: ${trans.usuarioId}, Folio: ${trans.usuarioFolio}');
                return trans;
              })
              // Filtrar transformaciones que deben ser eliminadas (peso=0 y con documentación)
              .where((transformacion) => !transformacion.debeSerEliminada)
              .toList();
          
          print('Transformaciones después de filtrar: ${transformaciones.length}');
          
          // Ordenar por fecha_inicio descendente
          transformaciones.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
          
          return transformaciones;
        });
  }
  
  /// Stream de transformaciones por folio del reciclador
  /// Esto permite ver todas las transformaciones de la misma organización
  Stream<List<TransformacionModel>> obtenerTransformacionesPorFolio() {
    final userData = _userSession.getUserData();
    if (userData == null) return Stream.value([]);
    
    final userFolio = userData['folio'] as String?;
    if (userFolio == null || userFolio.isEmpty) {
      // Si no hay folio, usar el método por usuario
      return obtenerTransformacionesUsuario();
    }
    
    // Extraer el prefijo del folio (R para reciclador)
    final folioPrefix = userFolio.substring(0, 1);
    
    // Solo aplicar filtro por folio para recicladores
    if (folioPrefix != 'R') {
      return obtenerTransformacionesUsuario();
    }
    
    print('=== TRANSFORMACIONES POR FOLIO ===');
    print('Buscando transformaciones con folio prefijo: $folioPrefix');
    
    return _firestore
        .collection('transformaciones')
        .where('usuario_folio', isGreaterThanOrEqualTo: folioPrefix)
        .where('usuario_folio', isLessThan: folioPrefix + '\uf8ff')
        .snapshots()
        .map((snapshot) {
          print('Transformaciones encontradas por folio: ${snapshot.docs.length}');
          
          final transformaciones = snapshot.docs
              .map((doc) => TransformacionModel.fromFirestore(doc))
              .where((transformacion) => !transformacion.debeSerEliminada)
              .toList();
          
          // Ordenar por fecha_inicio descendente
          transformaciones.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
          
          return transformaciones;
        });
  }
  
  /// Completa una transformación
  Future<void> completarTransformacion(String transformacionId) async {
    try {
      await _firestore
          .collection('transformaciones')
          .doc(transformacionId)
          .update({
        'estado': 'completada',
        'fecha_fin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al completar transformación: $e');
    }
  }
  
  /// Crea una muestra de laboratorio desde una transformación
  Future<String> crearMuestraLaboratorio({
    required String transformacionId,
    required double pesoMuestra,
  }) async {
    try {
      final userData = _userSession.getUserData();
      if (userData == null) throw Exception('Usuario no autenticado');
      
      // Obtener la transformación
      final transformacionDoc = await _firestore
          .collection('transformaciones')
          .doc(transformacionId)
          .get();
          
      if (!transformacionDoc.exists) {
        throw Exception('Transformación no encontrada');
      }
      
      final transformacion = TransformacionModel.fromFirestore(transformacionDoc);
      
      // Si se especifica un peso, validar que haya disponible
      if (pesoMuestra > 0 && pesoMuestra > transformacion.pesoDisponible) {
        throw Exception('Peso de muestra excede el peso disponible');
      }
      
      // Crear ID único para la muestra
      final muestraId = _firestore.collection('muestras_laboratorio').doc().id;
      final qrCode = 'MUESTRA-MEGALOTE-$transformacionId-$muestraId';
      
      // Si el peso es 0, solo registrar la muestra pendiente
      // El peso se actualizará cuando el laboratorio tome la muestra
      if (pesoMuestra == 0) {
        // Registrar muestra pendiente sin restar peso
        // No podemos usar FieldValue.serverTimestamp() dentro de arrayUnion
        // Usamos DateTime.now() en su lugar
        await _firestore
            .collection('transformaciones')
            .doc(transformacionId)
            .update({
          'muestras_laboratorio': FieldValue.arrayUnion([{
            'id': muestraId,
            'peso': 0,
            'estado': 'pendiente',
            'fecha_creacion': DateTime.now().toIso8601String(),
            'qr_code': qrCode,
            'creado_por': userData['uid'],
          }]),
        });
      } else {
        // Si hay peso, restar inmediatamente (comportamiento anterior)
        // No podemos usar FieldValue.serverTimestamp() dentro de arrayUnion
        // Usamos DateTime.now() en su lugar
        await _firestore
            .collection('transformaciones')
            .doc(transformacionId)
            .update({
          'peso_disponible': FieldValue.increment(-pesoMuestra),
          'muestras_laboratorio': FieldValue.arrayUnion([{
            'id': muestraId,
            'peso': pesoMuestra,
            'estado': 'completado',
            'fecha': DateTime.now().toIso8601String(),
            'qr_code': qrCode,
            'creado_por': userData['uid'],
          }]),
        });
      }
      
      return qrCode;
    } catch (e) {
      throw Exception('Error al crear muestra: $e');
    }
  }

  /// Registra una toma de muestra en un megalote
  /// NUEVO SISTEMA: Usa el servicio MuestraLaboratorioService para crear documentos independientes
  Future<void> registrarTomaMuestra({
    required String transformacionId,
    required double pesoMuestra,
    required String firmaOperador,
    required List<String> evidenciasFoto,
    required String operadorNombre,
    required String usuarioId,
    required String usuarioFolio,
  }) async {
    try {
      print('[TransformacionService] NUEVO SISTEMA - Registrando muestra independiente');
      
      // Importar el servicio de muestras independiente
      final MuestraLaboratorioService muestraService = MuestraLaboratorioService();
      
      // Crear muestra usando el nuevo servicio independiente
      final muestraId = await muestraService.crearMuestra(
        origenId: transformacionId,
        origenTipo: 'transformacion',
        pesoMuestra: pesoMuestra,
        firmaOperador: firmaOperador,
        evidenciasFoto: evidenciasFoto,
        qrCode: 'MUESTRA-MEGALOTE-$transformacionId',
      );
      
      print('[TransformacionService] Muestra creada con ID independiente: $muestraId');
      print('[TransformacionService] Peso muestra: $pesoMuestra kg');
      print('[TransformacionService] Transformación ID: $transformacionId');
      
    } catch (e) {
      print('[TransformacionService] Error al registrar muestra: $e');
      throw Exception('Error al registrar toma de muestra: $e');
    }
  }
  
  /// Actualiza la documentación de una transformación
  /// Ahora recibe Map<String, String> en lugar de Map<String, List<String>>
  Future<void> actualizarDocumentacion({
    required String transformacionId,
    required Map<String, String> documentos,
  }) async {
    try {
      print('[TransformacionService] Actualizando documentación de transformación: $transformacionId');
      
      // Verificar que el usuario actual es el dueño de la transformación
      final transformacion = await obtenerTransformacion(transformacionId);
      if (transformacion == null) {
        throw Exception('Transformación no encontrada');
      }
      
      final currentUser = _authService.currentUser;
      if (currentUser?.uid != transformacion.usuarioId) {
        throw Exception('No tienes permisos para actualizar esta transformación');
      }
      
      // Actualizar documentos en Firestore
      // Ahora guardamos strings individuales en lugar de arrays
      await _firestore.collection('transformaciones').doc(transformacionId).update({
        'documentos_asociados': documentos,
        'fecha_documentacion': FieldValue.serverTimestamp(),
        'documentacion_completada': true,
      });
      
      print('[TransformacionService] Documentación actualizada exitosamente');
    } catch (e) {
      print('[TransformacionService] Error al actualizar documentación: $e');
      throw Exception('Error al actualizar documentación: $e');
    }
  }
  
  /// Actualiza el estado de una transformación
  Future<void> actualizarEstadoTransformacion({
    required String transformacionId,
    required String nuevoEstado,
  }) async {
    try {
      print('[TransformacionService] Actualizando estado de transformación: $transformacionId a $nuevoEstado');
      
      // Verificar que el usuario actual es el dueño de la transformación
      final transformacion = await obtenerTransformacion(transformacionId);
      if (transformacion == null) {
        throw Exception('Transformación no encontrada');
      }
      
      final currentUser = _authService.currentUser;
      if (currentUser?.uid != transformacion.usuarioId) {
        throw Exception('No tienes permisos para actualizar esta transformación');
      }
      
      // Actualizar estado
      final Map<String, dynamic> updates = {
        'estado': nuevoEstado,
      };
      
      // Si el estado es completado, agregar fecha de fin
      if (nuevoEstado == 'completado') {
        updates['fecha_fin'] = FieldValue.serverTimestamp();
      }
      
      await _firestore.collection('transformaciones').doc(transformacionId).update(updates);
      
      print('[TransformacionService] Estado actualizado exitosamente');
    } catch (e) {
      print('[TransformacionService] Error al actualizar estado: $e');
      throw Exception('Error al actualizar estado: $e');
    }
  }
}