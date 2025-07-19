import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../services/firebase/ecoce_profile_service.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/loading_indicator.dart';

class MaestroAprobacionesScreen extends StatefulWidget {
  const MaestroAprobacionesScreen({super.key});

  @override
  State<MaestroAprobacionesScreen> createState() => _MaestroAprobacionesScreenState();
}

class _MaestroAprobacionesScreenState extends State<MaestroAprobacionesScreen> 
    with SingleTickerProviderStateMixin {
  final EcoceProfileService _profileService = EcoceProfileService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _pendingSolicitudes = [];
  List<Map<String, dynamic>> _approvedSolicitudes = [];
  bool _isLoading = true;
  
  // ID del usuario maestro (por ahora hardcodeado, luego se obtendría del usuario actual)
  final String _maestroUserId = 'ECOCE_ADMIN_001';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar solicitudes pendientes y aprobadas
      // Las rechazadas se eliminan, no se cargan
      final pendientes = await _profileService.getPendingSolicitudes();
      final aprobadas = await _profileService.getApprovedSolicitudes();
      
      setState(() {
        _pendingSolicitudes = pendientes;
        _approvedSolicitudes = aprobadas;
        // Las rechazadas se eliminan, no se cargan
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveSolicitud(Map<String, dynamic> solicitud) async {
    final datosPerfil = solicitud['datos_perfil'] as Map<String, dynamic>;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _ApprovalConfirmationDialog(
        title: 'Aprobar Cuenta',
        message: '¿Estás seguro de aprobar la cuenta de ${datosPerfil['ecoce_nombre']}?',
        isApproval: true,
      ),
    );

    if (confirm == true) {
      try {
        await _profileService.approveSolicitud(
          solicitudId: solicitud['solicitud_id'],
          approvedById: _maestroUserId,
          comments: 'Documentación verificada y aprobada',
        );
        
        // Mostrar el folio asignado basado en el subtipo
        final subtipo = datosPerfil['ecoce_subtipo'];
        final prefijo = subtipo == 'A' ? 'A' : 'P';
        
        _showSuccessMessage('Cuenta aprobada exitosamente\nSe asignará folio con prefijo: $prefijo');
        _loadProfiles();
      } catch (e) {
        _showErrorMessage('Error al aprobar la cuenta: ${e.toString()}');
      }
    }
  }

  Future<void> _rejectSolicitud(Map<String, dynamic> solicitud) async {
    final datosPerfil = solicitud['datos_perfil'] as Map<String, dynamic>;
    final String? reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectionReasonDialog(profileName: datosPerfil['ecoce_nombre']),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await _profileService.rejectSolicitud(
          solicitudId: solicitud['solicitud_id'],
          rejectedById: _maestroUserId,
          reason: reason,
        );
        
        _showSuccessMessage('Solicitud rechazada y eliminada correctamente');
        
        if (mounted) {
          _loadProfiles();
        }
      } catch (e) {
        _showErrorMessage('Error al rechazar la solicitud');
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: BioWayColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: BioWayColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      body: Column(
        children: [
          // Header con tabs
          Container(
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
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Contenido del header
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.approval,
                              color: Colors.white,
                              size: 40,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gestión de Aprobaciones',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Administra las solicitudes de proveedores',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // TabBar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                    tabs: [
                      Tab(
                        text: 'Pendientes',
                        icon: Icon(Icons.pending_actions, size: 20),
                      ),
                      Tab(
                        text: 'Aprobados',
                        icon: Icon(Icons.check_circle, size: 20),
                      ),
                      Tab(
                        text: 'Rechazados',
                        icon: Icon(Icons.cancel, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Contenido
          Expanded(
            child: _isLoading
                ? Center(child: LoadingIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPendingList(),
                      _buildApprovedList(),
                      _buildRejectedList(),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: 1, // Administración
        onItemTapped: (index) {
          // Manejar navegación si es necesario
        },
        primaryColor: BioWayColors.ecoceGreen,
        items: const [
          NavigationItem(
            icon: Icons.how_to_reg,
            label: 'Aprobación',
          ),
          NavigationItem(
            icon: Icons.admin_panel_settings,
            label: 'Administración',
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingSolicitudes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox,
        title: 'No hay solicitudes pendientes',
        subtitle: 'Las nuevas solicitudes aparecerán aquí',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfiles,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _pendingSolicitudes.length,
        itemBuilder: (context, index) {
          final solicitud = _pendingSolicitudes[index];
          return _SolicitudCard(
            solicitud: solicitud,
            onApprove: () => _approveSolicitud(solicitud),
            onReject: () => _rejectSolicitud(solicitud),
            onViewDetails: () => _viewSolicitudDetails(solicitud),
          );
        },
      ),
    );
  }

  Widget _buildApprovedList() {
    if (_approvedSolicitudes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'No hay cuentas aprobadas',
        subtitle: 'Las cuentas aprobadas aparecerán aquí',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfiles,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _approvedSolicitudes.length,
        itemBuilder: (context, index) {
          final solicitud = _approvedSolicitudes[index];
          return _SolicitudCard(
            solicitud: solicitud,
            onApprove: () {}, // No se puede aprobar de nuevo
            onReject: () {}, // No se puede rechazar una vez aprobada
            onViewDetails: () => _viewSolicitudDetails(solicitud),
            isApproved: true,
          );
        },
      ),
    );
  }

  Widget _buildRejectedList() {
    return _buildEmptyState(
      icon: Icons.delete_forever,
      title: 'Solicitudes rechazadas se eliminan',
      subtitle: 'Las solicitudes rechazadas son eliminadas permanentemente del sistema',
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: BioWayColors.lightGrey),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BioWayColors.darkGreen,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: BioWayColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  void _viewSolicitudDetails(Map<String, dynamic> solicitud) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SolicitudDetailsScreen(solicitud: solicitud),
      ),
    );
  }
}

// Widget de tarjeta de solicitud
class _SolicitudCard extends StatelessWidget {
  final Map<String, dynamic> solicitud;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewDetails;
  final bool isApproved;

  const _SolicitudCard({
    required this.solicitud,
    required this.onApprove,
    required this.onReject,
    required this.onViewDetails,
    this.isApproved = false,
  });

  @override
  Widget build(BuildContext context) {
    final datosPerfil = solicitud['datos_perfil'] as Map<String, dynamic>;
    final fechaSolicitud = solicitud['fecha_solicitud'] != null 
        ? (solicitud['fecha_solicitud'] as Timestamp).toDate()
        : DateTime.now();
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onViewDetails,
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
              _buildInfoRow(Icons.location_on, 'Ubicación', 
                '${datosPerfil['ecoce_municipio'] ?? 'N/A'}, ${datosPerfil['ecoce_estado'] ?? 'N/A'}'),
              _buildInfoRow(Icons.calendar_today, 'Fecha solicitud', 
                _formatDate(fechaSolicitud)),
              
              // Documentos
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BioWayColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Documentos presentados:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (datosPerfil['ecoce_const_sit_fis'] != null)
                          _buildDocChip(
                            context,
                            'Situación Fiscal',
                            datosPerfil['ecoce_const_sit_fis'],
                          ),
                        if (datosPerfil['ecoce_comp_domicilio'] != null)
                          _buildDocChip(
                            context,
                            'Comp. Domicilio',
                            datosPerfil['ecoce_comp_domicilio'],
                          ),
                        if (datosPerfil['ecoce_banco_caratula'] != null)
                          _buildDocChip(
                            context,
                            'Carátula Banco',
                            datosPerfil['ecoce_banco_caratula'],
                          ),
                        if (datosPerfil['ecoce_ine'] != null)
                          _buildDocChip(
                            context,
                            'INE',
                            datosPerfil['ecoce_ine'],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Botones de acción o información adicional
              if (!isApproved) ...[
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
              ] else if (isApproved && solicitud['fecha_revision'] != null) ...[
                SizedBox(height: 16),
                // Mostrar información de aprobación
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
                          'Aprobado el ${_formatDate((solicitud['fecha_revision'] as Timestamp).toDate())}',
                          style: TextStyle(
                            fontSize: 12,
                            color: BioWayColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
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

  Widget _buildDocChip(BuildContext context, String label, String? url) {
    final isUrl = url != null && (url.startsWith('http') || url.startsWith('https'));
    
    return InkWell(
      onTap: isUrl ? () => _viewDocument(context, label, url) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: BioWayColors.petBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: BioWayColors.petBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle, 
              size: 12, 
              color: BioWayColors.petBlue,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: BioWayColors.petBlue,
                decoration: isUrl ? TextDecoration.underline : null,
              ),
            ),
            if (isUrl) ...[
              SizedBox(width: 4),
              Icon(
                Icons.open_in_new,
                size: 10,
                color: BioWayColors.petBlue,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _viewDocument(BuildContext context, String documentName, String url) {
    // TODO: Implementar visualización de documento
    // Por ahora, mostrar un diálogo simple
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(documentName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description, size: 48, color: BioWayColors.petBlue),
            SizedBox(height: 16),
            Text('Documento disponible para revisión'),
            SizedBox(height: 8),
            Text(
              'URL: ${url.length > 50 ? '${url.substring(0, 50)}...' : url}',
              style: TextStyle(fontSize: 10, color: BioWayColors.textGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getSubtipoColor(String? subtipo) {
    switch (subtipo) {
      case 'A':
        return BioWayColors.darkGreen;
      case 'P':
        return BioWayColors.ppPurple;
      default:
        return BioWayColors.textGrey;
    }
  }

  IconData _getSubtipoIcon(String? subtipo) {
    switch (subtipo) {
      case 'A':
        return Icons.warehouse;
      case 'P':
        return Icons.sort;
      default:
        return Icons.business;
    }
  }
  
  String _getSubtipoLabel(String? subtipo) {
    switch (subtipo) {
      case 'A':
        return 'Centro de Acopio';
      case 'P':
        return 'Planta de Separación';
      default:
        return 'Usuario Origen';
    }
  }
}

// Diálogo de confirmación de aprobación
class _ApprovalConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool isApproval;

  const _ApprovalConfirmationDialog({
    required this.title,
    required this.message,
    required this.isApproval,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isApproval ? BioWayColors.success : BioWayColors.error,
          ),
          child: Text(isApproval ? 'Aprobar' : 'Rechazar'),
        ),
      ],
    );
  }
}

// Diálogo para ingresar razón de rechazo
class _RejectionReasonDialog extends StatefulWidget {
  final String profileName;

  const _RejectionReasonDialog({required this.profileName});

  @override
  State<_RejectionReasonDialog> createState() => _RejectionReasonDialogState();
}

class _RejectionReasonDialogState extends State<_RejectionReasonDialog> {
  final TextEditingController _reasonController = TextEditingController();
  final List<String> _commonReasons = [
    'Documentación incompleta',
    'Documentación ilegible',
    'Información incorrecta',
    'No cumple con los requisitos',
    'Documentos vencidos',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rechazar cuenta',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: BioWayColors.darkGreen,
              ),
            ),
            SizedBox(height: 8),
            Text(
              widget.profileName,
              style: TextStyle(
                fontSize: 14,
                color: BioWayColors.textGrey,
              ),
            ),
            SizedBox(height: 16),
            // Advertencia de eliminación
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BioWayColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: BioWayColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: BioWayColors.error,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La solicitud será eliminada permanentemente',
                      style: TextStyle(
                        fontSize: 12,
                        color: BioWayColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Razones comunes:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: BioWayColors.darkGreen,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonReasons.map((reason) {
                return ActionChip(
                  label: Text(reason),
                  onPressed: () {
                    _reasonController.text = reason;
                  },
                  backgroundColor: BioWayColors.lightGrey,
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Razón del rechazo',
                hintText: 'Ingresa o selecciona una razón',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (_reasonController.text.trim().isNotEmpty) {
                      Navigator.of(context).pop(_reasonController.text.trim());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.error,
                  ),
                  child: Text('Rechazar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// Pantalla de detalles de la solicitud
class SolicitudDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> solicitud;

  const SolicitudDetailsScreen({super.key, required this.solicitud});

  @override
  Widget build(BuildContext context) {
    final datosPerfil = solicitud['datos_perfil'] as Map<String, dynamic>;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de la Solicitud'),
        backgroundColor: BioWayColors.ecoceGreen,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO: Implementar vista detallada de la solicitud
            Center(
              child: Text(
                'Vista detallada de la solicitud\n${datosPerfil['ecoce_nombre'] ?? 'Sin nombre'}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}