import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/models/lotes/lote_origen_model.dart';
import 'package:app/models/lotes/lote_transportista_model.dart';
import 'package:app/models/lotes/lote_reciclador_model.dart';
import 'package:app/models/lotes/lote_laboratorio_model.dart';
import 'package:app/models/lotes/lote_transformador_model.dart';

class LoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Colecciones por tipo de usuario
  static const String LOTES_ORIGEN = 'lotes_origen';
  static const String LOTES_TRANSPORTISTA = 'lotes_transportista';
  static const String LOTES_RECICLADOR = 'lotes_reciclador';
  static const String LOTES_LABORATORIO = 'lotes_laboratorio';
  static const String LOTES_TRANSFORMADOR = 'lotes_transformador';

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
    return _firestore
        .collection(LOTES_ORIGEN)
        .orderBy('ecoce_origen_fecha_nace', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LoteOrigenModel.fromFirestore(doc))
            .toList());
  }

  Future<LoteOrigenModel?> getLoteOrigenById(String id) async {
    try {
      final doc = await _firestore.collection(LOTES_ORIGEN).doc(id).get();
      if (doc.exists) {
        return LoteOrigenModel.fromFirestore(doc);
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
    Query query = _firestore.collection(LOTES_TRANSPORTISTA);
    
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
    Query query = _firestore.collection(LOTES_RECICLADOR);
    
    if (estado != null) {
      query = query.where('estado', isEqualTo: estado);
    }
    
    return query
        .orderBy('fecha_creacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LoteRecicladorModel.fromFirestore(doc))
            .toList());
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
    return _firestore
        .collection(LOTES_LABORATORIO)
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
    return _firestore
        .collection(LOTES_TRANSFORMADOR)
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