import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
import '../shared/widgets/document_viewer_dialog.dart';
import 'widgets/maestro_info_section.dart';

/// Pantalla de detalles de una solicitud para revisión completa
class MaestroSolicitudDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> solicitud;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const MaestroSolicitudDetailsScreen({
    super.key,
    required this.solicitud,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final datosPerfil = solicitud['datos_perfil'] as Map<String, dynamic>;
    final isApproved = solicitud['estado'] == 'aprobada';
    
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        title: Text('Detalles de Solicitud'),
        backgroundColor: BioWayColors.ecoceGreen,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con información principal
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BioWayColors.ecoceGreen,
                    BioWayColors.ecoceGreen.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _getSubtipoIcon(datosPerfil['ecoce_subtipo']),
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 12),
                  Text(
                    datosPerfil['ecoce_nombre'] ?? 'Sin nombre',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getSubtipoLabel(datosPerfil['ecoce_subtipo']),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isApproved && solicitud['folio_asignado'] != null) ...[
                    SizedBox(height: 8),
                    Text(
                      'Folio: ${solicitud['folio_asignado']}',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Contenido
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Estado de la solicitud
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isApproved 
                          ? BioWayColors.success.withValues(alpha: 0.1)
                          : BioWayColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isApproved 
                            ? BioWayColors.success.withValues(alpha: 0.3)
                            : BioWayColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isApproved ? Icons.check_circle : Icons.pending_actions,
                          color: isApproved ? BioWayColors.success : BioWayColors.warning,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isApproved ? 'Solicitud Aprobada' : 'Solicitud Pendiente',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isApproved ? BioWayColors.success : BioWayColors.warning,
                                ),
                              ),
                              if (isApproved && solicitud['fecha_revision'] != null) ...[
                                SizedBox(height: 4),
                                Text(
                                  'Aprobada el ${_formatDate((solicitud['fecha_revision'] as Timestamp).toDate())}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: BioWayColors.textGrey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Información de contacto
                  MaestroInfoSection(
                    title: 'Información de Contacto',
                    icon: Icons.contact_mail,
                    color: BioWayColors.ecoceGreen,
                    items: [
                      InfoItem(label: 'Nombre del Contacto', value: datosPerfil['ecoce_nombre_contacto'] ?? 'N/A'),
                      InfoItem(label: 'Correo Electrónico', value: datosPerfil['ecoce_correo_contacto'] ?? 'N/A'),
                      InfoItem(label: 'Teléfono', value: datosPerfil['ecoce_tel_contacto'] ?? 'N/A'),
                      InfoItem(label: 'RFC', value: datosPerfil['ecoce_rfc'] ?? 'N/A'),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Información de ubicación
                  MaestroInfoSection(
                    title: 'Información de Ubicación',
                    icon: Icons.location_on,
                    color: BioWayColors.petBlue,
                    items: [
                      InfoItem(label: 'Calle', value: datosPerfil['ecoce_calle'] ?? 'N/A'),
                      InfoItem(label: 'Número', value: '${datosPerfil['ecoce_num_ext'] ?? ''} ${datosPerfil['ecoce_num_int'] ?? ''}'.trim()),
                      InfoItem(label: 'Colonia', value: datosPerfil['ecoce_colonia'] ?? 'N/A'),
                      InfoItem(label: 'C.P.', value: datosPerfil['ecoce_cp'] ?? 'N/A'),
                      InfoItem(label: 'Municipio', value: datosPerfil['ecoce_municipio'] ?? 'N/A'),
                      InfoItem(label: 'Estado', value: datosPerfil['ecoce_estado'] ?? 'N/A'),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Información bancaria
                  if (datosPerfil['ecoce_banco_nombre'] != null) ...[
                    MaestroInfoSection(
                      title: 'Información Bancaria',
                      icon: Icons.account_balance,
                      color: BioWayColors.darkGreen,
                      items: [
                        InfoItem(label: 'Banco', value: datosPerfil['ecoce_banco_nombre'] ?? 'N/A'),
                        InfoItem(label: 'Titular', value: datosPerfil['ecoce_banco_beneficiario'] ?? 'N/A'),
                        InfoItem(label: 'Cuenta', value: datosPerfil['ecoce_banco_num_cuenta'] ?? 'N/A'),
                        InfoItem(label: 'CLABE', value: datosPerfil['ecoce_banco_clabe'] ?? 'N/A'),
                      ],
                    ),
                    SizedBox(height: 16),
                  ],
                  
                  // Documentos
                  _buildDocumentsSection(context, datosPerfil),
                  
                  // Botones de acción (solo si está pendiente)
                  if (!isApproved && (onApprove != null || onReject != null)) ...[
                    SizedBox(height: 24),
                    Row(
                      children: [
                        if (onReject != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onReject,
                              icon: Icon(Icons.close),
                              label: Text('Rechazar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: BioWayColors.error,
                                side: BorderSide(color: BioWayColors.error, width: 2),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        if (onReject != null && onApprove != null)
                          SizedBox(width: 16),
                        if (onApprove != null)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onApprove,
                              icon: Icon(Icons.check),
                              label: Text('Aprobar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BioWayColors.success,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDocumentsSection(BuildContext context, Map<String, dynamic> datosPerfil) {
    final documents = <String, String?>{
      'Situación Fiscal': datosPerfil['ecoce_const_sit_fis'],
      'Comprobante de Domicilio': datosPerfil['ecoce_comp_domicilio'],
      'Carátula Bancaria': datosPerfil['ecoce_banco_caratula'],
      'INE': datosPerfil['ecoce_ine'],
    };
    
    final validDocuments = documents.entries
        .where((entry) => entry.value != null && entry.value!.isNotEmpty)
        .toList();
    
    if (validDocuments.isEmpty) {
      return Container();
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.folder_open,
                color: BioWayColors.ecoceGreen,
              ),
              SizedBox(width: 8),
              Text(
                'Documentos Presentados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...validDocuments.map((entry) => _buildDocumentItem(
            context,
            entry.key,
            entry.value!,
          )),
        ],
      ),
    );
  }
  
  Widget _buildDocumentItem(BuildContext context, String title, String url) {
    final isUrl = url.startsWith('http') || url.startsWith('https');
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: BioWayColors.backgroundGrey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: BioWayColors.petBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.description,
            color: BioWayColors.petBlue,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: BioWayColors.darkGreen,
          ),
        ),
        subtitle: Text(
          isUrl ? 'Documento disponible' : 'Documento cargado',
          style: TextStyle(
            fontSize: 12,
            color: BioWayColors.textGrey,
          ),
        ),
        trailing: Icon(
          Icons.visibility,
          color: BioWayColors.ecoceGreen,
        ),
        onTap: isUrl ? () => _viewDocument(context, title, url) : null,
      ),
    );
  }
  
  void _viewDocument(BuildContext context, String title, String url) {
    showDialog(
      context: context,
      builder: (context) => DocumentViewerDialog(
        title: title,
        url: url,
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return FormatUtils.formatDate(date);
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