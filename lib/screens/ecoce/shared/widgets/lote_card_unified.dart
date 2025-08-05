import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/ui_constants.dart';
import '../utils/material_utils.dart';

/// Widget unificado para mostrar tarjetas de lotes
/// Combina las funcionalidades de las 3 versiones anteriores
class LoteCard extends StatelessWidget {
  final Map<String, dynamic> lote;
  
  // Callbacks
  final VoidCallback? onTap;
  final VoidCallback? onQRTap;
  final VoidCallback? onActionTap;
  final VoidCallback? onDetailTap;
  
  // Personalización de acciones
  final bool showActions;
  final bool showQRButton;
  final String? actionButtonText;
  final Color? actionButtonColor;
  final IconData? actionButtonIcon;
  final Widget? trailing;
  
  // Opciones de visualización
  final bool showLocation;
  final bool showStatus;
  final bool responsive;
  
  const LoteCard({
    super.key,
    required this.lote,
    this.onTap,
    this.onQRTap,
    this.onActionTap,
    this.onDetailTap,
    this.showActions = true,
    this.showQRButton = true,
    this.actionButtonText,
    this.actionButtonColor,
    this.actionButtonIcon,
    this.trailing,
    this.showLocation = false,
    this.showStatus = false,
    this.responsive = false,
  });
  
  // Constructores nombrados para casos de uso específicos
  const LoteCard.reciclador({
    super.key,
    required this.lote,
    this.onTap,
    this.onQRTap,
    this.onActionTap,
    this.onDetailTap,
    this.actionButtonText,
    this.actionButtonColor,
    this.actionButtonIcon,
    this.trailing,
  }) : showActions = true,
       showQRButton = true,
       showLocation = false,
       showStatus = true,
       responsive = false;
       
  const LoteCard.repositorio({
    super.key,
    required this.lote,
    required VoidCallback this.onTap,
    this.responsive = true,
  }) : onQRTap = null,
       onActionTap = null,
       onDetailTap = null,
       showActions = false,
       showQRButton = false,
       actionButtonText = null,
       actionButtonColor = null,
       actionButtonIcon = null,
       trailing = null,
       showLocation = true,
       showStatus = true;
       
  const LoteCard.simple({
    super.key,
    required this.lote,
    this.onTap,
    this.onQRTap,
  }) : onActionTap = null,
       onDetailTap = null,
       showActions = true,
       showQRButton = true,
       actionButtonText = null,
       actionButtonColor = null,
       actionButtonIcon = null,
       trailing = null,
       showLocation = false,
       showStatus = false,
       responsive = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = responsive && screenWidth > 600;
    
    // Extraer datos con compatibilidad para diferentes estructuras
    final id = lote['id'] ?? lote['firebaseId'] ?? 'Sin ID';
    final material = lote['material'] ?? 'Sin material';
    final origen = lote['origen'] ?? lote['fuente'] ?? 'Origen desconocido';
    final peso = lote['peso'] ?? 0.0;
    final presentacion = lote['presentacion'];
    final estado = lote['estado'];
    final ubicacionActual = lote['ubicacionActual'];
    final fecha = lote['fecha'] ?? lote['fechaCreacion'];
    
    return Card(
      elevation: UIConstants.elevationSmall,
      margin: EdgeInsets.symmetric(horizontal: UIConstants.spacing16, vertical: UIConstants.spacing8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusConstants.borderRadiusMedium,
      ),
      child: InkWell(
        onTap: onTap != null ? () {
          HapticFeedback.lightImpact();
          onTap!();
        } : null,
        borderRadius: BorderRadiusConstants.borderRadiusMedium,
        child: Padding(
          padding: EdgeInsets.all(isTablet ? UIConstants.spacing20 : UIConstants.spacing16),
          child: Column(
            children: [
              // Header Row
              Row(
                children: [
                  _buildMaterialIcon(material),
                  SizedBox(width: UIConstants.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Lote #$id',
                                style: TextStyle(
                                  fontSize: isTablet ? UIConstants.fontSizeBody + 2 : UIConstants.fontSizeBody,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (showStatus && estado != null) ...[
                              SizedBox(width: UIConstants.spacing8),
                              _buildStatusChip(estado),
                            ],
                          ],
                        ),
                        SizedBox(height: UIConstants.spacing4),
                        Text(
                          origen,
                          style: TextStyle(
                            fontSize: isTablet ? UIConstants.fontSizeMedium : UIConstants.fontSizeSmall,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) 
                    trailing!
                  else if (showActions) 
                    _buildActionButtons(context),
                ],
              ),
              SizedBox(height: UIConstants.spacing16),
              
              // Info Chips
              Wrap(
                spacing: UIConstants.spacing8,
                runSpacing: UIConstants.spacing8,
                children: [
                  _buildInfoChip(
                    Icons.category,
                    material,
                    MaterialUtils.getMaterialColor(material),
                  ),
                  _buildInfoChip(
                    Icons.scale,
                    '${peso.toStringAsFixed(1)} kg',
                    Colors.blue,
                  ),
                  if (presentacion != null)
                    _buildInfoChip(
                      Icons.inventory_2,
                      presentacion,
                      Colors.purple,
                    ),
                  if (showLocation && ubicacionActual != null)
                    _buildInfoChip(
                      Icons.location_on,
                      ubicacionActual,
                      Colors.green,
                    ),
                  if (fecha != null)
                    _buildInfoChip(
                      Icons.calendar_today,
                      MaterialUtils.formatDate(fecha),
                      Colors.orange,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMaterialIcon(String material) {
    return Container(
      width: UIConstants.iconSizeLarge + UIConstants.spacing20,
      height: UIConstants.iconSizeLarge + UIConstants.spacing20,
      decoration: BoxDecoration(
        color: MaterialUtils.getMaterialColor(material).withValues(alpha: UIConstants.opacityLow),
        borderRadius: BorderRadiusConstants.borderRadiusSmall,
      ),
      child: Icon(
        MaterialUtils.getMaterialIcon(material),
        color: MaterialUtils.getMaterialColor(material),
        size: UIConstants.iconSizeMedium,
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context) {
    if (actionButtonText != null && onActionTap != null) {
      // Botón de acción personalizado
      return SizedBox(
        height: UIConstants.buttonHeightSmall + UIConstants.spacing4,
        child: ElevatedButton.icon(
          onPressed: onActionTap,
          icon: Icon(actionButtonIcon ?? Icons.arrow_forward, size: UIConstants.iconSizeBody + 2),
          label: Flexible(
            child: Text(
              actionButtonText!,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: actionButtonColor ?? Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusConstants.borderRadiusSmall,
            ),
            padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing12),
          ),
        ),
      );
    } else if (showQRButton && onQRTap != null) {
      // Botón QR por defecto
      return IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onQRTap!();
        },
        icon: const Icon(Icons.qr_code),
        tooltip: 'Ver código QR',
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusConstants.borderRadiusSmall,
          ),
        ),
      );
    }
    return SizedBox.shrink();
  }
  
  Widget _buildStatusChip(String estado) {
    Color statusColor;
    switch (estado.toLowerCase()) {
      case 'activo':
        statusColor = Colors.green;
        break;
      case 'procesando':
        statusColor = Colors.orange;
        break;
      case 'completado':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing8, vertical: UIConstants.spacing4 / 2),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: UIConstants.opacityLow),
        borderRadius: BorderRadiusConstants.borderRadiusMedium,
        border: Border.all(color: statusColor.withValues(alpha: UIConstants.opacityHigh)),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontSize: UIConstants.fontSizeSmall - 2,
          fontWeight: FontWeight.bold,
          color: statusColor,
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      constraints: BoxConstraints(maxWidth: UIConstants.maxContentWidth / 4),
      padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing12, vertical: UIConstants.spacing8 - 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: UIConstants.opacityLow),
        borderRadius: BorderRadiusConstants.borderRadiusLarge,
        border: Border.all(color: color.withValues(alpha: UIConstants.opacityMedium)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: UIConstants.fontSizeMedium, color: color),
          SizedBox(width: UIConstants.spacing4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: UIConstants.fontSizeSmall,
                color: color,
                fontWeight: FontWeight.w500,
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