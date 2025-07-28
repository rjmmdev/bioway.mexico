import 'package:flutter/material.dart';
import '../../../../models/lotes/lote_unificado_model.dart';
import '../../../../utils/format_utils.dart';

/// Bottom sheet reutilizable para mostrar detalles de un lote
class LoteDetailsSheet extends StatelessWidget {
  final LoteUnificadoModel lote;
  final Map<String, String>? additionalInfo;
  final Widget? actionButton;
  final String title;
  
  const LoteDetailsSheet({
    super.key,
    required this.lote,
    this.additionalInfo,
    this.actionButton,
    this.title = 'Detalles del Lote',
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: ${lote.id.substring(0, 8).toUpperCase()}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDetailSection(
                      title: 'Información General',
                      items: {
                        'Material': lote.datosGenerales.tipoMaterial,
                        'Presentación': lote.datosGenerales.materialPresentacion ?? 'N/A',
                        'Fuente': lote.datosGenerales.materialFuente ?? 'N/A',
                        'QR Code': lote.datosGenerales.qrCode,
                        'Tipo de Lote': lote.datosGenerales.tipoLote ?? 'original',
                        'Peso Inicial': '${lote.datosGenerales.pesoInicial} kg',
                        'Peso Actual': '${lote.pesoActual.toStringAsFixed(2)} kg',
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Información específica del proceso actual
                    if (lote.origen != null) ...[
                      _buildDetailSection(
                        title: 'Información de Origen',
                        items: {
                          'Fecha de Creación': FormatUtils.formatDateTime(lote.origen!.fechaEntrada),
                          'Peso': '${lote.origen!.pesoNace} kg',
                          'Operador': lote.origen!.firmaOperador != null ? 'Firmado' : 'Sin firma',
                          'Evidencias': '${lote.origen!.evidenciasFoto.length} fotos',
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    if (lote.reciclador != null) ...[
                      _buildDetailSection(
                        title: 'Información del Reciclador',
                        items: {
                          'Fecha de Entrada': FormatUtils.formatDateTime(lote.reciclador!.fechaEntrada),
                          if (lote.reciclador!.fechaSalida != null)
                            'Fecha de Salida': FormatUtils.formatDateTime(lote.reciclador!.fechaSalida!),
                          'Peso de Entrada': '${lote.reciclador!.pesoEntrada} kg',
                          if (lote.reciclador!.pesoProcesado != null)
                            'Peso Procesado': '${lote.reciclador!.pesoProcesado} kg',
                          if (lote.reciclador!.mermaProceso != null)
                            'Merma': '${lote.reciclador!.mermaProceso} kg',
                          'Usuario': lote.reciclador!.usuarioFolio,
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    if (lote.transformador != null) ...[
                      _buildDetailSection(
                        title: 'Información del Transformador',
                        items: {
                          'Fecha de Entrada': FormatUtils.formatDateTime(lote.transformador!.fechaEntrada),
                          if (lote.transformador!.fechaSalida != null)
                            'Fecha de Salida': FormatUtils.formatDateTime(lote.transformador!.fechaSalida!),
                          'Peso de Entrada': '${lote.transformador!.pesoEntrada} kg',
                          if (lote.transformador!.pesoSalida != null)
                            'Peso de Salida': '${lote.transformador!.pesoSalida} kg',
                          'Usuario': lote.transformador!.usuarioFolio,
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Información de transporte
                    if (lote.transporteFases.isNotEmpty) ...[
                      _buildDetailSection(
                        title: 'Información de Transporte',
                        items: {
                          'Fases completadas': '${lote.transporteFases.length}',
                          ...lote.transporteFases.map((key, value) => MapEntry(
                            'Fase ${key.replaceAll('fase_', '')}',
                            value.fechaSalida != null
                              ? 'Completada'
                              : 'En proceso'
                          )),
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Análisis de laboratorio
                    if (lote.analisisLaboratorio.isNotEmpty) ...[
                      _buildDetailSection(
                        title: 'Análisis de Laboratorio',
                        items: {
                          'Total de análisis': '${lote.analisisLaboratorio.length}',
                          'Peso total muestras': '${lote.pesoTotalMuestras.toStringAsFixed(2)} kg',
                          'Con certificado': '${lote.analisisLaboratorio.where((a) => a.certificado != null).length}',
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Trazabilidad
                    _buildDetailSection(
                      title: 'Trazabilidad',
                      items: {
                        'Proceso Actual': lote.datosGenerales.procesoActual,
                        'Historial': lote.datosGenerales.historialProcesos.join(' → '),
                        'Creado por': lote.datosGenerales.creadoPor,
                        'Fecha de creación': FormatUtils.formatDateTime(lote.datosGenerales.fechaCreacion),
                      },
                    ),
                    
                    // Información adicional personalizable
                    if (additionalInfo != null && additionalInfo!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildDetailSection(
                        title: 'Información Adicional',
                        items: additionalInfo!,
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Botón de acción personalizable
                    if (actionButton != null) actionButton!,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDetailSection({
    required String title,
    required Map<String, String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...items.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key}: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}