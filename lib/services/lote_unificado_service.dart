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

  /// Verificar si ambas partes han completado la transferencia (actualizado para subfases)
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
        print('VERIFICACIÓN ORIGEN ($procesoOrigen):');
        print('  Campos relevantes: ${datosOrigen.keys.toList()}');
        
        // Verificar si el origen ha completado su parte
        tieneEntrega = datosOrigen['entrega_completada'] == true || 
                      datosOrigen['fecha_salida'] != null || 
                      datosOrigen['firma_entrega'] != null ||
                      datosOrigen['firma_salida'] != null ||  // Agregar verificación de firma_salida
                      datosOrigen['firma_conductor'] != null; // Para transportista
        print('  - Origen existe: $origenExiste');
        print('  - Tiene Entrega: $tieneEntrega');
        print('  - entrega_completada: ${datosOrigen['entrega_completada']}');
        print('  - fecha_salida: ${datosOrigen['fecha_salida']}');
        print('  - firma_entrega: ${datosOrigen['firma_entrega']}');
        print('  - firma_salida: ${datosOrigen['firma_salida']}');
        print('  - firma_conductor: ${datosOrigen['firma_conductor']}');
        print('  - entregado_a: ${datosOrigen['entregado_a']}');
      } else {
        print('ADVERTENCIA: Documento origen ($procesoOrigen) no existe');
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
      
      if (destinoDoc != null && destinoDoc.exists) {
        destinoExiste = true;
        final datosDestino = destinoDoc.data() as Map<String, dynamic>;
        print('VERIFICACIÓN DESTINO ($procesoDestino):');
        print('  Campos relevantes: ${datosDestino.keys.toList()}');
        
        // Verificar si el destino ha completado su parte
        tieneRecepcion = datosDestino['recepcion_completada'] == true ||
                        datosDestino['firma_operador'] != null ||
                        datosDestino['firma_recepcion'] != null ||
                        datosDestino['peso_recibido'] != null ||
                        datosDestino['peso_entrada'] != null ||
                        datosDestino['fecha_entrada'] != null;  // Agregar verificación de fecha_entrada
        print('  - Destino existe: $destinoExiste');
        print('  - Tiene Recepción: $tieneRecepcion');
        print('  - recepcion_completada: ${datosDestino['recepcion_completada']}');
        print('  - firma_operador: ${datosDestino['firma_operador']}');
        print('  - firma_recepcion: ${datosDestino['firma_recepcion']}');
        print('  - peso_recibido: ${datosDestino['peso_recibido']}');
        print('  - peso_entrada: ${datosDestino['peso_entrada']}');
        print('  - fecha_entrada: ${datosDestino['fecha_entrada']}');
      } else {
        print('ADVERTENCIA: Documento destino ($procesoDestino) no existe');
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
        print('RESULTADO: Transferencia Reciclador->Transporte - Destino existe: $destinoExiste, Tiene recepción: $tieneRecepcion');
        print('DEBUG - OrigenExiste: $origenExiste, TieneEntrega: $tieneEntrega');
        print('DEBUG - Este caso ES unidireccional, resultado: $resultado');
      } else if (origenExiste && destinoExiste) {
        // Caso normal: ambos existen (para otros flujos)
        resultado = tieneEntrega && tieneRecepcion;
        print('RESULTADO: Ambos existen - Entrega: $tieneEntrega, Recepción: $tieneRecepcion');
      } else if (!origenExiste && destinoExiste && tieneRecepcion) {
        // Caso especial: solo el destino ha completado (recepción anticipada)
        // En este caso, esperamos a que el origen complete
        resultado = false;
        print('RESULTADO: Solo destino existe con recepción - Esperando origen');
      } else if (origenExiste && !destinoExiste && tieneEntrega) {
        // Caso especial: solo el origen ha completado (entrega anticipada)
        // En este caso, esperamos a que el destino complete
        resultado = false;
        print('RESULTADO: Solo origen existe con entrega - Esperando destino');
      } else {
        print('RESULTADO: Ninguna condición cumplida');
      }
      
      print('Transferencia Completa: $resultado');
      print('=====================================');
      
      return resultado;
    } catch (e) {
      print('Error verificando transferencia: $e');
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
      
      // Determinar si es una fase de transporte
      String procesoRealDestino = procesoDestino;
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
        print('Fase de transporte determinada: $faseTransporte');
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
        print('TRANSFERENCIA COMPLETA DETECTADA - Actualizando proceso_actual a: $procesoDestino');
        
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
      
      print('Actualizando transporte fase: $faseTransporte');
      
      await loteRef
          .collection(PROCESO_TRANSPORTE)
          .doc(faseTransporte)
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
  
  /// Verificar y actualizar transferencia después de que ambas partes completen
  Future<void> verificarYActualizarTransferencia({
    required String loteId,
    required String procesoOrigen,
    required String procesoDestino,
  }) async {
    try {
      print('=== VERIFICANDO Y ACTUALIZANDO TRANSFERENCIA ===');
      print('Lote: $loteId, Origen: $procesoOrigen, Destino: $procesoDestino');
      
      // Primero verificar el estado actual del lote
      final datosGeneralesDoc = await _firestore
          .collection(COLECCION_LOTES)
          .doc(loteId)
          .collection(DATOS_GENERALES)
          .doc('info')
          .get();
          
      if (datosGeneralesDoc.exists) {
        final procesoActualActual = datosGeneralesDoc.data()!['proceso_actual'];
        print('Proceso actual en DB: $procesoActualActual');
      }
      
      // Verificar si la transferencia está completa
      final esCompleta = await verificarTransferenciaCompleta(
        loteId: loteId,
        procesoOrigen: procesoOrigen,
        procesoDestino: procesoDestino,
      );
      
      if (esCompleta) {
        print('Transferencia completa detectada, actualizando proceso_actual...');
        
        // Actualizar proceso_actual y estado
        final batch = _firestore.batch();
        final loteRef = _firestore.collection(COLECCION_LOTES).doc(loteId);
        
        // Determinar fase de transporte si aplica
        String historialEntry = procesoDestino;
        if (procesoDestino == PROCESO_TRANSPORTE) {
          String faseTransporte = procesoOrigen == PROCESO_ORIGEN ? 'fase_1' : 'fase_2';
          historialEntry = '${PROCESO_TRANSPORTE}_$faseTransporte';
          print('Agregando al historial: $historialEntry');
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
        print('PROCESO ACTUALIZADO EXITOSAMENTE A: $procesoDestino');
        
        // Verificar que se actualizó correctamente
        final verificacion = await _firestore
            .collection(COLECCION_LOTES)
            .doc(loteId)
            .collection(DATOS_GENERALES)
            .doc('info')
            .get();
            
        if (verificacion.exists) {
          print('Verificación - proceso_actual ahora es: ${verificacion.data()!['proceso_actual']}');
        }
      } else {
        print('Transferencia aún no completa - Falta que una de las partes complete');
      }
    } catch (e) {
      print('ERROR verificando y actualizando transferencia: $e');
      print('Stack trace: ${StackTrace.current}');
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
      
      print('Resultados de las consultas:');
      print('- Datos generales existe: ${futures[0]?.exists ?? false}');
      print('- Origen existe: ${futures[1]?.exists ?? false}');
      print('- Transporte fase_1 existe: ${transporteFases.containsKey('fase_1')}');
      print('- Transporte fase_2 existe: ${transporteFases.containsKey('fase_2')}');
      print('- Reciclador existe: ${futures[2]?.exists ?? false}');
      print('- Análisis laboratorio: ${analisisLaboratorio.length} análisis');
      print('- Transformador existe: ${futures[3]?.exists ?? false}');
      
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
        transporteFases: transporteFases,
        reciclador: (futures[2] != null && futures[2]!.exists) ? futures[2] : null,
        analisisLaboratorio: analisisLaboratorio,
        transformador: (futures[3] != null && futures[3]!.exists) ? futures[3] : null,
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
      print('Error al buscar lote por código o ID: $e');
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
  
  /// Registrar análisis de laboratorio (proceso paralelo - no transfiere el lote)
  Future<void> registrarAnalisisLaboratorio({
    required String loteId,
    required double pesoMuestra,
    required String folioLaboratorio,
    String? firmaOperador,
    List<String>? evidenciasFoto,
  }) async {
    try {
      print('=== REGISTRANDO ANÁLISIS DE LABORATORIO ===');
      print('Lote ID: $loteId');
      print('Peso Muestra: $pesoMuestra kg');
      print('Folio Laboratorio: $folioLaboratorio');
      
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
      
      // Actualizar el peso en el proceso reciclador
      final recicladorDoc = await loteRef.collection(PROCESO_RECICLADOR).doc('data').get();
      if (recicladorDoc.exists) {
        final pesoActual = recicladorDoc.data()!['peso_procesado'] ?? 
                          recicladorDoc.data()!['peso_entrada'] ?? 0.0;
        
        // NO actualizamos el peso del reciclador aquí
        // El peso se calculará dinámicamente en el modelo
        // Esto mantiene la integridad de los datos originales
      }
      
      // Agregar al historial que se tomó muestra (opcional)
      // No modificamos proceso_actual porque el lote sigue con el reciclador
      
      await batch.commit();
      print('=== ANÁLISIS REGISTRADO EXITOSAMENTE ===');
      
    } catch (e) {
      print('ERROR al registrar análisis: $e');
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
      print('Error al obtener análisis: $e');
      return [];
    }
  }
  
  /// Obtener todos los lotes que tienen análisis del laboratorio actual
  Stream<List<LoteUnificadoModel>> obtenerLotesConAnalisisLaboratorio() {
    final userId = _currentUserId;
    if (userId == null) {
      print('No hay usuario autenticado');
      return Stream.value([]);
    }
    
    print('=== OBTENIENDO LOTES CON ANÁLISIS DE LABORATORIO ===');
    print('Usuario ID: $userId');
    
    return _firestore
        .collectionGroup('analisis_laboratorio')
        .where('usuario_id', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      print('Análisis encontrados: ${snapshot.docs.length}');
      
      // Obtener IDs únicos de lotes
      final loteIds = <String>{};
      for (final doc in snapshot.docs) {
        // El ID del lote está en el path: lotes/[loteId]/analisis_laboratorio/[analisisId]
        final pathSegments = doc.reference.path.split('/');
        if (pathSegments.length >= 2) {
          loteIds.add(pathSegments[1]);
        }
      }
      
      print('Lotes únicos con análisis: ${loteIds.length}');
      
      // Cargar los lotes completos
      final lotes = <LoteUnificadoModel>[];
      for (final loteId in loteIds) {
        final lote = await obtenerLotePorId(loteId);
        if (lote != null) {
          lotes.add(lote);
        }
      }
      
      print('Lotes cargados exitosamente: ${lotes.length}');
      return lotes;
    });
  }
}