import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para representar una transformación de múltiples lotes en el reciclador
class TransformacionModel {
  final String id;
  final String tipo; // 'agrupacion_reciclador'
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String estado; // 'en_proceso', 'completada', 'documentada'
  final List<LoteEntrada> lotesEntrada;
  final double pesoTotalEntrada;
  final double pesoDisponible;
  final double mermaProceso;
  final List<String> sublotesGenerados;
  final Map<String, String> documentosAsociados;
  final String usuarioId;
  final String usuarioFolio;
  final String? procesoAplicado;
  final String? observaciones;
  
  TransformacionModel({
    required this.id,
    required this.tipo,
    required this.fechaInicio,
    this.fechaFin,
    required this.estado,
    required this.lotesEntrada,
    required this.pesoTotalEntrada,
    required this.pesoDisponible,
    required this.mermaProceso,
    required this.sublotesGenerados,
    required this.documentosAsociados,
    required this.usuarioId,
    required this.usuarioFolio,
    this.procesoAplicado,
    this.observaciones,
  });
  
  factory TransformacionModel.fromFirestore(DocumentSnapshot doc) {
    print('[TransformacionModel] Iniciando conversión desde Firestore para doc: ${doc.id}');
    
    final rawData = doc.data();
    if (rawData == null) {
      print('[TransformacionModel] ERROR: rawData es null');
      throw Exception('Datos de transformación nulos');
    }
    
    if (rawData is! Map) {
      print('[TransformacionModel] ERROR: rawData no es Map, es: ${rawData.runtimeType}');
      throw Exception('Datos de transformación inválidos: se esperaba Map pero se recibió ${rawData.runtimeType}');
    }
    
    final data = Map<String, dynamic>.from(rawData);
    print('[TransformacionModel] Datos convertidos exitosamente a Map<String, dynamic>');
    
    // Validar y convertir fecha_inicio
    DateTime fechaInicio;
    try {
      final fechaInicioRaw = data['fecha_inicio'];
      print('[TransformacionModel] fecha_inicio tipo: ${fechaInicioRaw?.runtimeType}');
      
      if (fechaInicioRaw == null) {
        fechaInicio = DateTime.now();
        print('[TransformacionModel] ADVERTENCIA: fecha_inicio es null, usando fecha actual');
      } else if (fechaInicioRaw is Timestamp) {
        fechaInicio = fechaInicioRaw.toDate();
      } else if (fechaInicioRaw is int) {
        fechaInicio = DateTime.fromMillisecondsSinceEpoch(fechaInicioRaw);
        print('[TransformacionModel] fecha_inicio convertida desde int (timestamp)');
      } else {
        print('[TransformacionModel] ERROR: fecha_inicio tiene tipo inesperado: ${fechaInicioRaw.runtimeType}');
        throw Exception('Tipo de fecha_inicio inválido: ${fechaInicioRaw.runtimeType}');
      }
    } catch (e) {
      print('[TransformacionModel] ERROR al convertir fecha_inicio: $e');
      throw Exception('Error al convertir fecha_inicio: $e');
    }
    
    // Validar y convertir fecha_fin
    DateTime? fechaFin;
    if (data['fecha_fin'] != null) {
      try {
        final fechaFinRaw = data['fecha_fin'];
        if (fechaFinRaw is Timestamp) {
          fechaFin = fechaFinRaw.toDate();
        } else if (fechaFinRaw is int) {
          fechaFin = DateTime.fromMillisecondsSinceEpoch(fechaFinRaw);
        }
      } catch (e) {
        print('[TransformacionModel] ADVERTENCIA: Error al convertir fecha_fin: $e');
      }
    }
    
    // Validar y convertir lotes_entrada
    List<LoteEntrada> lotesEntrada = [];
    try {
      final lotesEntradaRaw = data['lotes_entrada'];
      print('[TransformacionModel] lotes_entrada tipo: ${lotesEntradaRaw?.runtimeType}');
      
      if (lotesEntradaRaw != null) {
        if (lotesEntradaRaw is List) {
          lotesEntrada = lotesEntradaRaw
              .map((e) {
                print('[TransformacionModel] Procesando lote_entrada elemento tipo: ${e.runtimeType}');
                if (e is Map) {
                  return LoteEntrada.fromMap(Map<String, dynamic>.from(e));
                } else {
                  print('[TransformacionModel] ERROR: elemento de lotes_entrada no es Map: $e');
                  throw Exception('Elemento de lotes_entrada inválido');
                }
              }).toList();
        } else {
          print('[TransformacionModel] ERROR: lotes_entrada no es List, es: ${lotesEntradaRaw.runtimeType}');
          throw Exception('lotes_entrada debe ser una lista');
        }
      }
    } catch (e) {
      print('[TransformacionModel] ERROR al procesar lotes_entrada: $e');
      throw Exception('Error al procesar lotes_entrada: $e');
    }
    
    // Validar documentos_asociados
    Map<String, String> documentosAsociados = {};
    try {
      final docsRaw = data['documentos_asociados'];
      if (docsRaw != null) {
        if (docsRaw is Map) {
          documentosAsociados = Map<String, String>.from(docsRaw);
        } else {
          print('[TransformacionModel] ADVERTENCIA: documentos_asociados no es Map, es: ${docsRaw.runtimeType}');
        }
      }
    } catch (e) {
      print('[TransformacionModel] ADVERTENCIA: Error al procesar documentos_asociados: $e');
    }
    
    print('[TransformacionModel] Creando instancia de TransformacionModel');
    
    return TransformacionModel(
      id: doc.id,
      tipo: data['tipo'] ?? 'agrupacion_reciclador',
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      estado: data['estado'] ?? 'en_proceso',
      lotesEntrada: lotesEntrada,
      pesoTotalEntrada: _convertirADouble(data['peso_total_entrada'], 'peso_total_entrada'),
      pesoDisponible: _convertirADouble(data['peso_disponible'], 'peso_disponible'),
      mermaProceso: _convertirADouble(data['merma_proceso'], 'merma_proceso'),
      sublotesGenerados: _convertirAListaString(data['sublotes_generados'], 'sublotes_generados'),
      documentosAsociados: documentosAsociados,
      usuarioId: data['usuario_id']?.toString() ?? '',
      usuarioFolio: data['usuario_folio']?.toString() ?? '',
      procesoAplicado: data['proceso_aplicado']?.toString(),
      observaciones: data['observaciones']?.toString(),
    );
  }
  
  /// Método helper para convertir valores a double de forma segura
  static double _convertirADouble(dynamic valor, String campo) {
    try {
      if (valor == null) return 0.0;
      if (valor is double) return valor;
      if (valor is int) return valor.toDouble();
      if (valor is String) return double.tryParse(valor) ?? 0.0;
      print('[TransformacionModel] ADVERTENCIA: $campo tiene tipo inesperado: ${valor.runtimeType}');
      return 0.0;
    } catch (e) {
      print('[TransformacionModel] ERROR al convertir $campo a double: $e');
      return 0.0;
    }
  }
  
  /// Método helper para convertir a lista de strings de forma segura
  static List<String> _convertirAListaString(dynamic valor, String campo) {
    try {
      if (valor == null) return [];
      if (valor is List) {
        return valor.map((e) => e.toString()).toList();
      }
      print('[TransformacionModel] ADVERTENCIA: $campo no es una lista: ${valor.runtimeType}');
      return [];
    } catch (e) {
      print('[TransformacionModel] ERROR al convertir $campo a List<String>: $e');
      return [];
    }
  }
  
  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'fecha_inicio': Timestamp.fromDate(fechaInicio),
      'fecha_fin': fechaFin != null ? Timestamp.fromDate(fechaFin!) : null,
      'estado': estado,
      'lotes_entrada': lotesEntrada.map((e) => e.toMap()).toList(),
      'peso_total_entrada': pesoTotalEntrada,
      'peso_disponible': pesoDisponible,
      'merma_proceso': mermaProceso,
      'sublotes_generados': sublotesGenerados,
      'documentos_asociados': documentosAsociados,
      'usuario_id': usuarioId,
      'usuario_folio': usuarioFolio,
      'proceso_aplicado': procesoAplicado,
      'observaciones': observaciones,
    };
  }
  
  /// Calcula el porcentaje de merma
  double get porcentajeMerma {
    if (pesoTotalEntrada == 0) return 0;
    return (mermaProceso / pesoTotalEntrada) * 100;
  }
  
  /// Verifica si hay peso disponible para crear sublotes
  bool get tienePesoDisponible => pesoDisponible > 0;
  
  /// Calcula el peso total asignado a sublotes
  double get pesoAsignadoSublotes => pesoTotalEntrada - mermaProceso - pesoDisponible;
  
  /// Verifica si tiene documentación cargada
  bool get tieneDocumentacion => documentosAsociados.isNotEmpty;
  
  /// Verifica si puede crear más sublotes
  bool get puedeCrearSublotes => pesoDisponible > 0;
  
  /// Verifica si puede subir documentación
  bool get puedeSubirDocumentacion => !tieneDocumentacion;
  
  /// Verifica si la transformación está lista para ser eliminada
  /// Se elimina cuando no hay peso disponible Y tiene documentación
  bool get debeSerEliminada => pesoDisponible <= 0 && tieneDocumentacion;
  
  /// Factory constructor alternativo para compatibilidad
  factory TransformacionModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime fechaInicio;
    try {
      final fechaInicioRaw = data['fecha_inicio'];
      if (fechaInicioRaw == null) {
        fechaInicio = DateTime.now();
      } else if (fechaInicioRaw is Timestamp) {
        fechaInicio = fechaInicioRaw.toDate();
      } else if (fechaInicioRaw is int) {
        fechaInicio = DateTime.fromMillisecondsSinceEpoch(fechaInicioRaw);
      } else {
        fechaInicio = DateTime.now();
      }
    } catch (e) {
      fechaInicio = DateTime.now();
    }
    
    DateTime? fechaFin;
    if (data['fecha_fin'] != null) {
      try {
        final fechaFinRaw = data['fecha_fin'];
        if (fechaFinRaw is Timestamp) {
          fechaFin = fechaFinRaw.toDate();
        } else if (fechaFinRaw is int) {
          fechaFin = DateTime.fromMillisecondsSinceEpoch(fechaFinRaw);
        }
      } catch (e) {
        // Ignore fecha_fin errors
      }
    }
    
    List<LoteEntrada> lotesEntrada = [];
    try {
      final lotesEntradaRaw = data['lotes_entrada'];
      if (lotesEntradaRaw != null && lotesEntradaRaw is List) {
        lotesEntrada = lotesEntradaRaw
            .map((e) => LoteEntrada.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      // Ignore lotes_entrada errors
    }
    
    Map<String, String> documentosAsociados = {};
    try {
      final docsRaw = data['documentos_asociados'];
      if (docsRaw != null && docsRaw is Map) {
        documentosAsociados = Map<String, String>.from(docsRaw);
      }
    } catch (e) {
      // Ignore documentos_asociados errors
    }
    
    return TransformacionModel(
      id: id,
      tipo: data['tipo'] ?? 'agrupacion_reciclador',
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      estado: data['estado'] ?? 'en_proceso',
      lotesEntrada: lotesEntrada,
      pesoTotalEntrada: _convertirADouble(data['peso_total_entrada'], 'peso_total_entrada'),
      pesoDisponible: _convertirADouble(data['peso_disponible'], 'peso_disponible'),
      mermaProceso: _convertirADouble(data['merma_proceso'], 'merma_proceso'),
      sublotesGenerados: _convertirAListaString(data['sublotes_generados'], 'sublotes_generados'),
      documentosAsociados: documentosAsociados,
      usuarioId: data['usuario_id']?.toString() ?? '',
      usuarioFolio: data['usuario_folio']?.toString() ?? '',
      procesoAplicado: data['proceso_aplicado']?.toString(),
      observaciones: data['observaciones']?.toString(),
    );
  }
  
  /// Getter para acceder a los datos raw (para compatibilidad)
  Map<String, dynamic> get datos => toMap();
}

/// Modelo para representar un lote de entrada en la transformación
class LoteEntrada {
  final String loteId;
  final double peso;
  final double porcentaje;
  final String tipoMaterial;
  
  LoteEntrada({
    required this.loteId,
    required this.peso,
    required this.porcentaje,
    required this.tipoMaterial,
  });
  
  factory LoteEntrada.fromMap(Map<String, dynamic> map) {
    return LoteEntrada(
      loteId: map['lote_id'] ?? '',
      peso: (map['peso'] ?? 0.0).toDouble(),
      porcentaje: (map['porcentaje'] ?? 0.0).toDouble(),
      tipoMaterial: map['tipo_material'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'lote_id': loteId,
      'peso': peso,
      'porcentaje': porcentaje,
      'tipo_material': tipoMaterial,
    };
  }
}