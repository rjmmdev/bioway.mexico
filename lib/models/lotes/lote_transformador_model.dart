import 'package:cloud_firestore/cloud_firestore.dart';

class LoteTransformadorModel {
  final String? id; // Firebase ID
  final String userId; // ID del usuario propietario del lote
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
  
  // Campos de salida
  final double? pesoSalida;
  final String? productoGenerado;
  final String? cantidadGenerada;
  final String? operadorSalida;
  final String? firmaSalida;
  final List<String>? evidenciasSalida;
  final String? comentariosSalida;
  final DateTime? fechaSalida;
  
  // Campos de documentación
  final Map<String, dynamic>? documentos;
  final DateTime? fechaDocumentacion;
  
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
    required this.userId,
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
    this.pesoSalida,
    this.productoGenerado,
    this.cantidadGenerada,
    this.operadorSalida,
    this.firmaSalida,
    this.evidenciasSalida,
    this.comentariosSalida,
    this.fechaSalida,
    this.documentos,
    this.fechaDocumentacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
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
      // Campos de salida
      'ecoce_transformador_peso_salida': pesoSalida,
      'ecoce_transformador_producto_generado': productoGenerado,
      'ecoce_transformador_cantidad_generada': cantidadGenerada,
      'ecoce_transformador_operador_salida': operadorSalida,
      'ecoce_transformador_firma_salida': firmaSalida,
      'ecoce_transformador_evidencias_salida': evidenciasSalida,
      'ecoce_transformador_comentarios_salida': comentariosSalida,
      'fecha_salida': fechaSalida != null ? Timestamp.fromDate(fechaSalida!) : null,
      // Campos de documentación
      'ecoce_transformador_documentos': documentos,
      'fecha_documentacion': fechaDocumentacion != null ? Timestamp.fromDate(fechaDocumentacion!) : null,
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
      userId: data['userId'] ?? '',
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
      // Campos de salida
      pesoSalida: data['ecoce_transformador_peso_salida']?.toDouble(),
      productoGenerado: data['ecoce_transformador_producto_generado'],
      cantidadGenerada: data['ecoce_transformador_cantidad_generada'],
      operadorSalida: data['ecoce_transformador_operador_salida'],
      firmaSalida: data['ecoce_transformador_firma_salida'],
      evidenciasSalida: data['ecoce_transformador_evidencias_salida'] != null 
          ? List<String>.from(data['ecoce_transformador_evidencias_salida']) 
          : null,
      comentariosSalida: data['ecoce_transformador_comentarios_salida'],
      fechaSalida: data['fecha_salida'] != null 
          ? (data['fecha_salida'] as Timestamp).toDate() 
          : null,
      // Campos de documentación
      documentos: data['ecoce_transformador_documentos'],
      fechaDocumentacion: data['fecha_documentacion'] != null 
          ? (data['fecha_documentacion'] as Timestamp).toDate() 
          : null,
    );
  }

  LoteTransformadorModel copyWith({
    String? id,
    String? userId,
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
    double? pesoSalida,
    String? productoGenerado,
    String? cantidadGenerada,
    String? operadorSalida,
    String? firmaSalida,
    List<String>? evidenciasSalida,
    String? comentariosSalida,
    DateTime? fechaSalida,
    Map<String, dynamic>? documentos,
    DateTime? fechaDocumentacion,
  }) {
    return LoteTransformadorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
      pesoSalida: pesoSalida ?? this.pesoSalida,
      productoGenerado: productoGenerado ?? this.productoGenerado,
      cantidadGenerada: cantidadGenerada ?? this.cantidadGenerada,
      operadorSalida: operadorSalida ?? this.operadorSalida,
      firmaSalida: firmaSalida ?? this.firmaSalida,
      evidenciasSalida: evidenciasSalida ?? this.evidenciasSalida,
      comentariosSalida: comentariosSalida ?? this.comentariosSalida,
      fechaSalida: fechaSalida ?? this.fechaSalida,
      documentos: documentos ?? this.documentos,
      fechaDocumentacion: fechaDocumentacion ?? this.fechaDocumentacion,
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