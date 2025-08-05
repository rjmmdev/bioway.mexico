import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../utils/ui_constants.dart';
import '../../../utils/format_utils.dart';
import '../../../utils/document_utils.dart';
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
        elevation: UIConstants.elevationNone,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con información principal
            Container(
              width: double.infinity,
              padding: EdgeInsetsConstants.paddingAll20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BioWayColors.ecoceGreen,
                    BioWayColors.ecoceGreen.withValues(alpha: UIConstants.opacityVeryHigh),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: UIConstants.opacityLow),
                    blurRadius: UIConstants.blurRadiusSmall + 2,
                    offset: Offset(0, UIConstants.offsetY),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _getSubtipoIcon(datosPerfil['ecoce_subtipo']),
                    size: UIConstants.iconSizeDialog,
                    color: Colors.white,
                  ),
                  SizedBox(height: UIConstants.spacing12),
                  Text(
                    datosPerfil['ecoce_nombre'] ?? 'Sin nombre',
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeXLarge,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: UIConstants.spacing8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing16, vertical: UIConstants.spacing8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: UIConstants.opacityMediumLow),
                      borderRadius: BorderRadiusConstants.borderRadiusLarge,
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
                    SizedBox(height: UIConstants.spacing8),
                    Text(
                      'Folio: ${solicitud['folio_asignado']}',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeBody + 2,
                        color: Colors.white.withValues(alpha: UIConstants.opacityAlmostFull),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Contenido
            Padding(
              padding: EdgeInsetsConstants.paddingAll16,
              child: Column(
                children: [
                  // Estado de la solicitud
                  Container(
                    width: double.infinity,
                    padding: EdgeInsetsConstants.paddingAll16,
                    decoration: BoxDecoration(
                      color: isApproved 
                          ? BioWayColors.success.withValues(alpha: UIConstants.opacityLow)
                          : BioWayColors.warning.withValues(alpha: UIConstants.opacityLow),
                      borderRadius: BorderRadiusConstants.borderRadiusMedium,
                      border: Border.all(
                        color: isApproved 
                            ? BioWayColors.success.withValues(alpha: UIConstants.opacityMediumLow)
                            : BioWayColors.warning.withValues(alpha: UIConstants.opacityMediumLow),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isApproved ? Icons.check_circle : Icons.pending_actions,
                          color: isApproved ? BioWayColors.success : BioWayColors.warning,
                        ),
                        SizedBox(width: UIConstants.spacing12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isApproved ? 'Solicitud Aprobada' : 'Solicitud Pendiente',
                                style: TextStyle(
                                  fontSize: UIConstants.fontSizeBody,
                                  fontWeight: FontWeight.bold,
                                  color: isApproved ? BioWayColors.success : BioWayColors.warning,
                                ),
                              ),
                              if (isApproved && solicitud['fecha_revision'] != null) ...[
                                SizedBox(height: UIConstants.spacing4),
                                Text(
                                  'Aprobada el ${_formatDate(_parseFechaRevision(solicitud['fecha_revision']))}',
                                  style: TextStyle(
                                    fontSize: UIConstants.fontSizeSmall + 1,
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
                  
                  SizedBox(height: UIConstants.spacing20),
                  
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
                  
                  SizedBox(height: UIConstants.spacing16),
                  
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
                  
                  SizedBox(height: UIConstants.spacing16),
                  
                  // Información Operativa (Paso 3 del registro)
                  _buildInformacionOperativa(context, datosPerfil),
                  
                  SizedBox(height: UIConstants.spacing16),
                  
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
                    SizedBox(height: UIConstants.spacing16),
                  ],
                  
                  // Documentos
                  _buildDocumentsSection(context, datosPerfil),
                  
                  // Actividades Autorizadas
                  if (datosPerfil['ecoce_act_autorizadas'] != null && 
                      (datosPerfil['ecoce_act_autorizadas'] as List).isNotEmpty) ...[
                    SizedBox(height: UIConstants.spacing16),
                    _buildActividadesSection(context, datosPerfil),
                  ],
                  
                  // Botones de acción (solo si está pendiente)
                  if (!isApproved && (onApprove != null || onReject != null)) ...[
                    SizedBox(height: UIConstants.spacing24),
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
                                side: BorderSide(color: BioWayColors.error, width: UIConstants.borderWidthThick),
                                padding: EdgeInsets.symmetric(vertical: UIConstants.spacing16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusConstants.borderRadiusMedium,
                                ),
                              ),
                            ),
                          ),
                        if (onReject != null && onApprove != null)
                          SizedBox(width: UIConstants.spacing16),
                        if (onApprove != null)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onApprove,
                              icon: Icon(Icons.check),
                              label: Text('Aprobar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BioWayColors.success,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: UIConstants.spacing16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusConstants.borderRadiusMedium,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing20),
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
    // Buscar documentos en datos_perfil o en el objeto solicitud principal
    final solicitudDocs = solicitud['documentos'] as Map<String, dynamic>?;
    
    final documents = <String, String?>{
      'Situación Fiscal': datosPerfil['ecoce_const_sit_fis'] ?? solicitudDocs?['const_sit_fis'],
      'Comprobante de Domicilio': datosPerfil['ecoce_comp_domicilio'] ?? solicitudDocs?['comp_domicilio'],
      'Carátula Bancaria': datosPerfil['ecoce_banco_caratula'] ?? solicitudDocs?['banco_caratula'],
      'INE': datosPerfil['ecoce_ine'] ?? solicitudDocs?['ine'],
      'Opinión de Cumplimiento': datosPerfil['ecoce_opinion_cumplimiento'] ?? solicitudDocs?['opinion_cumplimiento'],
      'RAMIR': datosPerfil['ecoce_ramir'] ?? solicitudDocs?['ramir'],
      'Plan de Manejo': datosPerfil['ecoce_plan_manejo'] ?? solicitudDocs?['plan_manejo'],
      'Licencia Ambiental': datosPerfil['ecoce_licencia_ambiental'] ?? solicitudDocs?['licencia_ambiental'],
    };
    
    final validDocuments = documents.entries
        .where((entry) => entry.value != null && entry.value!.isNotEmpty)
        .toList();
    
    if (validDocuments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadiusConstants.borderRadiusMedium,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
              blurRadius: UIConstants.blurRadiusSmall,
              offset: Offset(0, UIConstants.offsetY),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.folder_off,
              size: UIConstants.iconSizeLarge + UIConstants.spacing20,
              color: Colors.grey[400],
            ),
            SizedBox(height: UIConstants.spacing8),
            Text(
              'No hay documentos disponibles',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: UIConstants.fontSizeBody,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
            blurRadius: UIConstants.blurRadiusSmall,
            offset: Offset(0, UIConstants.offsetY),
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
              SizedBox(width: UIConstants.spacing8),
              Text(
                'Documentos Presentados',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeBody + 2,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: UIConstants.spacing16),
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
      margin: EdgeInsets.only(bottom: UIConstants.spacing12),
      decoration: BoxDecoration(
        color: BioWayColors.backgroundGrey,
        borderRadius: BorderRadiusConstants.borderRadiusSmall,
        border: Border.all(
          color: Colors.grey.withValues(alpha: UIConstants.opacityMediumLow),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: UIConstants.buttonHeightMedium,
          height: UIConstants.buttonHeightMedium,
          decoration: BoxDecoration(
            color: BioWayColors.petBlue.withValues(alpha: UIConstants.opacityLow),
            borderRadius: BorderRadiusConstants.borderRadiusSmall,
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
            fontSize: UIConstants.fontSizeSmall,
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
    DocumentUtils.openDocument(
      context: context,
      url: url,
      documentName: title,
    );
  }
  
  String _formatDate(DateTime date) {
    return FormatUtils.formatDate(date);
  }
  
  DateTime _parseFechaRevision(dynamic fecha) {
    if (fecha is Timestamp) {
      return fecha.toDate();
    } else if (fecha is String) {
      return DateTime.parse(fecha);
    } else {
      return DateTime.now();
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
  
  Widget _buildActividadesSection(BuildContext context, Map<String, dynamic> datosPerfil) {
    final actividades = datosPerfil['ecoce_act_autorizadas'] as List;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
            blurRadius: UIConstants.blurRadiusSmall,
            offset: Offset(0, UIConstants.offsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: BioWayColors.ecoceGreen,
              ),
              SizedBox(width: UIConstants.spacing8),
              Text(
                'Actividades Autorizadas',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeBody + 2,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: UIConstants.spacing16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actividades.map((actividad) {
              final actividadStr = actividad.toString();
              return Container(
                padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing12, vertical: UIConstants.spacing8 - 2),
                decoration: BoxDecoration(
                  color: BioWayColors.ecoceGreen.withValues(alpha: UIConstants.opacityLow),
                  borderRadius: BorderRadiusConstants.borderRadiusLarge,
                  border: Border.all(
                    color: BioWayColors.ecoceGreen.withValues(alpha: UIConstants.opacityMedium),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.done,
                      size: UIConstants.iconSizeBody,
                      color: BioWayColors.ecoceGreen,
                    ),
                    SizedBox(width: UIConstants.spacing4),
                    Text(
                      _getActividadLabel(actividadStr),
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeSmall + 1,
                        color: BioWayColors.darkGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  String _getActividadLabel(String actividadId) {
    final Map<String, String> actividadesMap = {
      'acopio': 'Acopio',
      'recoleccion': 'Recolección',
      'tratamiento': 'Tratamiento',
      'almacenamiento': 'Almacenamiento',
      'transporte': 'Transporte',
      'disposicion_final': 'Disposición Final',
      'comercializacion': 'Comercialización',
      'reciclaje': 'Reciclaje',
    };
    
    return actividadesMap[actividadId] ?? actividadId;
  }
  
  Widget _buildInformacionOperativa(BuildContext context, Map<String, dynamic> datosPerfil) {
    final materiales = datosPerfil['ecoce_lista_materiales'] as List?;
    final transporte = datosPerfil['ecoce_transporte'] as bool?;
    final dimensionesCapacidad = datosPerfil['ecoce_dim_cap'] as Map<String, dynamic>?;
    final pesoCapacidad = datosPerfil['ecoce_peso_cap'];
    final subtipo = datosPerfil['ecoce_subtipo'] as String?;
    final linkRedSocial = datosPerfil['ecoce_link_red_social'] as String?;
    
    // Si es transportista, no mostrar esta sección ya que no maneja materiales
    if (subtipo == 'V') {
      return const SizedBox.shrink();
    }
    
    // Verificar si hay información operativa para mostrar
    bool hasOperationalInfo = (materiales != null && materiales.isNotEmpty) ||
                              transporte != null ||
                              dimensionesCapacidad != null ||
                              pesoCapacidad != null ||
                              (linkRedSocial != null && linkRedSocial.isNotEmpty);
    
    if (!hasOperationalInfo) {
      return const SizedBox.shrink();
    }
    
    List<InfoItem> items = [];
    
    // Agregar materiales que maneja
    if (materiales != null && materiales.isNotEmpty) {
      String materialesStr = materiales.join(', ');
      items.add(
        InfoItem(
          label: 'Materiales que maneja',
          value: materialesStr,
        ),
      );
    }
    
    // Agregar información de transporte
    if (transporte != null) {
      items.add(
        InfoItem(
          label: 'Transporte propio',
          value: transporte ? 'Sí' : 'No',
        ),
      );
    }
    
    // Agregar link de redes sociales
    if (linkRedSocial != null && linkRedSocial.isNotEmpty) {
      items.add(
        InfoItem(
          label: 'Redes sociales',
          value: linkRedSocial,
          copyable: true,
        ),
      );
    }
    
    // Agregar capacidad de prensado (solo para Acopiador y Planta de Separación)
    if ((subtipo == 'A' || subtipo == 'P')) {
      if (dimensionesCapacidad != null) {
        final largo = dimensionesCapacidad['largo'] ?? 0;
        final ancho = dimensionesCapacidad['ancho'] ?? 0;
        final alto = dimensionesCapacidad['alto'] ?? 0;
        
        if (largo > 0 || ancho > 0 || alto > 0) {
          items.add(
            InfoItem(
              label: 'Dimensiones de prensado',
              value: '${largo}m × ${ancho}m × ${alto}m',
            ),
          );
        }
      }
      
      if (pesoCapacidad != null && pesoCapacidad > 0) {
        items.add(
          InfoItem(
            label: 'Capacidad de prensado',
            value: '${pesoCapacidad} kg',
          ),
        );
      }
    }
    
    // Si no hay items para mostrar, no mostrar la sección
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return MaestroInfoSection(
      title: 'Información Operativa',
      icon: Icons.factory,
      color: BioWayColors.ppPurple,
      items: items,
    );
  }
}