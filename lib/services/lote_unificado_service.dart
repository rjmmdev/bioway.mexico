import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/services/firebase/auth_service.dart';
import 'package:app/services/firebase/firebase_manager.dart';
import 'package:app/services/firebase/firebase_storage_service.dart';
import 'package:app/models/lotes/lote_unificado_model.dart';

/// Servicio centralizado para gestión de lotes con ID único e inmutable
class LoteUnificadoService {
  final FirebaseManager _firebaseManager = FirebaseManager();
  final AuthService _authService = AuthService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  // Obtener Firestore de la instancia correcta
  FirebaseFirestore get _firestore {
    final app = _firebaseManager.currentApp;
    if (app == null) {
      return FirebaseFirestore.instance;
    }
    return FirebaseFirestore.instanceFor(app: app);
  }
  
  // Obtener el ID del usuario actual
  String? get _currentUserId => _authService.currentUser?.uid;
  
  // Colección principal de lotes
  static const String COLECCION_LOTES = 'lotes';
  
  // Nombres de las subcolecciones
  static const String DATOS_GENERALES = 'datos_generales';
  static const String PROCESO_ORIGEN = 'origen';
  static const String PROCESO_TRANSPORTE = 'transporte';
  static const String PROCESO_RECICLADOR = 'reciclador';
  static const String PROCESO_LABORATORIO = 'laboratorio';
  static const String PROCESO_TRANSFORMADOR = 'transformador';
  
  /// Crear un nuevo lote (solo desde origen)
  Future<String> crearLoteDesdeOrigen({
    required String tipoMaterial,
    required double pesoInicial,
    required String direccion,
    required String fuente,
    required String presentacion,
    required String tipoPoli,
    required String origenMaterial, // Pre/Post consumo
    required String condiciones,
    required String nombreOperador,
    String? firmaOperador,
    String? comentarios,
    required List<String> evidenciasFoto,
    required String folioUsuario,
  }) async {
    try {
      // Generar ID único para el lote
      final loteRef = _firestore.collection(COLECCION_LOTES).doc();
      final loteId = loteRef.id;
      
      // Generar código QR único
      final qrCode = 'LOTE-$tipoPoli-$loteId';
      
      // Crear batch para operaciones atómicas
      final batch = _firestore.batch();
      
      // 1. Crear datos generales
      batch.set(
        loteRef.collection(DATOS_GENERALES).doc('info'),
        {
          'id': loteId,
          'fecha_creacion': FieldValue.serverTimestamp(),
          'creado_por': _currentUserId,
          'material_tipo': tipoPoli,
          'material_presentacion': presentacion,
          'material_fuente': fuente,
          'peso': pesoInicial,
          'tipo_material': tipoMaterial,
          'peso_inicial': pesoInicial,
          'estado_actual': 'en_origen',
          'proceso_actual': PROCESO_ORIGEN,
          'historial_procesos': [PROCESO_ORIGEN],
          'qr_code': qrCode,
          'origen_nombre': nombreOperador,
          'origen_folio': folioUsuario,
          'origen_tipo': 'Origen',
        },
      );
      
      // 2. Crear datos del proceso origen
      final datosOrigen = {
        'usuario_id': _currentUserId,
        'usuario_folio': folioUsuario,
        'fecha_entrada': FieldValue.serverTimestamp(),
        'fecha_salida': null,
        'direccion': direccion,
        'fuente': fuente,
        'presentacion': presentacion,
        'tipo_poli': tipoPoli,
        'origen': origenMaterial,
        'peso_nace': pesoInicial,
        'condiciones': condiciones,
        'nombre_operador': nombreOperador,
        'firma_operador': firmaOperador,
        'comentarios': comentarios,
        'evidencias_foto': evidenciasFoto,
        'qr_code': qrCode,
      };
      
      // Debug: Verificar datos antes de guardar
      print('=== DATOS A GUARDAR EN ORIGEN ===');
      print('Firma: $firmaOperador');
      print('Evidencias: ${evidenciasFoto.length} fotos');
      print('================================');
      
      batch.set(
        loteRef.collection(PROCESO_ORIGEN).doc('data'),
        datosOrigen,
      );
      
      // Ejecutar batch
      await batch.commit();
      
      return loteId;
    } catch (e) {
      throw Exception('Error al crear lote: $e');
    }
  }
  
  /// Crear o actualizar datos de un proceso para manejar transferencias parciales
  Future<void> crearOActualizarProceso({
    required String loteId,
    required String proceso,
    required Map<String, dynamic> datos,
  }) async {
    try {
      final loteRef = _firestore.collection(COLECCION_LOTES).doc(loteId);
      
      // Verificar si el proceso ya existe
      final procesoDoc = await loteRef.collection(proceso).doc('data').get();
      
      if (procesoDoc.exists) {
        // Actualizar datos existentes
        await procesoDoc.reference.update(datos);
      } else {
        // Crear nuevo proceso
        await procesoDoc.reference.set({
          'fecha_entrada': FieldValue.serverTimestamp(),
          ...datos,
        });
      }
    } catch (e) {
      throw Exception('Error al crear/actualizar proceso: $e');
    }
  }

  /// Verificar si ambas partes han completado la transferencia
  Future<bool> verificarTransferenciaCompleta({
    required String loteId,
    required String procesoOrigen,
    required String procesoDestino,
  }) async {
    try {
      print('=== VERIFICANDO TRANSFERENCIA COMPLETA ===');
      print('Lote ID: $loteId');
      print('Proceso Origen: $procesoOrigen');
      print('Proceso Destino: $procesoDestino');
      
      final loteRef = _firestore.collection(COLECCION_LOTES).doc(loteId);
      
      // Para casos especiales donde el destino puede completar primero
      // (ej: el reciclador puede escanear y recibir antes que el transportista entregue)
      bool origenExiste = false;
      bool tieneEntrega = false;
      bool destinoExiste = false;
      bool tieneRecepcion = false;
      
      // Verificar proceso origen (transporte)
      final origenDoc = await loteRef.collection(procesoOrigen).doc('data').get();
      if (origenDoc.exists) {
        origenExiste = true;
        final datosOrigen = origenDoc.data()!;
        print('Datos Origen: $datosOrigen');
        
        // Verificar si el origen ha completado su parte
        tieneEntrega = datosOrigen['entrega_completada'] == true || 
                      datosOrigen['fecha_salida'] != null || 
                      datosOrigen['firma_entrega'] != null ||
                      datosOrigen['firma_conductor'] != null; // Para transportista
        print('Origen existe: $origenExiste, Tiene Entrega: $tieneEntrega');
      }
      
      // Verificar proceso destino (reciclador/transformador)
      final destinoDoc = await loteRef.collection(procesoDestino).doc('data').get();
      if (destinoDoc.exists) {
        destinoExiste = true;
        final datosDestino = destinoDoc.data()!;
        print('Datos Destino: $datosDestino');
        
        // Verificar si el destino ha completado su parte
        tieneRecepcion = datosDestino['recepcion_completada'] == true ||
                        datosDestino['firma_operador'] != null ||
                        datosDestino['firma_recepcion'] != null ||
                        datosDestino['peso_recibido'] != null ||
                        datosDestino['peso_entrada'] != null;
        print('Destino existe: $destinoExiste, Tiene Recepción: $tieneRecepcion');
      }
      
      // La transferencia está completa si:
      // 1. Ambos procesos existen Y ambos han completado su parte
      // 2. O si solo existe el destino y ha completado la recepción (caso de recepción anticipada)
      bool resultado = false;
      
      if (origenExiste && destinoExiste) {
        // Caso normal: ambos existen
        resultado = tieneEntrega && tieneRecepcion;
      } else if (!origenExiste && destinoExiste && tieneRecepcion) {
        // Caso especial: solo el destino ha completado (recepción anticipada)
        // En este caso, esperamos a que el origen complete
        resultado = false;
      } else if (origenExiste && !destinoExiste && tieneEntrega) {
        // Caso especial: solo el origen ha completado (entrega anticipada)
        // En este caso, esperamos a que el destino complete
        resultado = false;
      }
      
      print('Transferencia Completa: $resultado');
      print('=====================================');
      
      return resultado;
    } catch (e) {
      print('Error verificando transferencia: $e');
      return false;
    }
  }

  /// Transferir lote a otro proceso (actualizado para manejar transferencias parciales)
  Future<void> transferirLote({
    required String loteId,
    required String procesoDestino,
    required String usuarioDestinoFolio,
    required Map<String, dynamic> datosIniciales,
  }) async {
    try {
      print('=== INICIANDO TRANSFERIR LOTE ===');
      print('Lote ID: $loteId');
      print('Proceso Destino: $procesoDestino');
      print('Usuario Destino: $usuarioDestinoFolio');
      
      final batch = _firestore.batch();
      final loteRef = _firestore.collection(COLECCION_LOTES).doc(loteId);
      
      // 1. Obtener proceso actual
      final datosGeneralesDoc = await loteRef.collection(DATOS_GENERALES).doc('info').get();
      if (!datosGeneralesDoc.exists) {
        throw Exception('Lote no encontrado');
      }
      
      final datosGenerales = datosGeneralesDoc.data()!;
      final procesoActual = datosGenerales['proceso_actual'] as String;
      print('Proceso Actual: $procesoActual');
      
      // 2. Crear o actualizar el proceso destino
      await crearOActualizarProceso(
        loteId: loteId,
        proceso: procesoDestino,
        datos: {
          'usuario_id': _currentUserId,
          'usuario_folio': usuarioDestinoFolio,
          ...datosIniciales,
        },
      );
      
      // 3. Si es una transferencia completa, actualizar datos generales
      final esTransferenciaCompleta = await verificarTransferenciaCompleta(
        loteId: loteId,
        procesoOrigen: procesoActual,
        procesoDestino: procesoDestino,
      );
      
      if (esTransferenciaCompleta) {
        print('TRANSFERENCIA COMPLETA DETECTADA - Actualizando proceso_actual a: $procesoDestino');
        // Marcar salida del proceso actual
        batch.update(
          loteRef.collection(procesoActual).doc('data'),
          {'fecha_salida': FieldValue.serverTimestamp()},
        );
        
        // Asegurar que el proceso destino tenga fecha_entrada
        final destinoDoc = await loteRef.collection(procesoDestino).doc('data').get();
        if (destinoDoc.exists && destinoDoc.data()!['fecha_entrada'] == null) {
          batch.update(
            loteRef.collection(procesoDestino).doc('data'),
            {'fecha_entrada': FieldValue.serverTimestamp()},
          );
        }
        
        // Actualizar datos generales
        batch.update(
          loteRef.collection(DATOS_GENERALES).doc('info'),
          {
            'estado_actual': 'en_$procesoDestino',
            'proceso_actual': procesoDestino,
            'historial_procesos': FieldValue.arrayUnion([procesoDestino]),
          },
        );
        
        await batch.commit();
        print('BATCH COMMIT EXITOSO - Lote transferido a: $procesoDestino');
      } else {
        print('TRANSFERENCIA PARCIAL - Esperando que la otra parte complete');
      }
      print('=== FIN TRANSFERIR LOTE ===');
    } catch (e) {
      print('ERROR en transferirLote: $e');
      throw Exception('Error al transferir lote: $e');
    }
  }
  
  /// Actualizar datos de un proceso específico
  Future<void> actualizarDatosProceso({
    required String loteId,
    required String proceso,
    required Map<String, dynamic> datos,
  }) async {
    try {
      await _firestore
          .collection(COLECCION_LOTES)
          .doc(loteId)
          .collection(proceso)
          .doc('data')
          .update(datos);
    } catch (e) {
      throw Exception('Error al actualizar datos del proceso: $e');
    }
  }
  
  /// Actualizar datos del proceso transporte
  Future<void> actualizarProcesoTransporte({
    required String loteId,
    required Map<String, dynamic> datos,
    String? transporteId,
  }) async {
    try {
      // Si no se especifica transporteId, obtener el más reciente
      if (transporteId == null) {
        final transportesSnapshot = await _firestore
            .collection(COLECCION_LOTES)
            .doc(loteId)
            .collection(PROCESO_TRANSPORTE)
            .orderBy('fecha_entrada', descending: true)
            .limit(1)
            .get();
        
        if (transportesSnapshot.docs.isEmpty) {
          throw Exception('No se encontró proceso de transporte activo');
        }
        
        transporteId = transportesSnapshot.docs.first.id;
      }
      
      await _firestore
          .collection(COLECCION_LOTES)
          .doc(loteId)
          .collection(PROCESO_TRANSPORTE)
          .doc(transporteId)
          .update(datos);
    } catch (e) {
      print('Error al actualizar proceso transporte: $e');
      throw Exception('Error al actualizar proceso transporte: $e');
    }
  }
  
  /// Obtener el transporte activo de un lote
  Future<Map<String, dynamic>?> obtenerTransporteActivo(String loteId) async {
    try {
      final transportesSnapshot = await _firestore
          .collection(COLECCION_LOTES)
          .doc(loteId)
          .collection(PROCESO_TRANSPORTE)
          .orderBy('fecha_entrada', descending: true)
          .limit(1)
          .get();
      
      if (transportesSnapshot.docs.isEmpty) return null;
      
      final doc = transportesSnapshot.docs.first;
      return {
        'id': doc.id,
        ...doc.data(),
      };
    } catch (e) {
      print('Error al obtener transporte activo: $e');
      return null;
    }
  }
  
  /// Obtener todos los transportes de un lote
  Future<List<Map<String, dynamic>>> obtenerHistorialTransportes(String loteId) async {
    try {
      final transportesSnapshot = await _firestore
          .collection(COLECCION_LOTES)
          .doc(loteId)
          .collection(PROCESO_TRANSPORTE)
          .orderBy('fecha_entrada', descending: false)
          .get();
      
      return transportesSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error al obtener historial de transportes: $e');
      return [];
    }
  }
  
  /// Obtener lote completo por ID
  Future<LoteUnificadoModel?> obtenerLotePorId(String loteId) async {
    try {
      print('=== OBTENIENDO LOTE POR ID ===');
      print('Lote ID: $loteId');
      
      final loteRef = _firestore.collection(COLECCION_LOTES).doc(loteId);
      
      // Obtener todos los datos en paralelo
      final futures = await Future.wait([
        loteRef.collection(DATOS_GENERALES).doc('info').get(),
        loteRef.collection(PROCESO_ORIGEN).doc('data').get(),
        _firestore.collection(COLECCION_LOTES).doc(loteId).collection(PROCESO_TRANSPORTE).orderBy('fecha_entrada', descending: true).limit(1).get().then((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null),
        loteRef.collection(PROCESO_RECICLADOR).doc('data').get(),
        loteRef.collection(PROCESO_LABORATORIO).doc('data').get(),
        loteRef.collection(PROCESO_TRANSFORMADOR).doc('data').get(),
      ]);
      
      print('Resultados de las consultas:');
      print('- Datos generales existe: ${futures[0]?.exists ?? false}');
      print('- Origen existe: ${futures[1]?.exists ?? false}');
      print('- Transporte existe: ${futures[2] != null}');
      print('- Reciclador existe: ${futures[3]?.exists ?? false}');
      print('- Laboratorio existe: ${futures[4]?.exists ?? false}');
      print('- Transformador existe: ${futures[5]?.exists ?? false}');
      
      // Verificar que existan datos generales
      if (futures[0] == null || !futures[0]!.exists) {
        print('ERROR: No existen datos generales para el lote');
        return null;
      }
      
      if (futures[1] != null && futures[1]!.exists) {
        final origenData = futures[1]!.data() as Map<String, dynamic>;
        print('Datos de origen encontrados:');
        print('- firma_operador: ${origenData['firma_operador']}');
        print('- evidencias_foto: ${origenData['evidencias_foto']}');
      }
      
      return LoteUnificadoModel.fromFirestore(
        id: loteId,
        datosGenerales: futures[0]!,
        origen: (futures[1] != null && futures[1]!.exists) ? futures[1] : null,
        transporte: futures[2] != null ? futures[2] as DocumentSnapshot : null,
        reciclador: (futures[3] != null && futures[3]!.exists) ? futures[3] : null,
        laboratorio: (futures[4] != null && futures[4]!.exists) ? futures[4] : null,
        transformador: (futures[5] != null && futures[5]!.exists) ? futures[5] : null,
      );
    } catch (e) {
      print('ERROR al obtener lote: $e');
      throw Exception('Error al obtener lote: $e');
    }
  }
  
  /// Obtener lotes por proceso actual
  Stream<List<LoteUnificadoModel>> obtenerLotesPorProceso(String proceso) {
    return _firestore
        .collectionGroup(DATOS_GENERALES)
        .where('proceso_actual', isEqualTo: proceso)
        .orderBy('fecha_creacion', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final lotes = <LoteUnificadoModel>[];
      
      for (final doc in snapshot.docs) {
        // Obtener el ID del lote desde la ruta del documento
        final loteId = doc.reference.parent.parent!.id;
        final lote = await obtenerLotePorId(loteId);
        if (lote != null) {
          lotes.add(lote);
        }
      }
      
      return lotes;
    });
  }
  
  /// Obtener lotes por proceso actual filtrando por usuario
  Stream<List<LoteUnificadoModel>> obtenerMisLotesPorProceso(String proceso) {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);
    
    return _firestore
        .collectionGroup(DATOS_GENERALES)
        .where('proceso_actual', isEqualTo: proceso)
        .orderBy('fecha_creacion', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final lotes = <LoteUnificadoModel>[];
      
      for (final doc in snapshot.docs) {
        try {
          // Obtener el ID del lote desde la ruta del documento
          final loteId = doc.reference.parent.parent!.id;
          
          // Obtener el documento del proceso específico
          final procesoDoc = await _firestore
              .collection(COLECCION_LOTES)
              .doc(loteId)
              .collection(proceso)
              .doc('data')
              .get();
          
          if (procesoDoc.exists) {
            final procesoData = procesoDoc.data()!;
            // Verificar que el usuario sea el propietario en este proceso
            // Para reciclador, verificar primero reciclador_id, luego usuario_id
            String propietarioId = procesoData['usuario_id'];
            if (proceso == 'reciclador' && procesoData['reciclador_id'] != null) {
              propietarioId = procesoData['reciclador_id'];
            }
            
            if (propietarioId == userId) {
              final lote = await obtenerLotePorId(loteId);
              if (lote != null) {
                lotes.add(lote);
              }
            }
          }
        } catch (e) {
          print('Error procesando lote en obtenerMisLotesPorProceso: $e');
        }
      }
      
      return lotes;
    });
  }
  
  /// Obtener lotes creados por el usuario actual
  Stream<List<LoteUnificadoModel>> obtenerMisLotesCreados() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);
    
    return _firestore
        .collectionGroup(DATOS_GENERALES)
        .where('creado_por', isEqualTo: userId)
        .orderBy('fecha_creacion', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final lotes = <LoteUnificadoModel>[];
      
      for (final doc in snapshot.docs) {
        final loteId = doc.reference.parent.parent!.id;
        final lote = await obtenerLotePorId(loteId);
        if (lote != null) {
          lotes.add(lote);
        }
      }
      
      return lotes;
    });
  }
  
  /// Obtener lotes en los que ha participado el usuario actual
  Stream<List<LoteUnificadoModel>> obtenerLotesConMiParticipacion() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);
    
    // Esta consulta es más compleja y requeriría índices compuestos
    // Por ahora, obtener todos los lotes y filtrar localmente
    return _firestore
        .collection(COLECCION_LOTES)
        .snapshots()
        .asyncMap((snapshot) async {
      final lotes = <LoteUnificadoModel>[];
      
      for (final doc in snapshot.docs) {
        final lote = await obtenerLotePorId(doc.id);
        if (lote != null && lote.usuarioHaParticipado(userId)) {
          lotes.add(lote);
        }
      }
      
      return lotes;
    });
  }
  
  /// Buscar lote por código QR
  Future<LoteUnificadoModel?> buscarLotePorQR(String qrCode) async {
    try {
      // Buscar en datos generales
      final query = await _firestore
          .collectionGroup(DATOS_GENERALES)
          .where('qr_code', isEqualTo: qrCode)
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) {
        return null;
      }
      
      // Obtener el ID del lote desde la ruta
      final loteId = query.docs.first.reference.parent.parent!.id;
      return obtenerLotePorId(loteId);
    } catch (e) {
      throw Exception('Error al buscar lote por QR: $e');
    }
  }
  
  /// Obtener estadísticas de lotes para el repositorio
  Future<Map<String, dynamic>> obtenerEstadisticasLotes() async {
    try {
      final stats = <String, dynamic>{
        'total_lotes': 0,
        'por_proceso': {
          PROCESO_ORIGEN: 0,
          PROCESO_TRANSPORTE: 0,
          PROCESO_RECICLADOR: 0,
          PROCESO_LABORATORIO: 0,
          PROCESO_TRANSFORMADOR: 0,
        },
        'peso_total': 0.0,
        'por_material': <String, int>{},
      };
      
      final query = await _firestore.collectionGroup(DATOS_GENERALES).get();
      
      for (final doc in query.docs) {
        final data = doc.data();
        stats['total_lotes'] = (stats['total_lotes'] as int) + 1;
        
        // Por proceso
        final procesoActual = data['proceso_actual'] as String;
        stats['por_proceso'][procesoActual] = 
            (stats['por_proceso'][procesoActual] as int) + 1;
        
        // Peso total
        stats['peso_total'] = 
            (stats['peso_total'] as double) + (data['peso_inicial'] as double);
        
        // Por material
        final tipoMaterial = data['tipo_material'] as String;
        stats['por_material'][tipoMaterial] = 
            (stats['por_material'][tipoMaterial] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
  
  /// Procesar recepción de lote en laboratorio
  Future<void> procesarRecepcionLaboratorio({
    required String loteId,
    required double temperaturaRecepcion,
    required String observaciones,
    required List<Offset> firmaRecepcion,
    required List<String> evidenciasFoto,
  }) async {
    try {
      // Convertir firma a base64
      final firmaBase64 = await _convertirFirmaABase64(firmaRecepcion);
      
      // Subir firma a Storage
      final firmaUrl = await _storageService.uploadBase64Image(
        firmaBase64,
        'laboratorio_recepcion_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // Subir evidencias fotográficas
      final evidenciasUrls = <String>[];
      for (final foto in evidenciasFoto) {
        final url = await _storageService.uploadBase64Image(
          foto,
          'laboratorio_evidencia_${DateTime.now().millisecondsSinceEpoch}_${evidenciasUrls.length}',
        );
        if (url != null) {
          evidenciasUrls.add(url);
        }
      }
      
      // Actualizar el lote en el sistema unificado
      await transferirLote(
        loteId: loteId,
        procesoDestino: PROCESO_LABORATORIO,
        usuarioDestinoFolio: _currentUserId ?? '',
        datosIniciales: {
          'temperatura_recepcion': temperaturaRecepcion,
          'observaciones': observaciones,
          'firma_recepcion': firmaUrl,
          'evidencias_foto': evidenciasUrls,
          'fecha_recepcion': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      print('Error al procesar recepción en laboratorio: $e');
      throw Exception('Error al procesar recepción: $e');
    }
  }
  
  /// Convertir puntos de firma a imagen base64
  Future<String> _convertirFirmaABase64(List<Offset> points) async {
    // Esta es una implementación simplificada
    // En producción, deberías usar un canvas para dibujar la firma
    return 'data:image/png;base64,placeholder_signature';
  }
  
  /// Obtener todos los lotes del sistema
  Stream<List<LoteUnificadoModel>> obtenerTodosLosLotes() {
    debugPrint('=== OBTENIENDO TODOS LOS LOTES ===');
    
    // Primero intentar con la estructura nueva (datos_generales)
    return _firestore
        .collectionGroup(DATOS_GENERALES)
        .snapshots()
        .asyncMap((querySnapshot) async {
      debugPrint('Documentos encontrados en datos_generales: ${querySnapshot.docs.length}');
      
      if (querySnapshot.docs.isEmpty) {
        // Si no hay documentos en la estructura nueva, buscar en la colección principal
        debugPrint('No se encontraron lotes en datos_generales, buscando en colección principal...');
        
        final lotesSnapshot = await _firestore.collection(COLECCION_LOTES).get();
        debugPrint('Lotes encontrados en colección principal: ${lotesSnapshot.docs.length}');
        
        final lotes = <LoteUnificadoModel>[];
        
        for (final doc in lotesSnapshot.docs) {
          try {
            debugPrint('Procesando lote: ${doc.id}');
            final lote = await obtenerLotePorId(doc.id);
            if (lote != null) {
              lotes.add(lote);
            }
          } catch (e) {
            debugPrint('Error procesando lote ${doc.id}: $e');
          }
        }
        
        return lotes;
      }
      
      // Procesar documentos de datos_generales
      final lotes = <LoteUnificadoModel>[];
      
      for (final doc in querySnapshot.docs) {
        try {
          // El ID del lote es el ID del documento padre
          final pathSegments = doc.reference.path.split('/');
          final loteId = pathSegments[pathSegments.length - 3];
          debugPrint('Procesando lote desde datos_generales: $loteId');
          
          final lote = await obtenerLotePorId(loteId);
          if (lote != null) {
            lotes.add(lote);
          }
        } catch (e) {
          debugPrint('Error procesando lote: $e');
        }
      }
      
      return lotes;
    });
  }
  
  /// Buscar lotes con filtros
  Stream<List<LoteUnificadoModel>> buscarLotes({
    String? query,
    String? proceso,
    String? tipoMaterial,
  }) {
    // Construir query base
    Query<Map<String, dynamic>> baseQuery = _firestore.collectionGroup(DATOS_GENERALES);
    
    // Aplicar filtros
    if (proceso != null && proceso.isNotEmpty) {
      baseQuery = baseQuery.where('proceso_actual', isEqualTo: proceso);
    }
    
    if (tipoMaterial != null && tipoMaterial.isNotEmpty) {
      baseQuery = baseQuery.where('material_tipo', isEqualTo: tipoMaterial);
    }
    
    // Por ahora no ordenar para evitar problemas de índices
    
    return baseQuery.snapshots().asyncMap((querySnapshot) async {
      final lotes = <LoteUnificadoModel>[];
      
      for (final doc in querySnapshot.docs) {
        try {
          // El ID del lote es el ID del documento padre
          final pathSegments = doc.reference.path.split('/');
          final loteId = pathSegments[pathSegments.length - 3];
          
          final lote = await obtenerLotePorId(loteId);
          if (lote != null) {
            // Aplicar filtro de búsqueda si existe
            if (query == null || query.isEmpty) {
              lotes.add(lote);
            } else {
              final searchLower = query.toLowerCase();
              if (lote.id.toLowerCase().contains(searchLower) ||
                  lote.datosGenerales.tipoMaterial.toLowerCase().contains(searchLower) ||
                  lote.datosGenerales.qrCode.toLowerCase().contains(searchLower) ||
                  (lote.origen?.nombreOperador.toLowerCase().contains(searchLower) ?? false)) {
                lotes.add(lote);
              }
            }
          }
        } catch (e) {
          debugPrint('Error procesando lote: $e');
        }
      }
      
      return lotes;
    });
  }
  
  /// Método de depuración para imprimir el estado completo de un lote
  Future<void> depurarEstadoLote(String loteId) async {
    try {
      print('=== DEPURANDO ESTADO DEL LOTE $loteId ===');
      
      final loteRef = _firestore.collection(COLECCION_LOTES).doc(loteId);
      
      // Obtener datos generales
      final datosGeneralesDoc = await loteRef.collection(DATOS_GENERALES).doc('info').get();
      if (datosGeneralesDoc.exists) {
        print('DATOS GENERALES:');
        final datos = datosGeneralesDoc.data()!;
        print('- proceso_actual: ${datos['proceso_actual']}');
        print('- estado_actual: ${datos['estado_actual']}');
        print('- historial_procesos: ${datos['historial_procesos']}');
      } else {
        print('ERROR: No existen datos generales');
      }
      
      // Verificar cada proceso
      final procesos = ['origen', 'transporte', 'reciclador'];
      for (final proceso in procesos) {
        final procesoDoc = await loteRef.collection(proceso).doc('data').get();
        if (procesoDoc.exists) {
          print('\nPROCESO $proceso:');
          final datos = procesoDoc.data()!;
          print('- fecha_entrada: ${datos['fecha_entrada']}');
          print('- fecha_salida: ${datos['fecha_salida']}');
          print('- entrega_completada: ${datos['entrega_completada']}');
          print('- recepcion_completada: ${datos['recepcion_completada']}');
        }
      }
      
      print('=== FIN DEPURACIÓN ===');
    } catch (e) {
      print('Error en depuración: $e');
    }
  }
  
  /// Obtener todos los lotes de manera simple (para el repositorio)
  Stream<List<Map<String, dynamic>>> obtenerTodosLotesSimple() {
    debugPrint('=== OBTENIENDO LOTES SIMPLE ===');
    
    return _firestore
        .collection(COLECCION_LOTES)
        .snapshots()
        .map((snapshot) {
      debugPrint('Lotes encontrados: ${snapshot.docs.length}');
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        debugPrint('Lote ${doc.id}: $data');
        return data;
      }).toList();
    });
  }
}