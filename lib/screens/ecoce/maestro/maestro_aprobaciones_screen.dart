import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../services/firebase/ecoce_profile_service.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
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
  
  List<EcoceProfileModel> _pendingProfiles = [];
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
      // Cargar todos los perfiles
      final allProfiles = await _profileService.getPendingProfiles();
      
      // Por ahora solo obtenemos los pendientes
      // En una implementación completa, cargaríamos todos y los filtrarías
      setState(() {
        _pendingProfiles = allProfiles;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar perfiles: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveProfile(EcoceProfileModel profile) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _ApprovalConfirmationDialog(
        title: 'Aprobar Cuenta',
        message: '¿Estás seguro de aprobar la cuenta de ${profile.ecoce_nombre}?',
        isApproval: true,
      ),
    );

    if (confirm == true) {
      try {
        await _profileService.approveProfile(
          profileId: profile.id,
          approvedById: _maestroUserId,
          comments: 'Documentación verificada y aprobada',
        );
        
        _showSuccessMessage('Cuenta aprobada exitosamente');
        _loadProfiles();
      } catch (e) {
        _showErrorMessage('Error al aprobar la cuenta');
      }
    }
  }

  Future<void> _rejectProfile(EcoceProfileModel profile) async {
    final String? reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectionReasonDialog(profileName: profile.ecoce_nombre),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await _profileService.rejectProfile(
          profileId: profile.id,
          rejectedById: _maestroUserId,
          reason: reason,
        );
        
        // Preguntar si eliminar la cuenta
        if (!mounted) return;
        
        final bool? deleteAccount = await showDialog<bool>(
          context: context,
          builder: (context) => _DeleteAccountDialog(),
        );
        
        if (deleteAccount == true) {
          await _profileService.deleteRejectedProfile(profile.id);
          if (mounted) {
            _showSuccessMessage('Cuenta rechazada y eliminada');
          }
        } else {
          if (mounted) {
            _showSuccessMessage('Cuenta rechazada');
          }
        }
        
        if (mounted) {
          _loadProfiles();
        }
      } catch (e) {
        _showErrorMessage('Error al rechazar la cuenta');
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
    if (_pendingProfiles.isEmpty) {
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
        itemCount: _pendingProfiles.length,
        itemBuilder: (context, index) {
          final profile = _pendingProfiles[index];
          return _ProfileCard(
            profile: profile,
            onApprove: () => _approveProfile(profile),
            onReject: () => _rejectProfile(profile),
            onViewDetails: () => _viewProfileDetails(profile),
          );
        },
      ),
    );
  }

  Widget _buildApprovedList() {
    return _buildEmptyState(
      icon: Icons.check_circle_outline,
      title: 'Cuentas aprobadas',
      subtitle: 'Aquí se mostrarán las cuentas aprobadas',
    );
  }

  Widget _buildRejectedList() {
    return _buildEmptyState(
      icon: Icons.cancel_outlined,
      title: 'Cuentas rechazadas',
      subtitle: 'Aquí se mostrarán las cuentas rechazadas',
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

  void _viewProfileDetails(EcoceProfileModel profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailsScreen(profile: profile),
      ),
    );
  }
}

// Widget de tarjeta de perfil
class _ProfileCard extends StatelessWidget {
  final EcoceProfileModel profile;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewDetails;

  const _ProfileCard({
    required this.profile,
    required this.onApprove,
    required this.onReject,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
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
                      color: _getActorColor(profile.ecoce_tipo_actor).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getActorIcon(profile.ecoce_tipo_actor),
                      color: _getActorColor(profile.ecoce_tipo_actor),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.ecoce_nombre,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                        Text(
                          profile.tipoActorLabel,
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
                      color: BioWayColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Pendiente',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              // Información
              _buildInfoRow(Icons.badge, 'Folio', profile.ecoce_folio),
              _buildInfoRow(Icons.person, 'Contacto', profile.ecoce_nombre_contacto),
              _buildInfoRow(Icons.email, 'Email', profile.ecoce_correo_contacto),
              _buildInfoRow(Icons.phone, 'Teléfono', profile.ecoce_tel_contacto),
              _buildInfoRow(Icons.location_on, 'Ubicación', 
                '${profile.ecoce_municipio}, ${profile.ecoce_estado}'),
              _buildInfoRow(Icons.calendar_today, 'Fecha registro', 
                _formatDate(profile.ecoce_fecha_reg)),
              
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
                        if (profile.ecoce_const_sit_fis != null)
                          _buildDocChip('Situación Fiscal'),
                        if (profile.ecoce_comp_domicilio != null)
                          _buildDocChip('Comp. Domicilio'),
                        if (profile.ecoce_banco_caratula != null)
                          _buildDocChip('Carátula Banco'),
                        if (profile.ecoce_ine != null)
                          _buildDocChip('INE'),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Botones de acción
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

  Widget _buildDocChip(String label) {
    return Container(
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
          Icon(Icons.check_circle, size: 12, color: BioWayColors.petBlue),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: BioWayColors.petBlue,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getActorColor(String tipoActor) {
    switch (tipoActor) {
      case 'A':
        return BioWayColors.darkGreen;
      case 'P':
        return BioWayColors.ppPurple;
      case 'R':
        return BioWayColors.petBlue;
      case 'T':
        return BioWayColors.recycleOrange;
      case 'V':
        return BioWayColors.deepBlue;
      case 'L':
        return BioWayColors.otherPurple;
      default:
        return BioWayColors.textGrey;
    }
  }

  IconData _getActorIcon(String tipoActor) {
    switch (tipoActor) {
      case 'A':
        return Icons.warehouse;
      case 'P':
        return Icons.sort;
      case 'R':
        return Icons.recycling;
      case 'T':
        return Icons.precision_manufacturing;
      case 'V':
        return Icons.local_shipping;
      case 'L':
        return Icons.science;
      default:
        return Icons.business;
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

// Diálogo para confirmar eliminación de cuenta
class _DeleteAccountDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: BioWayColors.warning),
          SizedBox(width: 8),
          Text('Eliminar cuenta'),
        ],
      ),
      content: Text(
        '¿Deseas eliminar permanentemente esta cuenta rechazada?\n\n'
        'Esta acción no se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Mantener cuenta'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: BioWayColors.error,
          ),
          child: Text('Eliminar permanentemente'),
        ),
      ],
    );
  }
}

// Pantalla de detalles del perfil
class ProfileDetailsScreen extends StatelessWidget {
  final EcoceProfileModel profile;

  const ProfileDetailsScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Perfil'),
        backgroundColor: BioWayColors.ecoceGreen,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO: Implementar vista detallada del perfil
            Center(
              child: Text(
                'Vista detallada del perfil\n${profile.ecoce_nombre}',
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