class ConfiguracionDisponibilidadModel {
  final List<String> estadosDisponibles;
  final List<String> municipiosDisponibles;
  final DateTime fechaActualizacion;

  ConfiguracionDisponibilidadModel({
    required this.estadosDisponibles,
    required this.municipiosDisponibles,
    required this.fechaActualizacion,
  });

  factory ConfiguracionDisponibilidadModel.fromJson(Map<String, dynamic> json) {
    return ConfiguracionDisponibilidadModel(
      estadosDisponibles: List<String>.from(json['estadosDisponibles'] ?? []),
      municipiosDisponibles: List<String>.from(json['municipiosDisponibles'] ?? []),
      fechaActualizacion: DateTime.parse(json['fechaActualizacion']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estadosDisponibles': estadosDisponibles,
      'municipiosDisponibles': municipiosDisponibles,
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
    };
  }
}