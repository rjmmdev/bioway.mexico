import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de residuo para BioWay
class Residuo {
  final String id;
  final String brindadorId;
  final String? brindadorNombre;
  final String? recolectorId;
  final Map<String, double> materiales; // {materialId: cantidad en kg}
  final String estado; // 'activo', 'recolectado', 'cancelado'
  final DateTime fechaCreacion;
  final DateTime? fechaRecoleccion;
  final double latitud;
  final double longitud;
  final String direccion;
  final List<String> fotos;
  final String? comentarioBrindador;
  final String? comentarioRecolector;
  final int? puntosEstimados;
  final int? puntosOtorgados;
  final double? co2Estimado;
  final double? co2Evitado;
  final Map<String, dynamic>? datosRecoleccion;
  
  Residuo({
    required this.id,
    required this.brindadorId,
    this.brindadorNombre,
    this.recolectorId,
    required this.materiales,
    required this.estado,
    required this.fechaCreacion,
    this.fechaRecoleccion,
    required this.latitud,
    required this.longitud,
    required this.direccion,
    required this.fotos,
    this.comentarioBrindador,
    this.comentarioRecolector,
    this.puntosEstimados,
    this.puntosOtorgados,
    this.co2Estimado,
    this.co2Evitado,
    this.datosRecoleccion,
  });
  
  /// Calcula el peso total del residuo
  double get pesoTotal {
    return materiales.values.fold(0.0, (acc, peso) => acc + peso);
  }
  
  /// Obtiene la lista de tipos de materiales
  List<String> get tiposMateriales {
    return materiales.keys.toList();
  }
  
  /// Determina si el residuo está activo para recolección
  bool get estaActivo => estado == 'activo';
  
  /// Determina si el residuo ya fue recolectado
  bool get fueRecolectado => estado == 'recolectado';
  
  /// Convierte a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'brindadorId': brindadorId,
      'brindadorNombre': brindadorNombre,
      'recolectorId': recolectorId,
      'materiales': materiales,
      'estado': estado,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaRecoleccion': fechaRecoleccion != null 
          ? Timestamp.fromDate(fechaRecoleccion!) 
          : null,
      'latitud': latitud,
      'longitud': longitud,
      'direccion': direccion,
      'fotos': fotos,
      'comentarioBrindador': comentarioBrindador,
      'comentarioRecolector': comentarioRecolector,
      'puntosEstimados': puntosEstimados,
      'puntosOtorgados': puntosOtorgados,
      'co2Estimado': co2Estimado,
      'co2Evitado': co2Evitado,
      'datosRecoleccion': datosRecoleccion,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
  
  /// Crea desde Map de Firebase
  factory Residuo.fromMap(Map<String, dynamic> map, String id) {
    return Residuo(
      id: id,
      brindadorId: map['brindadorId'],
      brindadorNombre: map['brindadorNombre'],
      recolectorId: map['recolectorId'],
      materiales: Map<String, double>.from(
        map['materiales']?.map((key, value) => 
          MapEntry(key, value.toDouble())
        ) ?? {},
      ),
      estado: map['estado'] ?? 'activo',
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
      fechaRecoleccion: map['fechaRecoleccion'] != null 
          ? (map['fechaRecoleccion'] as Timestamp).toDate()
          : null,
      latitud: (map['latitud'] ?? 0.0).toDouble(),
      longitud: (map['longitud'] ?? 0.0).toDouble(),
      direccion: map['direccion'] ?? '',
      fotos: List<String>.from(map['fotos'] ?? []),
      comentarioBrindador: map['comentarioBrindador'],
      comentarioRecolector: map['comentarioRecolector'],
      puntosEstimados: map['puntosEstimados'],
      puntosOtorgados: map['puntosOtorgados'],
      co2Estimado: map['co2Estimado'] != null ? (map['co2Estimado']).toDouble() : null,
      co2Evitado: map['co2Evitado'] != null ? (map['co2Evitado']).toDouble() : null,
      datosRecoleccion: map['datosRecoleccion'],
    );
  }
  
  /// Crea una copia con modificaciones
  Residuo copyWith({
    String? brindadorNombre,
    String? recolectorId,
    String? estado,
    DateTime? fechaRecoleccion,
    String? comentarioRecolector,
    int? puntosEstimados,
    int? puntosOtorgados,
    double? co2Estimado,
    double? co2Evitado,
    Map<String, dynamic>? datosRecoleccion,
  }) {
    return Residuo(
      id: id,
      brindadorId: brindadorId,
      brindadorNombre: brindadorNombre ?? this.brindadorNombre,
      recolectorId: recolectorId ?? this.recolectorId,
      materiales: materiales,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion,
      fechaRecoleccion: fechaRecoleccion ?? this.fechaRecoleccion,
      latitud: latitud,
      longitud: longitud,
      direccion: direccion,
      fotos: fotos,
      comentarioBrindador: comentarioBrindador,
      comentarioRecolector: comentarioRecolector ?? this.comentarioRecolector,
      puntosEstimados: puntosEstimados ?? this.puntosEstimados,
      puntosOtorgados: puntosOtorgados ?? this.puntosOtorgados,
      co2Estimado: co2Estimado ?? this.co2Estimado,
      co2Evitado: co2Evitado ?? this.co2Evitado,
      datosRecoleccion: datosRecoleccion ?? this.datosRecoleccion,
    );
  }
}