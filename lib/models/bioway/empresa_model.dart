class EmpresaModel {
  final String id;
  final String nombre;
  final String descripcion;
  final List<String> materialesRecolectan;
  final List<String> estadosDisponibles;
  final List<String> municipiosDisponibles;
  final String? codigoPostalRestriccion;
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
    this.codigoPostalRestriccion,
    required this.rangoRestringido,
    this.rangoMaximoKm,
    required this.fechaCreacion,
    required this.activa,
  });

  factory EmpresaModel.fromJson(Map<String, dynamic> json) {
    return EmpresaModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      materialesRecolectan: List<String>.from(json['materialesRecolectan'] ?? []),
      estadosDisponibles: List<String>.from(json['estadosDisponibles'] ?? []),
      municipiosDisponibles: List<String>.from(json['municipiosDisponibles'] ?? []),
      codigoPostalRestriccion: json['codigoPostalRestriccion'],
      rangoRestringido: json['rangoRestringido'] ?? false,
      rangoMaximoKm: json['rangoMaximoKm']?.toDouble(),
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      activa: json['activa'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'materialesRecolectan': materialesRecolectan,
      'estadosDisponibles': estadosDisponibles,
      'municipiosDisponibles': municipiosDisponibles,
      'codigoPostalRestriccion': codigoPostalRestriccion,
      'rangoRestringido': rangoRestringido,
      'rangoMaximoKm': rangoMaximoKm,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'activa': activa,
    };
  }
}