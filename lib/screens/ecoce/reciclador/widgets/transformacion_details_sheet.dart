import 'package:flutter/material.dart';
import '../../../../models/lotes/transformacion_model.dart';
import '../../../../utils/colors.dart';

/// Bottom sheet para mostrar detalles de una transformación
class TransformacionDetailsSheet extends StatelessWidget {
  final TransformacionModel transformacion;
  
  const TransformacionDetailsSheet({
    super.key,
    required this.transformacion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detalles del Megalote',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Información general
                _buildDetailSection(
                  'Información General',
                  [
                    _buildDetailRow('ID', transformacion.id.substring(0, 8).toUpperCase()),
                    _buildDetailRow('Material', transformacion.materialPredominante ?? 'Mixto'),
                    _buildDetailRow('Peso entrada', '${transformacion.pesoTotalEntrada.toStringAsFixed(2)} kg'),
                    _buildDetailRow('Peso asignado', '${transformacion.pesoAsignadoSublotes.toStringAsFixed(2)} kg'),
                    _buildDetailRow('Peso disponible', '${transformacion.pesoDisponible.toStringAsFixed(2)} kg'),
                    _buildDetailRow('Merma', '${transformacion.mermaProceso.toStringAsFixed(2)} kg'),
                    _buildDetailRow('Estado', transformacion.estado),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Lotes de entrada
                _buildDetailSection(
                  'Lotes de Entrada (${transformacion.lotesEntrada.length})',
                  transformacion.lotesEntrada.map((lote) =>
                    _buildDetailRow(
                      'Lote ${lote.loteId.substring(0, 8).toUpperCase()}',
                      '${lote.peso.toStringAsFixed(2)} kg'
                    )
                  ).toList(),
                ),
                const SizedBox(height: 20),
                
                // Sublotes generados
                if (transformacion.sublotesGenerados.isNotEmpty) ...[
                  _buildDetailSection(
                    'Sublotes Generados (${transformacion.sublotesGenerados.length})',
                    transformacion.sublotesGenerados.map((subloteId) =>
                      _buildDetailRow(
                        'Sublote ${subloteId.substring(0, 8).toUpperCase()}',
                        'Ver detalles'
                      )
                    ).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Muestras de laboratorio
                if (transformacion.muestrasLaboratorio.isNotEmpty) ...[
                  _buildDetailSection(
                    'Muestras de Laboratorio (${transformacion.muestrasLaboratorio.length})',
                    transformacion.muestrasLaboratorio.map((muestra) {
                      final estado = muestra['estado'] ?? 'pendiente';
                      final peso = muestra['peso'] ?? muestra['peso_muestra'] ?? 0;
                      final analisisCompletado = muestra['analisis_completado'] ?? false;
                      final tieneCertificado = muestra['certificado'] != null;
                      
                      String estadoTexto = 'Pendiente';
                      Color estadoColor = Colors.orange;
                      
                      if (tieneCertificado) {
                        estadoTexto = 'Finalizada';
                        estadoColor = Colors.green;
                      } else if (analisisCompletado) {
                        estadoTexto = 'Análisis completado';
                        estadoColor = Colors.blue;
                      } else if (estado == 'completado') {
                        estadoTexto = 'Muestra tomada';
                        estadoColor = Colors.indigo;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Muestra ${muestra['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: estadoColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                estadoTexto,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: estadoColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              peso > 0 ? '${peso.toStringAsFixed(2)} kg' : 'Sin peso',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: peso > 0 ? Colors.black87 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Documentación
                _buildDetailSection(
                  'Documentación',
                  [
                    _buildDetailRow(
                      'Ficha técnica',
                      transformacion.documentosAsociados['f_tecnica_pellet'] != null ? 'Cargada' : 'Pendiente',
                      valueColor: transformacion.documentosAsociados['f_tecnica_pellet'] != null ? Colors.green : Colors.orange,
                    ),
                    _buildDetailRow(
                      'Reporte de resultado',
                      transformacion.documentosAsociados['rep_result_reci'] != null ? 'Cargado' : 'Pendiente',
                      valueColor: transformacion.documentosAsociados['rep_result_reci'] != null ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}