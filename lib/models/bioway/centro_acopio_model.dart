class CentroAcopioModel {
  final String id;
  final String nombre;
  final String direccion;
  final String estado;
  final String municipio;
  final String codigoPostal;
  final double latitud;
  final double longitud;
  final String telefono;
  final String responsable;
  final double saldoPrepago;
  final double comisionBioWay;
  final double reputacion;
  final int totalRecepcionesMes;
  final Map<String, double> inventarioActual;
  final DateTime fechaRegistro;
  final DateTime? ultimaActividad;
  final bool activo;

  CentroAcopioModel({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.estado,
    required this.municipio,
    required this.codigoPostal,
    required this.latitud,
    required this.longitud,
    required this.telefono,
    required this.responsable,
    required this.saldoPrepago,
    required this.comisionBioWay,
    required this.reputacion,
    required this.totalRecepcionesMes,
    required this.inventarioActual,
    required this.fechaRegistro,
    this.ultimaActividad,
    required this.activo,
  });

  factory CentroAcopioModel.fromJson(Map<String, dynamic> json) {
    return CentroAcopioModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'] ?? '',
      estado: json['estado'] ?? '',
      municipio: json['municipio'] ?? '',
      codigoPostal: json['codigoPostal'] ?? '',
      latitud: json['latitud']?.toDouble() ?? 0.0,
      longitud: json['longitud']?.toDouble() ?? 0.0,
      telefono: json['telefono'] ?? '',
      responsable: json['responsable'] ?? '',
      saldoPrepago: json['saldoPrepago']?.toDouble() ?? 0.0,
      comisionBioWay: json['comisionBioWay']?.toDouble() ?? 0.0,
      reputacion: json['reputacion']?.toDouble() ?? 5.0,
      totalRecepcionesMes: json['totalRecepcionesMes'] ?? 0,
      inventarioActual: Map<String, double>.from(
        json['inventarioActual']?.map((k, v) => MapEntry(k, v.toDouble())) ?? {},
      ),
      fechaRegistro: DateTime.parse(json['fechaRegistro']),
      ultimaActividad: json['ultimaActividad'] != null 
          ? DateTime.parse(json['ultimaActividad']) 
          : null,
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'estado': estado,
      'municipio': municipio,
      'codigoPostal': codigoPostal,
      'latitud': latitud,
      'longitud': longitud,
      'telefono': telefono,
      'responsable': responsable,
      'saldoPrepago': saldoPrepago,
      'comisionBioWay': comisionBioWay,
      'reputacion': reputacion,
      'totalRecepcionesMes': totalRecepcionesMes,
      'inventarioActual': inventarioActual,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'ultimaActividad': ultimaActividad?.toIso8601String(),
      'activo': activo,
    };
  }
}