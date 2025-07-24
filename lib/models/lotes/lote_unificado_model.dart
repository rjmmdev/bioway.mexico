import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo unificado para lotes con ID único e inmutable
class LoteUnificadoModel {
  // Identificador único inmutable
  final String id;
  
  // Datos generales (siempre presentes)
  final DatosGeneralesLote datosGenerales;
  
  // Datos por proceso (pueden ser null si no ha pasado por ese proceso)
  final ProcesoOrigenData? origen;
  final ProcesoTransporteData? transporte;
  final ProcesoRecicladorData? reciclador;
  final ProcesoLaboratorioData? laboratorio;
  final ProcesoTransformadorData? transformador;
  
  LoteUnificadoModel({
    required this.id,
    required this.datosGenerales,
    this.origen,
    this.transporte,
    this.reciclador,
    this.laboratorio,
    this.transformador,
  });
  
  /// Crear desde documentos de Firestore
  factory LoteUnificadoModel.fromFirestore({
    required String id,
    required DocumentSnapshot datosGenerales,
    DocumentSnapshot? origen,
    DocumentSnapshot? transporte,
    DocumentSnapshot? reciclador,
    DocumentSnapshot? laboratorio,
    DocumentSnapshot? transformador,
  }) {
    return LoteUnificadoModel(
      id: id,
      datosGenerales: DatosGeneralesLote.fromMap(
        datosGenerales.data() as Map<String, dynamic>,
      ),
      origen: origen != null 
          ? ProcesoOrigenData.fromMap(origen.data() as Map<String, dynamic>)
          : null,
      transporte: transporte != null
          ? ProcesoTransporteData.fromMap(transporte.data() as Map<String, dynamic>)
          : null,
      reciclador: reciclador != null
          ? ProcesoRecicladorData.fromMap(reciclador.data() as Map<String, dynamic>)
          : null,
      laboratorio: laboratorio != null
          ? ProcesoLaboratorioData.fromMap(laboratorio.data() as Map<String, dynamic>)
          : null,
      transformador: transformador != null
          ? ProcesoTransformadorData.fromMap(transformador.data() as Map<String, dynamic>)
          : null,
    );
  }
  
  /// Verificar si un usuario ha participado en el lote
  bool usuarioHaParticipado(String userId) {
    return (origen?.usuarioId == userId) ||
           (transporte?.usuarioId == userId) ||
           (reciclador?.usuarioId == userId) ||
           (laboratorio?.usuarioId == userId) ||
           (transformador?.usuarioId == userId);
  }
  
  /// Obtener el peso actual del lote según el último proceso
  double get pesoActual {
    // Retornar el peso del proceso más reciente
    if (transformador != null) return transformador!.pesoSalida ?? transformador!.pesoEntrada;
    if (laboratorio != null) return laboratorio!.pesoMuestra;
    if (reciclador != null) return reciclador!.pesoProcesado ?? reciclador!.pesoEntrada;
    if (transporte != null) return transporte!.pesoEntregado ?? transporte!.pesoRecogido;
    if (origen != null) return origen!.pesoNace;
    return datosGenerales.pesoInicial;
  }
  
  /// Obtener la merma total acumulada
  double get mermaTotal {
    double merma = 0.0;
    
    if (transporte != null) {
      merma += transporte!.merma ?? 0.0;
    }
    if (reciclador != null) {
      merma += reciclador!.mermaProceso ?? 0.0;
    }
    if (transformador != null) {
      merma += transformador!.mermaTransformacion ?? 0.0;
    }
    
    return merma;
  }
  
  /// Obtener el porcentaje de merma
  double get porcentajeMerma {
    if (datosGenerales.pesoInicial == 0) return 0;
    return (mermaTotal / datosGenerales.pesoInicial) * 100;
  }
}

/// Datos generales del lote (siempre presentes)
class DatosGeneralesLote {
  final String id;
  final DateTime fechaCreacion;
  final String creadoPor;
  final String tipoMaterial;
  final double pesoInicial;
  final double peso;
  final String estadoActual;
  final String procesoActual;
  final List<String> historialProcesos;
  final String qrCode;
  final String? materialPresentacion;
  final String? materialFuente;
  
  DatosGeneralesLote({
    required this.id,
    required this.fechaCreacion,
    required this.creadoPor,
    required this.tipoMaterial,
    required this.pesoInicial,
    required this.peso,
    required this.estadoActual,
    required this.procesoActual,
    required this.historialProcesos,
    required this.qrCode,
    this.materialPresentacion,
    this.materialFuente,
  });
  
  factory DatosGeneralesLote.fromMap(Map<String, dynamic> map) {
    return DatosGeneralesLote(
      id: map['id'] ?? '',
      fechaCreacion: (map['fecha_creacion'] as Timestamp).toDate(),
      creadoPor: map['creado_por'] ?? '',
      tipoMaterial: map['tipo_material'] ?? '',
      pesoInicial: (map['peso_inicial'] ?? 0.0).toDouble(),
      peso: (map['peso'] ?? map['peso_inicial'] ?? 0.0).toDouble(),
      estadoActual: map['estado_actual'] ?? '',
      procesoActual: map['proceso_actual'] ?? '',
      historialProcesos: List<String>.from(map['historial_procesos'] ?? []),
      qrCode: map['qr_code'] ?? '',
      materialPresentacion: map['material_presentacion'],
      materialFuente: map['material_fuente'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'creado_por': creadoPor,
      'tipo_material': tipoMaterial,
      'peso_inicial': pesoInicial,
      'peso': peso,
      'estado_actual': estadoActual,
      'proceso_actual': procesoActual,
      'historial_procesos': historialProcesos,
      'qr_code': qrCode,
      'material_presentacion': materialPresentacion,
      'material_fuente': materialFuente,
    };
  }
}

/// Datos del proceso Origen
class ProcesoOrigenData {
  final String usuarioId;
  final String usuarioFolio;
  final DateTime fechaEntrada;
  final DateTime? fechaSalida;
  final String direccion;
  final String fuente;
  final String presentacion;
  final String tipoPoli;
  final String origen; // Pre/Post consumo
  final double pesoNace;
  final String condiciones;
  final String nombreOperador;
  final String? firmaOperador;
  final String? comentarios;
  final List<String> evidenciasFoto;
  final String qrCode;
  
  ProcesoOrigenData({
    required this.usuarioId,
    required this.usuarioFolio,
    required this.fechaEntrada,
    this.fechaSalida,
    required this.direccion,
    required this.fuente,
    required this.presentacion,
    required this.tipoPoli,
    required this.origen,
    required this.pesoNace,
    required this.condiciones,
    required this.nombreOperador,
    this.firmaOperador,
    this.comentarios,
    required this.evidenciasFoto,
    required this.qrCode,
  });
  
  factory ProcesoOrigenData.fromMap(Map<String, dynamic> map) {
    return ProcesoOrigenData(
      usuarioId: map['usuario_id'] ?? '',
      usuarioFolio: map['usuario_folio'] ?? '',
      fechaEntrada: (map['fecha_entrada'] as Timestamp).toDate(),
      fechaSalida: map['fecha_salida'] != null 
          ? (map['fecha_salida'] as Timestamp).toDate() 
          : null,
      direccion: map['direccion'] ?? '',
      fuente: map['fuente'] ?? '',
      presentacion: map['presentacion'] ?? '',
      tipoPoli: map['tipo_poli'] ?? '',
      origen: map['origen'] ?? '',
      pesoNace: (map['peso_nace'] ?? 0.0).toDouble(),
      condiciones: map['condiciones'] ?? '',
      nombreOperador: map['nombre_operador'] ?? '',
      firmaOperador: map['firma_operador'],
      comentarios: map['comentarios'],
      evidenciasFoto: List<String>.from(map['evidencias_foto'] ?? []),
      qrCode: map['qr_code'] ?? '',
    );
  }
}

/// Datos del proceso Transporte
class ProcesoTransporteData {
  final String usuarioId;
  final String usuarioFolio;
  final DateTime fechaEntrada;
  final DateTime? fechaSalida;
  final String origenRecogida;
  final String? destinoEntrega;
  final double pesoRecogido;
  final double? pesoEntregado;
  final double? merma;
  final String? condicionesTransporte;
  final String? firmaRecogida;
  final String? firmaEntrega;
  final List<String> evidenciasFoto;
  
  ProcesoTransporteData({
    required this.usuarioId,
    required this.usuarioFolio,
    required this.fechaEntrada,
    this.fechaSalida,
    required this.origenRecogida,
    this.destinoEntrega,
    required this.pesoRecogido,
    this.pesoEntregado,
    this.merma,
    this.condicionesTransporte,
    this.firmaRecogida,
    this.firmaEntrega,
    required this.evidenciasFoto,
  });
  
  factory ProcesoTransporteData.fromMap(Map<String, dynamic> map) {
    return ProcesoTransporteData(
      usuarioId: map['usuario_id'] ?? '',
      usuarioFolio: map['usuario_folio'] ?? '',
      fechaEntrada: (map['fecha_entrada'] as Timestamp).toDate(),
      fechaSalida: map['fecha_salida'] != null 
          ? (map['fecha_salida'] as Timestamp).toDate() 
          : null,
      origenRecogida: map['origen_recogida'] ?? '',
      destinoEntrega: map['destino_entrega'],
      pesoRecogido: (map['peso_recogido'] ?? 0.0).toDouble(),
      pesoEntregado: map['peso_entregado'] != null 
          ? (map['peso_entregado'] as num).toDouble() 
          : null,
      merma: map['merma'] != null ? (map['merma'] as num).toDouble() : null,
      condicionesTransporte: map['condiciones_transporte'],
      firmaRecogida: map['firma_recogida'],
      firmaEntrega: map['firma_entrega'],
      evidenciasFoto: List<String>.from(map['evidencias_foto'] ?? []),
    );
  }
}

/// Datos del proceso Reciclador
class ProcesoRecicladorData {
  final String usuarioId;
  final String usuarioFolio;
  final DateTime fechaEntrada;
  final DateTime? fechaSalida;
  final double pesoEntrada;
  final double? pesoProcesado;
  final double? mermaProceso;
  final String? procesoAplicado;
  final String? condicionesSalida;
  final List<String> evidenciasFoto;
  
  ProcesoRecicladorData({
    required this.usuarioId,
    required this.usuarioFolio,
    required this.fechaEntrada,
    this.fechaSalida,
    required this.pesoEntrada,
    this.pesoProcesado,
    this.mermaProceso,
    this.procesoAplicado,
    this.condicionesSalida,
    required this.evidenciasFoto,
  });
  
  factory ProcesoRecicladorData.fromMap(Map<String, dynamic> map) {
    return ProcesoRecicladorData(
      usuarioId: map['usuario_id'] ?? '',
      usuarioFolio: map['usuario_folio'] ?? '',
      fechaEntrada: (map['fecha_entrada'] as Timestamp).toDate(),
      fechaSalida: map['fecha_salida'] != null 
          ? (map['fecha_salida'] as Timestamp).toDate() 
          : null,
      pesoEntrada: (map['peso_entrada'] ?? 0.0).toDouble(),
      pesoProcesado: map['peso_procesado'] != null 
          ? (map['peso_procesado'] as num).toDouble() 
          : null,
      mermaProceso: map['merma_proceso'] != null 
          ? (map['merma_proceso'] as num).toDouble() 
          : null,
      procesoAplicado: map['proceso_aplicado'],
      condicionesSalida: map['condiciones_salida'],
      evidenciasFoto: List<String>.from(map['evidencias_foto'] ?? []),
    );
  }
}

/// Datos del proceso Laboratorio
class ProcesoLaboratorioData {
  final String usuarioId;
  final String usuarioFolio;
  final DateTime fechaEntrada;
  final DateTime? fechaSalida;
  final double pesoMuestra;
  final List<String> tipoAnalisis;
  final Map<String, dynamic>? resultados;
  final String? certificado;
  final String? observaciones;
  
  ProcesoLaboratorioData({
    required this.usuarioId,
    required this.usuarioFolio,
    required this.fechaEntrada,
    this.fechaSalida,
    required this.pesoMuestra,
    required this.tipoAnalisis,
    this.resultados,
    this.certificado,
    this.observaciones,
  });
  
  factory ProcesoLaboratorioData.fromMap(Map<String, dynamic> map) {
    return ProcesoLaboratorioData(
      usuarioId: map['usuario_id'] ?? '',
      usuarioFolio: map['usuario_folio'] ?? '',
      fechaEntrada: (map['fecha_entrada'] as Timestamp).toDate(),
      fechaSalida: map['fecha_salida'] != null 
          ? (map['fecha_salida'] as Timestamp).toDate() 
          : null,
      pesoMuestra: (map['peso_muestra'] ?? 0.0).toDouble(),
      tipoAnalisis: List<String>.from(map['tipo_analisis'] ?? []),
      resultados: map['resultados'] as Map<String, dynamic>?,
      certificado: map['certificado'],
      observaciones: map['observaciones'],
    );
  }
}

/// Datos del proceso Transformador
class ProcesoTransformadorData {
  final String usuarioId;
  final String usuarioFolio;
  final DateTime fechaEntrada;
  final DateTime? fechaSalida;
  final double pesoEntrada;
  final double? pesoSalida;
  final double? mermaTransformacion;
  final String? tipoProducto;
  final Map<String, dynamic>? especificaciones;
  final List<String> evidenciasFoto;
  
  ProcesoTransformadorData({
    required this.usuarioId,
    required this.usuarioFolio,
    required this.fechaEntrada,
    this.fechaSalida,
    required this.pesoEntrada,
    this.pesoSalida,
    this.mermaTransformacion,
    this.tipoProducto,
    this.especificaciones,
    required this.evidenciasFoto,
  });
  
  factory ProcesoTransformadorData.fromMap(Map<String, dynamic> map) {
    return ProcesoTransformadorData(
      usuarioId: map['usuario_id'] ?? '',
      usuarioFolio: map['usuario_folio'] ?? '',
      fechaEntrada: (map['fecha_entrada'] as Timestamp).toDate(),
      fechaSalida: map['fecha_salida'] != null 
          ? (map['fecha_salida'] as Timestamp).toDate() 
          : null,
      pesoEntrada: (map['peso_entrada'] ?? 0.0).toDouble(),
      pesoSalida: map['peso_salida'] != null 
          ? (map['peso_salida'] as num).toDouble() 
          : null,
      mermaTransformacion: map['merma_transformacion'] != null 
          ? (map['merma_transformacion'] as num).toDouble() 
          : null,
      tipoProducto: map['tipo_producto'],
      especificaciones: map['especificaciones'] as Map<String, dynamic>?,
      evidenciasFoto: List<String>.from(map['evidencias_foto'] ?? []),
    );
  }
}