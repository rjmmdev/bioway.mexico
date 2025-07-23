import 'package:cloud_firestore/cloud_firestore.dart';

class LoteLaboratorioModel {
  final String? id; // Firebase ID
  final String? loteOrigen; // ID del lote origen para Laboratorio
  final List<String>? lotes; // Lotes analizados (para compatibilidad)
  final double? pesoMuestra; // Peso de la muestra en kg
  final String? tipoMaterial; // Tipo de material
  final String? proveedor; // Proveedor o nombre del laboratorio
  final String? estado; // Estado del lote
  final String? humedad; // "XX.XX%"
  final double? pellets; // Pellets por gramo
  final String? ftir; // Tipo de polímero por FTIR
  final String? tempFusionInf; // Temperatura inferior
  final String? tempFusionSup; // Temperatura superior
  final String? contOrg; // "XX.XX%"
  final String? contInorg; // "XX.XX%"
  final String? oit; // OIT
  final String? densidad; // Densidad
  final String? norma; // Norma de referencia
  final String? observaciones;
  final bool? requisitos; // Cumple requisitos
  final String? informe; // URL del informe
  final DateTime? fechaAnalisis;

  LoteLaboratorioModel({
    this.id,
    this.loteOrigen,
    this.lotes,
    this.pesoMuestra,
    this.tipoMaterial,
    this.proveedor,
    this.estado,
    this.humedad,
    this.pellets,
    this.ftir,
    this.tempFusionInf,
    this.tempFusionSup,
    this.contOrg,
    this.contInorg,
    this.oit,
    this.densidad,
    this.norma,
    this.observaciones,
    this.requisitos,
    this.informe,
    this.fechaAnalisis,
  });

  Map<String, dynamic> toMap() {
    return {
      'ecoce_laboratorio_lote_origen': loteOrigen,
      'ecoce_laboratorio_lotes': lotes ?? (loteOrigen != null ? [loteOrigen!] : []),
      'ecoce_laboratorio_peso_muestra': pesoMuestra,
      'ecoce_laboratorio_tipo_material': tipoMaterial,
      'ecoce_laboratorio_proveedor': proveedor,
      'estado': estado,
      'ecoce_laboratorio_humedad': humedad,
      'ecoce_laboratorio_pellets': pellets,
      'ecoce_laboratorio_ftir': ftir,
      'ecoce_laboratorio_temp_fusion_inf': tempFusionInf,
      'ecoce_laboratorio_temp_fusion_sup': tempFusionSup,
      'ecoce_laboratorio_cont_org': contOrg,
      'ecoce_laboratorio_cont_inorg': contInorg,
      'ecoce_laboratorio_oit': oit,
      'ecoce_laboratorio_densidad': densidad,
      'ecoce_laboratorio_norma': norma,
      'ecoce_laboratorio_observaciones': observaciones,
      'ecoce_laboratorio_requisitos': requisitos,
      'ecoce_laboratorio_informe': informe,
      'fecha_analisis': fechaAnalisis != null ? Timestamp.fromDate(fechaAnalisis!) : null,
    };
  }

  factory LoteLaboratorioModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LoteLaboratorioModel(
      id: doc.id,
      loteOrigen: data['ecoce_laboratorio_lote_origen'],
      lotes: data['ecoce_laboratorio_lotes'] != null ? List<String>.from(data['ecoce_laboratorio_lotes']) : null,
      pesoMuestra: data['ecoce_laboratorio_peso_muestra']?.toDouble(),
      tipoMaterial: data['ecoce_laboratorio_tipo_material'],
      proveedor: data['ecoce_laboratorio_proveedor'],
      estado: data['estado'],
      humedad: data['ecoce_laboratorio_humedad'],
      pellets: data['ecoce_laboratorio_pellets']?.toDouble(),
      ftir: data['ecoce_laboratorio_ftir'],
      tempFusionInf: data['ecoce_laboratorio_temp_fusion_inf'],
      tempFusionSup: data['ecoce_laboratorio_temp_fusion_sup'],
      contOrg: data['ecoce_laboratorio_cont_org'],
      contInorg: data['ecoce_laboratorio_cont_inorg'],
      oit: data['ecoce_laboratorio_oit'],
      densidad: data['ecoce_laboratorio_densidad'],
      norma: data['ecoce_laboratorio_norma'],
      observaciones: data['ecoce_laboratorio_observaciones'],
      requisitos: data['ecoce_laboratorio_requisitos'],
      informe: data['ecoce_laboratorio_informe'],
      fechaAnalisis: data['fecha_analisis'] != null ? (data['fecha_analisis'] as Timestamp).toDate() : null,
    );
  }

  LoteLaboratorioModel copyWith({
    String? id,
    String? loteOrigen,
    List<String>? lotes,
    double? pesoMuestra,
    String? tipoMaterial,
    String? proveedor,
    String? estado,
    String? humedad,
    double? pellets,
    String? ftir,
    String? tempFusionInf,
    String? tempFusionSup,
    String? contOrg,
    String? contInorg,
    String? oit,
    String? densidad,
    String? norma,
    String? observaciones,
    bool? requisitos,
    String? informe,
    DateTime? fechaAnalisis,
  }) {
    return LoteLaboratorioModel(
      id: id ?? this.id,
      loteOrigen: loteOrigen ?? this.loteOrigen,
      lotes: lotes ?? this.lotes,
      pesoMuestra: pesoMuestra ?? this.pesoMuestra,
      tipoMaterial: tipoMaterial ?? this.tipoMaterial,
      proveedor: proveedor ?? this.proveedor,
      estado: estado ?? this.estado,
      humedad: humedad ?? this.humedad,
      pellets: pellets ?? this.pellets,
      ftir: ftir ?? this.ftir,
      tempFusionInf: tempFusionInf ?? this.tempFusionInf,
      tempFusionSup: tempFusionSup ?? this.tempFusionSup,
      contOrg: contOrg ?? this.contOrg,
      contInorg: contInorg ?? this.contInorg,
      oit: oit ?? this.oit,
      densidad: densidad ?? this.densidad,
      norma: norma ?? this.norma,
      observaciones: observaciones ?? this.observaciones,
      requisitos: requisitos ?? this.requisitos,
      informe: informe ?? this.informe,
      fechaAnalisis: fechaAnalisis ?? this.fechaAnalisis,
    );
  }

  // Obtener rango de temperatura como string
  String getRangoTemperatura() {
    if (tempFusionInf != null && tempFusionSup != null) {
      return '$tempFusionInf°C - $tempFusionSup°C';
    } else if (tempFusionInf != null) {
      return '$tempFusionInf°C';
    }
    return 'N/A';
  }

  // Formatear humedad sin el símbolo % para entrada
  static String formatHumedadForInput(String humedad) {
    return humedad.replaceAll('%', '').trim();
  }

  // Formatear humedad con el símbolo % para mostrar
  static String formatHumedadForDisplay(String value) {
    if (!value.contains('%')) {
      return '$value%';
    }
    return value;
  }
}