import 'package:flutter/material.dart';
import '../../../../models/lotes/lote_unificado_model.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/format_utils.dart';

/// Widget de tarjeta de lote reutilizable
class LoteCardGeneral extends StatelessWidget {
  final LoteUnificadoModel lote;
  final bool isSelected;
  final bool canBeSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final Widget? additionalInfo;
  final bool showCheckbox;
  final bool hasDocumentation;
  final Color? statusColor;
  final String? statusText;
  final IconData? statusIcon;
  
  const LoteCardGeneral({
    super.key,
    required this.lote,
    required this.onTap,
    this.isSelected = false,
    this.canBeSelected = false,
    this.onLongPress,
    this.trailing,
    this.additionalInfo,
    this.showCheckbox = false,
    this.hasDocumentation = false,
    this.statusColor,
    this.statusText,
    this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bool esSublote = lote.datosGenerales.tipoLote == 'derivado' || 
                          lote.datosGenerales.qrCode.startsWith('SUBLOTE-');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected 
          ? Border.all(color: BioWayColors.ecoceGreen, width: 2)
          : esSublote
            ? Border.all(color: Colors.purple.withValues(alpha: 0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: esSublote 
              ? Colors.purple.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
            blurRadius: esSublote ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Checkbox para selección múltiple
                  if (showCheckbox && canBeSelected) ...[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? BioWayColors.ecoceGreen
                          : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                            ? BioWayColors.ecoceGreen
                            : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => onTap(),
                        activeColor: BioWayColors.ecoceGreen,
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return Colors.transparent;
                        }),
                        checkColor: BioWayColors.ecoceGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  
                  // Status icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: esSublote 
                        ? Colors.purple.withValues(alpha: 0.1)
                        : (statusColor ?? Colors.blue).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      esSublote ? Icons.cut : (statusIcon ?? Icons.inventory_2),
                      color: esSublote ? Colors.purple : (statusColor ?? Colors.blue),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Info principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          esSublote 
                            ? 'SUBLOTE: ${lote.id.substring(0, 8).toUpperCase()}'
                            : 'ID: ${lote.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (statusText != null)
                          Text(
                            statusText!,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor ?? Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Trailing widget
                  if (trailing != null) trailing!,
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Información principal
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.category,
                      label: 'Material',
                      value: lote.datosGenerales.tipoMaterial,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.scale,
                      label: 'Peso',
                      value: '${lote.pesoActual.toStringAsFixed(2)} kg',
                      color: lote.tieneAnalisisLaboratorio ? Colors.blue : null,
                    ),
                  ),
                ],
              ),
              
              // Información adicional personalizable
              if (additionalInfo != null) ...[
                const SizedBox(height: 12),
                additionalInfo!,
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    double fontSize = 14,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}