import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/format_utils.dart';

/// Tarjeta simplificada para mostrar solicitudes en la pantalla maestro unificada
class MaestroSolicitudCard extends StatelessWidget {
  final Map<String, dynamic> solicitud;
  final VoidCallback onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool showAdminInfo;
  
  const MaestroSolicitudCard({
    super.key,
    required this.solicitud,
    required this.onTap,
    this.onApprove,
    this.onReject,
    this.onDelete,
    this.showActions = true,
    this.showAdminInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final datosPerfil = solicitud['datos_perfil'] as Map<String, dynamic>;
    
    // Handle fecha_solicitud - can be Timestamp or String
    DateTime fechaSolicitud;
    if (solicitud['fecha_solicitud'] != null) {
      if (solicitud['fecha_solicitud'] is Timestamp) {
        fechaSolicitud = (solicitud['fecha_solicitud'] as Timestamp).toDate();
      } else if (solicitud['fecha_solicitud'] is String) {
        fechaSolicitud = DateTime.parse(solicitud['fecha_solicitud'] as String);
      } else {
        fechaSolicitud = DateTime.now();
      }
    } else {
      fechaSolicitud = DateTime.now();
    }
    
    final isApproved = solicitud['estado'] == 'aprobada';
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getSubtipoColor(datosPerfil['ecoce_subtipo']).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getSubtipoIcon(datosPerfil['ecoce_subtipo']),
                      color: _getSubtipoColor(datosPerfil['ecoce_subtipo']),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          datosPerfil['ecoce_nombre'] ?? 'Sin nombre',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                        Text(
                          _getSubtipoLabel(datosPerfil['ecoce_subtipo']),
                          style: TextStyle(
                            fontSize: 13,
                            color: BioWayColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isApproved 
                          ? BioWayColors.success.withValues(alpha: 0.1)
                          : BioWayColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isApproved ? 'Aprobado' : 'Pendiente',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isApproved 
                            ? BioWayColors.success
                            : BioWayColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              // Información
              _buildInfoRow(Icons.badge, 'Folio', 
                isApproved && solicitud['folio_asignado'] != null 
                    ? solicitud['folio_asignado'] 
                    : 'Se asignará al aprobar'),
              _buildInfoRow(Icons.person, 'Contacto', datosPerfil['ecoce_nombre_contacto'] ?? 'N/A'),
              _buildInfoRow(Icons.email, 'Email', datosPerfil['ecoce_correo_contacto'] ?? 'N/A'),
              _buildInfoRow(Icons.phone, 'Teléfono', datosPerfil['ecoce_tel_contacto'] ?? 'N/A'),
              _buildInfoRow(Icons.calendar_today, 'Fecha solicitud', 
                _formatDate(fechaSolicitud)),
              
              // Mostrar información de aprobación si es administración
              if (showAdminInfo && isApproved && solicitud['fecha_revision'] != null) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BioWayColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, 
                        size: 16, 
                        color: BioWayColors.success,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Aprobado el ${_formatDate(_parseFecha(solicitud['fecha_revision']))}',
                          style: TextStyle(
                            fontSize: 12,
                            color: BioWayColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Botón de eliminar para usuarios en administración
                if (onDelete != null) ...[
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline, size: 18),
                      label: Text('Eliminar Usuario'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BioWayColors.error,
                        side: BorderSide(color: BioWayColors.error),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              
              // Botones de acción
              if (showActions && !isApproved) ...[
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: Icon(Icons.close, size: 18),
                        label: Text('Rechazar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BioWayColors.error,
                          side: BorderSide(color: BioWayColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: Icon(Icons.check, size: 18),
                        label: Text('Aprobar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BioWayColors.success,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: BioWayColors.textGrey),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: BioWayColors.textGrey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: BioWayColors.darkGreen,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return FormatUtils.formatDate(date);
  }
  
  DateTime _parseFecha(dynamic fecha) {
    if (fecha == null) return DateTime.now();
    
    if (fecha is Timestamp) {
      return fecha.toDate();
    } else if (fecha is String) {
      try {
        return DateTime.parse(fecha);
      } catch (e) {
        return DateTime.now();
      }
    } else if (fecha is DateTime) {
      return fecha;
    }
    
    return DateTime.now();
  }
  
  Color _getSubtipoColor(String? subtipo) {
    switch (subtipo) {
      case 'A': return BioWayColors.darkGreen;
      case 'P': return BioWayColors.ppPurple;
      case 'R': return BioWayColors.recycleOrange;
      case 'T': return BioWayColors.petBlue;
      case 'V': return BioWayColors.deepBlue;
      case 'L': return BioWayColors.otherPurple;
      default: return BioWayColors.textGrey;
    }
  }

  IconData _getSubtipoIcon(String? subtipo) {
    switch (subtipo) {
      case 'A': return Icons.warehouse;
      case 'P': return Icons.sort;
      case 'R': return Icons.recycling;
      case 'T': return Icons.auto_fix_high;
      case 'V': return Icons.local_shipping;
      case 'L': return Icons.science;
      default: return Icons.business;
    }
  }
  
  String _getSubtipoLabel(String? subtipo) {
    switch (subtipo) {
      case 'A': return 'Centro de Acopio';
      case 'P': return 'Planta de Separación';
      case 'R': return 'Reciclador';
      case 'T': return 'Transformador';
      case 'V': return 'Transportista';
      case 'L': return 'Laboratorio';
      default: return 'Usuario Origen';
    }
  }
}