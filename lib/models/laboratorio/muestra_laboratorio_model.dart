import 'package:cloud_firestore/cloud_firestore.dart';

class MuestraLaboratorioModel {
  final String id;
  final String tipo; // "megalote" | "lote"
  final String origenId; // transformacionId o loteId
  final String origenTipo; // "transformacion" | "lote"
  final String laboratorioId; // userId del laboratorio
  final String laboratorioFolio;
  final double pesoMuestra;
  final String estado; // "pendiente_analisis" | "analisis_completado" | "documentacion_completada"
  final DateTime fechaToma;
  final String? firmaOperador;
  final List<String> evidenciasFoto;
  final DatosAnalisis? datosAnalisis;
  final Map<String, String> documentos;
  final DateTime? fechaAnalisis;
  final DateTime? fechaDocumentacion;
  final String? qrCode;

  MuestraLaboratorioModel({
    required this.id,
    required this.tipo,
    required this.origenId,
    required this.origenTipo,
    required this.laboratorioId,
    required this.laboratorioFolio,
    required this.pesoMuestra,
    required this.estado,
    required this.fechaToma,
    this.firmaOperador,
    required this.evidenciasFoto,
    this.datosAnalisis,
    required this.documentos,
    this.fechaAnalisis,
    this.fechaDocumentacion,
    this.qrCode,
  });

  factory MuestraLaboratorioModel.fromMap(Map<String, dynamic> map, String id) {
    return MuestraLaboratorioModel(
      id: id,
      tipo: map['tipo'] ?? '',
      origenId: map['origen_id'] ?? '',
      origenTipo: map['origen_tipo'] ?? '',
      laboratorioId: map['laboratorio_id'] ?? '',
      laboratorioFolio: map['laboratorio_folio'] ?? '',
      pesoMuestra: (map['peso_muestra'] ?? 0).toDouble(),
      estado: map['estado'] ?? 'pendiente_analisis',
      fechaToma: (map['fecha_toma'] as Timestamp).toDate(),
      firmaOperador: map['firma_operador'],
      evidenciasFoto: List<String>.from(map['evidencias_foto'] ?? []),
      datosAnalisis: map['datos_analisis'] != null 
          ? DatosAnalisis.fromMap(map['datos_analisis'])
          : null,
      documentos: Map<String, String>.from(map['documentos'] ?? {}),
      fechaAnalisis: map['fecha_analisis'] != null 
          ? (map['fecha_analisis'] as Timestamp).toDate()
          : null,
      fechaDocumentacion: map['fecha_documentacion'] != null
          ? (map['fecha_documentacion'] as Timestamp).toDate()
          : null,
      qrCode: map['qr_code'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'origen_id': origenId,
      'origen_tipo': origenTipo,
      'laboratorio_id': laboratorioId,
      'laboratorio_folio': laboratorioFolio,
      'peso_muestra': pesoMuestra,
      'estado': estado,
      'fecha_toma': Timestamp.fromDate(fechaToma),
      'firma_operador': firmaOperador,
      'evidencias_foto': evidenciasFoto,
      if (datosAnalisis != null) 'datos_analisis': datosAnalisis!.toMap(),
      'documentos': documentos,
      if (fechaAnalisis != null) 'fecha_analisis': Timestamp.fromDate(fechaAnalisis!),
      if (fechaDocumentacion != null) 'fecha_documentacion': Timestamp.fromDate(fechaDocumentacion!),
      'qr_code': qrCode,
    };
  }

  MuestraLaboratorioModel copyWith({
    String? estado,
    DatosAnalisis? datosAnalisis,
    Map<String, String>? documentos,
    DateTime? fechaAnalisis,
    DateTime? fechaDocumentacion,
  }) {
    return MuestraLaboratorioModel(
      id: id,
      tipo: tipo,
      origenId: origenId,
      origenTipo: origenTipo,
      laboratorioId: laboratorioId,
      laboratorioFolio: laboratorioFolio,
      pesoMuestra: pesoMuestra,
      estado: estado ?? this.estado,
      fechaToma: fechaToma,
      firmaOperador: firmaOperador,
      evidenciasFoto: evidenciasFoto,
      datosAnalisis: datosAnalisis ?? this.datosAnalisis,
      documentos: documentos ?? this.documentos,
      fechaAnalisis: fechaAnalisis ?? this.fechaAnalisis,
      fechaDocumentacion: fechaDocumentacion ?? this.fechaDocumentacion,
      qrCode: qrCode,
    );
  }
}

class DatosAnalisis {
  final double? humedad;
  final double? pelletsGramo;  // Cambiado de int? a double?
  final String? tipoPolimero;
  final TemperaturaFusion? temperaturaFusion;
  final double? contenidoOrganico;
  final double? contenidoInorganico;
  final String? oit;
  final String? mfi;
  final String? densidad;
  final String? norma;
  final String? observaciones;
  final bool cumpleRequisitos;
  final String? analista;

  DatosAnalisis({
    this.humedad,
    this.pelletsGramo,  // Ya es double?, no necesita cambios aquí
    this.tipoPolimero,
    this.temperaturaFusion,
    this.contenidoOrganico,
    this.contenidoInorganico,
    this.oit,
    this.mfi,
    this.densidad,
    this.norma,
    this.observaciones,
    required this.cumpleRequisitos,
    this.analista,
  });

  factory DatosAnalisis.fromMap(Map<String, dynamic> map) {
    return DatosAnalisis(
      humedad: map['humedad']?.toDouble(),
      pelletsGramo: map['pellets_gramo']?.toDouble(),  // Convertir a double
      tipoPolimero: map['tipo_polimero'],
      temperaturaFusion: map['temperatura_fusion'] != null
          ? TemperaturaFusion.fromMap(map['temperatura_fusion'])
          : null,
      contenidoOrganico: map['contenido_organico']?.toDouble(),
      contenidoInorganico: map['contenido_inorganico']?.toDouble(),
      oit: map['oit'],
      mfi: map['mfi'],
      densidad: map['densidad'],
      norma: map['norma'],
      observaciones: map['observaciones'],
      cumpleRequisitos: map['cumple_requisitos'] ?? false,
      analista: map['analista'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (humedad != null) 'humedad': humedad,
      if (pelletsGramo != null) 'pellets_gramo': pelletsGramo,
      if (tipoPolimero != null) 'tipo_polimero': tipoPolimero,
      if (temperaturaFusion != null) 'temperatura_fusion': temperaturaFusion!.toMap(),
      if (contenidoOrganico != null) 'contenido_organico': contenidoOrganico,
      if (contenidoInorganico != null) 'contenido_inorganico': contenidoInorganico,
      if (oit != null) 'oit': oit,
      if (mfi != null) 'mfi': mfi,
      if (densidad != null) 'densidad': densidad,
      if (norma != null) 'norma': norma,
      if (observaciones != null) 'observaciones': observaciones,
      'cumple_requisitos': cumpleRequisitos,
      if (analista != null) 'analista': analista,
    };
  }
}

class TemperaturaFusion {
  final String tipo; // "unica" | "rango"
  final String unidad; // "C°" | "K°" | "F°"
  final double? valor; // si es única
  final double? minima; // si es rango
  final double? maxima; // si es rango

  TemperaturaFusion({
    required this.tipo,
    required this.unidad,
    this.valor,
    this.minima,
    this.maxima,
  });

  factory TemperaturaFusion.fromMap(Map<String, dynamic> map) {
    return TemperaturaFusion(
      tipo: map['tipo'] ?? 'unica',
      unidad: map['unidad'] ?? 'C°',
      valor: map['valor']?.toDouble(),
      minima: map['minima']?.toDouble(),
      maxima: map['maxima']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'unidad': unidad,
      if (valor != null) 'valor': valor,
      if (minima != null) 'minima': minima,
      if (maxima != null) 'maxima': maxima,
    };
  }
}