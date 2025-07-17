import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../utils/colors.dart';

class RecicladorLoteCard extends StatelessWidget {
  final Map<String, dynamic> lote;
  final VoidCallback? onTap;
  final VoidCallback? onDetailTap;
  final bool showActions;
  final Widget? trailing;
  final bool showActionButton;
  final String? actionButtonText;
  final Color? actionButtonColor;
  final VoidCallback? onActionPressed;

  const RecicladorLoteCard({
    super.key,
    required this.lote,
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
    final materialColor = _getMaterialColor(lote['material'] ?? '');
    
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
                  color: Colors.black.withOpacity(0.06),
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
                          materialColor.withOpacity(0.2),
                          materialColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getMaterialIcon(lote['material'] ?? ''),
                      color: materialColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Información del lote
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
                                lote['material'] ?? '',
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
                                'Lote ${lote['id'] ?? ''}',
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
                        // Segunda línea: Origen/Fuente
                        Text(
                          lote['origen'] ?? lote['fuente'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        // Tercera línea: Peso, Presentación y Fecha
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _buildCompactChip(
                              Icons.scale_outlined,
                              '${lote['peso']} kg',
                              Colors.blue,
                            ),
                            if (lote['presentacion'] != null)
                              _buildPresentacionChip(
                                lote['presentacion'],
                                Colors.green,
                              ),
                            _buildCompactChip(
                              Icons.calendar_today_outlined,
                              lote['fecha'] ?? _formatDate(lote['fechaCreacion'] ?? DateTime.now()),
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
                    color: (actionButtonColor ?? BioWayColors.ecoceGreen).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (lote['estado'] == 'finalizado')
                        Icon(
                          Icons.qr_code,
                          color: actionButtonColor ?? BioWayColors.ecoceGreen,
                          size: 18,
                        ),
                      if (lote['estado'] == 'finalizado')
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
  )
    );
}

  Widget _buildCompactChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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

  Widget _buildPresentacionChip(String presentacion, Color color) {
    final svgPath = presentacion == 'Pacas' 
        ? 'assets/images/icons/pacas.svg' 
        : 'assets/images/icons/sacos.svg';
        
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            svgPath,
            width: 12,
            height: 12,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              presentacion,
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

  Color _getMaterialColor(String material) {
    switch (material) {
      case 'PEBD':
        return BioWayColors.pebdPink;
      case 'PP':
        return BioWayColors.ppPurple;
      case 'Multilaminado':
        return BioWayColors.multilaminadoBrown;
      default:
        return BioWayColors.ecoceGreen;
    }
  }

  IconData _getMaterialIcon(String material) {
    switch (material) {
      case 'PEBD':
        return Icons.shopping_bag; // Bolsas
      case 'PP':
        return Icons.kitchen; // Contenedores
      case 'Multilaminado':
        return Icons.layers; // Capas múltiples
      default:
        return Icons.recycling;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}