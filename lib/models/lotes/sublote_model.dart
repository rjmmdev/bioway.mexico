import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para representar un sublote derivado de una transformación
class SubloteModel {
  final String id;
  final String tipo; // 'derivado'
  final String transformacionOrigen; // ID de la transformación que lo generó
  final double peso;
  final Map<String, ComposicionLote> composicion;
  final String procesoActual;
  final String qrCode;
  final DateTime fechaCreacion;
  final String creadoPor;
  final String creadoPorFolio;
  final String estadoActual;
  final List<String> historialProcesos;
  
  SubloteModel({
    required this.id,
    required this.tipo,
    required this.transformacionOrigen,
    required this.peso,
    required this.composicion,
    required this.procesoActual,
    required this.qrCode,
    required this.fechaCreacion,
    required this.creadoPor,
    required this.creadoPorFolio,
    required this.estadoActual,
    required this.historialProcesos,
  });
  
  factory SubloteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final composicionMap = <String, ComposicionLote>{};
    final composicionData = data['composicion'] as Map<String, dynamic>? ?? {};
    composicionData.forEach((key, value) {
      composicionMap[key] = ComposicionLote.fromMap(value as Map<String, dynamic>);
    });
    
    return SubloteModel(
      id: doc.id,
      tipo: data['tipo'] ?? 'derivado',
      transformacionOrigen: data['transformacion_origen'] ?? '',
      peso: (data['peso'] ?? 0.0).toDouble(),
      composicion: composicionMap,
      procesoActual: data['proceso_actual'] ?? 'reciclador',
      qrCode: data['qr_code'] ?? '',
      fechaCreacion: (data['fecha_creacion'] as Timestamp).toDate(),
      creadoPor: data['creado_por'] ?? '',
      creadoPorFolio: data['creado_por_folio'] ?? '',
      estadoActual: data['estado_actual'] ?? 'activo',
      historialProcesos: List<String>.from(data['historial_procesos'] ?? []),
    );
  }
  
  Map<String, dynamic> toMap() {
    final composicionMap = <String, dynamic>{};
    composicion.forEach((key, value) {
      composicionMap[key] = value.toMap();
    });
    
    return {
      'tipo': tipo,
      'transformacion_origen': transformacionOrigen,
      'peso': peso,
      'composicion': composicionMap,
      'proceso_actual': procesoActual,
      'qr_code': qrCode,
      'fecha_creacion': Timestamp.fromDate(fechaCreacion),
      'creado_por': creadoPor,
      'creado_por_folio': creadoPorFolio,
      'estado_actual': estadoActual,
      'historial_procesos': historialProcesos,
    };
  }
  
  /// Obtiene el material predominante basado en la composición
  String get materialPredominante {
    String material = '';
    double maxPorcentaje = 0;
    
    composicion.forEach((loteId, comp) {
      if (comp.porcentaje > maxPorcentaje) {
        maxPorcentaje = comp.porcentaje;
        material = comp.tipoMaterial;
      }
    });
    
    return material;
  }
  
  /// Verifica si el sublote puede ser transferido
  bool get puedeSerTransferido => estadoActual == 'activo' && peso > 0;
}

/// Modelo para representar la composición de un lote en el sublote
class ComposicionLote {
  final double pesoAportado;
  final double porcentaje;
  final String tipoMaterial;
  
  ComposicionLote({
    required this.pesoAportado,
    required this.porcentaje,
    required this.tipoMaterial,
  });
  
  factory ComposicionLote.fromMap(Map<String, dynamic> map) {
    return ComposicionLote(
      pesoAportado: (map['peso_aportado'] ?? 0.0).toDouble(),
      porcentaje: (map['porcentaje'] ?? 0.0).toDouble(),
      tipoMaterial: map['tipo_material'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'peso_aportado': pesoAportado,
      'porcentaje': porcentaje,
      'tipo_material': tipoMaterial,
    };
  }
}