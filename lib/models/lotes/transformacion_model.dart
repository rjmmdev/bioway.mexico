import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para representar una transformación de múltiples lotes en el reciclador
class TransformacionModel {
  final String id;
  final String tipo; // 'agrupacion_reciclador'
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String estado; // 'en_proceso', 'completada', 'documentada'
  final List<LoteEntrada> lotesEntrada;
  final double pesoTotalEntrada;
  final double pesoDisponible;
  final double mermaProceso;
  final List<String> sublotesGenerados;
  final List<String> documentosAsociados;
  final String usuarioId;
  final String usuarioFolio;
  final String? procesoAplicado;
  final String? observaciones;
  
  TransformacionModel({
    required this.id,
    required this.tipo,
    required this.fechaInicio,
    this.fechaFin,
    required this.estado,
    required this.lotesEntrada,
    required this.pesoTotalEntrada,
    required this.pesoDisponible,
    required this.mermaProceso,
    required this.sublotesGenerados,
    required this.documentosAsociados,
    required this.usuarioId,
    required this.usuarioFolio,
    this.procesoAplicado,
    this.observaciones,
  });
  
  factory TransformacionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TransformacionModel(
      id: doc.id,
      tipo: data['tipo'] ?? 'agrupacion_reciclador',
      fechaInicio: (data['fecha_inicio'] as Timestamp).toDate(),
      fechaFin: data['fecha_fin'] != null 
          ? (data['fecha_fin'] as Timestamp).toDate() 
          : null,
      estado: data['estado'] ?? 'en_proceso',
      lotesEntrada: (data['lotes_entrada'] as List<dynamic>)
          .map((e) => LoteEntrada.fromMap(e as Map<String, dynamic>))
          .toList(),
      pesoTotalEntrada: (data['peso_total_entrada'] ?? 0.0).toDouble(),
      pesoDisponible: (data['peso_disponible'] ?? 0.0).toDouble(),
      mermaProceso: (data['merma_proceso'] ?? 0.0).toDouble(),
      sublotesGenerados: List<String>.from(data['sublotes_generados'] ?? []),
      documentosAsociados: List<String>.from(data['documentos_asociados'] ?? []),
      usuarioId: data['usuario_id'] ?? '',
      usuarioFolio: data['usuario_folio'] ?? '',
      procesoAplicado: data['proceso_aplicado'],
      observaciones: data['observaciones'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'fecha_inicio': Timestamp.fromDate(fechaInicio),
      'fecha_fin': fechaFin != null ? Timestamp.fromDate(fechaFin!) : null,
      'estado': estado,
      'lotes_entrada': lotesEntrada.map((e) => e.toMap()).toList(),
      'peso_total_entrada': pesoTotalEntrada,
      'peso_disponible': pesoDisponible,
      'merma_proceso': mermaProceso,
      'sublotes_generados': sublotesGenerados,
      'documentos_asociados': documentosAsociados,
      'usuario_id': usuarioId,
      'usuario_folio': usuarioFolio,
      'proceso_aplicado': procesoAplicado,
      'observaciones': observaciones,
    };
  }
  
  /// Calcula el porcentaje de merma
  double get porcentajeMerma {
    if (pesoTotalEntrada == 0) return 0;
    return (mermaProceso / pesoTotalEntrada) * 100;
  }
  
  /// Verifica si hay peso disponible para crear sublotes
  bool get tienePesoDisponible => pesoDisponible > 0;
  
  /// Calcula el peso total asignado a sublotes
  double get pesoAsignadoSublotes => pesoTotalEntrada - mermaProceso - pesoDisponible;
}

/// Modelo para representar un lote de entrada en la transformación
class LoteEntrada {
  final String loteId;
  final double peso;
  final double porcentaje;
  final String tipoMaterial;
  
  LoteEntrada({
    required this.loteId,
    required this.peso,
    required this.porcentaje,
    required this.tipoMaterial,
  });
  
  factory LoteEntrada.fromMap(Map<String, dynamic> map) {
    return LoteEntrada(
      loteId: map['lote_id'] ?? '',
      peso: (map['peso'] ?? 0.0).toDouble(),
      porcentaje: (map['porcentaje'] ?? 0.0).toDouble(),
      tipoMaterial: map['tipo_material'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'lote_id': loteId,
      'peso': peso,
      'porcentaje': porcentaje,
      'tipo_material': tipoMaterial,
    };
  }
}