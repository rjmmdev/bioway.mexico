import 'package:cloud_firestore/cloud_firestore.dart';

class LoteOrigenModel {
  final String? id; // Firebase ID (generado automáticamente)
  final String userId; // ID del usuario propietario del lote
  final DateTime fechaNace; // Fecha de creación
  final String direccion; // Dirección del origen
  final String fuente; // Fuente del material
  final String presentacion; // Presentación del material
  final String tipoPoli; // Tipo de polímero
  final String origen; // Pre/Post consumo
  final double pesoNace; // Peso del material
  final String condiciones; // Condiciones del material
  final String nombreOpe; // Nombre del operador
  final String? firmaOpe; // URL de la firma del operador
  final String? comentarios; // Comentarios
  final List<String> eviFoto; // URLs de evidencias fotográficas

  LoteOrigenModel({
    this.id,
    required this.userId,
    required this.fechaNace,
    required this.direccion,
    required this.fuente,
    required this.presentacion,
    required this.tipoPoli,
    required this.origen,
    required this.pesoNace,
    required this.condiciones,
    required this.nombreOpe,
    this.firmaOpe,
    this.comentarios,
    required this.eviFoto,
  });

  // Convertir a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'ecoce_origen_lote': id,
      'ecoce_origen_fecha_nace': Timestamp.fromDate(fechaNace),
      'ecoce_origen_direccion': direccion,
      'ecoce_origen_fuente': fuente,
      'ecoce_origen_presentacion': presentacion,
      'ecoce_origen_tipo_poli': tipoPoli,
      'ecoce_origen_origen': origen,
      'ecoce_origen_peso_nace': pesoNace,
      'ecoce_origen_condiciones': condiciones,
      'ecoce_origen_nombre_ope': nombreOpe,
      'ecoce_origen_firma_ope': firmaOpe,
      'ecoce_origen_comentarios': comentarios,
      'ecoce_origen_evi_foto': eviFoto,
    };
  }

  // Crear desde Firebase Document
  factory LoteOrigenModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LoteOrigenModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      fechaNace: (data['ecoce_origen_fecha_nace'] as Timestamp).toDate(),
      direccion: data['ecoce_origen_direccion'] ?? '',
      fuente: data['ecoce_origen_fuente'] ?? '',
      presentacion: data['ecoce_origen_presentacion'] ?? '',
      tipoPoli: data['ecoce_origen_tipo_poli'] ?? '',
      origen: data['ecoce_origen_origen'] ?? '',
      pesoNace: (data['ecoce_origen_peso_nace'] ?? 0).toDouble(),
      condiciones: data['ecoce_origen_condiciones'] ?? '',
      nombreOpe: data['ecoce_origen_nombre_ope'] ?? '',
      firmaOpe: data['ecoce_origen_firma_ope'],
      comentarios: data['ecoce_origen_comentarios'],
      eviFoto: List<String>.from(data['ecoce_origen_evi_foto'] ?? []),
    );
  }

  // Crear copia con modificaciones
  LoteOrigenModel copyWith({
    String? id,
    String? userId,
    DateTime? fechaNace,
    String? direccion,
    String? fuente,
    String? presentacion,
    String? tipoPoli,
    String? origen,
    double? pesoNace,
    String? condiciones,
    String? nombreOpe,
    String? firmaOpe,
    String? comentarios,
    List<String>? eviFoto,
  }) {
    return LoteOrigenModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fechaNace: fechaNace ?? this.fechaNace,
      direccion: direccion ?? this.direccion,
      fuente: fuente ?? this.fuente,
      presentacion: presentacion ?? this.presentacion,
      tipoPoli: tipoPoli ?? this.tipoPoli,
      origen: origen ?? this.origen,
      pesoNace: pesoNace ?? this.pesoNace,
      condiciones: condiciones ?? this.condiciones,
      nombreOpe: nombreOpe ?? this.nombreOpe,
      firmaOpe: firmaOpe ?? this.firmaOpe,
      comentarios: comentarios ?? this.comentarios,
      eviFoto: eviFoto ?? this.eviFoto,
    );
  }
}