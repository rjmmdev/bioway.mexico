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
          ? DateTime.parse(map['fechaCreacion'])
          : DateTime.now(),
      fechaActualizacion: map['fechaActualizacion'] != null
          ? DateTime.parse(map['fechaActualizacion'])
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
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
    };
  }
}