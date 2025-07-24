import 'package:cloud_firestore/cloud_firestore.dart';

class LoteTransportistaModel {
  final String? id; // Firebase ID
  final String userId; // ID del usuario transportista
  
  // Datos de entrada
  final DateTime? fechaRecepcion;
  final List<String> lotesEntrada; // IDs de lotes escaneados
  final String? tipoOrigen; // Tipo más común de polímero
  final String? direccionOrigen;
  final double? pesoRecibido; // Suma de pesos
  final String? nombreOpe;
  final String? placas;
  final String? firmaSalida; // URL de firma
  final String? comentariosEntrada;
  final List<String> eviFotoEntrada;
  
  // Datos de salida
  final DateTime? fechaEntrega;
  final List<String>? lotesSalida; // Lotes seleccionados para entregar
  final String? tipoDestino;
  final String? direccionDestino;
  final double? pesoEntregado;
  final String? firmaRecibe; // URL de firma
  final String? comentariosSalida;
  final List<String>? eviFotoSalida;
  
  // Estado del lote
  final String estado; // 'en_transporte', 'entregado'

  LoteTransportistaModel({
    this.id,
    required this.userId,
    this.fechaRecepcion,
    required this.lotesEntrada,
    this.tipoOrigen,
    this.direccionOrigen,
    this.pesoRecibido,
    this.nombreOpe,
    this.placas,
    this.firmaSalida,
    this.comentariosEntrada,
    required this.eviFotoEntrada,
    this.fechaEntrega,
    this.lotesSalida,
    this.tipoDestino,
    this.direccionDestino,
    this.pesoEntregado,
    this.firmaRecibe,
    this.comentariosSalida,
    this.eviFotoSalida,
    required this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      // Identificación
      'userId': userId,
      
      // Entrada
      'ecoce_transportista_fecha_recepcion': fechaRecepcion != null ? Timestamp.fromDate(fechaRecepcion!) : null,
      'ecoce_transportista_lotes_entrada': lotesEntrada,
      'ecoce_transportista_tipo_origen': tipoOrigen,
      'ecoce_transportista_direccion_origen': direccionOrigen,
      'ecoce_transportista_peso_recibido': pesoRecibido,
      'ecoce_transportista_nombre_ope': nombreOpe,
      'ecoce_transportista_placas': placas,
      'ecoce_transportista_firma_salida': firmaSalida,
      'ecoce_transportista_comentarios_entrada': comentariosEntrada,
      'ecoce_transportista_evi_foto_entrada': eviFotoEntrada,
      
      // Salida
      'ecoce_transportista_fecha_entrega': fechaEntrega != null ? Timestamp.fromDate(fechaEntrega!) : null,
      'ecoce_transportista_lotes_salida': lotesSalida,
      'ecoce_transportista_tipo_destino': tipoDestino,
      'ecoce_transportista_direccion_destino': direccionDestino,
      'ecoce_transportista_peso_entregado': pesoEntregado,
      'ecoce_transportista_firma_recibe': firmaRecibe,
      'ecoce_transportista_comentarios_salida': comentariosSalida,
      'ecoce_transportista_evi_foto_salida': eviFotoSalida,
      
      'estado': estado,
    };
  }

  factory LoteTransportistaModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LoteTransportistaModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      // Entrada
      fechaRecepcion: data['ecoce_transportista_fecha_recepcion'] != null 
          ? (data['ecoce_transportista_fecha_recepcion'] as Timestamp).toDate() 
          : null,
      lotesEntrada: List<String>.from(data['ecoce_transportista_lotes_entrada'] ?? []),
      tipoOrigen: data['ecoce_transportista_tipo_origen'],
      direccionOrigen: data['ecoce_transportista_direccion_origen'],
      pesoRecibido: (data['ecoce_transportista_peso_recibido'] ?? 0).toDouble(),
      nombreOpe: data['ecoce_transportista_nombre_ope'],
      placas: data['ecoce_transportista_placas'],
      firmaSalida: data['ecoce_transportista_firma_salida'],
      comentariosEntrada: data['ecoce_transportista_comentarios_entrada'],
      eviFotoEntrada: List<String>.from(data['ecoce_transportista_evi_foto_entrada'] ?? []),
      
      // Salida
      fechaEntrega: data['ecoce_transportista_fecha_entrega'] != null 
          ? (data['ecoce_transportista_fecha_entrega'] as Timestamp).toDate() 
          : null,
      lotesSalida: data['ecoce_transportista_lotes_salida'] != null 
          ? List<String>.from(data['ecoce_transportista_lotes_salida']) 
          : null,
      tipoDestino: data['ecoce_transportista_tipo_destino'],
      direccionDestino: data['ecoce_transportista_direccion_destino'],
      pesoEntregado: data['ecoce_transportista_peso_entregado']?.toDouble(),
      firmaRecibe: data['ecoce_transportista_firma_recibe'],
      comentariosSalida: data['ecoce_transportista_comentarios_salida'],
      eviFotoSalida: data['ecoce_transportista_evi_foto_salida'] != null 
          ? List<String>.from(data['ecoce_transportista_evi_foto_salida']) 
          : null,
      
      estado: data['estado'] ?? 'en_transporte',
    );
  }

  LoteTransportistaModel copyWith({
    String? id,
    String? userId,
    DateTime? fechaRecepcion,
    List<String>? lotesEntrada,
    String? tipoOrigen,
    String? direccionOrigen,
    double? pesoRecibido,
    String? nombreOpe,
    String? placas,
    String? firmaSalida,
    String? comentariosEntrada,
    List<String>? eviFotoEntrada,
    DateTime? fechaEntrega,
    List<String>? lotesSalida,
    String? tipoDestino,
    String? direccionDestino,
    double? pesoEntregado,
    String? firmaRecibe,
    String? comentariosSalida,
    List<String>? eviFotoSalida,
    String? estado,
  }) {
    return LoteTransportistaModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fechaRecepcion: fechaRecepcion ?? this.fechaRecepcion,
      lotesEntrada: lotesEntrada ?? this.lotesEntrada,
      tipoOrigen: tipoOrigen ?? this.tipoOrigen,
      direccionOrigen: direccionOrigen ?? this.direccionOrigen,
      pesoRecibido: pesoRecibido ?? this.pesoRecibido,
      nombreOpe: nombreOpe ?? this.nombreOpe,
      placas: placas ?? this.placas,
      firmaSalida: firmaSalida ?? this.firmaSalida,
      comentariosEntrada: comentariosEntrada ?? this.comentariosEntrada,
      eviFotoEntrada: eviFotoEntrada ?? this.eviFotoEntrada,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      lotesSalida: lotesSalida ?? this.lotesSalida,
      tipoDestino: tipoDestino ?? this.tipoDestino,
      direccionDestino: direccionDestino ?? this.direccionDestino,
      pesoEntregado: pesoEntregado ?? this.pesoEntregado,
      firmaRecibe: firmaRecibe ?? this.firmaRecibe,
      comentariosSalida: comentariosSalida ?? this.comentariosSalida,
      eviFotoSalida: eviFotoSalida ?? this.eviFotoSalida,
      estado: estado ?? this.estado,
    );
  }
}