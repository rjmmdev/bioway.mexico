import 'package:cloud_firestore/cloud_firestore.dart';

class LoteRecicladorModel {
  final String? id; // Firebase ID
  final String userId; // ID del usuario propietario del lote
  
  // Entrada
  final List<String> conjuntoLotes; // Lotes escaneados
  final String? loteEntrada; // ID del nuevo lote creado
  final Map<String, double>? tipoPoli; // {"PEBD": 40.0, "PP": 35.0, "Multilaminado": 25.0}
  final double? pesoBruto; // Suma de pesos escaneados
  final double? pesoNeto; // Peso aprovechable
  final String? nombreOpeEntrada;
  final String? firmaEntrada; // URL
  
  // Salida
  final double? pesoResultante;
  final double? merma; // Diferencia entre neto y resultante
  final List<String>? procesos; // ["Lavado", "Triturado", etc.]
  final String? nombreOpeSalida;
  final String? firmaSalida; // URL
  final List<String>? eviFoto;
  final String? observaciones;
  
  // Documentación
  final String? fTecnicaPellet; // URL del documento
  final String? repResultReci; // URL del documento
  
  // Estado
  final String estado; // 'entrada', 'salida', 'documentado'

  LoteRecicladorModel({
    this.id,
    required this.userId,
    required this.conjuntoLotes,
    this.loteEntrada,
    this.tipoPoli,
    this.pesoBruto,
    this.pesoNeto,
    this.nombreOpeEntrada,
    this.firmaEntrada,
    this.pesoResultante,
    this.merma,
    this.procesos,
    this.nombreOpeSalida,
    this.firmaSalida,
    this.eviFoto,
    this.observaciones,
    this.fTecnicaPellet,
    this.repResultReci,
    required this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      // Entrada
      'ecoce_reciclador_conjunto_lotes': conjuntoLotes,
      'ecoce_reciclador_lote_entrada': loteEntrada,
      'ecoce_reciclador_tipo_poli': tipoPoli,
      'ecoce_reciclador_peso_bruto': pesoBruto,
      'ecoce_reciclador_peso_neto': pesoNeto,
      'ecoce_reciclador_nombre_ope_entrada': nombreOpeEntrada,
      'ecoce_reciclador_firma_entrada': firmaEntrada,
      
      // Salida
      'ecoce_reciclador_peso_resultante': pesoResultante,
      'ecoce_reciclador_merma': merma,
      'ecoce_reciclador_procesos': procesos,
      'ecoce_reciclador_nombre_ope_salida': nombreOpeSalida,
      'ecoce_reciclador_firma_salida': firmaSalida,
      'ecoce_reciclador_evi_foto': eviFoto,
      'ecoce_reciclador_observaciones': observaciones,
      
      // Documentación
      'ecoce_reciclador_f_tecnica_pellet': fTecnicaPellet,
      'ecoce_reciclador_rep_result_reci': repResultReci,
      
      'estado': estado,
      'fecha_creacion': FieldValue.serverTimestamp(),
    };
  }

  factory LoteRecicladorModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LoteRecicladorModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      // Entrada
      conjuntoLotes: List<String>.from(data['ecoce_reciclador_conjunto_lotes'] ?? []),
      loteEntrada: data['ecoce_reciclador_lote_entrada'],
      tipoPoli: data['ecoce_reciclador_tipo_poli'] != null 
          ? Map<String, double>.from(data['ecoce_reciclador_tipo_poli']) 
          : null,
      pesoBruto: data['ecoce_reciclador_peso_bruto']?.toDouble(),
      pesoNeto: data['ecoce_reciclador_peso_neto']?.toDouble(),
      nombreOpeEntrada: data['ecoce_reciclador_nombre_ope_entrada'],
      firmaEntrada: data['ecoce_reciclador_firma_entrada'],
      
      // Salida
      pesoResultante: data['ecoce_reciclador_peso_resultante']?.toDouble(),
      merma: data['ecoce_reciclador_merma']?.toDouble(),
      procesos: data['ecoce_reciclador_procesos'] != null 
          ? List<String>.from(data['ecoce_reciclador_procesos']) 
          : null,
      nombreOpeSalida: data['ecoce_reciclador_nombre_ope_salida'],
      firmaSalida: data['ecoce_reciclador_firma_salida'],
      eviFoto: data['ecoce_reciclador_evi_foto'] != null 
          ? List<String>.from(data['ecoce_reciclador_evi_foto']) 
          : null,
      observaciones: data['ecoce_reciclador_observaciones'],
      
      // Documentación
      fTecnicaPellet: data['ecoce_reciclador_f_tecnica_pellet'],
      repResultReci: data['ecoce_reciclador_rep_result_reci'],
      
      estado: data['estado'] ?? 'entrada',
    );
  }

  LoteRecicladorModel copyWith({
    String? id,
    String? userId,
    List<String>? conjuntoLotes,
    String? loteEntrada,
    Map<String, double>? tipoPoli,
    double? pesoBruto,
    double? pesoNeto,
    String? nombreOpeEntrada,
    String? firmaEntrada,
    double? pesoResultante,
    double? merma,
    List<String>? procesos,
    String? nombreOpeSalida,
    String? firmaSalida,
    List<String>? eviFoto,
    String? observaciones,
    String? fTecnicaPellet,
    String? repResultReci,
    String? estado,
  }) {
    return LoteRecicladorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      conjuntoLotes: conjuntoLotes ?? this.conjuntoLotes,
      loteEntrada: loteEntrada ?? this.loteEntrada,
      tipoPoli: tipoPoli ?? this.tipoPoli,
      pesoBruto: pesoBruto ?? this.pesoBruto,
      pesoNeto: pesoNeto ?? this.pesoNeto,
      nombreOpeEntrada: nombreOpeEntrada ?? this.nombreOpeEntrada,
      firmaEntrada: firmaEntrada ?? this.firmaEntrada,
      pesoResultante: pesoResultante ?? this.pesoResultante,
      merma: merma ?? this.merma,
      procesos: procesos ?? this.procesos,
      nombreOpeSalida: nombreOpeSalida ?? this.nombreOpeSalida,
      firmaSalida: firmaSalida ?? this.firmaSalida,
      eviFoto: eviFoto ?? this.eviFoto,
      observaciones: observaciones ?? this.observaciones,
      fTecnicaPellet: fTecnicaPellet ?? this.fTecnicaPellet,
      repResultReci: repResultReci ?? this.repResultReci,
      estado: estado ?? this.estado,
    );
  }

  // Calcular merma automáticamente
  double calcularMerma() {
    if (pesoNeto != null && pesoResultante != null) {
      return pesoNeto! - pesoResultante!;
    }
    return 0.0;
  }

  // Obtener tipo de polímero predominante
  String getTipoPredominante() {
    if (tipoPoli == null || tipoPoli!.isEmpty) return 'N/A';
    
    String tipoPredominante = '';
    double maxPorcentaje = 0;
    
    tipoPoli!.forEach((tipo, porcentaje) {
      if (porcentaje > maxPorcentaje) {
        maxPorcentaje = porcentaje;
        tipoPredominante = tipo;
      }
    });
    
    return tipoPredominante;
  }
}