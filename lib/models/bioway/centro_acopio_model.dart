<<<<<<< HEAD
import 'package:cloud_firestore/cloud_firestore.dart';

=======
>>>>>>> cabe8f1f3af68c346d1354cdabc8decc624748c0
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
<<<<<<< HEAD
  final Map<String, dynamic> inventarioActual;
=======
  final Map<String, double> inventarioActual;
>>>>>>> cabe8f1f3af68c346d1354cdabc8decc624748c0
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

<<<<<<< HEAD
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
=======
  factory CentroAcopioModel.fromJson(Map<String, dynamic> json) {
    return CentroAcopioModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'] ?? '',
      estado: json['estado'] ?? '',
      municipio: json['municipio'] ?? '',
      codigoPostal: json['codigoPostal'] ?? '',
      latitud: (json['latitud'] ?? 0.0).toDouble(),
      longitud: (json['longitud'] ?? 0.0).toDouble(),
      telefono: json['telefono'] ?? '',
      responsable: json['responsable'] ?? '',
      saldoPrepago: (json['saldoPrepago'] ?? 0.0).toDouble(),
      comisionBioWay: (json['comisionBioWay'] ?? 0.10).toDouble(),
      reputacion: (json['reputacion'] ?? 5.0).toDouble(),
      totalRecepcionesMes: json['totalRecepcionesMes'] ?? 0,
      inventarioActual: Map<String, double>.from(json['inventarioActual'] ?? {}),
      fechaRegistro: json['fechaRegistro'] != null
          ? DateTime.parse(json['fechaRegistro'])
          : DateTime.now(),
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
>>>>>>> cabe8f1f3af68c346d1354cdabc8decc624748c0
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
<<<<<<< HEAD
      'fechaRegistro': Timestamp.fromDate(fechaRegistro),
=======
      'fechaRegistro': fechaRegistro.toIso8601String(),
>>>>>>> cabe8f1f3af68c346d1354cdabc8decc624748c0
      'activo': activo,
    };
  }
}