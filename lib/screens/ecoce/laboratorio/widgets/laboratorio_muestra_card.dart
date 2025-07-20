import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';
import '../../shared/utils/material_utils.dart';

class LaboratorioMuestraCard extends StatelessWidget {
  final Map<String, dynamic> muestra;
  final VoidCallback? onTap;
  final VoidCallback? onDetailTap;
  final bool showActions;
  final Widget? trailing;
  final bool showActionButton;
  final String? actionButtonText;
  final Color? actionButtonColor;
  final VoidCallback? onActionPressed;

  const LaboratorioMuestraCard({
    super.key,
    required this.muestra,
    this.onTap,
    this.onDetailTap,
    this.showActions = true,
    this.trailing,
    this.showActionButton = false,
    this.actionButtonText,
    this.actionButtonColor,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final materialColor = MaterialUtils.getMaterialColor(muestra['material'] ?? '');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: showActionButton ? null : (onTap ?? onDetailTap),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icono del material
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              materialColor.withValues(alpha: 0.2),
                              materialColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          MaterialUtils.getMaterialIcon(muestra['material'] ?? ''),
                          color: materialColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Información de la muestra
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Primera línea: Material y ID
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: materialColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    muestra['material'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Muestra ${muestra['id'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Segunda línea: Origen
                            Text(
                              muestra['origen'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            // Tercera línea: Peso, Estado y Fecha
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _buildCompactChip(
                                  Icons.scale_outlined,
                                  '${muestra['peso']} kg',
                                  Colors.blue,
                                ),
                                if (muestra['estado'] != null)
                                  _buildEstadoChip(
                                    muestra['estado'],
                                    _getEstadoColor(muestra['estado']),
                                  ),
                                _buildCompactChip(
                                  Icons.calendar_today_outlined,
                                  muestra['fecha'] ?? MaterialUtils.formatDate(DateTime.now()),
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Acciones o trailing widget
                      if (trailing != null)
                        trailing!
                      else if (showActions) ...[
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: onActionPressed ?? onTap,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Botón de acción si se proporciona
                if (showActionButton && actionButtonText != null && onActionPressed != null)
                  InkWell(
                    onTap: onActionPressed,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: (actionButtonColor ?? BioWayColors.ecoceGreen).withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getActionIcon(muestra['estado']),
                            color: actionButtonColor ?? BioWayColors.ecoceGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            actionButtonText!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: actionButtonColor ?? BioWayColors.ecoceGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(String estado, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(estado),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _getEstadoText(estado),
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }


  IconData _getStatusIcon(String estado) {
    switch (estado) {
      case 'formulario':
        return Icons.assignment_outlined;
      case 'documentacion':
        return Icons.upload_file;
      case 'finalizado':
        return Icons.check_circle;
      case 'registro':
        return Icons.edit_note;
      default:
        return Icons.science;
    }
  }

  IconData _getActionIcon(String? estado) {
    switch (estado) {
      case 'formulario':
        return Icons.assignment;
      case 'documentacion':
        return Icons.upload_file;
      case 'finalizado':
        return Icons.picture_as_pdf;
      default:
        return Icons.science;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'formulario':
        return BioWayColors.warning;
      case 'documentacion':
        return BioWayColors.info;
      case 'finalizado':
        return BioWayColors.success;
      case 'registro':
        return BioWayColors.error;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoText(String estado) {
    switch (estado) {
      case 'formulario':
        return 'Formulario';
      case 'documentacion':
        return 'Documentación';
      case 'finalizado':
        return 'Finalizado';
      case 'registro':
        return 'En registro';
      default:
        return estado;
    }
  }

}