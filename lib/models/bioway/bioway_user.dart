import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de usuario para la plataforma BioWay
class BioWayUser {
  final String uid;
  final String nombre;
  final String email;
  final String tipoUsuario; // 'brindador', 'recolector', 'centro_acopio' o 'maestro'
  final int bioCoins;
  final String nivel;
  final DateTime fechaRegistro;
  final DateTime? ultimaActualizacion;
  
  // Campos específicos para Brindador
  final String? direccion;
  final String? numeroExterior;
  final String? codigoPostal;
  final String? estado;
  final String? municipio;
  final String? colonia;
  final double? latitud;
  final double? longitud;
  final String? estadoResiduo; // '0' = puede brindar, '1' = ya brindó
  final Map<String, dynamic>? residuoActual;
  final bool isPremium; // Indica si el usuario brindador tiene cuenta premium
  final DateTime? fechaPremium; // Fecha desde que es premium
  final String? nivelReconocimiento; // Bronce, Plata, Oro, Platino
  final int diasConsecutivosReciclando; // Para el sistema de reconocimientos
  final Map<String, dynamic>? estadisticasAmbientales; // CO2 evitado, árboles salvados, etc.
  
  // Campos específicos para Recolector
  final String? empresa;
  final String? codigoEspecial;
  final bool? verificado;
  final List<String>? materialesPreferidos;
  final String? vehiculo;
  final double? capacidadKg;
  final String? licenciaConducir;
  
  // Estadísticas
  final int totalResiduosBrindados;
  final int totalResiduosRecolectados;
  final double totalKgReciclados;
  final double totalCO2Evitado;
  
  // Configuración
  final bool notificacionesActivas;
  final String? tokenFCM;
  final String? fotoPerfilUrl;
  
  BioWayUser({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.tipoUsuario,
    this.bioCoins = 0,
    this.nivel = 'BioBaby',
    required this.fechaRegistro,
    this.ultimaActualizacion,
    // Brindador
    this.direccion,
    this.numeroExterior,
    this.codigoPostal,
    this.estado,
    this.municipio,
    this.colonia,
    this.latitud,
    this.longitud,
    this.estadoResiduo = '0',
    this.residuoActual,
    this.isPremium = false,
    this.fechaPremium,
    this.nivelReconocimiento,
    this.diasConsecutivosReciclando = 0,
    this.estadisticasAmbientales,
    // Recolector
    this.empresa,
    this.codigoEspecial,
    this.verificado = false,
    this.materialesPreferidos,
    this.vehiculo,
    this.capacidadKg,
    this.licenciaConducir,
    // Estadísticas
    this.totalResiduosBrindados = 0,
    this.totalResiduosRecolectados = 0,
    this.totalKgReciclados = 0.0,
    this.totalCO2Evitado = 0.0,
    // Configuración
    this.notificacionesActivas = true,
    this.tokenFCM,
    this.fotoPerfilUrl,
  });

  /// Determina si es un usuario Brindador
  bool get isBrindador => tipoUsuario == 'brindador';
  
  /// Determina si es un usuario Recolector
  bool get isRecolector => tipoUsuario == 'recolector';
  
  /// Determina si es un Centro de Acopio
  bool get isCentroAcopio => tipoUsuario == 'centro_acopio';
  
  /// Determina si es un usuario Maestro
  bool get isMaestro => tipoUsuario == 'maestro';
  
  /// Determina si el usuario puede brindar residuos (solo Brindador)
  bool get puedeBrindar => isBrindador && estadoResiduo == '0';
  
  /// Determina si es un usuario premium (solo Brindador)
  bool get isBrindadorPremium => isBrindador && isPremium;
  
  /// Obtiene el nivel de reconocimiento basado en días consecutivos
  String obtenerNivelReconocimiento() {
    if (diasConsecutivosReciclando >= 100) return 'Platino';
    if (diasConsecutivosReciclando >= 50) return 'Oro';
    if (diasConsecutivosReciclando >= 30) return 'Plata';
    if (diasConsecutivosReciclando >= 7) return 'Bronce';
    return 'Sin nivel';
  }
  
  /// Calcula el nivel basado en BioCoins
  String calcularNivel() {
    if (bioCoins >= 1000000) return 'Admin';
    if (bioCoins >= 100000) return 'BioGod';
    if (bioCoins >= 10000) return 'BioExpert';
    if (bioCoins >= 1000) return 'BioWay';
    if (bioCoins >= 500) return 'BioMidWay';
    if (bioCoins >= 100) return 'BioBaby';
    return 'BioBaby';
  }
  
  /// Calcula el progreso hacia el siguiente nivel (0.0 a 1.0)
  double get progresoNivel {
    if (bioCoins < 100) return bioCoins / 100;
    if (bioCoins < 500) return (bioCoins - 100) / 400;
    if (bioCoins < 1000) return (bioCoins - 500) / 500;
    if (bioCoins < 10000) return (bioCoins - 1000) / 9000;
    if (bioCoins < 100000) return (bioCoins - 10000) / 90000;
    if (bioCoins < 1000000) return (bioCoins - 100000) / 900000;
    return 1.0;
  }
  
  /// Obtiene los puntos necesarios para el siguiente nivel
  int get puntosParaSiguienteNivel {
    if (bioCoins < 100) return 100 - bioCoins;
    if (bioCoins < 500) return 500 - bioCoins;
    if (bioCoins < 1000) return 1000 - bioCoins;
    if (bioCoins < 10000) return 10000 - bioCoins;
    if (bioCoins < 100000) return 100000 - bioCoins;
    if (bioCoins < 1000000) return 1000000 - bioCoins;
    return 0;
  }
  
  /// Convierte el modelo a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'email': email,
      'tipoUsuario': tipoUsuario,
      'bioCoins': bioCoins,
      'nivel': nivel,
      'fechaRegistro': Timestamp.fromDate(fechaRegistro),
      'ultimaActualizacion': ultimaActualizacion != null 
          ? Timestamp.fromDate(ultimaActualizacion!) 
          : FieldValue.serverTimestamp(),
      // Campos de Brindador
      if (isBrindador) ...{
        'direccion': direccion,
        'numeroExterior': numeroExterior,
        'codigoPostal': codigoPostal,
        'estado': estado,
        'municipio': municipio,
        'colonia': colonia,
        'latitud': latitud,
        'longitud': longitud,
        'estadoResiduo': estadoResiduo,
        'residuoActual': residuoActual,
        'isPremium': isPremium,
        'fechaPremium': fechaPremium != null ? Timestamp.fromDate(fechaPremium!) : null,
        'nivelReconocimiento': nivelReconocimiento,
        'diasConsecutivosReciclando': diasConsecutivosReciclando,
        'estadisticasAmbientales': estadisticasAmbientales,
      },
      // Campos de Recolector
      if (isRecolector) ...{
        'empresa': empresa,
        'codigoEspecial': codigoEspecial,
        'verificado': verificado,
        'materialesPreferidos': materialesPreferidos,
        'vehiculo': vehiculo,
        'capacidadKg': capacidadKg,
        'licenciaConducir': licenciaConducir,
      },
      // Estadísticas
      'totalResiduosBrindados': totalResiduosBrindados,
      'totalResiduosRecolectados': totalResiduosRecolectados,
      'totalKgReciclados': totalKgReciclados,
      'totalCO2Evitado': totalCO2Evitado,
      // Configuración
      'notificacionesActivas': notificacionesActivas,
      'tokenFCM': tokenFCM,
      'fotoPerfilUrl': fotoPerfilUrl,
    };
  }
  
  /// Crea una instancia desde un Map de Firebase
  factory BioWayUser.fromMap(Map<String, dynamic> map, String uid) {
    return BioWayUser(
      uid: uid,
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      tipoUsuario: map['tipoUsuario'] ?? 'brindador',
      bioCoins: map['bioCoins'] ?? 0,
      nivel: map['nivel'] ?? 'BioBaby',
      fechaRegistro: (map['fechaRegistro'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ultimaActualizacion: (map['ultimaActualizacion'] as Timestamp?)?.toDate(),
      // Brindador
      direccion: map['direccion'],
      numeroExterior: map['numeroExterior'],
      codigoPostal: map['codigoPostal'],
      estado: map['estado'],
      municipio: map['municipio'],
      colonia: map['colonia'],
      latitud: map['latitud']?.toDouble(),
      longitud: map['longitud']?.toDouble(),
      estadoResiduo: map['estadoResiduo'] ?? '0',
      residuoActual: map['residuoActual'],
      isPremium: map['isPremium'] ?? false,
      fechaPremium: (map['fechaPremium'] as Timestamp?)?.toDate(),
      nivelReconocimiento: map['nivelReconocimiento'],
      diasConsecutivosReciclando: map['diasConsecutivosReciclando'] ?? 0,
      estadisticasAmbientales: map['estadisticasAmbientales'],
      // Recolector
      empresa: map['empresa'],
      codigoEspecial: map['codigoEspecial'],
      verificado: map['verificado'] ?? false,
      materialesPreferidos: List<String>.from(map['materialesPreferidos'] ?? []),
      vehiculo: map['vehiculo'],
      capacidadKg: map['capacidadKg']?.toDouble(),
      licenciaConducir: map['licenciaConducir'],
      // Estadísticas
      totalResiduosBrindados: map['totalResiduosBrindados'] ?? 0,
      totalResiduosRecolectados: map['totalResiduosRecolectados'] ?? 0,
      totalKgReciclados: (map['totalKgReciclados'] ?? 0).toDouble(),
      totalCO2Evitado: (map['totalCO2Evitado'] ?? 0).toDouble(),
      // Configuración
      notificacionesActivas: map['notificacionesActivas'] ?? true,
      tokenFCM: map['tokenFCM'],
      fotoPerfilUrl: map['fotoPerfilUrl'],
    );
  }
  
  /// Crea una copia con modificaciones
  BioWayUser copyWith({
    String? nombre,
    String? email,
    int? bioCoins,
    String? nivel,
    DateTime? ultimaActualizacion,
    String? direccion,
    String? numeroExterior,
    String? codigoPostal,
    String? estado,
    String? municipio,
    String? colonia,
    double? latitud,
    double? longitud,
    String? estadoResiduo,
    Map<String, dynamic>? residuoActual,
    bool? isPremium,
    DateTime? fechaPremium,
    String? nivelReconocimiento,
    int? diasConsecutivosReciclando,
    Map<String, dynamic>? estadisticasAmbientales,
    String? empresa,
    String? codigoEspecial,
    bool? verificado,
    List<String>? materialesPreferidos,
    String? vehiculo,
    double? capacidadKg,
    String? licenciaConducir,
    int? totalResiduosBrindados,
    int? totalResiduosRecolectados,
    double? totalKgReciclados,
    double? totalCO2Evitado,
    bool? notificacionesActivas,
    String? tokenFCM,
    String? fotoPerfilUrl,
  }) {
    return BioWayUser(
      uid: uid,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      tipoUsuario: tipoUsuario,
      bioCoins: bioCoins ?? this.bioCoins,
      nivel: nivel ?? this.nivel,
      fechaRegistro: fechaRegistro,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
      direccion: direccion ?? this.direccion,
      numeroExterior: numeroExterior ?? this.numeroExterior,
      codigoPostal: codigoPostal ?? this.codigoPostal,
      estado: estado ?? this.estado,
      municipio: municipio ?? this.municipio,
      colonia: colonia ?? this.colonia,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      estadoResiduo: estadoResiduo ?? this.estadoResiduo,
      residuoActual: residuoActual ?? this.residuoActual,
      isPremium: isPremium ?? this.isPremium,
      fechaPremium: fechaPremium ?? this.fechaPremium,
      nivelReconocimiento: nivelReconocimiento ?? this.nivelReconocimiento,
      diasConsecutivosReciclando: diasConsecutivosReciclando ?? this.diasConsecutivosReciclando,
      estadisticasAmbientales: estadisticasAmbientales ?? this.estadisticasAmbientales,
      empresa: empresa ?? this.empresa,
      codigoEspecial: codigoEspecial ?? this.codigoEspecial,
      verificado: verificado ?? this.verificado,
      materialesPreferidos: materialesPreferidos ?? this.materialesPreferidos,
      vehiculo: vehiculo ?? this.vehiculo,
      capacidadKg: capacidadKg ?? this.capacidadKg,
      licenciaConducir: licenciaConducir ?? this.licenciaConducir,
      totalResiduosBrindados: totalResiduosBrindados ?? this.totalResiduosBrindados,
      totalResiduosRecolectados: totalResiduosRecolectados ?? this.totalResiduosRecolectados,
      totalKgReciclados: totalKgReciclados ?? this.totalKgReciclados,
      totalCO2Evitado: totalCO2Evitado ?? this.totalCO2Evitado,
      notificacionesActivas: notificacionesActivas ?? this.notificacionesActivas,
      tokenFCM: tokenFCM ?? this.tokenFCM,
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
    );
  }
}