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
  final DateTime fechaCreacion;
  final bool activa;

  EmpresaModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.materialesRecolectan,
    required this.estadosDisponibles,
    required this.municipiosDisponibles,
    required this.rangoRestringido,
    this.rangoMaximoKm,
    required this.fechaCreacion,
    required this.activa,
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
      fechaCreacion: map['fechaCreacion'] != null 
          ? (map['fechaCreacion'] as Timestamp).toDate()
          : DateTime.now(),
      activa: map['activa'] ?? true,
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
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'activa': activa,
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
    DateTime? fechaCreacion,
    bool? activa,
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
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      activa: activa ?? this.activa,
    );
  }
}