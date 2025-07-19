import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/format_utils.dart';

/// Tarjeta reutilizable para mostrar información de usuario en las pantallas maestro
class MaestroUserCard extends StatelessWidget {
  final String id;
  final String nombre;
  final String tipoUsuario;
  final String? folio;
  final DateTime? fecha;
  final String? estado;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showExpandIcon;
  final Map<String, dynamic>? additionalInfo;

  const MaestroUserCard({
    super.key,
    required this.id,
    required this.nombre,
    required this.tipoUsuario,
    this.folio,
    this.fecha,
    this.estado,
    this.icon,
    this.color,
    this.onTap,
    this.trailing,
    this.showExpandIcon = true,
    this.additionalInfo,
  });

  @override
  Widget build(BuildContext context) {
    final userColor = color ?? _getColorForType(tipoUsuario);
    final userIcon = icon ?? _getIconForType(tipoUsuario);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Icono del tipo de usuario
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: userColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      userIcon,
                      color: userColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Información principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildChip(tipoUsuario, userColor),
                            if (folio != null) ...[
                              const SizedBox(width: 8),
                              _buildChip(folio!, Colors.blue),
                            ],
                            if (estado != null) ...[
                              const SizedBox(width: 8),
                              _buildStatusChip(estado!),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Trailing widget o icono de expansión
                  if (trailing != null)
                    trailing!
                  else if (showExpandIcon)
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                ],
              ),
              // Información adicional
              if (fecha != null || additionalInfo != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (fecha != null) ...[
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        FormatUtils.formatDate(fecha),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (additionalInfo != null) ...[
                      const Spacer(),
                      ...additionalInfo!.entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Row(
                          children: [
                            Icon(
                              _getIconForInfoKey(entry.key),
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              entry.value.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'activo':
      case 'aprobado':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pendiente':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'rechazado':
      case 'inactivo':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 12,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForType(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'origen':
      case 'acopiador':
        return BioWayColors.darkGreen;
      case 'reciclador':
        return BioWayColors.primaryGreen;
      case 'transporte':
      case 'transportista':
        return BioWayColors.petBlue;
      case 'laboratorio':
        return BioWayColors.ppPurple;
      case 'transformador':
        return Colors.orange;
      case 'planta':
      case 'planta de separación':
        return BioWayColors.ppPurple;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForType(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'origen':
      case 'acopiador':
        return Icons.warehouse;
      case 'reciclador':
        return Icons.recycling;
      case 'transporte':
      case 'transportista':
        return Icons.local_shipping;
      case 'laboratorio':
        return Icons.science;
      case 'transformador':
        return Icons.transform;
      case 'planta':
      case 'planta de separación':
        return Icons.sort;
      default:
        return Icons.business;
    }
  }

  IconData _getIconForInfoKey(String key) {
    switch (key.toLowerCase()) {
      case 'email':
      case 'correo':
        return Icons.email;
      case 'telefono':
      case 'phone':
        return Icons.phone;
      case 'direccion':
      case 'ubicacion':
        return Icons.location_on;
      case 'documentos':
        return Icons.description;
      default:
        return Icons.info_outline;
    }
  }
}