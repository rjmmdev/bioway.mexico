import 'package:cloud_firestore/cloud_firestore.dart';

class EmpresaModel {
  final String id;
  final String nombre;
  final String descripcion;
  final List<String> materialesRecolectan;
  final List<String> estadosDisponibles;
  final List<String> municipiosDisponibles;
  final bool rangoRestringido;
  final double? rangoMaximoKm;
  final bool activa;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  EmpresaModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.materialesRecolectan,
    required this.estadosDisponibles,
    required this.municipiosDisponibles,
    required this.rangoRestringido,
    this.rangoMaximoKm,
    required this.activa,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory EmpresaModel.fromMap(Map<String, dynamic> map, String id) {
    return EmpresaModel(
      id: id,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      materialesRecolectan: List<String>.from(map['materialesRecolectan'] ?? []),
      estadosDisponibles: List<String>.from(map['estadosDisponibles'] ?? []),
      municipiosDisponibles: List<String>.from(map['municipiosDisponibles'] ?? []),
      rangoRestringido: map['rangoRestringido'] ?? false,
      rangoMaximoKm: map['rangoMaximoKm']?.toDouble(),
      activa: map['activa'] ?? true,
      fechaCreacion: map['fechaCreacion'] != null 
          ? (map['fechaCreacion'] is Timestamp
              ? (map['fechaCreacion'] as Timestamp).toDate()
              : DateTime.parse(map['fechaCreacion']))
          : DateTime.now(),
      fechaActualizacion: map['fechaActualizacion'] != null
          ? (map['fechaActualizacion'] is Timestamp
              ? (map['fechaActualizacion'] as Timestamp).toDate()
              : DateTime.parse(map['fechaActualizacion']))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'materialesRecolectan': materialesRecolectan,
      'estadosDisponibles': estadosDisponibles,
      'municipiosDisponibles': municipiosDisponibles,
      'rangoRestringido': rangoRestringido,
      'rangoMaximoKm': rangoMaximoKm,
      'activa': activa,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
    };
  }

  EmpresaModel copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    List<String>? materialesRecolectan,
    List<String>? estadosDisponibles,
    List<String>? municipiosDisponibles,
    bool? rangoRestringido,
    double? rangoMaximoKm,
    bool? activa,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return EmpresaModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      materialesRecolectan: materialesRecolectan ?? this.materialesRecolectan,
      estadosDisponibles: estadosDisponibles ?? this.estadosDisponibles,
      municipiosDisponibles: municipiosDisponibles ?? this.municipiosDisponibles,
      rangoRestringido: rangoRestringido ?? this.rangoRestringido,
      rangoMaximoKm: rangoMaximoKm ?? this.rangoMaximoKm,
      activa: activa ?? this.activa,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}