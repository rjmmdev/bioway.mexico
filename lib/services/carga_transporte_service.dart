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
    required double pesoTotalRecogido,
    String? firmaRecogida,
    required List<String> evidenciasFotoRecogida,
    String? comentariosRecogida,
  }) async {
    try {
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
        // Obtener el peso original del lote
        final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
        final pesoOriginalLote = lote?.datosGenerales.peso ?? 0.0;
        
        // Primero actualizar el proceso anterior (origen, reciclador, etc.) para marcarlo como entregado
        final procesoAnterior = lote?.datosGenerales.procesoActual ?? 'origen';
        await _loteUnificadoService.actualizarDatosProceso(
          loteId: loteId,
          proceso: procesoAnterior,
          datos: {
            'entrega_completada': true,
            'fecha_salida': FieldValue.serverTimestamp(),
            'entregado_a': transportistaFolio,
          },
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
            'peso_recogido': pesoOriginalLote, // Usar el peso original del lote
            'firma_recogida': firmaRecogida,
            'evidencias_foto_recogida': evidenciasFotoRecogida,
            'comentarios_recogida': comentariosRecogida,
            'recepcion_completada': true, // Marcar como recibido automáticamente
          },
        );
        
        // Obtener el ID del transporte recién creado
        final transporteActivo = await _loteUnificadoService.obtenerTransporteActivo(loteId);
        if (transporteActivo != null) {
          transporteIds[loteId] = transporteActivo['id'];
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
      
      for (final cargaDoc in cargasSnapshot.docs) {
        final carga = CargaTransporteModel.fromFirestore(cargaDoc);
        
        // Obtener información de cada lote
        for (final loteId in carga.lotesIds) {
          final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
          if (lote != null && lote.datosGenerales.procesoActual == 'transporte') {
            lotesInfo.add({
              'lote_id': loteId,
              'carga_id': carga.id,
              'material': lote.datosGenerales.tipoMaterial,
              'peso': lote.datosGenerales.peso,
              'origen_folio': carga.origenUsuarioFolio,
              'origen_nombre': carga.origenUsuarioNombre,
              'fecha_recogida': carga.fechaRecogida,
            });
          }
        }
      }
      
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
          transporteId: transporteId,
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
}