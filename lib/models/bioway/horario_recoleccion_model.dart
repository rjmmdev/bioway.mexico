class HorarioRecoleccionModel {
  final String dia; // lunes, martes, etc.
  final List<String> materialesDisponibles;
  final String horaInicio;
  final String horaFin;
  final bool activo;

  HorarioRecoleccionModel({
    required this.dia,
    required this.materialesDisponibles,
    required this.horaInicio,
    required this.horaFin,
    required this.activo,
  });

  factory HorarioRecoleccionModel.fromJson(Map<String, dynamic> json) {
    return HorarioRecoleccionModel(
      dia: json['dia'] ?? '',
      materialesDisponibles: List<String>.from(json['materialesDisponibles'] ?? []),
      horaInicio: json['horaInicio'] ?? '',
      horaFin: json['horaFin'] ?? '',
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dia': dia,
      'materialesDisponibles': materialesDisponibles,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'activo': activo,
    };
  }
}