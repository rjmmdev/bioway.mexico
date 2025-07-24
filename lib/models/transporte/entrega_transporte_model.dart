import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para representar una entrega de transporte (puede ser parcial de una carga)
class EntregaTransporteModel {
  final String id;
  final String cargaId; // ID de la carga de la que provienen los lotes
  final String transportistaId;
  final String transportistaFolio;
  final String transportistaNombre;
  final DateTime fechaCreacion;
  final List<String> lotesIds; // Lotes específicos que se entregan
  final String estadoEntrega; // 'pendiente', 'entregada'
  
  // Datos del destinatario
  final String destinatarioId;
  final String destinatarioFolio;
  final String destinatarioNombre;
  final String destinatarioTipo; // 'reciclador', 'transformador', etc.
  
  // Datos de la entrega
  final DateTime? fechaEntrega;
  final double pesoTotalEntregado;
  final String? firmaEntrega;
  final List<String> evidenciasFotoEntrega;
  final String? comentariosEntrega;
  
  // QR de la entrega para que el destinatario escanee
  final String qrEntrega;
  
  EntregaTransporteModel({
    required this.id,
    required this.cargaId,
    required this.transportistaId,
    required this.transportistaFolio,
    required this.transportistaNombre,
    required this.fechaCreacion,
    required this.lotesIds,
    required this.estadoEntrega,
    required this.destinatarioId,
    required this.destinatarioFolio,
    required this.destinatarioNombre,
    required this.destinatarioTipo,
    this.fechaEntrega,
    required this.pesoTotalEntregado,
    this.firmaEntrega,
    required this.evidenciasFotoEntrega,
    this.comentariosEntrega,
    required this.qrEntrega,
  });
  
  factory EntregaTransporteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EntregaTransporteModel(
      id: doc.id,
      cargaId: data['carga_id'] ?? '',
      transportistaId: data['transportista_id'] ?? '',
      transportistaFolio: data['transportista_folio'] ?? '',
      transportistaNombre: data['transportista_nombre'] ?? '',
      fechaCreacion: (data['fecha_creacion'] as Timestamp).toDate(),
      lotesIds: List<String>.from(data['lotes_ids'] ?? []),
      estadoEntrega: data['estado_entrega'] ?? 'pendiente',
      destinatarioId: data['destinatario_id'] ?? '',
      destinatarioFolio: data['destinatario_folio'] ?? '',
      destinatarioNombre: data['destinatario_nombre'] ?? '',
      destinatarioTipo: data['destinatario_tipo'] ?? '',
      fechaEntrega: data['fecha_entrega'] != null 
          ? (data['fecha_entrega'] as Timestamp).toDate() 
          : null,
      pesoTotalEntregado: (data['peso_total_entregado'] ?? 0.0).toDouble(),
      firmaEntrega: data['firma_entrega'],
      evidenciasFotoEntrega: List<String>.from(data['evidencias_foto_entrega'] ?? []),
      comentariosEntrega: data['comentarios_entrega'],
      qrEntrega: data['qr_entrega'] ?? '',
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'carga_id': cargaId,
      'transportista_id': transportistaId,
      'transportista_folio': transportistaFolio,
      'transportista_nombre': transportistaNombre,
      'fecha_creacion': Timestamp.fromDate(fechaCreacion),
      'lotes_ids': lotesIds,
      'estado_entrega': estadoEntrega,
      'destinatario_id': destinatarioId,
      'destinatario_folio': destinatarioFolio,
      'destinatario_nombre': destinatarioNombre,
      'destinatario_tipo': destinatarioTipo,
      'fecha_entrega': fechaEntrega != null ? Timestamp.fromDate(fechaEntrega!) : null,
      'peso_total_entregado': pesoTotalEntregado,
      'firma_entrega': firmaEntrega,
      'evidencias_foto_entrega': evidenciasFotoEntrega,
      'comentarios_entrega': comentariosEntrega,
      'qr_entrega': qrEntrega,
    };
  }
}