import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/models/lotes/lote_origen_model.dart';
import 'package:app/models/lotes/lote_transportista_model.dart';
import 'package:app/models/lotes/lote_reciclador_model.dart';
import 'package:app/models/lotes/lote_laboratorio_model.dart';
import 'package:app/models/lotes/lote_transformador_model.dart';
import 'package:app/services/firebase/auth_service.dart';
import 'package:app/services/firebase/firebase_manager.dart';

class LoteService {
  final FirebaseManager _firebaseManager = FirebaseManager();
  final AuthService _authService = AuthService();
  
  // Obtener Firestore de la instancia correcta
  FirebaseFirestore get _firestore {
    final app = _firebaseManager.currentApp;
    if (app == null) {
      return FirebaseFirestore.instance;
    }
    return FirebaseFirestore.instanceFor(app: app);
  }
  
  // Obtener el ID del usuario actual de la instancia correcta
  String? get _currentUserId => _authService.currentUser?.uid;

  // Colecciones por tipo de usuario
  static const String LOTES_ORIGEN = 'lotes_origen';
  static const String LOTES_TRANSPORTISTA = 'lotes_transportista';
  static const String LOTES_RECICLADOR = 'lotes_reciclador';
  static const String LOTES_LABORATORIO = 'lotes_laboratorio';
  static const String LOTES_TRANSFORMADOR = 'lotes_transformador';
  
  // Nueva colección unificada
  static const String LOTES = 'lotes';

  // === ORIGEN ===
  Future<String> crearLoteOrigen(LoteOrigenModel lote) async {
    try {
      final docRef = await _firestore.collection(LOTES_ORIGEN).add(lote.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear lote de origen: $e');
    }
  }

  Stream<List<LoteOrigenModel>> getLotesOrigen() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);
    
    // Buscar en la nueva estructura unificada - simplificado para evitar índices complejos
    return _firestore
        .collectionGroup('datos_generales')
        .where('creado_por', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          List<LoteOrigenModel> lotes = [];
          
          for (var doc in snapshot.docs) {
            final data = doc.data();
            
            // Filtrar solo lotes en proceso origen
            if (data['proceso_actual'] != 'origen') continue;
            
            // Extraer el ID del lote del path del documento
            final pathParts = doc.reference.path.split('/');
            if (pathParts.length >= 2) {
              final loteId = pathParts[pathParts.length - 3]; // lotes/[ID]/datos_generales/info
              
              try {
                // Obtener los datos completos del proceso origen
                final origenDoc = await _firestore
                    .collection(LOTES)
                    .doc(loteId)
                    .collection('origen')
                    .doc('data')
                    .get();
                    
                if (origenDoc.exists) {
                  final origenData = origenDoc.data()!;
                  
                  // Crear un LoteOrigenModel con todos los datos
                  lotes.add(LoteOrigenModel(
                    id: loteId,
                    userId: userId,
                    fechaNace: data['fecha_creacion'] != null 
                        ? (data['fecha_creacion'] as Timestamp).toDate() 
                        : DateTime.now(),
                    direccion: origenData['direccion'] ?? 'Sin dirección',
                    fuente: origenData['fuente'] ?? '',
                    presentacion: origenData['presentacion'] ?? '',
                    tipoPoli: origenData['tipo_poli'] ?? '',
                    origen: origenData['origen'] ?? 'Post-consumo',
                    pesoNace: (origenData['peso_nace'] as num?)?.toDouble() ?? 0.0,
                    condiciones: origenData['condiciones'] ?? '',
                    nombreOpe: origenData['nombre_operador'] ?? '',
                    firmaOpe: origenData['firma_operador'],
                    comentarios: origenData['comentarios'],
                    eviFoto: List<String>.from(origenData['evidencias_foto'] ?? []),
                  ));
                }
              } catch (e) {
                // Si falla obtener los datos de origen, usar datos generales
                lotes.add(LoteOrigenModel(
                  id: loteId,
                  userId: userId,
                  fechaNace: data['fecha_creacion'] != null 
                      ? (data['fecha_creacion'] as Timestamp).toDate() 
                      : DateTime.now(),
                  direccion: 'Sin dirección',
                  fuente: data['material_fuente'] ?? '',
                  presentacion: data['material_presentacion'] ?? '',
                  tipoPoli: data['material_tipo'] ?? '',
                  origen: 'Post-consumo',
                  pesoNace: (data['peso'] as num?)?.toDouble() ?? 0.0,
                  condiciones: '',
                  nombreOpe: data['origen_nombre'] ?? '',
                  eviFoto: [],
                ));
              }
            }
          }
          
          // Ordenar manualmente por fecha
          lotes.sort((a, b) => b.fechaNace.compareTo(a.fechaNace));
          
          return lotes;
        });
  }

  Future<LoteOrigenModel?> getLoteOrigenById(String id) async {
    try {
      // Buscar en la nueva estructura unificada
      final datosDoc = await _firestore
          .collection(LOTES)
          .doc(id)
          .collection('datos_generales')
          .doc('info')
          .get();
          
      if (datosDoc.exists) {
        final data = datosDoc.data()!;
        
        // Obtener también los datos específicos del proceso origen
        final origenDoc = await _firestore
            .collection(LOTES)
            .doc(id)
            .collection('origen')
            .doc('data')
            .get();
            
        if (origenDoc.exists) {
          final origenData = origenDoc.data()!;
          
          return LoteOrigenModel(
            id: id,
            userId: data['creado_por'] ?? _currentUserId ?? '',
            fechaNace: data['fecha_creacion'] != null 
                ? (data['fecha_creacion'] as Timestamp).toDate() 
                : DateTime.now(),
            direccion: origenData['direccion'] ?? 'Sin dirección',
            fuente: origenData['fuente'] ?? '',
            presentacion: origenData['presentacion'] ?? '',
            tipoPoli: origenData['tipo_poli'] ?? '',
            origen: origenData['origen'] ?? 'Post-consumo',
            pesoNace: (origenData['peso_nace'] as num?)?.toDouble() ?? 0.0,
            condiciones: origenData['condiciones'] ?? '',
            nombreOpe: origenData['nombre_operador'] ?? '',
            firmaOpe: origenData['firma_operador'],
            comentarios: origenData['comentarios'],
            eviFoto: List<String>.from(origenData['evidencias_foto'] ?? []),
          );
        } else {
          // Si no hay datos de origen, usar solo datos generales
          return LoteOrigenModel(
            id: id,
            userId: data['creado_por'] ?? _currentUserId ?? '',
            fechaNace: data['fecha_creacion'] != null 
                ? (data['fecha_creacion'] as Timestamp).toDate() 
                : DateTime.now(),
            direccion: 'Sin dirección',
            fuente: data['material_fuente'] ?? '',
            presentacion: data['material_presentacion'] ?? '',
            tipoPoli: data['material_tipo'] ?? '',
            origen: 'Post-consumo',
            pesoNace: (data['peso'] as num?)?.toDouble() ?? 0.0,
            condiciones: '',
            nombreOpe: data['origen_nombre'] ?? '',
            eviFoto: [],
          );
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener lote de origen: $e');
    }
  }

  // === TRANSPORTISTA ===
  Future<String> crearLoteTransportista(LoteTransportistaModel lote) async {
    try {
      final docRef = await _firestore.collection(LOTES_TRANSPORTISTA).add(lote.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear lote de transportista: $e');
    }
  }

  Future<void> actualizarLoteTransportista(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(LOTES_TRANSPORTISTA).doc(id).update(data);
    } catch (e) {
      throw Exception('Error al actualizar lote de transportista: $e');
    }
  }

  Stream<List<LoteTransportistaModel>> getLotesTransportista({String? estado}) {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);
    
    Query query = _firestore.collection(LOTES_TRANSPORTISTA)
        .where('userId', isEqualTo: userId);
    
    if (estado != null) {
      query = query.where('estado', isEqualTo: estado);
    }
    
    return query
        .orderBy('ecoce_transportista_fecha_recepcion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LoteTransportistaModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<LoteTransportistaModel>> getLotesTransportistaByUserId({
    required String userId,
    String? estado,
  }) {
    Query query = _firestore.collection(LOTES_TRANSPORTISTA)
        .where('userId', isEqualTo: userId);
    
    if (estado != null) {
      query = query.where('estado', isEqualTo: estado);
    }
    
    return query
        .orderBy('ecoce_transportista_fecha_recepcion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LoteTransportistaModel.fromFirestore(doc))
            .toList());
  }

  // === RECICLADOR ===
  Future<String> crearLoteReciclador(LoteRecicladorModel lote) async {
    try {
      final docRef = await _firestore.collection(LOTES_RECICLADOR).add(lote.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear lote de reciclador: $e');
    }
  }

  Future<void> actualizarLoteReciclador(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(LOTES_RECICLADOR).doc(id).update(data);
    } catch (e) {
      throw Exception('Error al actualizar lote de reciclador: $e');
    }
  }

  Stream<List<LoteRecicladorModel>> getLotesReciclador({String? estado}) {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);
    
    // Primero intentar obtener lotes del sistema unificado
    return _firestore
        .collectionGroup('datos_generales')
        .where('proceso_actual', isEqualTo: 'reciclador')
        .snapshots()
        .asyncMap((snapshot) async {
      final lotes = <LoteRecicladorModel>[];
      
      for (final doc in snapshot.docs) {
        try {
          // Obtener el ID del lote desde la ruta del documento
          final pathSegments = doc.reference.path.split('/');
          final loteId = pathSegments[pathSegments.length - 3];
          
          // Obtener el documento del proceso reciclador
          final recicladorDoc = await _firestore
              .collection('lotes')
              .doc(loteId)
              .collection('reciclador')
              .doc('data')
              .get();
          
          if (recicladorDoc.exists) {
            final recicladorData = recicladorDoc.data()!;
            final datosGenerales = doc.data();
            
            // Verificar que sea del usuario actual
            if (recicladorData['usuario_id'] != userId) continue;
            
            // Obtener el tipo de polímero del material
            final tipoMaterial = datosGenerales['material_tipo'] ?? '';
            Map<String, double> tipoPoliMap = {};
            
            // Crear mapa de tipo poli según el material
            if (tipoMaterial.isNotEmpty) {
              tipoPoliMap[tipoMaterial] = 100.0; // 100% del material especificado
            }
            
            // Crear modelo compatible con LoteRecicladorModel
            final loteModel = LoteRecicladorModel(
              id: loteId,
              userId: recicladorData['usuario_id'] ?? '',
              conjuntoLotes: [loteId], // Por ahora solo el lote actual
              loteEntrada: loteId,
              tipoPoli: tipoPoliMap.isNotEmpty ? tipoPoliMap : null,
              pesoBruto: (recicladorData['peso_bruto'] ?? recicladorData['peso_entrada'] ?? 0.0).toDouble(),
              pesoNeto: (recicladorData['peso_neto'] ?? 0.0).toDouble(),
              nombreOpeEntrada: recicladorData['operador_nombre'] ?? '',
              firmaEntrada: recicladorData['firma_operador'],
              // Datos de salida
              pesoResultante: (recicladorData['peso_neto_salida'] ?? 0.0).toDouble(),
              merma: (recicladorData['merma'] ?? 0.0).toDouble(),
              procesos: recicladorData['procesos_aplicados'] != null 
                  ? List<String>.from(recicladorData['procesos_aplicados']) 
                  : [],
              nombreOpeSalida: recicladorData['operador_salida_nombre'],
              firmaSalida: recicladorData['firma_salida'],
              eviFoto: recicladorData['evidencias_foto'] != null 
                  ? List<String>.from(recicladorData['evidencias_foto']) 
                  : [],
              observaciones: recicladorData['comentarios'],
              // Documentación
              fTecnicaPellet: recicladorData['f_tecnica_pellet'],
              repResultReci: recicladorData['rep_result_reci'],
              // Estado
              estado: _mapearEstadoReciclador(recicladorData),
            );
            
            // Aplicar filtro de estado si se especifica
            if (estado == null || loteModel.estado == estado) {
              lotes.add(loteModel);
            }
          }
        } catch (e) {
          print('Error procesando lote del sistema unificado: $e');
        }
      }
      
      // También buscar en la colección antigua para compatibilidad
      Query query = _firestore.collection(LOTES_RECICLADOR)
          .where('userId', isEqualTo: userId);
      
      if (estado != null) {
        query = query.where('estado', isEqualTo: estado);
      }
      
      try {
        final oldSnapshot = await query
            .orderBy('fecha_creacion', descending: true)
            .get();
            
        for (var doc in oldSnapshot.docs) {
          lotes.add(LoteRecicladorModel.fromFirestore(doc));
        }
      } catch (e) {
        print('Error obteniendo lotes antiguos: $e');
      }
      
      // Ordenar por fecha (los del sistema unificado no tienen fecha_creacion, 
      // así que usamos el ID que contiene timestamp)
      lotes.sort((a, b) {
        // Para lotes del sistema unificado, usar el ID como referencia de tiempo
        final timeA = a.id?.split('-').last ?? '';
        final timeB = b.id?.split('-').last ?? '';
        return timeB.compareTo(timeA);
      });
      
      return lotes;
    });
  }
  
  // Método auxiliar para mapear el estado del reciclador
  String _mapearEstadoReciclador(Map<String, dynamic> data) {
    // Si tiene documentación completa, está finalizado
    if ((data['f_tecnica_pellet'] != null && data['f_tecnica_pellet'] != '') && 
        (data['rep_result_reci'] != null && data['rep_result_reci'] != '')) {
      return 'finalizado';
    }
    
    // Si tiene formulario de salida completo (todos los campos requeridos), está en documentación
    if (data['peso_neto_salida'] != null && data['peso_neto_salida'] > 0 &&
        data['operador_salida_nombre'] != null && data['operador_salida_nombre'] != '' &&
        data['firma_salida'] != null && data['firma_salida'] != '' &&
        data['procesos_aplicados'] != null && (data['procesos_aplicados'] as List).isNotEmpty &&
        data['tipo_poli_salida'] != null && data['tipo_poli_salida'] != '' &&
        data['presentacion_salida'] != null && data['presentacion_salida'] != '') {
      return 'documentado';
    }
    
    // Si solo tiene documentación parcial, sigue en documentación
    if (data['f_tecnica_pellet'] != null || data['rep_result_reci'] != null) {
      return 'documentado';
    }
    
    // Si tiene algún dato de salida (formulario parcial), está en salida
    if (data['peso_neto_salida'] != null || 
        data['operador_salida_nombre'] != null ||
        data['firma_salida'] != null ||
        data['procesos_aplicados'] != null ||
        data['tipo_poli_salida'] != null ||
        data['presentacion_salida'] != null) {
      return 'salida';
    }
    
    // Si es un lote recién recibido (solo tiene datos de entrada), va a salida
    if (data['peso_bruto'] != null || data['peso_neto'] != null || data['peso_entrada'] != null) {
      return 'salida';
    }
    
    // Por defecto, salida (para lotes recién transferidos)
    return 'salida';
  }

  // === LABORATORIO ===
  Future<String> crearLoteLaboratorio(LoteLaboratorioModel lote) async {
    try {
      final docRef = await _firestore.collection(LOTES_LABORATORIO).add(lote.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear lote de laboratorio: $e');
    }
  }

  Stream<List<LoteLaboratorioModel>> getLotesLaboratorio() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);
    
    return _firestore
        .collection(LOTES_LABORATORIO)
        .where('userId', isEqualTo: userId)
        .orderBy('fecha_analisis', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LoteLaboratorioModel.fromFirestore(doc))
            .toList());
  }

  // === TRANSFORMADOR ===
  Future<String> crearLoteTransformador(LoteTransformadorModel lote) async {
    try {
      final docRef = await _firestore.collection(LOTES_TRANSFORMADOR).add(lote.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear lote de transformador: $e');
    }
  }

  Stream<List<LoteTransformadorModel>> getLotesTransformador() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);
    
    return _firestore
        .collection(LOTES_TRANSFORMADOR)
        .where('userId', isEqualTo: userId)
        .orderBy('fecha_transformacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LoteTransformadorModel.fromFirestore(doc))
            .toList());
  }

  // === FUNCIONES AUXILIARES ===
  
  // Obtener información de múltiples lotes por IDs
  Future<List<Map<String, dynamic>>> getLotesInfo(List<String> loteIds) async {
    List<Map<String, dynamic>> lotesInfo = [];
    
    for (String loteId in loteIds) {
      // Buscar en cada colección hasta encontrar el lote
      Map<String, dynamic>? loteInfo = await _buscarLoteEnColecciones(loteId);
      if (loteInfo != null) {
        lotesInfo.add(loteInfo);
      }
    }
    
    return lotesInfo;
  }

  Future<Map<String, dynamic>?> _buscarLoteEnColecciones(String loteId) async {
    // Lista de colecciones a buscar
    final colecciones = [
      LOTES_ORIGEN,
      LOTES_TRANSPORTISTA,
      LOTES_RECICLADOR,
      LOTES_LABORATORIO,
      LOTES_TRANSFORMADOR,
    ];

    for (String coleccion in colecciones) {
      try {
        final doc = await _firestore.collection(coleccion).doc(loteId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          data['tipo_lote'] = coleccion;
          return data;
        }
      } catch (e) {
        // Continuar con la siguiente colección
      }
    }
    
    return null;
  }

  // Calcular tipo de polímero predominante de una lista de lotes
  Future<Map<String, double>> calcularTipoPolimeroPredominante(List<String> loteIds) async {
    Map<String, double> tiposPolimero = {};
    double pesoTotal = 0;

    for (String loteId in loteIds) {
      final loteInfo = await _buscarLoteEnColecciones(loteId);
      if (loteInfo != null) {
        String? tipoPoli;
        double peso = 0;

        // Extraer tipo de polímero según el tipo de lote
        if (loteInfo['tipo_lote'] == LOTES_ORIGEN) {
          tipoPoli = loteInfo['ecoce_origen_tipo_poli'] as String?;
          peso = (loteInfo['ecoce_origen_peso_nace'] ?? 0).toDouble();
        } else if (loteInfo['tipo_lote'] == LOTES_RECICLADOR) {
          // Para reciclador, usar el tipo predominante
          final tipoPoliMap = loteInfo['ecoce_reciclador_tipo_poli'] as Map<String, dynamic>?;
          if (tipoPoliMap != null && tipoPoliMap.isNotEmpty) {
            // Encontrar el tipo con mayor porcentaje
            double maxPorcentaje = 0;
            tipoPoliMap.forEach((tipo, porcentaje) {
              if (porcentaje > maxPorcentaje) {
                maxPorcentaje = porcentaje.toDouble();
                tipoPoli = tipo;
              }
            });
          }
          peso = (loteInfo['ecoce_reciclador_peso_bruto'] ?? 0).toDouble();
        }

        if (tipoPoli != null && peso > 0) {
          tiposPolimero[tipoPoli!] = (tiposPolimero[tipoPoli] ?? 0) + peso;
          pesoTotal += peso;
        }
      }
    }

    // Convertir a porcentajes
    if (pesoTotal > 0) {
      final tiposPolimeroTemp = Map<String, double>.from(tiposPolimero);
      tiposPolimeroTemp.forEach((tipo, peso) {
        tiposPolimero[tipo] = (peso / pesoTotal) * 100;
      });
    }

    return tiposPolimero;
  }

  // Calcular peso total de una lista de lotes
  Future<double> calcularPesoTotal(List<String> loteIds) async {
    double pesoTotal = 0;

    for (String loteId in loteIds) {
      final loteInfo = await _buscarLoteEnColecciones(loteId);
      if (loteInfo != null) {
        // Extraer peso según el tipo de lote
        if (loteInfo['tipo_lote'] == LOTES_ORIGEN) {
          pesoTotal += (loteInfo['ecoce_origen_peso_nace'] ?? 0).toDouble();
        } else if (loteInfo['tipo_lote'] == LOTES_TRANSPORTISTA) {
          pesoTotal += (loteInfo['ecoce_transportista_peso_recibido'] ?? 0).toDouble();
        } else if (loteInfo['tipo_lote'] == LOTES_RECICLADOR) {
          pesoTotal += (loteInfo['ecoce_reciclador_peso_bruto'] ?? 0).toDouble();
        }
      }
    }

    return pesoTotal;
  }

  // Actualizar lote de laboratorio
  Future<void> actualizarLoteLaboratorio(String loteId, Map<String, dynamic> datos) async {
    await _firestore.collection(LOTES_LABORATORIO).doc(loteId).update(datos);
  }

  // Obtener historial completo de trazabilidad de un lote
  Future<List<Map<String, dynamic>>> obtenerHistorialTrazabilidad(String loteId) async {
    List<Map<String, dynamic>> historial = [];
    Set<String> lotesVisitados = {};
    
    // Función recursiva para rastrear el lote hacia atrás
    Future<void> rastrearLote(String currentLoteId) async {
      if (lotesVisitados.contains(currentLoteId)) return;
      lotesVisitados.add(currentLoteId);
      
      // Buscar el lote en todas las colecciones
      final loteInfo = await _buscarLoteEnColecciones(currentLoteId);
      if (loteInfo == null) return;
      
      final tipoLote = loteInfo['tipo_lote'];
      final data = loteInfo;
      
      // Agregar evento según el tipo de lote
      switch (tipoLote) {
        case LOTES_ORIGEN:
          historial.add({
            'tipo': data['ecoce_origen_tipo_usuario'] == 'Acopiador' ? 'Acopiador' : 'Planta de Separación',
            'accion': 'Lote Creado',
            'actor': data['ecoce_origen_direccion'] ?? 'Sin dirección',
            'fecha': (data['fecha_nace'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'detalles': {
              'material': data['ecoce_origen_tipo_poli'],
              'peso': data['ecoce_origen_peso_nace'],
              'fuente': data['ecoce_origen_fuente'],
              'presentacion': data['ecoce_origen_presentacion'],
            },
            'peso': data['ecoce_origen_peso_nace'],
            'loteId': currentLoteId,
          });
          break;
          
        case LOTES_TRANSPORTISTA:
          final lotes = data['ecoce_transportista_lotes'] as List<dynamic>? ?? [];
          
          historial.add({
            'tipo': 'Transportista',
            'accion': 'Transporte',
            'actor': data['ecoce_transportista_proveedor'] ?? 'Transportista',
            'fecha': (data['fecha_creacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'detalles': {
              'origen': data['ecoce_transportista_direccion_origen'],
              'destino': data['ecoce_transportista_direccion_destino'],
              'peso': data['ecoce_transportista_peso_total'],
              'lotes_transportados': lotes.length,
            },
            'peso': data['ecoce_transportista_peso_total'],
            'loteId': currentLoteId,
          });
          
          // Rastrear lotes anteriores
          for (String lotId in lotes) {
            await rastrearLote(lotId);
          }
          break;
          
        case LOTES_RECICLADOR:
          final conjuntoLotes = data['ecoce_reciclador_conjunto_lotes'] as List<dynamic>? ?? [];
          
          historial.add({
            'tipo': 'Reciclador',
            'accion': 'Procesamiento',
            'actor': data['ecoce_reciclador_nombre_ope_entrada'] ?? 'Reciclador',
            'fecha': (data['fecha_creacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'detalles': {
              'peso_bruto': data['ecoce_reciclador_peso_bruto'],
              'peso_neto': data['ecoce_reciclador_peso_neto'],
              'peso_resultante': data['ecoce_reciclador_peso_resultante'],
              'merma': data['ecoce_reciclador_merma'],
              'procesos': data['ecoce_reciclador_procesos'],
            },
            'peso': data['ecoce_reciclador_peso_resultante'] ?? data['ecoce_reciclador_peso_neto'],
            'loteId': currentLoteId,
          });
          
          // Rastrear lotes anteriores
          for (String lotId in conjuntoLotes) {
            await rastrearLote(lotId);
          }
          break;
          
        case LOTES_LABORATORIO:
          final loteOrigen = data['ecoce_laboratorio_lote_origen'];
          
          historial.add({
            'tipo': 'Laboratorio',
            'accion': 'Análisis',
            'actor': data['ecoce_laboratorio_proveedor'] ?? 'Laboratorio',
            'fecha': (data['fecha_analisis'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'detalles': {
              'tipo_material': data['ecoce_laboratorio_tipo_material'],
              'peso_muestra': data['ecoce_laboratorio_peso_muestra'],
              'cumple_requisitos': data['ecoce_laboratorio_cumple_requisitos'],
              'tipo_polimero': data['ecoce_laboratorio_ftir'],
            },
            'peso': data['ecoce_laboratorio_peso_muestra'],
            'loteId': currentLoteId,
          });
          
          // Rastrear lote anterior
          if (loteOrigen != null) {
            await rastrearLote(loteOrigen);
          }
          break;
          
        case LOTES_TRANSFORMADOR:
          final lotesRecibidos = data['ecoce_transformador_lotes_recibidos'] as List<dynamic>? ?? [];
          
          historial.add({
            'tipo': 'Transformador',
            'accion': 'Transformación',
            'actor': data['ecoce_transformador_proveedor'] ?? 'Transformador',
            'fecha': (data['fecha_creacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'detalles': {
              'producto_fabricado': data['ecoce_transformador_producto_fabricado'],
              'peso_ingreso': data['ecoce_transformador_peso_ingreso'],
              'tipos_analisis': data['ecoce_transformador_tipos_analisis'],
              'composicion': data['ecoce_transformador_composicion_material'],
            },
            'peso': data['ecoce_transformador_peso_ingreso'],
            'loteId': currentLoteId,
          });
          
          // Rastrear lotes anteriores
          for (String lotId in lotesRecibidos) {
            await rastrearLote(lotId);
          }
          break;
      }
    }
    
    // Iniciar el rastreo
    await rastrearLote(loteId);
    
    // Ordenar por fecha (más reciente primero)
    historial.sort((a, b) => b['fecha'].compareTo(a['fecha']));
    
    return historial;
  }

  // Buscar lotes en el repositorio con filtros
  Stream<List<Map<String, dynamic>>> buscarLotesRepositorio({
    String? searchQuery,
    String? tipoMaterial,
    String? tipoActor,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async* {
    // Lista de todas las colecciones a buscar
    final colecciones = [
      LOTES_ORIGEN,
      LOTES_TRANSPORTISTA,
      LOTES_RECICLADOR,
      LOTES_LABORATORIO,
      LOTES_TRANSFORMADOR,
    ];
    
    List<Map<String, dynamic>> todosLosLotes = [];
    
    for (String coleccion in colecciones) {
      Query query = _firestore.collection(coleccion);
      
      // Aplicar filtros de fecha si existen
      if (fechaInicio != null) {
        query = query.where('fecha_creacion', isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio));
      }
      if (fechaFin != null) {
        query = query.where('fecha_creacion', isLessThanOrEqualTo: Timestamp.fromDate(fechaFin));
      }
      
      final snapshot = await query.get();
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['tipo_coleccion'] = coleccion;
        
        // Determinar tipo de actor y material según la colección
        String? tipoActorLote;
        String? materialLote;
        DateTime? fechaCreacion;
        double? peso;
        
        switch (coleccion) {
          case LOTES_ORIGEN:
            tipoActorLote = data['ecoce_origen_tipo_usuario'];
            materialLote = data['ecoce_origen_tipo_poli'];
            fechaCreacion = (data['fecha_nace'] as Timestamp?)?.toDate();
            peso = data['ecoce_origen_peso_nace']?.toDouble();
            break;
          case LOTES_TRANSPORTISTA:
            tipoActorLote = 'Transportista';
            materialLote = await _obtenerMaterialPredominante(data['ecoce_transportista_lotes'] ?? []);
            fechaCreacion = (data['fecha_creacion'] as Timestamp?)?.toDate();
            peso = data['ecoce_transportista_peso_total']?.toDouble();
            break;
          case LOTES_RECICLADOR:
            tipoActorLote = 'Reciclador';
            final tipoPoli = data['ecoce_reciclador_tipo_poli'] as Map<String, dynamic>?;
            if (tipoPoli != null && tipoPoli.isNotEmpty) {
              materialLote = tipoPoli.entries.reduce((a, b) => a.value > b.value ? a : b).key;
            }
            fechaCreacion = (data['fecha_creacion'] as Timestamp?)?.toDate();
            peso = data['ecoce_reciclador_peso_resultante']?.toDouble() ?? data['ecoce_reciclador_peso_neto']?.toDouble();
            break;
          case LOTES_LABORATORIO:
            tipoActorLote = 'Laboratorio';
            materialLote = data['ecoce_laboratorio_tipo_material'];
            fechaCreacion = (data['fecha_analisis'] as Timestamp?)?.toDate();
            peso = data['ecoce_laboratorio_peso_muestra']?.toDouble();
            break;
          case LOTES_TRANSFORMADOR:
            tipoActorLote = 'Transformador';
            materialLote = data['ecoce_transformador_tipo_polimero'];
            fechaCreacion = (data['fecha_creacion'] as Timestamp?)?.toDate();
            peso = data['ecoce_transformador_peso_ingreso']?.toDouble();
            break;
        }
        
        // Aplicar filtros
        bool incluir = true;
        
        if (tipoMaterial != null && materialLote != tipoMaterial) {
          incluir = false;
        }
        
        if (tipoActor != null && tipoActorLote != tipoActor) {
          incluir = false;
        }
        
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          final idMatch = doc.id.toLowerCase().contains(query);
          final materialMatch = materialLote?.toLowerCase().contains(query) ?? false;
          incluir = incluir && (idMatch || materialMatch);
        }
        
        if (incluir) {
          todosLosLotes.add({
            'id': doc.id,
            'tipo_actor': tipoActorLote,
            'material': materialLote,
            'fecha_creacion': fechaCreacion,
            'peso': peso,
            'data': data,
          });
        }
      }
    }
    
    // Ordenar por fecha de creación (más reciente primero)
    todosLosLotes.sort((a, b) {
      final fechaA = a['fecha_creacion'] as DateTime?;
      final fechaB = b['fecha_creacion'] as DateTime?;
      if (fechaA == null) return 1;
      if (fechaB == null) return -1;
      return fechaB.compareTo(fechaA);
    });
    
    yield todosLosLotes;
  }

  // Obtener material predominante de una lista de lotes
  Future<String?> _obtenerMaterialPredominante(List<dynamic> loteIds) async {
    if (loteIds.isEmpty) return null;
    
    final tiposPoli = await calcularTipoPolimeroPredominante(
      loteIds.map((e) => e.toString()).toList()
    );
    
    if (tiposPoli.isEmpty) return null;
    
    return tiposPoli.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}