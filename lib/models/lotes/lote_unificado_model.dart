import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo unificado para lotes con ID único e inmutable
class LoteUnificadoModel {
  // Identificador único inmutable
  final String id;
  
  // Datos generales (siempre presentes)
  final DatosGeneralesLote datosGenerales;
  
  // Datos por proceso (pueden ser null si no ha pasado por ese proceso)
  final ProcesoOrigenData? origen;
  
  // Transporte con múltiples fases
  final Map<String, ProcesoTransporteData> transporteFases;
  
  final ProcesoRecicladorData? reciclador;
  
  // Laboratorio como proceso paralelo (no toma posesión del lote)
  final List<AnalisisLaboratorioData> analisisLaboratorio;
  
  final ProcesoTransformadorData? transformador;
  
  LoteUnificadoModel({
    required this.id,
    required this.datosGenerales,
    this.origen,
    Map<String, ProcesoTransporteData>? transporteFases,
    this.reciclador,
    List<AnalisisLaboratorioData>? analisisLaboratorio,
    this.transformador,
  }) : transporteFases = transporteFases ?? {},
        analisisLaboratorio = analisisLaboratorio ?? [];
  
  // Getter de compatibilidad para código existente
  ProcesoTransporteData? get transporte => transporteFases['fase_1'];
  
  /// Crear desde documentos de Firestore
  factory LoteUnificadoModel.fromFirestore({
    required String id,
    required DocumentSnapshot datosGenerales,
    DocumentSnapshot? origen,
    Map<String, DocumentSnapshot>? transporteFases,
    DocumentSnapshot? reciclador,
    List<DocumentSnapshot>? analisisLaboratorio,
    DocumentSnapshot? transformador,
  }) {
    // Convertir documentos de transporte a Map de ProcesoTransporteData
    final Map<String, ProcesoTransporteData> fasesTransporte = {};
    transporteFases?.forEach((fase, doc) {
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data is Map) {
          fasesTransporte[fase] = ProcesoTransporteData.fromMap(
            Map<String, dynamic>.from(data),
          );
        }
      }
    });
    
    // Convertir documentos de análisis de laboratorio
    final List<AnalisisLaboratorioData> analisis = [];
    analisisLaboratorio?.forEach((doc) {
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data is Map) {
          analisis.add(AnalisisLaboratorioData.fromMap(
            Map<String, dynamic>.from(data),
          ));
        }
      }
    });
    
    return LoteUnificadoModel(
      id: id,
      datosGenerales: DatosGeneralesLote.fromMap(
        Map<String, dynamic>.from(datosGenerales.data() as Map),
      ),
      origen: origen != null && origen.exists && origen.data() != null
          ? ProcesoOrigenData.fromMap(Map<String, dynamic>.from(origen.data() as Map))
          : null,
      transporteFases: fasesTransporte,
      reciclador: reciclador != null && reciclador.exists && reciclador.data() != null
          ? ProcesoRecicladorData.fromMap(Map<String, dynamic>.from(reciclador.data() as Map))
          : null,
      analisisLaboratorio: analisis,
      transformador: transformador != null && transformador.exists && transformador.data() != null
          ? ProcesoTransformadorData.fromMap(Map<String, dynamic>.from(transformador.data() as Map))
          : null,
    );
  }
  
  /// Verificar si un usuario ha participado en el lote
  bool usuarioHaParticipado(String userId) {
    // Verificar en todas las fases de transporte
    final participoEnTransporte = transporteFases.values.any(
      (fase) => fase.usuarioId == userId
    );
    
    // Verificar en todos los análisis de laboratorio
    final participoEnLaboratorio = analisisLaboratorio.any(
      (analisis) => analisis.usuarioId == userId
    );
    
    return (origen?.usuarioId == userId) ||
           participoEnTransporte ||
           (reciclador?.usuarioId == userId) ||
           participoEnLaboratorio ||
           (transformador?.usuarioId == userId);
  }
  
  /// Obtener el peso actual del lote según el último proceso
  double get pesoActual {
    final proceso = datosGenerales.procesoActual;
    
    // TRANSFORMADOR: Prioriza SU peso procesado/recibido
    if (proceso == 'transformador') {
      // Primero buscar el peso que el transformador registró
      if (transformador != null && transformador!.pesoSalida != null && transformador!.pesoSalida! > 0) {
        // Este es el peso neto aprovechable que el transformador tiene disponible
        return transformador!.pesoSalida!;
      }
      
      // Fallback: Si no hay datos del transformador, usar peso del reciclador
      if (reciclador != null) {
        double pesoReciclador = reciclador!.pesoProcesado ?? reciclador!.pesoEntrada ?? 0;
        // Restar muestras de laboratorio si las hay
        double pesoMuestras = analisisLaboratorio.fold(0.0, 
          (sum, analisis) => sum + analisis.pesoMuestra
        );
        final pesoNeto = pesoReciclador - pesoMuestras;
        if (pesoNeto > 0) return pesoNeto;
      }
      
      // Fallback: buscar en transporte fase_2
      if (transporteFases.containsKey('fase_2')) {
        final fase2 = transporteFases['fase_2']!;
        final pesoTransporte = fase2.pesoEntregado ?? fase2.pesoRecogido ?? 0;
        if (pesoTransporte > 0) return pesoTransporte;
      }
      
      // Último fallback: datos generales
      if (datosGenerales.peso > 0) return datosGenerales.peso;
      if (datosGenerales.pesoInicial > 0) return datosGenerales.pesoInicial;
    }
    
    // TRANSPORTE: Usa el peso que está transportando (del proceso anterior)
    if (proceso == 'transporte') {
      // Determinar qué fase de transporte es
      final fase = determinarFaseTransporte();
      
      if (fase == 'fase_2') {
        // Transportando desde reciclador hacia transformador
        if (reciclador != null) {
          double pesoReciclador = reciclador!.pesoProcesado ?? reciclador!.pesoEntrada ?? 0;
          // Restar muestras de laboratorio si las hay
          double pesoMuestras = analisisLaboratorio.fold(0.0, 
            (sum, analisis) => sum + analisis.pesoMuestra
          );
          return pesoReciclador - pesoMuestras;
        }
      } else if (fase == 'fase_1') {
        // Transportando desde origen hacia reciclador
        if (origen != null && origen!.pesoNace > 0) {
          return origen!.pesoNace;
        }
      }
      
      // Fallback: verificar las fases de transporte directamente
      if (transporteFases.containsKey('fase_2')) {
        final fase2 = transporteFases['fase_2']!;
        final pesoTransporte = fase2.pesoRecogido ?? 0;
        if (pesoTransporte > 0) return pesoTransporte;
      }
      if (transporteFases.containsKey('fase_1')) {
        final fase1 = transporteFases['fase_1']!;
        final pesoTransporte = fase1.pesoRecogido ?? 0;
        if (pesoTransporte > 0) return pesoTransporte;
      }
    }
    
    // RECICLADOR: Usa su peso procesado
    if (proceso == 'reciclador' && reciclador != null) {
      // Si hay análisis de laboratorio, restar el peso de las muestras
      double pesoReciclador = reciclador!.pesoProcesado ?? reciclador!.pesoEntrada;
      double pesoMuestras = analisisLaboratorio.fold(0.0, 
        (sum, analisis) => sum + analisis.pesoMuestra
      );
      return pesoReciclador - pesoMuestras;
    }
    
    // ORIGEN: Usa su peso inicial
    if (proceso == 'origen' && origen != null && origen!.pesoNace > 0) {
      return origen!.pesoNace;
    }
    
    // FALLBACK GENERAL: Para cualquier otro caso
    // Verificar fase_1 de transporte (origen -> reciclador)
    if (transporteFases.containsKey('fase_1')) {
      final fase1 = transporteFases['fase_1']!;
      final pesoTransporte = fase1.pesoEntregado ?? fase1.pesoRecogido;
      if (pesoTransporte > 0) return pesoTransporte;
    }
    
    // Si hay origen, usar su peso
    if (origen != null && origen!.pesoNace > 0) return origen!.pesoNace;
    
    // Fallback final a datos generales
    return datosGenerales.peso ?? datosGenerales.pesoActual ?? datosGenerales.pesoNace ?? datosGenerales.pesoInicial ?? 0;
  }
  
  /// Obtener la merma total acumulada
  double get mermaTotal {
    double merma = 0.0;
    
    // Sumar merma de todas las fases de transporte
    transporteFases.values.forEach((fase) {
      merma += fase.merma ?? 0.0;
    });
    
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
  
  /// Obtener la fase de transporte más reciente
  ProcesoTransporteData? get transporteActual {
    if (transporteFases.containsKey('fase_2')) {
      return transporteFases['fase_2'];
    }
    return transporteFases['fase_1'];
  }
  
  /// Determinar la siguiente fase de transporte basado en el proceso actual
  String determinarFaseTransporte() {
    // Si el proceso actual es origen, es fase_1
    if (datosGenerales.procesoActual == 'origen') {
      return 'fase_1';
    }
    // Si el proceso actual es reciclador, es fase_2
    else if (datosGenerales.procesoActual == 'reciclador') {
      return 'fase_2';
    }
    // Por defecto retornar fase_1
    return 'fase_1';
  }
  
  /// Obtener el peso total de muestras tomadas por laboratorio
  double get pesoTotalMuestras {
    return analisisLaboratorio.fold(0.0, 
      (sum, analisis) => sum + analisis.pesoMuestra
    );
  }
  
  /// Verificar si el lote tiene análisis de laboratorio
  bool get tieneAnalisisLaboratorio => analisisLaboratorio.isNotEmpty;
  
  /// Verificar si el lote puede ser incluido en una transformación
  bool get puedeSerTransformado {
    // Solo lotes originales en proceso reciclador pueden ser transformados
    return datosGenerales.tipoLote == 'original' &&
           !datosGenerales.consumidoEnTransformacion &&
           datosGenerales.procesoActual == 'reciclador' &&
           reciclador != null;
  }
  
  /// Verificar si es un sublote
  bool get esSublote => datosGenerales.tipoLote == 'derivado';
  
  /// Verificar si está consumido en una transformación
  bool get estaConsumido => datosGenerales.consumidoEnTransformacion;
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
  
  // Campos para sistema de transformaciones
  final String tipoLote; // 'original' o 'derivado'
  final bool consumidoEnTransformacion;
  final String? transformacionId; // Si fue consumido, ID de la transformación
  final String? subloteOrigenId; // Si es derivado, ID del sublote
  
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
    this.tipoLote = 'original',
    this.consumidoEnTransformacion = false,
    this.transformacionId,
    this.subloteOrigenId,
  });
  
  factory DatosGeneralesLote.fromMap(Map<String, dynamic> map) {
    return DatosGeneralesLote(
      id: map['id'] ?? '',
      fechaCreacion: (map['fecha_creacion'] as Timestamp).toDate(),
      creadoPor: map['creado_por'] ?? '',
      tipoMaterial: map['tipo_material'] ?? '',
      pesoInicial: (map['peso_inicial'] ?? map['peso_nace'] ?? map['peso'] ?? 0.0).toDouble(),
      peso: (map['peso'] ?? map['peso_actual'] ?? map['peso_inicial'] ?? map['peso_nace'] ?? 0.0).toDouble(),
      estadoActual: map['estado_actual'] ?? '',
      procesoActual: map['proceso_actual'] ?? '',
      historialProcesos: List<String>.from(map['historial_procesos'] ?? []),
      qrCode: map['qr_code'] ?? '',
      materialPresentacion: map['material_presentacion'],
      materialFuente: map['material_fuente'],
      tipoLote: map['tipo_lote'] ?? 'original',
      consumidoEnTransformacion: map['consumido_en_transformacion'] ?? false,
      transformacionId: map['transformacion_id'],
      subloteOrigenId: map['sublote_origen_id'],
    );
  }
  
  // Getters de compatibilidad para peso
  double get pesoNace => pesoInicial;
  double get pesoActual => peso;
  
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
      'tipo_lote': tipoLote,
      'consumido_en_transformacion': consumidoEnTransformacion,
      'transformacion_id': transformacionId,
      'sublote_origen_id': subloteOrigenId,
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
  final String? vehiculoPlacas;
  final String? nombreConductor;
  final String? firmaRecogida;
  final String? firmaEntrega;
  final List<String> evidenciasFoto;
  final List<String>? evidenciasFotoRecogida;
  final List<String>? evidenciasFotoEntrega;
  final String? comentariosRecogida;
  final String? comentariosEntrega;
  final String? transporteNumero;
  
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
    this.vehiculoPlacas,
    this.nombreConductor,
    this.firmaRecogida,
    this.firmaEntrega,
    required this.evidenciasFoto,
    this.evidenciasFotoRecogida,
    this.evidenciasFotoEntrega,
    this.comentariosRecogida,
    this.comentariosEntrega,
    this.transporteNumero,
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
      vehiculoPlacas: map['vehiculo_placas'],
      nombreConductor: map['nombre_conductor'],
      firmaRecogida: map['firma_recogida'],
      firmaEntrega: map['firma_entrega'],
      evidenciasFoto: List<String>.from(map['evidencias_foto'] ?? []),
      evidenciasFotoRecogida: map['evidencias_foto_recogida'] != null 
          ? List<String>.from(map['evidencias_foto_recogida']) 
          : null,
      evidenciasFotoEntrega: map['evidencias_foto_entrega'] != null
          ? List<String>.from(map['evidencias_foto_entrega'])
          : null,
      comentariosRecogida: map['comentarios_recogida'],
      comentariosEntrega: map['comentarios_entrega'],
      transporteNumero: map['transporte_numero'],
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
      resultados: _convertirAMapStringDynamic(map['resultados'], 'resultados'),
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
    // Calcular pesoSalida con fallback a peso_recibido, peso_neto o peso_procesado
    double? pesoSalida;
    if (map['peso_salida'] != null) {
      pesoSalida = (map['peso_salida'] as num).toDouble();
    } else if (map['peso_recibido'] != null) {
      // Fallback a peso_recibido (usado en formulario de recepción)
      pesoSalida = (map['peso_recibido'] as num).toDouble();
    } else if (map['peso_neto'] != null) {
      // Fallback a peso_neto si existe
      pesoSalida = (map['peso_neto'] as num).toDouble();
    } else if (map['peso_procesado'] != null) {
      // Fallback a peso_procesado si existe
      pesoSalida = (map['peso_procesado'] as num).toDouble();
    }
    
    // Calcular merma con fallback a merma_recepcion
    double? mermaTransformacion;
    if (map['merma_transformacion'] != null) {
      mermaTransformacion = (map['merma_transformacion'] as num).toDouble();
    } else if (map['merma_recepcion'] != null) {
      // Fallback a merma_recepcion (usado en formulario de recepción)
      mermaTransformacion = (map['merma_recepcion'] as num).toDouble();
    }
    
    return ProcesoTransformadorData(
      usuarioId: map['usuario_id'] ?? '',
      usuarioFolio: map['usuario_folio'] ?? '',
      fechaEntrada: (map['fecha_entrada'] as Timestamp).toDate(),
      fechaSalida: map['fecha_salida'] != null 
          ? (map['fecha_salida'] as Timestamp).toDate() 
          : null,
      pesoEntrada: (map['peso_entrada'] ?? 0.0).toDouble(),
      pesoSalida: pesoSalida,
      mermaTransformacion: mermaTransformacion,
      tipoProducto: map['tipo_producto'],
      especificaciones: _convertirAMapStringDynamic(map['especificaciones'], 'especificaciones'),
      evidenciasFoto: List<String>.from(map['evidencias_foto'] ?? []),
    );
  }
}

/// Método helper para convertir de forma segura a Map<String, dynamic>
Map<String, dynamic>? _convertirAMapStringDynamic(dynamic valor, String campo) {
  try {
    if (valor == null) return null;
    if (valor is Map<String, dynamic>) return valor;
    if (valor is Map) {
      print('[LoteUnificadoModel] ADVERTENCIA: Convirtiendo $campo de Map genérico a Map<String, dynamic>');
      return Map<String, dynamic>.from(valor);
    }
    print('[LoteUnificadoModel] ERROR: $campo no es un Map, es: ${valor.runtimeType}, valor: $valor');
    return null;
  } catch (e) {
    print('[LoteUnificadoModel] ERROR al convertir $campo a Map<String, dynamic>: $e');
    return null;
  }
}

/// Datos de análisis de laboratorio (proceso paralelo)
class AnalisisLaboratorioData {
  final String id;
  final String usuarioId;
  final String usuarioFolio;
  final DateTime fechaToma;
  final double pesoMuestra;
  final String? certificado;
  final String? firmaOperador;
  final List<String> evidenciasFoto;
  
  AnalisisLaboratorioData({
    required this.id,
    required this.usuarioId,
    required this.usuarioFolio,
    required this.fechaToma,
    required this.pesoMuestra,
    this.certificado,
    this.firmaOperador,
    required this.evidenciasFoto,
  });
  
  factory AnalisisLaboratorioData.fromMap(Map<String, dynamic> map) {
    return AnalisisLaboratorioData(
      id: map['id'] ?? '',
      usuarioId: map['usuario_id'] ?? '',
      usuarioFolio: map['usuario_folio'] ?? '',
      fechaToma: (map['fecha_toma'] as Timestamp).toDate(),
      pesoMuestra: (map['peso_muestra'] ?? 0.0).toDouble(),
      certificado: map['certificado'],
      firmaOperador: map['firma_operador'],
      evidenciasFoto: List<String>.from(map['evidencias_foto'] ?? []),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'usuario_folio': usuarioFolio,
      'fecha_toma': Timestamp.fromDate(fechaToma),
      'peso_muestra': pesoMuestra,
      'certificado': certificado,
      'firma_operador': firmaOperador,
      'evidencias_foto': evidenciasFoto,
    };
  }
}