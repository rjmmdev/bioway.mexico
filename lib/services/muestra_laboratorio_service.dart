import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/laboratorio/muestra_laboratorio_model.dart';
import 'user_session_service.dart';
import 'firebase/auth_service.dart';
import 'firebase/firebase_manager.dart';

class MuestraLaboratorioService {
  late final FirebaseFirestore _firestore;
  late final AuthService _authService;
  final UserSessionService _userSession = UserSessionService();
  final FirebaseManager _firebaseManager = FirebaseManager();
  
  MuestraLaboratorioService() {
    // Usar la instancia de Firebase correspondiente a la app actual
    final app = _firebaseManager.currentApp;
    if (app != null) {
      _firestore = FirebaseFirestore.instanceFor(app: app);
    } else {
      _firestore = FirebaseFirestore.instance;
    }
    _authService = AuthService();
  }
  
  static const String COLLECTION_MUESTRAS = 'muestras_laboratorio';
  static const String COLLECTION_TRANSFORMACIONES = 'transformaciones';
  static const String COLLECTION_LOTES = 'lotes';

  // Crear nueva muestra de laboratorio
  Future<String> crearMuestra({
    required String origenId,
    required String origenTipo, // "transformacion" o "lote"
    required double pesoMuestra,
    required String firmaOperador,
    required List<String> evidenciasFoto,
    String? qrCode,
  }) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      final userData = _userSession.getUserData();
      final laboratorioFolio = userData?['folio'] ?? '';

      // Determinar el tipo de muestra
      final tipo = origenTipo == 'transformacion' ? 'megalote' : 'lote';

      // Usar transacción para asegurar consistencia
      return await _firestore.runTransaction((transaction) async {
        // Verificar que el origen existe y obtener datos
        DocumentSnapshot origenDoc;
        double pesoDisponible = 0;
        
        if (origenTipo == 'transformacion') {
          // Para transformaciones (megalotes)
          // Las transformaciones se guardan directamente en la colección, no en subcolección
          final transformacionRef = _firestore
              .collection(COLLECTION_TRANSFORMACIONES)
              .doc(origenId);
          
          origenDoc = await transaction.get(transformacionRef);
          if (!origenDoc.exists) {
            throw Exception('La transformación no existe');
          }
          
          final data = origenDoc.data() as Map<String, dynamic>;
          pesoDisponible = (data['peso_disponible'] ?? 0).toDouble();
          
          // Verificar peso disponible
          if (pesoDisponible < pesoMuestra) {
            throw Exception('Peso insuficiente. Disponible: ${pesoDisponible.toStringAsFixed(2)} kg');
          }
          
          // Actualizar transformación
          final nuevosPesoDisponible = pesoDisponible - pesoMuestra;
          final pesoMuestrasTotal = (data['peso_muestras_total'] ?? 0).toDouble() + pesoMuestra;
          final muestrasIds = List<String>.from(data['muestras_laboratorio_ids'] ?? []);
          
          // Crear referencia para la nueva muestra
          final muestraRef = _firestore.collection(COLLECTION_MUESTRAS).doc();
          muestrasIds.add(muestraRef.id);
          
          // Actualizar datos de la transformación (referencia ya correcta)
          transaction.update(transformacionRef, {
            'peso_disponible': nuevosPesoDisponible,
            'peso_muestras_total': pesoMuestrasTotal,
            'muestras_laboratorio_ids': muestrasIds,
            'tiene_muestra_laboratorio': true,
          });
          
          // Crear documento de muestra
          print('[MUESTRA_SERVICE] ========================================');
          print('[MUESTRA_SERVICE] CREANDO NUEVA MUESTRA');
          print('[MUESTRA_SERVICE] ID generado: ${muestraRef.id}');
          print('[MUESTRA_SERVICE] Origen (transformación): $origenId');
          print('[MUESTRA_SERVICE] Usuario laboratorio: $userId');
          
          final muestraData = MuestraLaboratorioModel(
            id: muestraRef.id,
            tipo: tipo,
            origenId: origenId,
            origenTipo: origenTipo,
            laboratorioId: userId,
            laboratorioFolio: laboratorioFolio,
            pesoMuestra: pesoMuestra,
            estado: 'pendiente_analisis',
            fechaToma: DateTime.now(),
            firmaOperador: firmaOperador,
            evidenciasFoto: evidenciasFoto,
            documentos: {},
            qrCode: qrCode ?? 'MUESTRA-MEGALOTE-${muestraRef.id}',
          );
          
          transaction.set(muestraRef, muestraData.toMap());
          
          print('[MUESTRA_SERVICE] ✓ Muestra creada exitosamente');
          print('[MUESTRA_SERVICE] Path: ${muestraRef.path}');
          print('[MUESTRA_SERVICE] ========================================');
          
          return muestraRef.id;
          
        } else {
          // Para lotes regulares (implementación futura)
          final loteRef = _firestore
              .collection(COLLECTION_LOTES)
              .doc(origenId)
              .collection('datos_generales')
              .doc('info');
          
          origenDoc = await transaction.get(loteRef);
          if (!origenDoc.exists) {
            throw Exception('El lote no existe');
          }
          
          // TODO: Implementar lógica para lotes regulares
          throw Exception('Toma de muestras de lotes regulares no implementada aún');
        }
      });
      
    } catch (e) {
      print('Error creando muestra de laboratorio: $e');
      throw Exception('Error al crear muestra: ${e.toString()}');
    }
  }

  // Obtener todas las muestras del usuario actual
  Stream<List<MuestraLaboratorioModel>> obtenerMuestrasUsuario() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(COLLECTION_MUESTRAS)
        .where('laboratorio_id', isEqualTo: userId)
        .orderBy('fecha_toma', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MuestraLaboratorioModel.fromMap(
              doc.data(),
              doc.id,
            );
          }).toList();
        });
  }

  // Obtener muestras por estado
  Stream<List<MuestraLaboratorioModel>> obtenerMuestrasPorEstado(String estado) {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    // Si el estado es para documentación, incluir muestras con análisis completado
    Query<Map<String, dynamic>> query = _firestore
        .collection(COLLECTION_MUESTRAS)
        .where('laboratorio_id', isEqualTo: userId);
    
    // Para la pestaña de documentación, mostrar muestras con análisis completado
    if (estado == 'pendiente_documentacion') {
      query = query.where('estado', isEqualTo: 'analisis_completado');
    } else {
      query = query.where('estado', isEqualTo: estado);
    }

    return query
        .orderBy('fecha_toma', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MuestraLaboratorioModel.fromMap(
              doc.data(),
              doc.id,
            );
          }).toList();
        });
  }

  // Obtener muestra específica por ID
  Future<MuestraLaboratorioModel?> obtenerMuestraPorId(String muestraId) async {
    try {
      final doc = await _firestore
          .collection(COLLECTION_MUESTRAS)
          .doc(muestraId)
          .get();
      
      if (!doc.exists) return null;
      
      final data = doc.data();
      if (data == null) return null;
      
      // Verificar que la muestra pertenece al usuario actual
      final userId = _authService.currentUser?.uid;
      if (data['laboratorio_id'] != userId) {
        throw Exception('No tiene permisos para acceder a esta muestra');
      }
      
      return MuestraLaboratorioModel.fromMap(data, doc.id);
    } catch (e) {
      print('Error obteniendo muestra: $e');
      return null;
    }
  }

  // Actualizar muestra con resultados de análisis
  Future<void> actualizarAnalisis(
    String muestraId,
    Map<String, dynamic> datosAnalisis,
  ) async {
    try {
      print('[MUESTRA_SERVICE] ========================================');
      print('[MUESTRA_SERVICE] INICIANDO ACTUALIZACIÓN DE ANÁLISIS');
      print('[MUESTRA_SERVICE] Muestra ID recibido: $muestraId');
      print('[MUESTRA_SERVICE] Colección: $COLLECTION_MUESTRAS');
      
      final userId = _authService.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');
      print('[MUESTRA_SERVICE] Usuario actual: $userId');

      // Verificar que la muestra existe y pertenece al usuario
      final muestraRef = _firestore.collection(COLLECTION_MUESTRAS).doc(muestraId);
      print('[MUESTRA_SERVICE] Path del documento: ${muestraRef.path}');
      
      final muestraDoc = await muestraRef.get();
      
      if (!muestraDoc.exists) {
        print('[MUESTRA_SERVICE] ERROR: La muestra $muestraId NO EXISTE');
        throw Exception('La muestra no existe');
      }
      
      final data = muestraDoc.data()!;
      print('[MUESTRA_SERVICE] Muestra encontrada. Estado actual: ${data['estado']}');
      print('[MUESTRA_SERVICE] Laboratorio ID en muestra: ${data['laboratorio_id']}');
      
      if (data['laboratorio_id'] != userId) {
        print('[MUESTRA_SERVICE] ERROR: Usuario $userId no tiene permisos para muestra de ${data['laboratorio_id']}');
        throw Exception('No tiene permisos para actualizar esta muestra');
      }

      // Actualizar con los datos de análisis y cambiar estado
      print('[MUESTRA_SERVICE] Actualizando documento con análisis...');
      await muestraRef.update({
        'datos_analisis': datosAnalisis,
        'estado': 'analisis_completado', // Estado correcto para documentación pendiente
        'fecha_analisis': FieldValue.serverTimestamp(),
      });
      
      print('[MUESTRA_SERVICE] ✓ EXITOSO: Muestra $muestraId actualizada');
      print('[MUESTRA_SERVICE] Nuevo estado: analisis_completado');
      print('[MUESTRA_SERVICE] ========================================');
      
    } catch (e) {
      print('[MUESTRA_SERVICE] ERROR CRITICO: ${e.toString()}');
      print('[MUESTRA_SERVICE] ========================================');
      throw Exception('Error al actualizar análisis: ${e.toString()}');
    }
  }

  // Actualizar muestra con documentación
  Future<void> actualizarDocumentacion(
    String muestraId,
    Map<String, String> documentos,
  ) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      // Verificar que la muestra existe y pertenece al usuario
      final muestraDoc = await _firestore
          .collection(COLLECTION_MUESTRAS)
          .doc(muestraId)
          .get();
      
      if (!muestraDoc.exists) {
        throw Exception('La muestra no existe');
      }
      
      final data = muestraDoc.data()!;
      if (data['laboratorio_id'] != userId) {
        throw Exception('No tiene permisos para actualizar esta muestra');
      }

      // Actualizar con la documentación y cambiar estado a completado
      await _firestore
          .collection(COLLECTION_MUESTRAS)
          .doc(muestraId)
          .update({
            'documentos': documentos,
            'estado': 'documentacion_completada', // Estado final
            'fecha_documentacion': FieldValue.serverTimestamp(),
          });
      
      print('[LABORATORIO] ✓ Muestra $muestraId completada: estado = documentacion_completada');
      
    } catch (e) {
      print('Error actualizando documentación: $e');
      throw Exception('Error al actualizar documentación: ${e.toString()}');
    }
  }

  // Obtener información del megalote asociado a una muestra
  Future<Map<String, dynamic>?> obtenerInfoMegalote(String transformacionId) async {
    try {
      final doc = await _firestore
          .collection(COLLECTION_TRANSFORMACIONES)
          .doc(transformacionId)
          .collection('datos_generales')
          .doc('info')
          .get();
      
      if (!doc.exists) return null;
      
      return doc.data();
    } catch (e) {
      print('Error obteniendo info del megalote: $e');
      return null;
    }
  }

  // Método helper para obtener estadísticas
  Future<Map<String, int>> obtenerEstadisticasMuestras() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        return {
          'pendientes': 0,
          'analizadas': 0,
          'documentadas': 0,
          'total': 0,
        };
      }

      final snapshot = await _firestore
          .collection(COLLECTION_MUESTRAS)
          .where('laboratorio_id', isEqualTo: userId)
          .get();

      int pendientes = 0;
      int analizadas = 0;
      int documentadas = 0;

      for (var doc in snapshot.docs) {
        final estado = doc.data()['estado'];
        switch (estado) {
          case 'pendiente_analisis':
            pendientes++;
            break;
          case 'analisis_completado':
            analizadas++;
            break;
          case 'documentacion_completada':
            documentadas++;
            break;
        }
      }

      return {
        'pendientes': pendientes,
        'analizadas': analizadas,
        'documentadas': documentadas,
        'total': snapshot.docs.length,
      };
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {
        'pendientes': 0,
        'analizadas': 0,
        'documentadas': 0,
        'total': 0,
      };
    }
  }
}