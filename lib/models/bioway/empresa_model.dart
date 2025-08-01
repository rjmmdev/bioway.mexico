<<<<<<< HEAD
import 'package:cloud_firestore/cloud_firestore.dart';

=======
>>>>>>> cabe8f1f3af68c346d1354cdabc8decc624748c0
class EmpresaModel {
  final String id;
  final String nombre;
  final String descripcion;
  final List<String> materialesRecolectan;
  final List<String> estadosDisponibles;
  final List<String> municipiosDisponibles;
  final bool rangoRestringido;
  final double? rangoMaximoKm;
<<<<<<< HEAD
  final DateTime fechaCreacion;
  final bool activa;
=======
  final bool activa;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
>>>>>>> cabe8f1f3af68c346d1354cdabc8decc624748c0

  EmpresaModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.materialesRecolectan,
    required this.estadosDisponibles,
    required this.municipiosDisponibles,
    required this.rangoRestringido,
    this.rangoMaximoKm,
<<<<<<< HEAD
    required this.fechaCreacion,
    required this.activa,
=======
    required this.activa,
    required this.fechaCreacion,
    required this.fechaActualizacion,
>>>>>>> cabe8f1f3af68c346d1354cdabc8decc624748c0
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
<<<<<<< HEAD
      fechaCreacion: map['fechaCreacion'] != null 
          ? (map['fechaCreacion'] as Timestamp).toDate()
          : DateTime.now(),
      activa: map['activa'] ?? true,
=======
      activa: map['activa'] ?? true,
      fechaCreacion: map['fechaCreacion'] != null
          ? DateTime.parse(map['fechaCreacion'])
          : DateTime.now(),
      fechaActualizacion: map['fechaActualizacion'] != null
          ? DateTime.parse(map['fechaActualizacion'])
          : DateTime.now(),
>>>>>>> cabe8f1f3af68c346d1354cdabc8decc624748c0
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
<<<<<<< HEAD
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
=======
      'activa': activa,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
    };
  }
>>>>>>> cabe8f1f3af68c346d1354cdabc8decc624748c0
}