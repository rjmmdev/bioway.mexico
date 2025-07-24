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
        await _loteUnificadoService.transferirLote(
          loteId: loteId,
          procesoDestino: 'transporte',
          usuarioDestinoFolio: transportistaFolio,
          datosIniciales: {
            'carga_id': cargaId,
            'origen_recogida': origenUsuarioFolio,
            'vehiculo_placas': vehiculoPlacas,
            'nombre_conductor': nombreConductor,
            'peso_recogido': pesoTotalRecogido / lotesIds.length, // Peso promedio por lote
            'firma_recogida': firmaRecogida,
            'evidencias_foto_recogida': evidenciasFotoRecogida,
            'comentarios_recogida': comentariosRecogida,
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
      
      // Verificar si todos los lotes han sido entregados
      bool todosEntregados = true;
      for (final loteId in carga.lotesIds) {
        final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
        if (lote != null && lote.datosGenerales.procesoActual == 'transporte') {
          todosEntregados = false;
          break;
        }
      }
      
      // Actualizar estado de la carga
      await cargaDoc.reference.update({
        'estado_carga': todosEntregados ? 'entregada_completa' : 'entregada_parcial',
      });
      
    } catch (e) {
      print('Error al verificar estado de carga: $e');
    }
  }
}