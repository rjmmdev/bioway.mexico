import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../utils/colors.dart';
import '../../shared/utils/material_utils.dart';
import '../../../../utils/format_utils.dart';

class OrigenLoteCard extends StatelessWidget {
  final Map<String, dynamic> lote;
  final VoidCallback? onQRTap;
  final bool showActions;

  const OrigenLoteCard({
    super.key,
    required this.lote,
    this.onQRTap,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final materialColor = MaterialUtils.getMaterialColor(lote['material'] ?? '');
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onQRTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              child: Row(
                children: [
                  // Icono del material
                  Container(
                    width: isCompact ? 42 : 48,
                    height: isCompact ? 42 : 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          materialColor.withValues(alpha:0.2),
                          materialColor.withValues(alpha:0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      MaterialUtils.getMaterialIcon(lote['material'] ?? ''),
                      color: materialColor,
                      size: isCompact ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isCompact ? 12 : 16),
                  // Información del lote
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primera línea: Material y ID
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 6 : 8,
                                vertical: isCompact ? 2 : 3,
                              ),
                              decoration: BoxDecoration(
                                color: materialColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                lote['material'] ?? '',
                                style: TextStyle(
                                  fontSize: isCompact ? 10 : 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Lote ${lote['id'] ?? lote['firebaseId'] ?? ''}',
                                style: TextStyle(
                                  fontSize: isCompact ? 10 : 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Segunda línea: Fuente (sin prefijo "Fuente:")
                        Text(
                          lote['fuente'] ?? 'Sin especificar',
                          style: TextStyle(
                            fontSize: isCompact ? 13 : 14,
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
                              isCompact,
                            ),
                            if (lote['presentacion'] != null)
                              _buildPresentacionChip(
                                lote['presentacion'],
                                Colors.green,
                                isCompact,
                              ),
                            _buildCompactChip(
                              Icons.calendar_today_outlined,
                              lote['fecha'] != null 
                                ? MaterialUtils.formatDate(lote['fecha'])
                                : FormatUtils.formatDate(DateTime.now()),
                              Colors.orange,
                              isCompact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Acciones
                  if (showActions) ...[
                    SizedBox(width: isCompact ? 8 : 12),
                    Container(
                      decoration: BoxDecoration(
                        color: BioWayColors.ecoceGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onQRTap?.call();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: EdgeInsets.all(isCompact ? 8 : 10),
                            child: Icon(
                              Icons.qr_code,
                              color: Colors.white,
                              size: isCompact ? 18 : 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactChip(IconData icon, String text, Color color, bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8, 
        vertical: isCompact ? 3 : 4
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isCompact ? 11 : 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
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

  Widget _buildPresentacionChip(String presentacion, Color color, bool isCompact) {
    final svgPath = presentacion == 'Pacas' 
        ? 'assets/images/icons/pacas.svg' 
        : 'assets/images/icons/sacos.svg';
        
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8, 
        vertical: isCompact ? 3 : 4
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            svgPath,
            width: isCompact ? 11 : 12,
            height: isCompact ? 11 : 12,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              presentacion,
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
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
}