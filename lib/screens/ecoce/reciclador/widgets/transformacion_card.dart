import 'package:flutter/material.dart';
import '../../../../models/lotes/transformacion_model.dart';
import '../../../../utils/colors.dart';

/// Tarjeta de transformación (megalote) específica del reciclador
class TransformacionCard extends StatelessWidget {
  final TransformacionModel transformacion;
  final VoidCallback onTap;
  final VoidCallback? onCreateSublote;
  final VoidCallback? onCreateMuestra;
  final VoidCallback? onUploadDocuments;
  
  const TransformacionCard({
    super.key,
    required this.transformacion,
    required this.onTap,
    this.onCreateSublote,
    this.onCreateMuestra,
    this.onUploadDocuments,
  });

  @override
  Widget build(BuildContext context) {
    final bool isComplete = transformacion.estado == 'completada';
    final hasAvailableWeight = transformacion.pesoDisponible > 0;
    final hasDocumentation = transformacion.tieneDocumentacion;
    
    // Ocultar megalotes solo cuando peso=0 Y tiene documentación
    if (transformacion.debeSerEliminada) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: BioWayColors.ecoceGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.merge_type,
                      color: BioWayColors.ecoceGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MEGALOTE ${transformacion.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          isComplete ? 'Completado' : 'En proceso',
                          style: TextStyle(
                            fontSize: 12,
                            color: isComplete ? Colors.grey : BioWayColors.ecoceGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Información de peso
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.scale,
                    label: 'Entrada',
                    value: '${transformacion.pesoTotalEntrada.toStringAsFixed(2)} kg',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.inventory_2,
                    label: 'Disponible',
                    value: '${transformacion.pesoDisponible.toStringAsFixed(2)} kg',
                    color: hasAvailableWeight ? Colors.green : Colors.grey,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Lotes de entrada
              Text(
                '${transformacion.lotesEntrada.length} lotes combinados',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              
              // Mostrar advertencia si no tiene peso pero falta documentación
              if (!hasAvailableWeight && !hasDocumentation) ...[
                const SizedBox(height: 8),
                _buildWarningContainer(
                  'Sube la documentación para completar este megalote',
                  Colors.orange,
                ),
              ],
              
              // Mostrar información cuando el megalote será eliminado
              if (!hasAvailableWeight && hasDocumentation) ...[
                const SizedBox(height: 8),
                _buildWarningContainer(
                  'Megalote completado y documentado',
                  Colors.green,
                ),
              ],
              
              if (transformacion.sublotesGenerados.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${transformacion.sublotesGenerados.length} sublotes generados',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón Crear Sublote
                  _buildActionButton(
                    icon: Icons.cut,
                    label: 'Sublote',
                    onPressed: hasAvailableWeight ? onCreateSublote : null,
                    enabled: hasAvailableWeight,
                    color: BioWayColors.ecoceGreen,
                  ),
                  
                  // Botón Muestra
                  _buildActionButton(
                    icon: Icons.science,
                    label: 'Muestra',
                    onPressed: hasAvailableWeight ? onCreateMuestra : null,
                    enabled: hasAvailableWeight,
                    color: Colors.orange,
                  ),
                  
                  // Botón Documentación
                  _buildActionButton(
                    icon: transformacion.tieneDocumentacion 
                      ? Icons.check_circle 
                      : Icons.upload_file,
                    label: 'Documentación',
                    onPressed: transformacion.tieneDocumentacion 
                      ? null 
                      : onUploadDocuments,
                    enabled: !transformacion.tieneDocumentacion,
                    color: transformacion.tieneDocumentacion 
                      ? Colors.green 
                      : BioWayColors.info,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWarningContainer(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            color == Colors.green ? Icons.check_circle : Icons.warning_amber_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool enabled,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: enabled ? (color ?? BioWayColors.ecoceGreen) : Colors.grey[400],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: enabled ? (color ?? BioWayColors.ecoceGreen) : Colors.grey[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}