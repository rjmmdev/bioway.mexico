import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/services/firebase/auth_service.dart';
import 'package:app/services/firebase/firebase_manager.dart';
import 'package:app/services/firebase/firebase_storage_service.dart';
import 'package:app/models/lotes/lote_unificado_model.dart';
import 'package:app/utils/qr_utils.dart';

/// Servicio centralizado para gestión de lotes con ID único e inmutable
class LoteUnificadoService {
  final FirebaseManager _firebaseManager = FirebaseManager();
  final AuthService _authService = AuthService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  // Debug flag - set to false in production
  static const bool _debugMode = false;
  
  void _debugPrint(String message) {
    if (_debugMode) {
      debugPrint('[LoteUnificado] $message');
    }
  }
  
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
  String? get currentUserId => _currentUserId;
  
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
      _debugPrint('=== DATOS A GUARDAR EN ORIGEN ===');
      _debugPrint('Firma: $firmaOperador');
      _debugPrint('Evidencias: ${evidenciasFoto.length} fotos');
      _debugPrint('================================');
      
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

  /// Verificar si ambas partes han completado la transferencia (actualizado para subfases)
  Future<bool> verificarTransferenciaCompleta({
    required String loteId,
    required String procesoOrigen,
    required String procesoDestino,
  }) async {
    try {
      _debugPrint('=== VERIFICANDO TRANSFERENCIA COMPLETA ===');
      _debugPrint('Lote ID: $loteId');
      _debugPrint('Proceso Origen: $procesoOrigen');
      _debugPrint('Proceso Destino: $procesoDestino');
      
      final loteRef = _firestore.collection(COLECCION_LOTES).doc(loteId);
      
      // Para casos especiales donde el destino puede completar primero
      // (ej: el reciclador puede escanear y recibir antes que el transportista entregue)
      bool origenExiste = false;
      bool tieneEntrega = false;
      bool destinoExiste = false;
      bool tieneRecepcion = false;
      
      // Verificar proceso origen
      DocumentSnapshot? origenDoc;
      
      // Si el origen es transporte, determinar la fase
      if (procesoOrigen == PROCESO_TRANSPORTE) {
        // Verificar ambas fases para encontrar la activa
        final fase1Doc = await loteRef.collection(PROCESO_TRANSPORTE).doc('fase_1').get();
        final fase2Doc = await loteRef.collection(PROCESO_TRANSPORTE).doc('fase_2').get();
        
        // Usar la fase más reciente
        if (fase2Doc.exists && procesoDestino == PROCESO_TRANSFORMADOR) {
          origenDoc = fase2Doc;
        } else if (fase1Doc.exists) {
          origenDoc = fase1Doc;
        }
      } else {
        origenDoc = await loteRef.collection(procesoOrigen).doc('data').get();
      }
      
      if (origenDoc != null && origenDoc.exists) {
        origenExiste = true;
        final datosOrigen = origenDoc.data() as Map<String, dynamic>;
        _debugPrint('VERIFICACIÓN ORIGEN ($procesoOrigen):');
        _debugPrint('  Campos relevantes: ${datosOrigen.keys.toList()}');
        
        // Verificar si el origen ha completado su parte
        tieneEntrega = datosOrigen['entrega_completada'] == true || 
                      datosOrigen['fecha_salida'] != null || 
                      datosOrigen['firma_entrega'] != null ||
                      datosOrigen['firma_salida'] != null ||  // Agregar verificación de firma_salida
                      datosOrigen['firma_conductor'] != null; // Para transportista
        _debugPrint('  - Origen existe: $origenExiste');
        _debugPrint('  - Tiene Entrega: $tieneEntrega');
        _debugPrint('  - entrega_completada: ${datosOrigen['entrega_completada']}');
        _debugPrint('  - fecha_salida: ${datosOrigen['fecha_salida']}');
        _debugPrint('  - firma_entrega: ${datosOrigen['firma_entrega']}');
        _debugPrint('  - firma_salida: ${datosOrigen['firma_salida']}');
        _debugPrint('  - firma_conductor: ${datosOrigen['firma_conductor']}');
        _debugPrint('  - entregado_a: ${datosOrigen['entregado_a']}');
      } else {
        _debugPrint('ADVERTENCIA: Documento origen ($procesoOrigen) no existe');
      }
      
      // Verificar proceso destino (reciclador/transformador/transporte)
      DocumentSnapshot? destinoDoc;
      
      if (procesoDestino == PROCESO_TRANSPORTE) {
        // Para transporte, verificar las fases
        String faseDestino = 'fase_1'; // Por defecto fase_1 cuando viene de origen
        if (procesoOrigen == PROCESO_RECICLADOR) {
          faseDestino = 'fase_2';
        }
        destinoDoc = await loteRef.collection(PROCESO_TRANSPORTE).doc(faseDestino).get();
      } else {
        destinoDoc = await loteRef.collection(procesoDestino).doc('data').get();
      }
      
      if (destinoDoc.exists) {
        destinoExiste = true;
        final datosDestino = destinoDoc.data() as Map<String, dynamic>;
        _debugPrint('VERIFICACIÓN DESTINO ($procesoDestino):');
        _debugPrint('  Campos relevantes: ${datosDestino.keys.toList()}');
        
        // Verificar si el destino ha completado su parte
        tieneRecepcion = datosDestino['recepcion_completada'] == true ||
                        datosDestino['firma_operador'] != null ||
                        datosDestino['firma_recepcion'] != null ||
                        datosDestino['peso_recibido'] != null ||
                        datosDestino['peso_entrada'] != null ||
                        datosDestino['fecha_entrada'] != null;  // Agregar verificación de fecha_entrada
        _debugPrint('  - Destino existe: $destinoExiste');
        _debugPrint('  - Tiene Recepción: $tieneRecepcion');
        _debugPrint('  - recepcion_completada: ${datosDestino['recepcion_completada']}');
        _debugPrint('  - firma_operador: ${datosDestino['firma_operador']}');
        _debugPrint('  - firma_recepcion: ${datosDestino['firma_recepcion']}');
        _debugPrint('  - peso_recibido: ${datosDestino['peso_recibido']}');
        _debugPrint('  - peso_entrada: ${datosDestino['peso_entrada']}');
        _debugPrint('  - fecha_entrada: ${datosDestino['fecha_entrada']}');
      } else {
        _debugPrint('ADVERTENCIA: Documento destino ($procesoDestino) no existe');
      }
      
      // La transferencia está completa si:
      // 1. Para reciclador -> transporte: Solo verificar que el transportista recibió (unidireccional)
      // 2. Para otros casos: Ambos procesos deben completar su parte (bidireccional)
      bool resultado = false;
      
      // Caso especial: Reciclador -> Transportista es unidireccional
      if (procesoOrigen == PROCESO_RECICLADOR && procesoDestino == PROCESO_TRANSPORTE) {
        // El reciclador ya autorizó la salida al generar el QR
        // Solo necesitamos que el transportista haya recibido
        resultado = destinoExiste && tieneRecepcion;
        _debugPrint('RESULTADO: Transferencia Reciclador->Transporte - Destino existe: $destinoExiste, Tiene recepción: $tieneRecepcion');
        _debugPrint('DEBUG - OrigenExiste: $origenExiste, TieneEntrega: $tieneEntrega');
        _debugPrint('DEBUG - Este caso ES unidireccional, resultado: $resultado');
      } else if (origenExiste && destinoExiste) {
        // Caso normal: ambos existen (para otros flujos)
        resultado = tieneEntrega && tieneRecepcion;
        _debugPrint('RESULTADO: Ambos existen - Entrega: $tieneEntrega, Recepción: $tieneRecepcion');
      } else if (!origenExiste && destinoExiste && tieneRecepcion) {
        // Caso especial: solo el destino ha completado (recepción anticipada)
        // En este caso, esperamos a que el origen complete
        resultado = false;
        _debugPrint('RESULTADO: Solo destino existe con recepción - Esperando origen');
      } else if (origenExiste && !destinoExiste && tieneEntrega) {
        // Caso especial: solo el origen ha completado (entrega anticipada)
        // En este caso, esperamos a que el destino complete
        resultado = false;
        _debugPrint('RESULTADO: Solo origen existe con entrega - Esperando destino');
      } else {
        _debugPrint('RESULTADO: Ninguna condición cumplida');
      }
      
      _debugPrint('Transferencia Completa: $resultado');
      _debugPrint('=====================================');
      
      return resultado;
    } catch (e) {
      _debugPrint('Error verificando transferencia: $e');
      return false;
    }
  }

  /// Transferir lote a otro proceso (actualizado para manejar subfases de transporte)
  Future<void> transferirLote({
    required String loteId,
    required String procesoDestino,
    required String usuarioDestinoFolio,
    required Map<String, dynamic> datosIniciales,
  }) async {
    try {
      _debugPrint('=== INICIANDO TRANSFERIR LOTE ===');
      _debugPrint('Lote ID: $loteId');
      _debugPrint('Proceso Destino: $procesoDestino');
      _debugPrint('Usuario Destino: $usuarioDestinoFolio');
      
      final batch = _firestore.batch();
      final loteRef = _firestore.collection(COLECCION_LOTES).doc(loteId);
      
      // 1. Obtener proceso actual
      final datosGeneralesDoc = await loteRef.collection(DATOS_GENERALES).doc('info').get();
      if (!datosGeneralesDoc.exists) {
        throw Exception('Lote no encontrado');
      }
      
      final datosGenerales = datosGeneralesDoc.data()!;
      final procesoActual = datosGenerales['proceso_actual'] as String;
      _debugPrint('Proceso Actual: $procesoActual');
      
      // Determinar si es una fase de transporte
      String? faseTransporte;
      
      if (procesoDestino == PROCESO_TRANSPORTE) {
        // Determinar la fase basado en el proceso actual
        if (procesoActual == PROCESO_ORIGEN) {
          faseTransporte = 'fase_1';
        } else if (procesoActual == PROCESO_RECICLADOR) {
          faseTransporte = 'fase_2';
        } else {
          faseTransporte = 'fase_1'; // Por defecto
        }
        _debugPrint('Fase de transporte determinada: $faseTransporte');
      }
      
      // 2. Crear o actualizar el proceso destino
      // No sobrescribir usuario_id si ya viene en datosIniciales
      final datosFinales = {
        'usuario_folio': usuarioDestinoFolio,
        ...datosIniciales,
      };
      
      // Solo agregar usuario_id si no viene en datosIniciales
      if (!datosIniciales.containsKey('usuario_id')) {
        datosFinales['usuario_id'] = _currentUserId;
      }
      
      // Si es transporte, guardar en la subfase correspondiente
      if (faseTransporte != null) {
        await loteRef.collection(PROCESO_TRANSPORTE).doc(faseTransporte).set({
          'fecha_entrada': FieldValue.serverTimestamp(),
          ...datosFinales,
        });
      } else {
        await crearOActualizarProceso(
          loteId: loteId,
          proceso: procesoDestino,
          datos: datosFinales,
        );
      }
      
      // 3. Si es una transferencia completa, actualizar datos generales
      final esTransferenciaCompleta = await verificarTransferenciaCompleta(
        loteId: loteId,
        procesoOrigen: procesoActual,
        procesoDestino: procesoDestino,
      );
      
      if (esTransferenciaCompleta) {
        _debugPrint('TRANSFERENCIA COMPLETA DETECTADA - Actualizando proceso_actual a: $procesoDestino');
        
        // Marcar salida del proceso actual
        if (procesoActual == PROCESO_TRANSPORTE) {
          // Si el proceso actual es transporte, determinar qué fase marcar como completada
          final fase = faseTransporte == 'fase_2' ? 'fase_1' : 'fase_2';
          final faseDoc = await loteRef.collection(PROCESO_TRANSPORTE).doc(fase).get();
          if (faseDoc.exists) {
            batch.update(
              loteRef.collection(PROCESO_TRANSPORTE).doc(fase),
              {'fecha_salida': FieldValue.serverTimestamp()},
            );
          }
        } else {
          batch.update(
            loteRef.collection(procesoActual).doc('data'),
            {'fecha_salida': FieldValue.serverTimestamp()},
          );
        }
        
        // Asegurar que el proceso destino tenga fecha_entrada
        if (procesoDestino == PROCESO_TRANSPORTE && faseTransporte != null) {
          final destinoDoc = await loteRef.collection(PROCESO_TRANSPORTE).doc(faseTransporte).get();
          if (destinoDoc.exists && destinoDoc.data()!['fecha_entrada'] == null) {
            batch.update(
              loteRef.collection(PROCESO_TRANSPORTE).doc(faseTransporte),
              {'fecha_entrada': FieldValue.serverTimestamp()},
            );
          }
        } else {
          final destinoDoc = await loteRef.collection(procesoDestino).doc('data').get();
          if (destinoDoc.exists && destinoDoc.data()!['fecha_entrada'] == null) {
            batch.update(
              loteRef.collection(procesoDestino).doc('data'),
              {'fecha_entrada': FieldValue.serverTimestamp()},
            );
          }
        }
        
        // Actualizar datos generales
        // Para el historial, agregar la fase específica si es transporte
        final historialEntry = procesoDestino == PROCESO_TRANSPORTE && faseTransporte != null
            ? '${PROCESO_TRANSPORTE}_$faseTransporte'
            : procesoDestino;
            
        batch.update(
          loteRef.collection(DATOS_GENERALES).doc('info'),
          {
            'estado_actual': 'en_$procesoDestino',
            'proceso_actual': procesoDestino,
            'historial_procesos': FieldValue.arrayUnion([historialEntry]),
          },
        );
        
        await batch.commit();
        _debugPrint('BATCH COMMIT EXITOSO - Lote transferido a: $procesoDestino');
      } else {
        _debugPrint('TRANSFERENCIA PARCIAL - Esperando que la otra parte complete');
      }
      _debugPrint('=== FIN TRANSFERIR LOTE ===');
    } catch (e) {
      _debugPrint('ERROR en transferirLote: $e');
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
      // Si es transporte, necesitamos determinar la fase
      if (proceso == PROCESO_TRANSPORTE) {
        await actualizarProcesoTransporte(
          loteId: loteId,
          datos: datos,
        );
      } else {
        await _firestore
            .collection(COLECCION_LOTES)
            .doc(loteId)
            .collection(proceso)
            .doc('data')
            .update(datos);
      }
    } catch (e) {
      throw Exception('Error al actualizar datos del proceso: $e');
    }
  }
  
  /// Actualizar datos del proceso transporte (actualizado para subfases)
  Future<void> actualizarProcesoTransporte({
    required String loteId,
    required Map<String, dynamic> datos,
    String? faseTransporte,
  }) async {
    try {
      final loteRef = _firestore.collection(COLECCION_LOTES).doc(loteId);
      
      // Si no se especifica fase, determinar la fase activa
      if (faseTransporte == null) {
        // Estrategia más robusta: verificar qué documento existe
        final fase1Doc = await loteRef.collection(PROCESO_TRANSPORTE).doc('fase_1').get();
        final fase2Doc = await loteRef.collection(PROCESO_TRANSPORTE).doc('fase_2').get();
        
        if (fase2Doc.exists && !fase1Doc.exists) {
          // Solo existe fase_2
          faseTransporte = 'fase_2';
        } else if (fase1Doc.exists && !fase2Doc.exists) {
          // Solo existe fase_1
          faseTransporte = 'fase_1';
        } else if (fase1Doc.exists && fase2Doc.exists) {
          // Existen ambas fases, usar la más reciente basado en fecha_entrada
          final fecha1 = fase1Doc.data()!['fecha_entrada'] as Timestamp?;
          final fecha2 = fase2Doc.data()!['fecha_entrada'] as Timestamp?;
          
          if (fecha2 != null && (fecha1 == null || fecha2.compareTo(fecha1) > 0)) {
            faseTransporte = 'fase_2';
          } else {
            faseTransporte = 'fase_1';
          }
        } else {
          // No existe ninguna fase, usar lógica basada en historial
          final datosGenerales = await loteRef.collection(DATOS_GENERALES).doc('info').get();
          if (datosGenerales.exists) {
            final historial = List<String>.from(datosGenerales.data()!['historial_procesos'] ?? []);
            
            // Si el lote pasó por reciclador, debe ser fase_2
            if (historial.contains('reciclador')) {
              faseTransporte = 'fase_2';
            } else {
              faseTransporte = 'fase_1';
            }
          } else {
            faseTransporte = 'fase_1'; // Por defecto
          }
        }
      }
      
      _debugPrint('Actualizando transporte fase: $faseTransporte');
      
      await loteRef
          .collection(PROCESO_TRANSPORTE)
          .doc(faseTransporte)
          .update(datos);
    } catch (e) {
      _debugPrint('Error al actualizar proceso transporte: $e');
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
      _debugPrint('Error al obtener transporte activo: $e');
      return null;
    }
  }
  
  /// Verificar y actualizar transferencia después de que ambas partes completen
  Future<void> verificarYActualizarTransferencia({
    required String loteId,
    required String procesoOrigen,
    required String procesoDestino,
  }) async {
    try {
      _debugPrint('=== VERIFICANDO Y ACTUALIZANDO TRANSFERENCIA ===');
      _debugPrint('Lote: $loteId, Origen: $procesoOrigen, Destino: $procesoDestino');
      
      // Primero verificar el estado actual del lote
      final datosGeneralesDoc = await _firestore
          .collection(COLECCION_LOTES)
          .doc(loteId)
          .collection(DATOS_GENERALES)
          .doc('info')
          .get();
          
      if (datosGeneralesDoc.exists) {
        final procesoActualActual = datosGeneralesDoc.data()!['proceso_actual'];
        _debugPrint('Proceso actual en DB: $procesoActualActual');
      }
      
      // Verificar si la transferencia está completa
      final esCompleta = await verificarTransferenciaCompleta(
        loteId: loteId,
        procesoOrigen: procesoOrigen,
        procesoDestino: procesoDestino,
      );
      
      if (esCompleta) {
        _debugPrint('Transferencia completa detectada, actualizando proceso_actual...');
        
        // Actualizar proceso_actual y estado
        final batch = _firestore.batch();
        final loteRef = _firestore.collection(COLECCION_LOTES).doc(loteId);
        
        // Determinar fase de transporte si aplica
        String historialEntry = procesoDestino;
        if (procesoDestino == PROCESO_TRANSPORTE) {
          String faseTransporte = procesoOrigen == PROCESO_ORIGEN ? 'fase_1' : 'fase_2';
          historialEntry = '${PROCESO_TRANSPORTE}_$faseTransporte';
          _debugPrint('Agregando al historial: $historialEntry');
        }
        
        batch.update(
          loteRef.collection(DATOS_GENERALES).doc('info'),
          {
            'estado_actual': 'en_$procesoDestino',
            'proceso_actual': procesoDestino,
            'historial_procesos': FieldValue.arrayUnion([historialEntry]),
            'fecha_ultima_actualizacion': FieldValue.serverTimestamp(),
          },
        );
        
        await batch.commit();
        _debugPrint('PROCESO ACTUALIZADO EXITOSAMENTE A: $procesoDestino');
        
        // Verificar que se actualizó correctamente
        final verificacion = await _firestore
            .collection(COLECCION_LOTES)
            .doc(loteId)
            .collection(DATOS_GENERALES)
            .doc('info')
            .get();
            
        if (verificacion.exists) {
          _debugPrint('Verificación - proceso_actual ahora es: ${verificacion.data()!['proceso_actual']}');
        }
      } else {
        _debugPrint('Transferencia aún no completa - Falta que una de las partes complete');
      }
    } catch (e) {
      _debugPrint('ERROR verificando y actualizando transferencia: $e');
      _debugPrint('Stack trace: ${StackTrace.current}');
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
      _debugPrint('Error al obtener historial de transportes: $e');
      return [];
    }
  }
  
  /// Obtener lote completo por ID
  Future<LoteUnificadoModel?> obtenerLotePorId(String loteId) async {
    try {
      _debugPrint('=== OBTENIENDO LOTE POR ID ===');
      _debugPrint('Lote ID: $loteId');
      
      final loteRef = _firestore.collection(COLECCION_LOTES).doc(loteId);
      
      // Obtener las fases de transporte
      final Map<String, DocumentSnapshot> transporteFases = {};
      
      // Verificar fase_1
      final fase1Doc = await loteRef.collection(PROCESO_TRANSPORTE).doc('fase_1').get();
      if (fase1Doc.exists) {
        transporteFases['fase_1'] = fase1Doc;
      }
      
      // Verificar fase_2
      final fase2Doc = await loteRef.collection(PROCESO_TRANSPORTE).doc('fase_2').get();
      if (fase2Doc.exists) {
        transporteFases['fase_2'] = fase2Doc;
      }
      
      // Obtener análisis de laboratorio
      final analisisSnapshot = await loteRef
          .collection('analisis_laboratorio')
          .orderBy('fecha_toma', descending: true)
          .get();
      
      final List<DocumentSnapshot> analisisLaboratorio = analisisSnapshot.docs;
      
      // Obtener todos los datos en paralelo
      final futures = await Future.wait([
        loteRef.collection(DATOS_GENERALES).doc('info').get(),
        loteRef.collection(PROCESO_ORIGEN).doc('data').get(),
        loteRef.collection(PROCESO_RECICLADOR).doc('data').get(),
        loteRef.collection(PROCESO_TRANSFORMADOR).doc('data').get(),
      ]);
      
      _debugPrint('Resultados de las consultas:');
      _debugPrint('- Datos generales existe: ${futures[0].exists}');
      _debugPrint('- Origen existe: ${futures[1].exists}');
      _debugPrint('- Transporte fase_1 existe: ${transporteFases.containsKey('fase_1')}');
      _debugPrint('- Transporte fase_2 existe: ${transporteFases.containsKey('fase_2')}');
      _debugPrint('- Reciclador existe: ${futures[2].exists}');
      _debugPrint('- Análisis laboratorio: ${analisisLaboratorio.length} análisis');
      _debugPrint('- Transformador existe: ${futures[3].exists}');
      
      // Verificar que existan datos generales
      if (!futures[0].exists) {
        _debugPrint('ERROR: No existen datos generales para el lote');
        return null;
      }
      
      if (futures[1].exists) {
        final origenData = futures[1].data() as Map<String, dynamic>;
        _debugPrint('Datos de origen encontrados:');
        _debugPrint('- firma_operador: ${origenData['firma_operador']}');
        _debugPrint('- evidencias_foto: ${origenData['evidencias_foto']}');
      }
      
      return LoteUnificadoModel.fromFirestore(
        id: loteId,
        datosGenerales: futures[0],
        origen: futures[1].exists ? futures[1] : null,
        transporteFases: transporteFases,
        reciclador: futures[2].exists ? futures[2] : null,
        analisisLaboratorio: analisisLaboratorio,
        transformador: futures[3].exists ? futures[3] : null,
      );
    } catch (e) {
      _debugPrint('ERROR al obtener lote: $e');
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
  
  /// Obtener lotes del reciclador incluyendo transferidos sin documentación
  Stream<List<LoteUnificadoModel>> obtenerLotesRecicladorConPendientes() {
    return _firestore
        .collectionGroup(DATOS_GENERALES)
        .where('proceso_actual', whereIn: ['reciclador', 'transporte', 'transformador'])
        .orderBy('fecha_creacion', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final lotes = <LoteUnificadoModel>[];
      
      for (final doc in snapshot.docs) {
        final loteId = doc.reference.parent.parent!.id;
        final lote = await obtenerLotePorId(loteId);
        
        if (lote != null) {
          // Incluir lotes del reciclador o sublotes (tipo_lote: 'derivado')
          bool esDelReciclador = lote.reciclador != null || lote.esSublote;
          
          if (!esDelReciclador) {
            continue; // Saltar si no es del reciclador ni sublote
          }
          
          // EXCLUIR LOTES CONSUMIDOS EN TRANSFORMACIONES
          if (lote.estaConsumido) {
            continue; // Saltar lotes consumidos
          }
          
          // Incluir si está en reciclador o si fue transferido pero le falta documentación
          if (lote.datosGenerales.procesoActual == 'reciclador') {
            lotes.add(lote);
          } else if (lote.datosGenerales.procesoActual == 'transporte' || 
                     lote.datosGenerales.procesoActual == 'transformador') {
            // Verificar documentación directamente desde Firebase
            try {
              final recicladorDoc = await _firestore
                  .collection(COLECCION_LOTES)
                  .doc(loteId)
                  .collection(PROCESO_RECICLADOR)
                  .doc('data')
                  .get();
              
              if (recicladorDoc.exists) {
                final data = recicladorDoc.data() ?? {};
                final fTecnicaPellet = data['f_tecnica_pellet'];
                final repResultReci = data['rep_result_reci'];
                
                // Solo incluir si falta documentación
                if (fTecnicaPellet == null || repResultReci == null) {
                  lotes.add(lote);
                }
              }
            } catch (e) {
              _debugPrint('Error verificando documentación: $e');
            }
          }
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
          _debugPrint('Error procesando lote en obtenerMisLotesPorProceso: $e');
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
  
  /// Buscar lote por código QR o ID directo
  /// Intenta primero buscar por QR completo, si no encuentra, extrae el ID y busca por ID
  Future<LoteUnificadoModel?> buscarLotePorCodigoOId(String codigo) async {
    try {
      // Primero intentar buscar por QR completo
      var lote = await buscarLotePorQR(codigo);
      
      if (lote == null) {
        // Si no encuentra, intentar extraer el ID y buscar directamente
        final loteId = QRUtils.extractLoteIdFromQR(codigo);
        lote = await obtenerLotePorId(loteId);
      }
      
      return lote;
    } catch (e) {
      _debugPrint('Error al buscar lote por código o ID: $e');
      return null;
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
  
  /// Procesar muestra de megalote cuando el laboratorio la toma
  Future<void> procesarMuestraMegalote({
    required String qrCode,
    required double pesoMuestra,
    required String firmaOperador,
    List<String>? evidenciasFoto,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('Usuario no autenticado');
      
      // Extraer IDs del QR code: MUESTRA-MEGALOTE-transformacionId-muestraId
      final parts = qrCode.split('-');
      if (parts.length != 4 || parts[0] != 'MUESTRA' || parts[1] != 'MEGALOTE') {
        throw Exception('Código QR de muestra inválido');
      }
      
      final transformacionId = parts[2];
      final muestraId = parts[3];
      
      // Obtener la transformación
      final transformacionDoc = await _firestore
          .collection('transformaciones')
          .doc(transformacionId)
          .get();
          
      if (!transformacionDoc.exists) {
        throw Exception('Transformación no encontrada');
      }
      
      final transformacionData = transformacionDoc.data()!;
      final pesoDisponible = transformacionData['peso_disponible'] as double;
      
      // Validar peso disponible
      if (pesoMuestra > pesoDisponible) {
        throw Exception('Peso de muestra ($pesoMuestra kg) excede el peso disponible ($pesoDisponible kg)');
      }
      
      // Buscar la muestra pendiente
      final muestrasLab = List<Map<String, dynamic>>.from(
        transformacionData['muestras_laboratorio'] ?? []
      );
      
      final muestraIndex = muestrasLab.indexWhere((m) => m['id'] == muestraId);
      if (muestraIndex == -1) {
        throw Exception('Muestra no encontrada');
      }
      
      // Actualizar la muestra con el peso real
      muestrasLab[muestraIndex] = {
        ...muestrasLab[muestraIndex],
        'peso': pesoMuestra,
        'estado': 'completado',
        'fecha_toma': FieldValue.serverTimestamp(),
        'tomado_por': userId,
        'firma_operador': firmaOperador,
        if (evidenciasFoto != null) 'evidencias_foto': evidenciasFoto,
      };
      
      // Actualizar la transformación
      await _firestore.collection('transformaciones').doc(transformacionId).update({
        'peso_disponible': FieldValue.increment(-pesoMuestra),
        'muestras_laboratorio': muestrasLab,
      });
      
      _debugPrint('Muestra de megalote procesada: $muestraId con peso $pesoMuestra kg');
    } catch (e) {
      throw Exception('Error al procesar muestra de megalote: $e');
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
      _debugPrint('Error al procesar recepción en laboratorio: $e');
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
      _debugPrint('=== DEPURANDO ESTADO DEL LOTE $loteId ===');
      
      final loteRef = _firestore.collection(COLECCION_LOTES).doc(loteId);
      
      // Obtener datos generales
      final datosGeneralesDoc = await loteRef.collection(DATOS_GENERALES).doc('info').get();
      if (datosGeneralesDoc.exists) {
        _debugPrint('DATOS GENERALES:');
        final datos = datosGeneralesDoc.data()!;
        _debugPrint('- proceso_actual: ${datos['proceso_actual']}');
        _debugPrint('- estado_actual: ${datos['estado_actual']}');
        _debugPrint('- historial_procesos: ${datos['historial_procesos']}');
      } else {
        _debugPrint('ERROR: No existen datos generales');
      }
      
      // Verificar cada proceso
      final procesos = ['origen', 'transporte', 'reciclador'];
      for (final proceso in procesos) {
        final procesoDoc = await loteRef.collection(proceso).doc('data').get();
        if (procesoDoc.exists) {
          _debugPrint('\nPROCESO $proceso:');
          final datos = procesoDoc.data()!;
          _debugPrint('- fecha_entrada: ${datos['fecha_entrada']}');
          _debugPrint('- fecha_salida: ${datos['fecha_salida']}');
          _debugPrint('- entrega_completada: ${datos['entrega_completada']}');
          _debugPrint('- recepcion_completada: ${datos['recepcion_completada']}');
        }
      }
      
      _debugPrint('=== FIN DEPURACIÓN ===');
    } catch (e) {
      _debugPrint('Error en depuración: $e');
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
  
  /// Registrar análisis de laboratorio (proceso paralelo - no transfiere el lote)
  Future<void> registrarAnalisisLaboratorio({
    required String loteId,
    required double pesoMuestra,
    required String folioLaboratorio,
    String? firmaOperador,
    List<String>? evidenciasFoto,
  }) async {
    try {
      _debugPrint('=== REGISTRANDO ANÁLISIS DE LABORATORIO ===');
      _debugPrint('Lote ID: $loteId');
      _debugPrint('Peso Muestra: $pesoMuestra kg');
      _debugPrint('Folio Laboratorio: $folioLaboratorio');
      
      final loteRef = _firestore.collection(COLECCION_LOTES).doc(loteId);
      final batch = _firestore.batch();
      
      // Verificar que el lote esté en proceso reciclador
      final datosGeneralesDoc = await loteRef.collection(DATOS_GENERALES).doc('info').get();
      if (!datosGeneralesDoc.exists) {
        throw Exception('Lote no encontrado');
      }
      
      final procesoActual = datosGeneralesDoc.data()!['proceso_actual'];
      if (procesoActual != PROCESO_RECICLADOR) {
        throw Exception('El lote debe estar en proceso reciclador para tomar muestras');
      }
      
      // Generar ID único para el análisis
      final analisisId = _firestore.collection('temp').doc().id;
      
      // Crear documento de análisis
      final analisisData = {
        'id': analisisId,
        'usuario_id': _currentUserId,
        'usuario_folio': folioLaboratorio,
        'fecha_toma': FieldValue.serverTimestamp(),
        'peso_muestra': pesoMuestra,
        'firma_operador': firmaOperador,
        'evidencias_foto': evidenciasFoto ?? [],
        'certificado': null,
      };
      
      batch.set(
        loteRef.collection('analisis_laboratorio').doc(analisisId),
        analisisData,
      );
      
      // Verificar que existe el proceso reciclador
      final recicladorDoc = await loteRef.collection(PROCESO_RECICLADOR).doc('data').get();
      if (!recicladorDoc.exists) {
        throw Exception('El lote no tiene datos de reciclador');
      }
      
      // Agregar al historial que se tomó muestra (opcional)
      // No modificamos proceso_actual porque el lote sigue con el reciclador
      
      await batch.commit();
      _debugPrint('=== ANÁLISIS REGISTRADO EXITOSAMENTE ===');
      
    } catch (e) {
      _debugPrint('ERROR al registrar análisis: $e');
      throw Exception('Error al registrar análisis de laboratorio: $e');
    }
  }
  
  
  /// Obtener análisis de laboratorio de un lote
  Future<List<AnalisisLaboratorioData>> obtenerAnalisisLaboratorio(String loteId) async {
    try {
      final snapshot = await _firestore
          .collection(COLECCION_LOTES)
          .doc(loteId)
          .collection('analisis_laboratorio')
          .orderBy('fecha_toma', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => 
        AnalisisLaboratorioData.fromMap(doc.data())
      ).toList();
    } catch (e) {
      _debugPrint('Error al obtener análisis: $e');
      return [];
    }
  }
  
  /// Obtener todos los lotes que tienen análisis del laboratorio actual
  Stream<List<LoteUnificadoModel>> obtenerLotesConAnalisisLaboratorio() {
    final userId = _currentUserId;
    if (userId == null) {
      _debugPrint('No hay usuario autenticado');
      return Stream.value([]);
    }
    
    _debugPrint('=== OBTENIENDO LOTES CON ANÁLISIS DE LABORATORIO ===');
    _debugPrint('Usuario ID: $userId');
    
    return _firestore
        .collectionGroup('analisis_laboratorio')
        .where('usuario_id', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      _debugPrint('Análisis encontrados: ${snapshot.docs.length}');
      
      // Obtener IDs únicos de lotes
      final loteIds = <String>{};
      for (final doc in snapshot.docs) {
        // El ID del lote está en el path: lotes/[loteId]/analisis_laboratorio/[analisisId]
        final pathSegments = doc.reference.path.split('/');
        if (pathSegments.length >= 2) {
          loteIds.add(pathSegments[1]);
        }
      }
      
      _debugPrint('Lotes únicos con análisis: ${loteIds.length}');
      
      // Cargar los lotes completos
      final lotes = <LoteUnificadoModel>[];
      for (final loteId in loteIds) {
        final lote = await obtenerLotePorId(loteId);
        if (lote != null) {
          lotes.add(lote);
        }
      }
      
      _debugPrint('Lotes cargados exitosamente: ${lotes.length}');
      return lotes;
    });
  }
  
  /// Actualizar proceso de transformador
  Future<void> actualizarProcesoTransformador({
    required String loteId,
    required Map<String, dynamic> datosTransformador,
  }) async {
    try {
      _debugPrint('=== ACTUALIZANDO PROCESO TRANSFORMADOR ===');
      _debugPrint('Lote ID: $loteId');
      _debugPrint('Datos: $datosTransformador');
      
      final loteRef = _firestore.collection(COLECCION_LOTES).doc(loteId);
      final batch = _firestore.batch();
      
      // Verificar que el lote existe
      final datosGeneralesDoc = await loteRef.collection(DATOS_GENERALES).doc('info').get();
      if (!datosGeneralesDoc.exists) {
        throw Exception('Lote no encontrado');
      }
      
      // Verificar que el lote está en proceso transformador
      final procesoActual = datosGeneralesDoc.data()!['proceso_actual'];
      if (procesoActual != PROCESO_TRANSFORMADOR) {
        throw Exception('El lote debe estar en proceso transformador');
      }
      
      // Verificar que existe el documento del transformador
      final transformadorDoc = await loteRef.collection(PROCESO_TRANSFORMADOR).doc('data').get();
      if (!transformadorDoc.exists) {
        throw Exception('No se encontraron datos del proceso transformador');
      }
      
      // Actualizar datos del transformador con los campos de salida
      final transformadorData = transformadorDoc.data()!;
      transformadorData.addAll(datosTransformador);
      
      batch.update(
        loteRef.collection(PROCESO_TRANSFORMADOR).doc('data'),
        transformadorData,
      );
      
      // Si el estado cambia, actualizar también en datos generales
      if (datosTransformador['estado'] != null) {
        batch.update(
          loteRef.collection(DATOS_GENERALES).doc('info'),
          {
            'estado': datosTransformador['estado'],
            'fecha_actualizacion': FieldValue.serverTimestamp(),
          },
        );
      }
      
      await batch.commit();
      _debugPrint('=== PROCESO TRANSFORMADOR ACTUALIZADO EXITOSAMENTE ===');
      
    } catch (e) {
      _debugPrint('ERROR al actualizar proceso transformador: $e');
      throw Exception('Error al actualizar proceso de transformador: $e');
    }
  }
  
  /// Obtener todos los lotes completos para el repositorio
  Stream<List<LoteUnificadoModel>> obtenerTodosLotesRepositorio({
    String? searchQuery,
    String? tipoMaterial,
    String? procesoActual,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) {
    _debugPrint('=== OBTENIENDO LOTES PARA REPOSITORIO ===');
    _debugPrint('Filtros: searchQuery=$searchQuery, tipoMaterial=$tipoMaterial, procesoActual=$procesoActual');
    
    Query<Map<String, dynamic>> query = _firestore.collection(COLECCION_LOTES);
    
    // No aplicar filtros de Firebase para poder hacer búsquedas más complejas en memoria
    
    return query.snapshots().asyncMap((snapshot) async {
      _debugPrint('Lotes encontrados: ${snapshot.docs.length}');
      
      final lotes = <LoteUnificadoModel>[];
      
      for (final doc in snapshot.docs) {
        try {
          final lote = await obtenerLotePorId(doc.id);
          if (lote != null) {
            // Aplicar filtros en memoria
            bool incluir = true;
            
            // Filtro por búsqueda
            if (searchQuery != null && searchQuery.isNotEmpty) {
              final query = searchQuery.toLowerCase();
              incluir = lote.id.toLowerCase().contains(query) ||
                       (lote.datosGenerales.tipoMaterial != null && lote.datosGenerales.tipoMaterial!.toLowerCase().contains(query));
            }
            
            // Filtro por tipo de material
            if (incluir && tipoMaterial != null && tipoMaterial != 'Todos') {
              incluir = lote.datosGenerales.tipoMaterial == tipoMaterial;
            }
            
            // Filtro por proceso actual
            if (incluir && procesoActual != null && procesoActual != 'Todos') {
              incluir = lote.datosGenerales.procesoActual == procesoActual;
            }
            
            // Filtro por fecha
            if (incluir && fechaInicio != null) {
              incluir = lote.datosGenerales.fechaCreacion.isAfter(fechaInicio);
            }
            
            if (incluir && fechaFin != null) {
              incluir = lote.datosGenerales.fechaCreacion.isBefore(fechaFin);
            }
            
            if (incluir) {
              lotes.add(lote);
            }
          }
        } catch (e) {
          _debugPrint('Error al construir lote ${doc.id}: $e');
        }
      }
      
      // Ordenar por fecha de creación descendente
      lotes.sort((a, b) => b.datosGenerales.fechaCreacion.compareTo(a.datosGenerales.fechaCreacion));
      
      _debugPrint('Lotes filtrados: ${lotes.length}');
      return lotes;
    });
  }


  /// Obtener estadísticas del reciclador
  /// - lotesRecibidos: Total de lotes aceptados a través del escáner (independiente del estado actual)
  /// - megalotesCreados: Total de megalotes (transformaciones) creados por el usuario
  /// - materialProcesado: Suma del peso de entrada de todos los megalotes creados
  Future<Map<String, dynamic>> obtenerEstadisticasReciclador() async {
    try {
      final userId = _currentUserId;
      debugPrint('=== OBTENIENDO ESTADÍSTICAS RECICLADOR ===');
      debugPrint('Usuario ID: $userId');
      
      if (userId == null) {
        debugPrint('No hay usuario autenticado');
        return {
          'lotesRecibidos': 0,
          'megalotesCreados': 0,
          'materialProcesado': 0.0,
        };
      }

      int lotesRecibidos = 0;
      int megalotesCreados = 0;
      double materialProcesado = 0.0;

      // 1. Obtener todas las transformaciones del usuario para contar lotes y megalotes
      debugPrint('Obteniendo transformaciones del usuario...');
      
      // Nueva estrategia: contar lotes únicos desde las transformaciones del usuario
      final transformacionesUsuario = await _firestore
          .collection('transformaciones')
          .where('usuario_id', isEqualTo: userId)
          .get();
      
      Set<String> lotesUnicos = {};
      
      for (final transformDoc in transformacionesUsuario.docs) {
        final data = transformDoc.data();
        final lotesEntrada = data['lotes_entrada'] as List<dynamic>?;
        
        if (lotesEntrada != null) {
          for (var lote in lotesEntrada) {
            if (lote is Map<String, dynamic>) {
              final loteId = lote['lote_id'] as String?;
              if (loteId != null) {
                lotesUnicos.add(loteId);
              }
            }
          }
        }
      }
      
      lotesRecibidos = lotesUnicos.length;
      debugPrint('Lotes únicos recibidos (desde transformaciones): $lotesRecibidos');

      // 2. Contar megalotes creados y sumar material procesado
      // Ya tenemos las transformaciones del usuario, usarlas
      megalotesCreados = transformacionesUsuario.docs.length;
      debugPrint('\nMegalotes creados: $megalotesCreados');
      
      // Sumar el peso de entrada de todos los megalotes
      for (final transformacionDoc in transformacionesUsuario.docs) {
        final data = transformacionDoc.data();
        final pesoTotalEntrada = (data['peso_total_entrada'] as num?)?.toDouble() ?? 0.0;
        materialProcesado += pesoTotalEntrada;
        debugPrint('Transformación ${transformacionDoc.id} - Peso: $pesoTotalEntrada kg');
      }

      debugPrint('=== ESTADÍSTICAS RECICLADOR ===');
      debugPrint('Lotes recibidos: $lotesRecibidos');
      debugPrint('Megalotes creados: $megalotesCreados');
      debugPrint('Material procesado: $materialProcesado kg');

      return {
        'lotesRecibidos': lotesRecibidos,
        'megalotesCreados': megalotesCreados,
        'materialProcesado': materialProcesado,
      };
    } catch (e) {
      debugPrint('Error obteniendo estadísticas del reciclador: $e');
      return {
        'lotesRecibidos': 0,
        'megalotesCreados': 0,
        'materialProcesado': 0.0,
      };
    }
  }

  /// Stream de estadísticas del reciclador en tiempo real
  Stream<Map<String, dynamic>> streamEstadisticasReciclador() {
    final userId = _currentUserId;
    
    if (userId == null) {
      return Stream.value({
        'lotesRecibidos': 0,
        'megalotesCreados': 0,
        'materialProcesado': 0.0,
      });
    }

    // Stream solo de transformaciones ya que los lotes se cuentan desde ahí
    return _firestore
        .collection('transformaciones')
        .where('usuario_id', isEqualTo: userId)
        .snapshots()
        .map((transformacionesSnapshot) {
          int lotesRecibidos = 0;
          int megalotesCreados = 0;
          double materialProcesado = 0.0;
          
          Set<String> lotesUnicos = {};
          
          // Contar megalotes
          megalotesCreados = transformacionesSnapshot.docs.length;
          
          // Contar lotes únicos y sumar material procesado
          for (final transformacionDoc in transformacionesSnapshot.docs) {
            final data = transformacionDoc.data();
            
            // Contar lotes únicos
            final lotesEntrada = data['lotes_entrada'] as List<dynamic>?;
            if (lotesEntrada != null) {
              for (var lote in lotesEntrada) {
                if (lote is Map<String, dynamic>) {
                  final loteId = lote['lote_id'] as String?;
                  if (loteId != null) {
                    lotesUnicos.add(loteId);
                  }
                }
              }
            }
            
            // Sumar peso
            final pesoTotalEntrada = (data['peso_total_entrada'] as num?)?.toDouble() ?? 0.0;
            materialProcesado += pesoTotalEntrada;
          }
          
          lotesRecibidos = lotesUnicos.length;
          
          return {
            'lotesRecibidos': lotesRecibidos,
            'megalotesCreados': megalotesCreados,
            'materialProcesado': materialProcesado,
          };
        });
  }
  
  // ============= MÉTODOS PARA SISTEMA DE TRANSFORMACIONES =============
  
  /// Obtiene lotes del reciclador que pueden ser transformados
  Stream<List<LoteUnificadoModel>> obtenerLotesTransformables() {
    final userId = _currentUserId;
    if (userId == null) {
      _debugPrint('No hay usuario autenticado');
      return Stream.value([]);
    }
    
    return _firestore
        .collection(COLECCION_LOTES)
        .where('datos_generales.proceso_actual', isEqualTo: 'reciclador')
        .where('datos_generales.tipo_lote', isEqualTo: 'original')
        .where('datos_generales.consumido_en_transformacion', isEqualTo: false)
        .snapshots()
        .asyncMap((snapshot) async {
      List<LoteUnificadoModel> lotes = [];
      
      for (var doc in snapshot.docs) {
        try {
          final lote = await obtenerLotePorId(doc.id);
          if (lote != null && lote.puedeSerTransformado) {
            // Verificar que el lote pertenece al reciclador actual
            if (lote.reciclador?.usuarioId == userId) {
              lotes.add(lote);
            }
          }
        } catch (e) {
          _debugPrint('Error procesando lote ${doc.id}: $e');
        }
      }
      
      return lotes;
    });
  }
  
  /// Marca múltiples lotes como consumidos en una transformación
  Future<void> marcarLotesComoConsumidos({
    required List<String> loteIds,
    required String transformacionId,
  }) async {
    try {
      // Usar batch para actualizar múltiples documentos
      final batch = _firestore.batch();
      
      for (final loteId in loteIds) {
        final datosGeneralesRef = _firestore
            .collection(COLECCION_LOTES)
            .doc(loteId)
            .collection(DATOS_GENERALES)
            .doc('info');
            
        batch.update(datosGeneralesRef, {
          'consumido_en_transformacion': true,
          'transformacion_id': transformacionId,
          'fecha_consumido': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      _debugPrint('${loteIds.length} lotes marcados como consumidos en transformación $transformacionId');
    } catch (e) {
      _debugPrint('Error al marcar lotes como consumidos: $e');
      throw Exception('Error al marcar lotes como consumidos: $e');
    }
  }
  
  /// Crea un lote en el sistema unificado a partir de un sublote
  Future<void> crearLoteDesdeSubLote({
    required String subloteId,
    required Map<String, dynamic> datosSubLote,
  }) async {
    try {
      // Crear estructura de lote unificado
      final loteRef = _firestore.collection(COLECCION_LOTES).doc(subloteId);
      
      // Datos generales
      await loteRef.collection(DATOS_GENERALES).doc('info').set({
        'id': subloteId,
        'fecha_creacion': FieldValue.serverTimestamp(),
        'creado_por': datosSubLote['creado_por'],
        'tipo_material': datosSubLote['material_predominante'] ?? 'Mixto',
        'peso_inicial': datosSubLote['peso'],
        'peso': datosSubLote['peso'],
        'estado_actual': 'activo',
        'proceso_actual': 'reciclador',
        'historial_procesos': ['reciclador'],
        'qr_code': datosSubLote['qr_code'],
        'tipo_lote': 'derivado',
        'consumido_en_transformacion': false,
        'sublote_origen_id': subloteId,
        'transformacion_origen': datosSubLote['transformacion_origen'],
      });
      
      // Proceso reciclador
      await loteRef.collection(PROCESO_RECICLADOR).doc('data').set({
        'usuario_id': datosSubLote['creado_por'],
        'usuario_folio': datosSubLote['creado_por_folio'],
        'fecha_entrada': FieldValue.serverTimestamp(),
        'peso_entrada': datosSubLote['peso'],
        'evidencias_foto': [],
        'es_sublote': true,
        'composicion': datosSubLote['composicion'] ?? {},
      });
      
      _debugPrint('Lote creado desde sublote: $subloteId');
    } catch (e) {
      _debugPrint('Error al crear lote desde sublote: $e');
      throw Exception('Error al crear lote desde sublote: $e');
    }
  }
  
  /// Obtiene lotes del reciclador incluyendo sublotes
  Stream<List<LoteUnificadoModel>> obtenerLotesRecicladorConSublotes() {
    final userId = _currentUserId;
    if (userId == null) {
      _debugPrint('No hay usuario autenticado');
      return Stream.value([]);
    }
    
    return _firestore
        .collection(COLECCION_LOTES)
        .where('datos_generales.proceso_actual', isEqualTo: 'reciclador')
        .snapshots()
        .asyncMap((snapshot) async {
      List<LoteUnificadoModel> lotes = [];
      
      for (var doc in snapshot.docs) {
        try {
          final lote = await obtenerLotePorId(doc.id);
          if (lote != null && lote.reciclador?.usuarioId == userId) {
            lotes.add(lote);
          }
        } catch (e) {
          _debugPrint('Error procesando lote ${doc.id}: $e');
        }
      }
      
      // Ordenar: primero lotes originales no consumidos, luego sublotes, luego consumidos
      lotes.sort((a, b) {
        if (a.estaConsumido && !b.estaConsumido) return 1;
        if (!a.estaConsumido && b.estaConsumido) return -1;
        if (a.esSublote && !b.esSublote) return 1;
        if (!a.esSublote && b.esSublote) return -1;
        return b.datosGenerales.fechaCreacion.compareTo(a.datosGenerales.fechaCreacion);
      });
      
      return lotes;
    });
  }
}