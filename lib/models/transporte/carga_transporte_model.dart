import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para representar una carga de transporte que agrupa múltiples lotes
class CargaTransporteModel {
  final String id;
  final String transportistaId;
  final String transportistaFolio;
  final DateTime fechaCreacion;
  final List<String> lotesIds; // IDs de los lotes incluidos en la carga
  final String estadoCarga; // 'en_transporte', 'entregada_parcial', 'entregada_completa'
  
  // Datos de recogida
  final String origenUsuarioId; // Usuario del que se recogieron los lotes
  final String origenUsuarioFolio;
  final String origenUsuarioNombre;
  final String origenUsuarioTipo; // 'origen', 'reciclador', etc.
  final DateTime fechaRecogida;
  final String vehiculoPlacas;
  final String nombreConductor;
  final String nombreOperador;
  final double pesoTotalRecogido;
  final String? firmaRecogida;
  final List<String> evidenciasFotoRecogida;
  final String? comentariosRecogida;
  
  // QR de la carga para facilitar entregas
  final String qrCarga;
  
  CargaTransporteModel({
    required this.id,
    required this.transportistaId,
    required this.transportistaFolio,
    required this.fechaCreacion,
    required this.lotesIds,
    required this.estadoCarga,
    required this.origenUsuarioId,
    required this.origenUsuarioFolio,
    required this.origenUsuarioNombre,
    required this.origenUsuarioTipo,
    required this.fechaRecogida,
    required this.vehiculoPlacas,
    required this.nombreConductor,
    required this.nombreOperador,
    required this.pesoTotalRecogido,
    this.firmaRecogida,
    required this.evidenciasFotoRecogida,
    this.comentariosRecogida,
    required this.qrCarga,
  });
  
  factory CargaTransporteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CargaTransporteModel(
      id: doc.id,
      transportistaId: data['transportista_id'] ?? '',
      transportistaFolio: data['transportista_folio'] ?? '',
      fechaCreacion: (data['fecha_creacion'] as Timestamp).toDate(),
      lotesIds: List<String>.from(data['lotes_ids'] ?? []),
      estadoCarga: data['estado_carga'] ?? 'en_transporte',
      origenUsuarioId: data['origen_usuario_id'] ?? '',
      origenUsuarioFolio: data['origen_usuario_folio'] ?? '',
      origenUsuarioNombre: data['origen_usuario_nombre'] ?? '',
      origenUsuarioTipo: data['origen_usuario_tipo'] ?? '',
      fechaRecogida: (data['fecha_recogida'] as Timestamp).toDate(),
      vehiculoPlacas: data['vehiculo_placas'] ?? '',
      nombreConductor: data['nombre_conductor'] ?? '',
      nombreOperador: data['nombre_operador'] ?? '',
      pesoTotalRecogido: (data['peso_total_recogido'] ?? 0.0).toDouble(),
      firmaRecogida: data['firma_recogida'],
      evidenciasFotoRecogida: List<String>.from(data['evidencias_foto_recogida'] ?? []),
      comentariosRecogida: data['comentarios_recogida'],
      qrCarga: data['qr_carga'] ?? '',
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'transportista_id': transportistaId,
      'transportista_folio': transportistaFolio,
      'fecha_creacion': Timestamp.fromDate(fechaCreacion),
      'lotes_ids': lotesIds,
      'estado_carga': estadoCarga,
      'origen_usuario_id': origenUsuarioId,
      'origen_usuario_folio': origenUsuarioFolio,
      'origen_usuario_nombre': origenUsuarioNombre,
      'origen_usuario_tipo': origenUsuarioTipo,
      'fecha_recogida': Timestamp.fromDate(fechaRecogida),
      'vehiculo_placas': vehiculoPlacas,
      'nombre_conductor': nombreConductor,
      'nombre_operador': nombreOperador,
      'peso_total_recogido': pesoTotalRecogido,
      'firma_recogida': firmaRecogida,
      'evidencias_foto_recogida': evidenciasFotoRecogida,
      'comentarios_recogida': comentariosRecogida,
      'qr_carga': qrCarga,
    };
  }
}