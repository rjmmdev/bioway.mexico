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
    print('[TransformacionService] Iniciando creación de transformación');
    print('[TransformacionService] Número de lotes: ${lotes.length}');
    print('[TransformacionService] Merma proceso: $mermaProceso');
    
    try {
      final userData = _userSession.getUserData();
      if (userData == null) throw Exception('Usuario no autenticado');
      
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
        usuarioId: userData['uid'],
        usuarioFolio: userData['folio'] ?? '',
        procesoAplicado: procesoAplicado,
        observaciones: observaciones,
      );
      
      print('[TransformacionService] Transformación creada en memoria');
      print('[TransformacionService] Convirtiendo transformación a Map');
      
      final transformacionMap = transformacion.toMap();
      print('[TransformacionService] Map de transformación creado exitosamente');
      
      // Usar transacción para asegurar consistencia
      await _firestore.runTransaction((transaction) async {
        print('[TransformacionService] Iniciando transacción');
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
        
        // NO crear entrada en lotes unificados para el sublote
        // Los sublotes se manejan separadamente y solo se crean como lotes
        // cuando se necesita transferirlos a otro proceso
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
}