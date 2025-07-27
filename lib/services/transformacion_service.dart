import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lotes/transformacion_model.dart';
import '../models/lotes/sublote_model.dart';
import '../models/lotes/lote_unificado_model.dart';
import 'user_session_service.dart';

/// Servicio para manejar las transformaciones de lotes en el reciclador
class TransformacionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserSessionService _userSession = UserSessionService();
  
  /// Crea una nueva transformación con múltiples lotes
  Future<String> crearTransformacion({
    required List<LoteUnificadoModel> lotes,
    required double mermaProceso,
    String? procesoAplicado,
    String? observaciones,
  }) async {
    try {
      final userData = _userSession.getUserData();
      if (userData == null) throw Exception('Usuario no autenticado');
      
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
      for (var loteEntrada in lotesEntrada) {
        loteEntrada = LoteEntrada(
          loteId: loteEntrada.loteId,
          peso: loteEntrada.peso,
          porcentaje: (loteEntrada.peso / pesoTotal) * 100,
          tipoMaterial: loteEntrada.tipoMaterial,
        );
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
        documentosAsociados: [],
        usuarioId: userData['uid'],
        usuarioFolio: userData['folio'] ?? '',
        procesoAplicado: procesoAplicado,
        observaciones: observaciones,
      );
      
      // Usar transacción para asegurar consistencia
      await _firestore.runTransaction((transaction) async {
        // Crear la transformación
        transaction.set(transformacionRef, transformacion.toMap());
        
        // Marcar cada lote como consumido
        for (final lote in lotes) {
          final loteRef = _firestore
              .collection('lotes')
              .doc(lote.id)
              .collection('datos_generales')
              .doc('data');
              
          transaction.update(loteRef, {
            'consumido_en_transformacion': true,
            'transformacion_id': transformacionId,
            'fecha_consumido': FieldValue.serverTimestamp(),
          });
        }
      });
      
      return transformacionId;
    } catch (e) {
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
      
      // Usar transacción para actualizar transformación y crear sublote
      await _firestore.runTransaction((transaction) async {
        // Crear el sublote
        transaction.set(subloteRef, sublote.toMap());
        
        // Actualizar la transformación
        transaction.update(
          _firestore.collection('transformaciones').doc(transformacionId),
          {
            'peso_disponible': FieldValue.increment(-peso),
            'sublotes_generados': FieldValue.arrayUnion([subloteId]),
          },
        );
        
        // Crear entrada en lotes unificados para el sublote
        final datosGeneralesRef = _firestore
            .collection('lotes')
            .doc(subloteId)
            .collection('datos_generales')
            .doc('data');
            
        transaction.set(datosGeneralesRef, {
          'id': subloteId,
          'fecha_creacion': FieldValue.serverTimestamp(),
          'creado_por': userData['uid'],
          'tipo_material': sublote.materialPredominante,
          'peso_inicial': peso,
          'peso': peso,
          'estado_actual': 'activo',
          'proceso_actual': 'reciclador',
          'historial_procesos': ['reciclador'],
          'qr_code': sublote.qrCode,
          'tipo_lote': 'derivado',
          'consumido_en_transformacion': false,
          'sublote_origen_id': subloteId,
        });
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
  
  /// Stream de transformaciones del usuario actual
  Stream<List<TransformacionModel>> obtenerTransformacionesUsuario() {
    final userData = _userSession.getUserData();
    if (userData == null) return Stream.value([]);
    
    return _firestore
        .collection('transformaciones')
        .where('usuario_id', isEqualTo: userData['uid'])
        .orderBy('fecha_inicio', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransformacionModel.fromFirestore(doc))
            .toList());
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
      
      // Validar peso disponible
      if (pesoMuestra > transformacion.pesoDisponible) {
        throw Exception('Peso de muestra excede el peso disponible');
      }
      
      // Crear ID único para la muestra
      final muestraId = _firestore.collection('muestras_laboratorio').doc().id;
      final qrCode = 'MUESTRA-MEGALOTE-$muestraId';
      
      // Actualizar la transformación para restar el peso
      await _firestore
          .collection('transformaciones')
          .doc(transformacionId)
          .update({
        'peso_disponible': FieldValue.increment(-pesoMuestra),
        'muestras_laboratorio': FieldValue.arrayUnion([{
          'id': muestraId,
          'peso': pesoMuestra,
          'fecha': FieldValue.serverTimestamp(),
          'qr_code': qrCode,
        }]),
      });
      
      return qrCode;
    } catch (e) {
      throw Exception('Error al crear muestra: $e');
    }
  }
}