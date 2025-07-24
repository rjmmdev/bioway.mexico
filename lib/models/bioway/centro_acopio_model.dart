import 'package:cloud_firestore/cloud_firestore.dart';

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
  final Map<String, dynamic> inventarioActual;
  final DateTime fechaRegistro;
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
    required this.activo,
  });

  factory CentroAcopioModel.fromJson(Map<String, dynamic> map) {
    return CentroAcopioModel(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      direccion: map['direccion'] ?? '',
      estado: map['estado'] ?? '',
      municipio: map['municipio'] ?? '',
      codigoPostal: map['codigoPostal'] ?? '',
      latitud: (map['latitud'] ?? 0.0).toDouble(),
      longitud: (map['longitud'] ?? 0.0).toDouble(),
      telefono: map['telefono'] ?? '',
      responsable: map['responsable'] ?? '',
      saldoPrepago: (map['saldoPrepago'] ?? 0.0).toDouble(),
      comisionBioWay: (map['comisionBioWay'] ?? 0.10).toDouble(),
      reputacion: (map['reputacion'] ?? 5.0).toDouble(),
      totalRecepcionesMes: map['totalRecepcionesMes'] ?? 0,
      inventarioActual: map['inventarioActual'] ?? {},
      fechaRegistro: map['fechaRegistro'] != null 
          ? (map['fechaRegistro'] is Timestamp 
              ? (map['fechaRegistro'] as Timestamp).toDate()
              : DateTime.parse(map['fechaRegistro']))
          : DateTime.now(),
      activo: map['activo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
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
      'fechaRegistro': Timestamp.fromDate(fechaRegistro),
      'activo': activo,
    };
  }
}