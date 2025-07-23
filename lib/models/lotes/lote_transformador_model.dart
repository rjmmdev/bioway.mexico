import 'package:cloud_firestore/cloud_firestore.dart';

class LoteTransformadorModel {
  final String? id; // Firebase ID
  final List<String>? lotesRecibidos; // Lotes recibidos
  final DateTime? fechaCreacion;
  final String? proveedor;
  final double? pesoIngreso; // Peso de entrada
  final List<String>? tiposAnalisis; // Tipos de análisis realizados
  final String? productoFabricado; // Producto fabricado
  final String? composicionMaterial;
  final String? operadorRecibe;
  final String? firmaRecibe; // URL de la firma
  final List<String>? evidenciaFotografica; // Evidencias fotográficas
  final List<String>? procesosAplicados; // Procesos aplicados después
  final String? comentarios;
  final String? tipoPolimero; // Tipo de polímero predominante
  final String? estado; // Estado del lote
  
  // Campos legacy para compatibilidad
  List<String> get lotes => lotesRecibidos ?? [];
  List<String> get procesos => tiposAnalisis ?? [];
  String get producto => productoFabricado ?? '';
  double get pctReciclado => 33.0; // Valor fijo
  String? get tipoPoli => tipoPolimero;
  double get productoMasa => pesoIngreso ?? 0.0;
  String get nombreOpe => operadorRecibe ?? '';
  String? get firmaOpe => firmaRecibe;
  String? get observaciones => comentarios;
  List<String> get eviFoto => evidenciaFotografica ?? [];
  String? get fTecnicaPelletLab => null; // URL ficha técnica
  DateTime get fechaTransformacion => fechaCreacion ?? DateTime.now();

  LoteTransformadorModel({
    this.id,
    this.lotesRecibidos,
    this.fechaCreacion,
    this.proveedor,
    this.pesoIngreso,
    this.tiposAnalisis,
    this.productoFabricado,
    this.composicionMaterial,
    this.operadorRecibe,
    this.firmaRecibe,
    this.evidenciaFotografica,
    this.procesosAplicados,
    this.comentarios,
    this.tipoPolimero,
    this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'ecoce_transformador_lotes_recibidos': lotesRecibidos,
      'fecha_creacion': fechaCreacion != null ? Timestamp.fromDate(fechaCreacion!) : null,
      'ecoce_transformador_proveedor': proveedor,
      'ecoce_transformador_peso_ingreso': pesoIngreso,
      'ecoce_transformador_tipos_analisis': tiposAnalisis,
      'ecoce_transformador_producto_fabricado': productoFabricado,
      'ecoce_transformador_composicion_material': composicionMaterial,
      'ecoce_transformador_operador_recibe': operadorRecibe,
      'ecoce_transformador_firma_recibe': firmaRecibe,
      'ecoce_transformador_evidencia_fotografica': evidenciaFotografica,
      'ecoce_transformador_procesos_aplicados': procesosAplicados,
      'ecoce_transformador_comentarios': comentarios,
      'ecoce_transformador_tipo_polimero': tipoPolimero,
      'estado': estado,
      // Legacy fields for compatibility
      'ecoce_transformador_lotes': lotes,
      'ecoce_transformador_procesos': procesos,
      'ecoce_transformador_producto': producto,
      'ecoce_transformador_pct_reciclado': pctReciclado,
      'ecoce_transformador_tipo_poli': tipoPoli,
      'ecoce_transformador_producto_masa': productoMasa,
      'ecoce_transformador_nombre_ope': nombreOpe,
      'ecoce_transformador_firma_ope': firmaOpe,
      'ecoce_transformador_observaciones': observaciones,
      'ecoce_transformador_evi_foto': eviFoto,
      'ecoce_transformador_f_tecnica_pellet_lab': fTecnicaPelletLab,
      'fecha_transformacion': Timestamp.fromDate(fechaTransformacion),
    };
  }

  factory LoteTransformadorModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LoteTransformadorModel(
      id: doc.id,
      lotesRecibidos: data['ecoce_transformador_lotes_recibidos'] != null 
          ? List<String>.from(data['ecoce_transformador_lotes_recibidos']) 
          : (data['ecoce_transformador_lotes'] != null ? List<String>.from(data['ecoce_transformador_lotes']) : null),
      fechaCreacion: data['fecha_creacion'] != null 
          ? (data['fecha_creacion'] as Timestamp).toDate() 
          : (data['fecha_transformacion'] != null ? (data['fecha_transformacion'] as Timestamp).toDate() : null),
      proveedor: data['ecoce_transformador_proveedor'],
      pesoIngreso: data['ecoce_transformador_peso_ingreso']?.toDouble() 
          ?? data['ecoce_transformador_producto_masa']?.toDouble(),
      tiposAnalisis: data['ecoce_transformador_tipos_analisis'] != null 
          ? List<String>.from(data['ecoce_transformador_tipos_analisis']) 
          : (data['ecoce_transformador_procesos'] != null ? List<String>.from(data['ecoce_transformador_procesos']) : null),
      productoFabricado: data['ecoce_transformador_producto_fabricado'] 
          ?? data['ecoce_transformador_producto'],
      composicionMaterial: data['ecoce_transformador_composicion_material'],
      operadorRecibe: data['ecoce_transformador_operador_recibe'] 
          ?? data['ecoce_transformador_nombre_ope'],
      firmaRecibe: data['ecoce_transformador_firma_recibe'] 
          ?? data['ecoce_transformador_firma_ope'],
      evidenciaFotografica: data['ecoce_transformador_evidencia_fotografica'] != null 
          ? List<String>.from(data['ecoce_transformador_evidencia_fotografica']) 
          : (data['ecoce_transformador_evi_foto'] != null ? List<String>.from(data['ecoce_transformador_evi_foto']) : null),
      procesosAplicados: data['ecoce_transformador_procesos_aplicados'] != null 
          ? List<String>.from(data['ecoce_transformador_procesos_aplicados']) 
          : null,
      comentarios: data['ecoce_transformador_comentarios'] 
          ?? data['ecoce_transformador_observaciones'],
      tipoPolimero: data['ecoce_transformador_tipo_polimero'] 
          ?? data['ecoce_transformador_tipo_poli'],
      estado: data['estado'],
    );
  }

  LoteTransformadorModel copyWith({
    String? id,
    List<String>? lotesRecibidos,
    DateTime? fechaCreacion,
    String? proveedor,
    double? pesoIngreso,
    List<String>? tiposAnalisis,
    String? productoFabricado,
    String? composicionMaterial,
    String? operadorRecibe,
    String? firmaRecibe,
    List<String>? evidenciaFotografica,
    List<String>? procesosAplicados,
    String? comentarios,
    String? tipoPolimero,
    String? estado,
  }) {
    return LoteTransformadorModel(
      id: id ?? this.id,
      lotesRecibidos: lotesRecibidos ?? this.lotesRecibidos,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      proveedor: proveedor ?? this.proveedor,
      pesoIngreso: pesoIngreso ?? this.pesoIngreso,
      tiposAnalisis: tiposAnalisis ?? this.tiposAnalisis,
      productoFabricado: productoFabricado ?? this.productoFabricado,
      composicionMaterial: composicionMaterial ?? this.composicionMaterial,
      operadorRecibe: operadorRecibe ?? this.operadorRecibe,
      firmaRecibe: firmaRecibe ?? this.firmaRecibe,
      evidenciaFotografica: evidenciaFotografica ?? this.evidenciaFotografica,
      procesosAplicados: procesosAplicados ?? this.procesosAplicados,
      comentarios: comentarios ?? this.comentarios,
      tipoPolimero: tipoPolimero ?? this.tipoPolimero,
      estado: estado ?? this.estado,
    );
  }

  // Lista de procesos disponibles
  static const List<String> procesosDisponibles = [
    'Inyección',
    'Soplado',
    'Extrusión',
    'Rotomoldeo',
    'Termoformado',
    'Compresión',
    'Calandrado',
    'Laminado',
  ];

  // Obtener descripción del porcentaje reciclado
  String getPorcentajeRecicladoDesc() {
    return '${pctReciclado.toStringAsFixed(0)}% Material Reciclado';
  }
}