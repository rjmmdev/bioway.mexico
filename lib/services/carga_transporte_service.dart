import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/models/transporte/carga_transporte_model.dart';
import 'package:app/models/transporte/entrega_transporte_model.dart';
import 'package:app/services/firebase/firebase_manager.dart';
import 'package:app/services/firebase/auth_service.dart';
import 'package:app/services/firebase/ecoce_profile_service.dart';
import 'package:app/services/lote_unificado_service.dart';

/// Servicio para gestionar cargas y entregas del transportista
class CargaTransporteService {
  final FirebaseManager _firebaseManager = FirebaseManager();
  final AuthService _authService = AuthService();
  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  
  FirebaseFirestore get _firestore {
    final app = _firebaseManager.currentApp;
    if (app == null) {
      return FirebaseFirestore.instance;
    }
    return FirebaseFirestore.instanceFor(app: app);
  }
  
  String? get _currentUserId => _authService.currentUser?.uid;
  
  /// Verificar si un lote ya está en una carga activa
  Future<bool> loteEstaEnCargaActiva(String loteId) async {
    try {
      // Buscar cargas activas que contengan este lote
      final cargasSnapshot = await _firestore
          .collection('cargas_transporte')
          .where('transportista_id', isEqualTo: _currentUserId)
          .where('estado_carga', whereIn: ['en_transporte', 'entregada_parcial'])
          .where('lotes_ids', arrayContains: loteId)
          .get();
      
      if (cargasSnapshot.docs.isNotEmpty) {
        print('Lote $loteId encontrado en ${cargasSnapshot.docs.length} cargas activas');
        for (final doc in cargasSnapshot.docs) {
          print('  - Carga ID: ${doc.id}');
        }
      }
      
      return cargasSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error verificando si lote está en carga activa: $e');
      return false;
    }
  }
  
  /// Limpiar lotes duplicados de cargas activas
  Future<void> limpiarLotesDuplicados() async {
    try {
      print('=== LIMPIANDO LOTES DUPLICADOS ===');
      
      // Obtener todas las cargas activas del transportista
      final cargasSnapshot = await _firestore
          .collection('cargas_transporte')
          .where('transportista_id', isEqualTo: _currentUserId)
          .where('estado_carga', whereIn: ['en_transporte', 'entregada_parcial'])
          .orderBy('fecha_creacion', descending: false) // Más antiguas primero
          .get();
      
      final lotesVistos = <String, String>{}; // loteId -> cargaId (primera aparición)
      final cargasConDuplicados = <String, List<String>>{}; // cargaId -> lotes a remover
      
      // Identificar duplicados
      for (final cargaDoc in cargasSnapshot.docs) {
        final cargaId = cargaDoc.id;
        final lotesIds = List<String>.from(cargaDoc.data()['lotes_ids'] ?? []);
        final lotesARemover = <String>[];
        
        for (final loteId in lotesIds) {
          if (lotesVistos.containsKey(loteId)) {
            // Este lote ya está en otra carga
            print('Lote duplicado $loteId: ya está en carga ${lotesVistos[loteId]}, removiendo de carga $cargaId');
            lotesARemover.add(loteId);
          } else {
            lotesVistos[loteId] = cargaId;
          }
        }
        
        if (lotesARemover.isNotEmpty) {
          cargasConDuplicados[cargaId] = lotesARemover;
        }
      }
      
      // Remover duplicados
      for (final entry in cargasConDuplicados.entries) {
        final cargaId = entry.key;
        final lotesARemover = entry.value;
        
        await _firestore.collection('cargas_transporte').doc(cargaId).update({
          'lotes_ids': FieldValue.arrayRemove(lotesARemover),
        });
        
        print('Removidos ${lotesARemover.length} lotes duplicados de carga $cargaId');
      }
      
      print('Limpieza de duplicados completada');
      print('================================');
    } catch (e) {
      print('Error limpiando lotes duplicados: $e');
    }
  }
  
  /// Crear una nueva carga con los lotes escaneados
  Future<String> crearCarga({
    required List<String> lotesIds,
    required String transportistaFolio,
    required String origenUsuarioId,
    required String origenUsuarioFolio,
    required String origenUsuarioNombre,
    required String origenUsuarioTipo,
    required String vehiculoPlacas,
    required String nombreConductor,
    required String nombreOperador,
    required double pesoTotalRecogido,
    String? firmaRecogida,
    required List<String> evidenciasFotoRecogida,
    String? comentariosRecogida,
  }) async {
    try {
      // Verificar que ningún lote esté ya en una carga activa
      for (final loteId in lotesIds) {
        final yaEnCarga = await loteEstaEnCargaActiva(loteId);
        if (yaEnCarga) {
          throw Exception('El lote $loteId ya está en una carga activa');
        }
      }
      
      // Generar ID para la carga
      final cargaRef = _firestore.collection('cargas_transporte').doc();
      final cargaId = cargaRef.id;
      
      // Generar QR para la carga
      final qrCarga = 'CARGA-$cargaId';
      
      // Crear modelo de carga
      final carga = CargaTransporteModel(
        id: cargaId,
        transportistaId: _currentUserId!,
        transportistaFolio: transportistaFolio,
        fechaCreacion: DateTime.now(),
        lotesIds: lotesIds,
        estadoCarga: 'en_transporte',
        origenUsuarioId: origenUsuarioId,
        origenUsuarioFolio: origenUsuarioFolio,
        origenUsuarioNombre: origenUsuarioNombre,
        origenUsuarioTipo: origenUsuarioTipo,
        fechaRecogida: DateTime.now(),
        vehiculoPlacas: vehiculoPlacas,
        nombreConductor: nombreConductor,
        nombreOperador: nombreOperador,
        pesoTotalRecogido: pesoTotalRecogido,
        firmaRecogida: firmaRecogida,
        evidenciasFotoRecogida: evidenciasFotoRecogida,
        comentariosRecogida: comentariosRecogida,
        qrCarga: qrCarga,
      );
      
      // Guardar en Firestore
      await cargaRef.set(carga.toFirestore());
      
      // Actualizar cada lote para transferirlo al transportista
      final transporteIds = <String, String>{}; // loteId -> transporteId
      
      for (final loteId in lotesIds) {
        // Obtener el peso actual del lote (puede ser diferente al original si fue procesado)
        final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
        final pesoActualLote = lote?.pesoActual ?? 0.0;
        
        // Primero actualizar el proceso anterior (origen, reciclador, etc.) para marcarlo como entregado
        final procesoAnterior = lote?.datosGenerales.procesoActual ?? 'origen';
        
        // No sobrescribir firma_salida si ya existe (preservar la firma del proceso anterior)
        final datosActualizacion = <String, dynamic>{
          'entrega_completada': true,
          'fecha_salida': FieldValue.serverTimestamp(),
          'entregado_a': transportistaFolio,
        };
        
        // Solo agregar firma_salida si el proceso anterior no tiene una
        // (por ejemplo, si es origen que no usa firma_salida)
        if (procesoAnterior == 'origen') {
          datosActualizacion['firma_salida'] = firmaRecogida;
        }
        
        await _loteUnificadoService.actualizarDatosProceso(
          loteId: loteId,
          proceso: procesoAnterior,
          datos: datosActualizacion,
        );
        
        // Luego crear el proceso transporte con los datos iniciales
        await _loteUnificadoService.transferirLote(
          loteId: loteId,
          procesoDestino: 'transporte',
          usuarioDestinoFolio: transportistaFolio,
          datosIniciales: {
            'carga_id': cargaId,
            'origen_recogida': origenUsuarioFolio,
            'vehiculo_placas': vehiculoPlacas,
            'nombre_conductor': nombreConductor,
            'nombre_operador': nombreOperador, // Agregar el nombre del operador
            'peso_recogido': pesoActualLote, // Usar el peso actual del lote
            'firma_recogida': firmaRecogida,
            'evidencias_foto_recogida': evidenciasFotoRecogida,
            'comentarios_recogida': comentariosRecogida,
            'recepcion_completada': true, // Marcar como recibido automáticamente
            'fecha_entrada': FieldValue.serverTimestamp(), // Asegurar que tenga fecha de entrada
          },
        );
        
        // Obtener el ID del transporte recién creado
        final transporteActivo = await _loteUnificadoService.obtenerTransporteActivo(loteId);
        if (transporteActivo != null) {
          transporteIds[loteId] = transporteActivo['id'];
        }
        
        // Solo agregar delay para origen (mantiene compatibilidad)
        // Para reciclador no es necesario ya que la actualización es inmediata
        if (procesoAnterior == 'origen') {
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        // Verificar y actualizar la transferencia si está completa
        print('Verificando transferencia para lote: $loteId');
        print('DEBUG - Proceso anterior: $procesoAnterior');
        await _loteUnificadoService.verificarYActualizarTransferencia(
          loteId: loteId,
          procesoOrigen: procesoAnterior,
          procesoDestino: 'transporte',
        );
        
        // Verificar si el proceso_actual ya se actualizó
        final verificacionDoc = await _firestore
            .collection('lotes')
            .doc(loteId)
            .collection('datos_generales')
            .doc('info')
            .get();
            
        final procesoActualDespues = verificacionDoc.data()?['proceso_actual'];
        print('DEBUG - Proceso actual después de verificarYActualizarTransferencia: $procesoActualDespues');
        
        // Para reciclador -> transporte, SIEMPRE actualizamos inmediatamente
        // porque el reciclador ya autorizó la salida al generar el QR
        if (procesoAnterior == 'reciclador') {
          if (procesoActualDespues == 'transporte') {
            print('El proceso ya fue actualizado por verificarYActualizarTransferencia');
          } else {
            print('Transferencia desde Reciclador - Forzando actualización del proceso_actual');
            print('ADVERTENCIA: verificarYActualizarTransferencia no actualizó el proceso');
            
            // Actualizar directamente el proceso_actual en una transacción para garantizar atomicidad
            await _firestore.runTransaction((transaction) async {
              final datosGeneralesRef = _firestore
                  .collection('lotes')
                  .doc(loteId)
                  .collection('datos_generales')
                  .doc('info');
                  
              transaction.update(datosGeneralesRef, {
                'proceso_actual': 'transporte',
                'estado_actual': 'en_transporte',
                'fecha_ultima_actualizacion': FieldValue.serverTimestamp(),
                'historial_procesos': FieldValue.arrayUnion(['transporte_fase_2']),
              });
            });
            
            print('Proceso actualizado exitosamente a transporte para lote: $loteId');
          }
        }
      }
      
      // Guardar los IDs de transporte en la carga para referencia futura
      await cargaRef.update({
        'transporte_ids': transporteIds,
      });
      
      return cargaId;
    } catch (e) {
      print('Error al crear carga: $e');
      throw Exception('Error al crear carga: $e');
    }
  }
  
  /// Obtener cargas del transportista actual
  Stream<List<CargaTransporteModel>> getCargasTransportista() {
    return _firestore
        .collection('cargas_transporte')
        .where('transportista_id', isEqualTo: _currentUserId)
        .where('estado_carga', whereIn: ['en_transporte', 'entregada_parcial'])
        .orderBy('fecha_creacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CargaTransporteModel.fromFirestore(doc))
            .toList());
  }
  
  /// Obtener lotes individuales de todas las cargas activas
  Future<List<Map<String, dynamic>>> getLotesEnTransporte() async {
    try {
      // Obtener todas las cargas activas
      final cargasSnapshot = await _firestore
          .collection('cargas_transporte')
          .where('transportista_id', isEqualTo: _currentUserId)
          .where('estado_carga', whereIn: ['en_transporte', 'entregada_parcial'])
          .get();
      
      final lotesInfo = <Map<String, dynamic>>[];
      final lotesProcessed = <String>{}; // Para evitar duplicados
      
      print('=== OBTENIENDO LOTES EN TRANSPORTE ===');
      print('Cargas encontradas: ${cargasSnapshot.docs.length}');
      
      for (final cargaDoc in cargasSnapshot.docs) {
        final carga = CargaTransporteModel.fromFirestore(cargaDoc);
        print('Procesando carga: ${carga.id} con ${carga.lotesIds.length} lotes');
        
        // Obtener información de cada lote
        for (final loteId in carga.lotesIds) {
          // Verificar si ya procesamos este lote
          if (lotesProcessed.contains(loteId)) {
            print('ADVERTENCIA: Lote $loteId duplicado en múltiples cargas');
            continue;
          }
          
          final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
          if (lote != null && lote.datosGenerales.procesoActual == 'transporte') {
            lotesProcessed.add(loteId);
            lotesInfo.add({
              'lote_id': loteId,
              'carga_id': carga.id,
              'material': lote.datosGenerales.tipoMaterial,
              'peso': lote.pesoActual,
              'peso_original': lote.datosGenerales.peso,
              'tiene_muestras_lab': lote.tieneAnalisisLaboratorio,
              'peso_muestras': lote.tieneAnalisisLaboratorio ? lote.pesoTotalMuestras : 0.0,
              'origen_folio': carga.origenUsuarioFolio,
              'origen_nombre': carga.origenUsuarioNombre,
              'fecha_recogida': carga.fechaRecogida,
            });
          }
        }
      }
      
      print('Total lotes únicos encontrados: ${lotesInfo.length}');
      print('=================================');
      
      return lotesInfo;
    } catch (e) {
      print('Error al obtener lotes en transporte: $e');
      return [];
    }
  }
  
  /// Verificar y actualizar el estado de una carga
  Future<void> actualizarEstadoCarga(String cargaId) async {
    try {
      print('=== ACTUALIZANDO ESTADO DE CARGA ===');
      print('Carga ID: $cargaId');
      
      final cargaDoc = await _firestore
          .collection('cargas_transporte')
          .doc(cargaId)
          .get();
          
      if (!cargaDoc.exists) {
        print('ERROR: Carga no encontrada');
        return;
      }
      
      final carga = CargaTransporteModel.fromFirestore(cargaDoc);
      print('Total lotes en carga: ${carga.lotesIds.length}');
      print('Estado actual de la carga: ${carga.estadoCarga}');
      
      // Verificar el estado de todos los lotes
      int lotesEntregados = 0;
      int lotesEnTransito = 0;
      
      for (final loteId in carga.lotesIds) {
        final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
        if (lote != null) {
          print('Lote $loteId - Proceso actual: ${lote.datosGenerales.procesoActual}');
          if (lote.datosGenerales.procesoActual != 'transporte') {
            // El lote ya fue transferido a otro proceso
            lotesEntregados++;
          } else {
            lotesEnTransito++;
          }
        }
      }
      
      // Actualizar el estado de la carga según los lotes
      String nuevoEstado = carga.estadoCarga;
      
      if (lotesEntregados == carga.lotesIds.length) {
        // Todos los lotes fueron entregados
        nuevoEstado = 'entregada';
      } else if (lotesEntregados > 0) {
        // Algunos lotes fueron entregados
        nuevoEstado = 'entregada_parcial';
      }
      
      print('Lotes entregados: $lotesEntregados');
      print('Lotes en tránsito: $lotesEnTransito');
      
      // Actualizar en Firebase si cambió el estado
      if (nuevoEstado != carga.estadoCarga) {
        print('Actualizando estado de carga de "${carga.estadoCarga}" a "$nuevoEstado"');
        await cargaDoc.reference.update({
          'estado_carga': nuevoEstado,
          'lotes_entregados': lotesEntregados,
          'lotes_en_transito': lotesEnTransito,
          'ultima_actualizacion': FieldValue.serverTimestamp(),
        });
        print('Estado actualizado exitosamente');
      } else {
        print('No se requiere actualización del estado');
      }
      print('=== FIN ACTUALIZAR ESTADO DE CARGA ===');
    } catch (e) {
      print('Error al actualizar estado de carga: $e');
    }
  }
  
  /// Crear una entrega con lotes seleccionados
  Future<String> crearEntrega({
    required List<String> lotesIds,
    required String cargaId,
    required String transportistaFolio,
    required String destinatarioId,
    required String destinatarioFolio,
    required String destinatarioNombre,
    required String destinatarioTipo,
    required double pesoTotalEntregado,
  }) async {
    try {
      // Generar ID para la entrega
      final entregaRef = _firestore.collection('entregas_transporte').doc();
      final entregaId = entregaRef.id;
      
      // Generar QR para la entrega
      final qrEntrega = 'ENTREGA-$entregaId';
      
      // Obtener nombre del transportista
      final profileService = EcoceProfileService();
      final transportistaProfile = await profileService.getProfileByUserId(_currentUserId!);
      final transportistaNombre = transportistaProfile?.ecoceNombre ?? 'Transportista';
      
      // Crear modelo de entrega
      final entrega = EntregaTransporteModel(
        id: entregaId,
        cargaId: cargaId,
        transportistaId: _currentUserId!,
        transportistaFolio: transportistaFolio,
        transportistaNombre: transportistaNombre,
        fechaCreacion: DateTime.now(),
        lotesIds: lotesIds,
        estadoEntrega: 'pendiente',
        destinatarioId: destinatarioId,
        destinatarioFolio: destinatarioFolio,
        destinatarioNombre: destinatarioNombre,
        destinatarioTipo: destinatarioTipo,
        pesoTotalEntregado: pesoTotalEntregado,
        evidenciasFotoEntrega: [],
        qrEntrega: qrEntrega,
      );
      
      // Guardar en Firestore
      await entregaRef.set(entrega.toFirestore());
      
      return qrEntrega;
    } catch (e) {
      print('Error al crear entrega: $e');
      throw Exception('Error al crear entrega: $e');
    }
  }
  
  /// Obtener entrega por código QR
  Future<EntregaTransporteModel?> getEntregaPorQR(String qr) async {
    try {
      final snapshot = await _firestore
          .collection('entregas_transporte')
          .where('qr_entrega', isEqualTo: qr)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      
      return EntregaTransporteModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error al obtener entrega por QR: $e');
      return null;
    }
  }
  
  /// Completar una entrega
  Future<void> completarEntrega({
    required String entregaId,
    required String firmaEntrega,
    required List<String> evidenciasFotoEntrega,
    String? comentariosEntrega,
  }) async {
    try {
      // Obtener la entrega
      final entregaDoc = await _firestore
          .collection('entregas_transporte')
          .doc(entregaId)
          .get();
      
      if (!entregaDoc.exists) {
        throw Exception('Entrega no encontrada');
      }
      
      final entrega = EntregaTransporteModel.fromFirestore(entregaDoc);
      
      // Actualizar la entrega
      await entregaDoc.reference.update({
        'estado_entrega': 'entregada',
        'fecha_entrega': FieldValue.serverTimestamp(),
        'firma_entrega': firmaEntrega,
        'evidencias_foto_entrega': evidenciasFotoEntrega,
        'comentarios_entrega': comentariosEntrega,
      });
      
      // Obtener los IDs de transporte de la carga
      final cargaDoc = await _firestore
          .collection('cargas_transporte')
          .doc(entrega.cargaId)
          .get();
      
      final transporteIds = cargaDoc.data()?['transporte_ids'] as Map<String, dynamic>? ?? {};
      
      // Actualizar cada lote en el sistema unificado
      for (final loteId in entrega.lotesIds) {
        // Obtener el transporteId específico para este lote
        final transporteId = transporteIds[loteId] as String?;
        
        // Primero actualizar datos del transporte
        await _loteUnificadoService.actualizarProcesoTransporte(
          loteId: loteId,
          datos: {
            'fecha_salida': FieldValue.serverTimestamp(),
            'destino_entrega': entrega.destinatarioFolio,
            'peso_entregado': entrega.pesoTotalEntregado / entrega.lotesIds.length,
            'firma_entrega': firmaEntrega,
            'evidencias_foto_entrega': evidenciasFotoEntrega,
            'comentarios_entrega': comentariosEntrega,
          },
        );
        
        // Luego transferir al destinatario
        await _loteUnificadoService.transferirLote(
          loteId: loteId,
          procesoDestino: entrega.destinatarioTipo,
          usuarioDestinoFolio: entrega.destinatarioFolio,
          datosIniciales: {
            'peso_entrada': entrega.pesoTotalEntregado / entrega.lotesIds.length,
            'transportista_folio': entrega.transportistaFolio,
            'entrega_id': entregaId,
            'transporte_origen': entrega.transportistaFolio,
            'transporte_numero': transporteId?.split('_')[1] ?? '1',
          },
        );
      }
      
      // Verificar si la carga está completamente entregada
      await _verificarEstadoCarga(entrega.cargaId);
      
      // Intentar eliminar el documento de entregas_transporte
      // Si falla por permisos, marcar como completada pero sin eliminar
      try {
        await _firestore
            .collection('entregas_transporte')
            .doc(entregaId)
            .delete();
      } catch (deleteError) {
        print('No se pudo eliminar la entrega (posiblemente por permisos): $deleteError');
        // Marcar la entrega como completada para que no aparezca en pendientes
        await _firestore
            .collection('entregas_transporte')
            .doc(entregaId)
            .update({
          'estado_entrega': 'completada_archivada',
          'fecha_archivado': FieldValue.serverTimestamp(),
        });
      }
      
    } catch (e) {
      print('Error al completar entrega: $e');
      throw Exception('Error al completar entrega: $e');
    }
  }
  
  /// Verificar si una carga ha sido entregada completamente
  Future<void> _verificarEstadoCarga(String cargaId) async {
    try {
      // Obtener la carga
      final cargaDoc = await _firestore
          .collection('cargas_transporte')
          .doc(cargaId)
          .get();
      
      if (!cargaDoc.exists) return;
      
      final carga = CargaTransporteModel.fromFirestore(cargaDoc);
      
      // Verificar si todos los lotes han sido entregados Y recibidos
      bool todosTransferidos = true;
      bool todosEntregados = true;
      
      for (final loteId in carga.lotesIds) {
        final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
        if (lote != null) {
          // Verificar si el lote sigue en transporte
          if (lote.datosGenerales.procesoActual == 'transporte') {
            todosTransferidos = false;
            
            // Verificar si al menos fue entregado (aunque no recibido)
            final transporteDoc = await _firestore
                .collection('lotes')
                .doc(loteId)
                .collection('transporte')
                .doc('data')
                .get();
                
            if (transporteDoc.exists && 
                transporteDoc.data()?['entrega_completada'] != true) {
              todosEntregados = false;
            }
          }
        }
      }
      
      // Determinar el estado de la carga
      String nuevoEstado;
      if (todosTransferidos) {
        nuevoEstado = 'completada_y_transferida';
      } else if (todosEntregados) {
        nuevoEstado = 'entregada_completa';
      } else {
        nuevoEstado = 'entregada_parcial';
      }
      
      // Actualizar estado de la carga
      await cargaDoc.reference.update({
        'estado_carga': nuevoEstado,
        'fecha_actualizacion': FieldValue.serverTimestamp(),
      });
      
      // Si todos los lotes han sido transferidos completamente, 
      // marcar la carga para limpieza
      if (todosTransferidos) {
        await _marcarCargaParaLimpieza(cargaId);
        
        // DESACTIVADO: Limpieza automática para evitar interferencias
        // La limpieza debe ejecutarse manualmente o por un proceso batch
        // _ejecutarLimpiezaAutomatica();
      }
      
    } catch (e) {
      print('Error al verificar estado de carga: $e');
    }
  }
  
  /// Marcar una carga para limpieza posterior
  Future<void> _marcarCargaParaLimpieza(String cargaId) async {
    try {
      print('=== MARCANDO CARGA PARA LIMPIEZA ===');
      print('Carga ID: $cargaId');
      
      // Agregar un timestamp de cuando se completó la transferencia
      await _firestore
          .collection('cargas_transporte')
          .doc(cargaId)
          .update({
        'fecha_transferencia_completa': FieldValue.serverTimestamp(),
        'marcada_para_limpieza': true,
      });
      
      print('Carga marcada para limpieza exitosamente');
    } catch (e) {
      print('Error marcando carga para limpieza: $e');
    }
  }
  
  /// Limpiar documentos de cargas y entregas completadas
  /// Este método debe ejecutarse periódicamente o cuando sea conveniente
  /// NOTA: Por defecto usa 30 días de retención para mayor seguridad
  Future<void> limpiarDocumentosCompletados({
    Duration tiempoRetencion = const Duration(days: 30),
    bool soloMarcar = true, // Por defecto solo marca, no elimina
  }) async {
    try {
      print('=== INICIANDO LIMPIEZA DE DOCUMENTOS ===');
      
      final ahora = DateTime.now();
      final fechaLimite = ahora.subtract(tiempoRetencion);
      
      // 1. Limpiar cargas completadas y transferidas
      final cargasQuery = await _firestore
          .collection('cargas_transporte')
          .where('marcada_para_limpieza', isEqualTo: true)
          .where('fecha_transferencia_completa', isLessThan: Timestamp.fromDate(fechaLimite))
          .get();
      
      print('Cargas a limpiar: ${cargasQuery.docs.length}');
      
      for (final cargaDoc in cargasQuery.docs) {
        try {
          // Verificar una vez más que todos los lotes están transferidos
          final carga = CargaTransporteModel.fromFirestore(cargaDoc);
          bool puedeEliminar = true;
          
          for (final loteId in carga.lotesIds) {
            final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
            if (lote != null && lote.datosGenerales.procesoActual == 'transporte') {
              puedeEliminar = false;
              break;
            }
          }
          
          if (puedeEliminar) {
            if (soloMarcar) {
              // Solo marcar como archivada, no eliminar
              await cargaDoc.reference.update({
                'estado_archivado': 'archivada_para_limpieza',
                'fecha_archivado': FieldValue.serverTimestamp(),
                'puede_eliminar': true,
              });
              print('Carga ${cargaDoc.id} marcada como archivada');
            } else {
              // Eliminar solo si explícitamente se solicita
              await cargaDoc.reference.delete();
              print('Carga ${cargaDoc.id} eliminada exitosamente');
            }
          } else {
            print('Carga ${cargaDoc.id} aún tiene lotes activos, no se puede limpiar');
          }
        } catch (e) {
          print('Error eliminando carga ${cargaDoc.id}: $e');
        }
      }
      
      // 2. Limpiar entregas completadas o archivadas
      final entregasQuery = await _firestore
          .collection('entregas_transporte')
          .where('estado_entrega', whereIn: ['entregada', 'completada_archivada'])
          .get();
      
      print('Entregas a evaluar: ${entregasQuery.docs.length}');
      
      for (final entregaDoc in entregasQuery.docs) {
        try {
          final entrega = EntregaTransporteModel.fromFirestore(entregaDoc);
          
          // Verificar si todos los lotes de la entrega han sido transferidos
          bool todosTransferidos = true;
          
          for (final loteId in entrega.lotesIds) {
            final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
            if (lote != null && lote.datosGenerales.procesoActual == 'transporte') {
              todosTransferidos = false;
              break;
            }
          }
          
          if (todosTransferidos) {
            // Verificar tiempo de retención
            final fechaEntrega = entregaDoc.data()['fecha_entrega'] as Timestamp?;
            final fechaArchivado = entregaDoc.data()['fecha_archivado'] as Timestamp?;
            final fechaReferencia = fechaArchivado ?? fechaEntrega;
            
            if (fechaReferencia != null && 
                fechaReferencia.toDate().isBefore(fechaLimite)) {
              if (soloMarcar) {
                // Solo marcar como archivada, no eliminar
                await entregaDoc.reference.update({
                  'estado_archivado': 'archivada_para_limpieza',
                  'fecha_marcado_limpieza': FieldValue.serverTimestamp(),
                  'puede_eliminar': true,
                });
                print('Entrega ${entregaDoc.id} marcada como archivada');
              } else {
                // Eliminar solo si explícitamente se solicita
                await entregaDoc.reference.delete();
                print('Entrega ${entregaDoc.id} eliminada exitosamente');
              }
            }
          }
        } catch (e) {
          print('Error procesando entrega ${entregaDoc.id}: $e');
        }
      }
      
      print('=== LIMPIEZA COMPLETADA ===');
    } catch (e) {
      print('Error en limpieza de documentos: $e');
    }
  }
  
  /// Ejecutar limpieza automática al completar operaciones críticas
  Future<void> _ejecutarLimpiezaAutomatica() async {
    try {
      // Solo ejecutar si han pasado más de 24 horas desde la última limpieza
      final ultimaLimpieza = await _obtenerUltimaLimpieza();
      final ahora = DateTime.now();
      
      if (ultimaLimpieza == null || 
          ahora.difference(ultimaLimpieza).inHours >= 24) {
        // Ejecutar limpieza en background sin bloquear
        limpiarDocumentosCompletados().then((_) {
          _guardarFechaLimpieza();
        }).catchError((e) {
          print('Error en limpieza automática: $e');
        });
      }
    } catch (e) {
      print('Error verificando limpieza automática: $e');
    }
  }
  
  Future<DateTime?> _obtenerUltimaLimpieza() async {
    // Implementar usando SharedPreferences o un documento en Firestore
    // Por ahora retornamos null para simplificar
    return null;
  }
  
  Future<void> _guardarFechaLimpieza() async {
    // Implementar guardado de fecha de última limpieza
    // Puede ser en SharedPreferences o Firestore
  }
  
  /// Obtener estadísticas de documentos pendientes de limpieza
  Future<Map<String, int>> obtenerEstadisticasLimpieza() async {
    try {
      // Contar cargas marcadas para limpieza
      final cargasQuery = await _firestore
          .collection('cargas_transporte')
          .where('marcada_para_limpieza', isEqualTo: true)
          .get();
      
      // Contar entregas completadas/archivadas
      final entregasQuery = await _firestore
          .collection('entregas_transporte')
          .where('estado_entrega', whereIn: ['entregada', 'completada_archivada'])
          .get();
      
      // Contar documentos archivados para limpieza
      final archivadosQuery = await _firestore
          .collection('cargas_transporte')
          .where('estado_archivado', isEqualTo: 'archivada_para_limpieza')
          .get();
      
      return {
        'cargas_pendientes': cargasQuery.docs.length,
        'entregas_completadas': entregasQuery.docs.length,
        'documentos_archivados': archivadosQuery.docs.length,
        'total_pendiente_limpieza': cargasQuery.docs.length + entregasQuery.docs.length,
      };
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {
        'cargas_pendientes': 0,
        'entregas_completadas': 0,
        'documentos_archivados': 0,
        'total_pendiente_limpieza': 0,
      };
    }
  }
  
  /// Verificar si hay documentos que necesitan limpieza
  Future<bool> hayDocumentosPendientesLimpieza({
    Duration tiempoRetencion = const Duration(days: 30),
  }) async {
    try {
      final fechaLimite = DateTime.now().subtract(tiempoRetencion);
      
      // Verificar cargas
      final cargasQuery = await _firestore
          .collection('cargas_transporte')
          .where('marcada_para_limpieza', isEqualTo: true)
          .where('fecha_transferencia_completa', isLessThan: Timestamp.fromDate(fechaLimite))
          .limit(1)
          .get();
      
      if (cargasQuery.docs.isNotEmpty) return true;
      
      // Verificar entregas
      final entregasQuery = await _firestore
          .collection('entregas_transporte')
          .where('estado_entrega', whereIn: ['entregada', 'completada_archivada'])
          .limit(1)
          .get();
      
      return entregasQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error verificando documentos pendientes: $e');
      return false;
    }
  }
  
  /// Obtener el número de lotes entregados por el transportista
  Future<int> obtenerNumeroLotesEntregados() async {
    try {
      // Obtener todas las cargas del transportista
      final cargasSnapshot = await _firestore
          .collection('cargas_transporte')
          .where('transportista_id', isEqualTo: _currentUserId)
          .get();
      
      int totalLotesEntregados = 0;
      
      // Para cada carga, verificar cuántos lotes ya no están en transporte
      for (final cargaDoc in cargasSnapshot.docs) {
        final carga = CargaTransporteModel.fromFirestore(cargaDoc);
        
        // Verificar cada lote de la carga
        for (final loteId in carga.lotesIds) {
          final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
          
          // Si el lote ya no está en transporte, significa que fue entregado
          if (lote != null && lote.datosGenerales.procesoActual != 'transporte') {
            totalLotesEntregados++;
          }
        }
      }
      
      return totalLotesEntregados;
    } catch (e) {
      print('Error obteniendo lotes entregados: $e');
      return 0;
    }
  }
}