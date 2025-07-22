import 'package:cloud_firestore/cloud_firestore.dart';

class BioCompetencia {
  final String userId;
  final String userName;
  final String userAvatar;
  final int bioImpulso;
  final int bioImpulsoMaximo;
  final bool bioImpulsoActivo;
  final DateTime ultimaActividad;
  final int reciclajesEstaSemana;
  final DateTime inicioSemanaActual;
  final int puntosSemanales;
  final int puntosTotales;
  final int posicionRanking;
  final double kgReciclados;
  final double co2Evitado;
  final List<Map<String, dynamic>> recompensasObtenidas;
  final int nivel;
  final String insigniaActual;

  BioCompetencia({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.bioImpulso,
    required this.bioImpulsoMaximo,
    required this.bioImpulsoActivo,
    required this.ultimaActividad,
    required this.reciclajesEstaSemana,
    required this.inicioSemanaActual,
    required this.puntosSemanales,
    required this.puntosTotales,
    required this.posicionRanking,
    required this.kgReciclados,
    required this.co2Evitado,
    this.recompensasObtenidas = const [],
    required this.nivel,
    required this.insigniaActual,
  });

  factory BioCompetencia.fromMap(Map<String, dynamic> map) {
    return BioCompetencia(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'] ?? '',
      bioImpulso: map['bioImpulso'] ?? 0,
      bioImpulsoMaximo: map['bioImpulsoMaximo'] ?? 0,
      bioImpulsoActivo: map['bioImpulsoActivo'] ?? false,
      ultimaActividad: map['ultimaActividad'] != null 
          ? (map['ultimaActividad'] as Timestamp).toDate()
          : DateTime.now(),
      reciclajesEstaSemana: map['reciclajesEstaSemana'] ?? 0,
      inicioSemanaActual: map['inicioSemanaActual'] != null 
          ? (map['inicioSemanaActual'] as Timestamp).toDate()
          : DateTime.now(),
      puntosSemanales: map['puntosSemanales'] ?? 0,
      puntosTotales: map['puntosTotales'] ?? 0,
      posicionRanking: map['posicionRanking'] ?? 0,
      kgReciclados: (map['kgReciclados'] ?? 0.0).toDouble(),
      co2Evitado: (map['co2Evitado'] ?? 0.0).toDouble(),
      recompensasObtenidas: List<Map<String, dynamic>>.from(map['recompensasObtenidas'] ?? []),
      nivel: map['nivel'] ?? 1,
      insigniaActual: map['insigniaActual'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'bioImpulso': bioImpulso,
      'bioImpulsoMaximo': bioImpulsoMaximo,
      'bioImpulsoActivo': bioImpulsoActivo,
      'ultimaActividad': Timestamp.fromDate(ultimaActividad),
      'reciclajesEstaSemana': reciclajesEstaSemana,
      'inicioSemanaActual': Timestamp.fromDate(inicioSemanaActual),
      'puntosSemanales': puntosSemanales,
      'puntosTotales': puntosTotales,
      'posicionRanking': posicionRanking,
      'kgReciclados': kgReciclados,
      'co2Evitado': co2Evitado,
      'recompensasObtenidas': recompensasObtenidas,
      'nivel': nivel,
      'insigniaActual': insigniaActual,
    };
  }
}