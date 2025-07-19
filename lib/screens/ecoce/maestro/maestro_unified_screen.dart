import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../services/firebase/ecoce_profile_service.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/loading_indicator.dart';
import 'widgets/maestro_solicitud_card.dart';
import 'maestro_solicitud_details_screen.dart';

/// Pantalla unificada para la gestión de usuarios maestro ECOCE
/// Combina la funcionalidad de aprobación y administración de usuarios
class MaestroUnifiedScreen extends StatefulWidget {
  const MaestroUnifiedScreen({super.key});

  @override
  State<MaestroUnifiedScreen> createState() => _MaestroUnifiedScreenState();
}

class _MaestroUnifiedScreenState extends State<MaestroUnifiedScreen> 
    with SingleTickerProviderStateMixin {
  final EcoceProfileService _profileService = EcoceProfileService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Estados
  List<Map<String, dynamic>> _pendingSolicitudes = [];
  List<Map<String, dynamic>> _approvedSolicitudes = [];
  bool _isLoading = true;
  final List<String> _filtrosTipoUsuario = [];
  int _selectedIndex = 0; // 0: Aprobación, 1: Administración
  
  // ID del usuario maestro (por ahora hardcodeado, luego se obtendría del usuario actual)
  final String _maestroUserId = 'ECOCE_ADMIN_001';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSolicitudes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSolicitudes() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar solicitudes pendientes y aprobadas desde Firebase
      final pendientes = await _profileService.getPendingSolicitudes();
      final aprobadas = await _profileService.getApprovedSolicitudes();
      
      setState(() {
        _pendingSolicitudes = pendientes;
        _approvedSolicitudes = aprobadas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Error al cargar solicitudes: ${e.toString()}');
    }
  }

  List<Map<String, dynamic>> get _solicitudesFiltradas {
    var solicitudes = _tabController.index == 0 ? _pendingSolicitudes : 
                     _tabController.index == 1 ? _approvedSolicitudes : <Map<String, dynamic>>[];
    
    return solicitudes.where((solicitud) {
      final datosPerfil = solicitud['datos_perfil'] as Map<String, dynamic>;
      
      // Filtro por búsqueda
      if (_searchController.text.isNotEmpty) {
        final searchLower = _searchController.text.toLowerCase();
        final nombre = (datosPerfil['ecoce_nombre'] ?? '').toString().toLowerCase();
        final folio = (solicitud['folio_asignado'] ?? '').toString().toLowerCase();
        
        if (!nombre.contains(searchLower) && !folio.contains(searchLower)) {
          return false;
        }
      }
      
      // Filtro por tipo de usuario
      if (_filtrosTipoUsuario.isNotEmpty) {
        final subtipo = datosPerfil['ecoce_subtipo'] ?? '';
        final tipoUsuario = _getSubtipoLabel(subtipo);
        
        if (!_filtrosTipoUsuario.contains(tipoUsuario)) {
          return false;
        }
      }
      
      return true;
    }).toList();
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
        
        final subtipo = datosPerfil['ecoce_subtipo'];
        final prefijo = _getPrefijoFolio(subtipo);
        
        _showSuccessMessage('Cuenta aprobada exitosamente\nSe asignará folio con prefijo: $prefijo');
        _loadSolicitudes();
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
        _loadSolicitudes();
      } catch (e) {
        _showErrorMessage('Error al rechazar la solicitud');
      }
    }
  }

  void _viewSolicitudDetails(Map<String, dynamic> solicitud) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaestroSolicitudDetailsScreen(
          solicitud: solicitud,
          onApprove: () async {
            Navigator.pop(context);
            await _approveSolicitud(solicitud);
          },
          onReject: () async {
            Navigator.pop(context);
            await _rejectSolicitud(solicitud);
          },
        ),
      ),
    );
  }

  void _mostrarFiltroTipoUsuario() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Filtrar por Tipo de Usuario',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCheckboxTile('Centro de Acopio', 'A', Icons.warehouse, BioWayColors.darkGreen, setDialogState),
                    _buildCheckboxTile('Planta de Separación', 'P', Icons.sort, BioWayColors.ppPurple, setDialogState),
                    _buildCheckboxTile('Reciclador', 'R', Icons.recycling, BioWayColors.recycleOrange, setDialogState),
                    _buildCheckboxTile('Transformador', 'T', Icons.auto_fix_high, BioWayColors.petBlue, setDialogState),
                    _buildCheckboxTile('Transportista', 'V', Icons.local_shipping, BioWayColors.deepBlue, setDialogState),
                    _buildCheckboxTile('Laboratorio', 'L', Icons.science, BioWayColors.otherPurple, setDialogState),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _filtrosTipoUsuario.clear();
                    });
                  },
                  child: Text(
                    'Limpiar',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.ecoceGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Aplicar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCheckboxTile(String titulo, String codigo, IconData icon, Color color, StateSetter setDialogState) {
    final isSelected = _filtrosTipoUsuario.contains(titulo);
    
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        titulo,
        style: TextStyle(
          color: isSelected ? color : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (bool? value) {
          setDialogState(() {
            if (value == true) {
              _filtrosTipoUsuario.add(titulo);
            } else {
              _filtrosTipoUsuario.remove(titulo);
            }
          });
        },
        activeColor: color,
        side: BorderSide(color: color, width: 2),
      ),
      onTap: () {
        setDialogState(() {
          if (isSelected) {
            _filtrosTipoUsuario.remove(titulo);
          } else {
            _filtrosTipoUsuario.add(titulo);
          }
        });
      },
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
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
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: BioWayColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helpers
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

  String _getPrefijoFolio(String? subtipo) {
    switch (subtipo) {
      case 'A': return 'A';
      case 'P': return 'P';
      case 'R': return 'R';
      case 'T': return 'T';
      case 'V': return 'V';
      case 'L': return 'L';
      default: return 'U';
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 40,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Usuario Maestro ECOCE',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Gestión de Solicitudes',
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
                  if (_selectedIndex == 0) // Solo mostrar tabs en la vista de aprobación
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                      onTap: (_) => setState(() {}),
                      tabs: [
                        Tab(
                          text: 'Pendientes (${_pendingSolicitudes.length})',
                          icon: Icon(Icons.pending_actions, size: 20),
                        ),
                        Tab(
                          text: 'Aprobados (${_approvedSolicitudes.length})',
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
          
          // Barra de búsqueda y filtros
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            color: Colors.white,
            child: Column(
              children: [
                // Buscador
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o folio...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: BioWayColors.ecoceGreen, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                
                SizedBox(height: screenHeight * 0.015),
                
                // Filtro tipo usuario
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _mostrarFiltroTipoUsuario,
                    icon: Icon(Icons.filter_list),
                    label: Text(
                      _filtrosTipoUsuario.isEmpty
                          ? 'Filtrar por Tipo de Usuario'
                          : 'Tipos: ${_filtrosTipoUsuario.length} seleccionados',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BioWayColors.ecoceGreen,
                      side: BorderSide(color: BioWayColors.ecoceGreen),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.015,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido
          Expanded(
            child: _isLoading
                ? Center(child: LoadingIndicator())
                : _selectedIndex == 0
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSolicitudesList(isPending: true),
                          _buildSolicitudesList(isPending: false),
                          _buildRejectedList(),
                        ],
                      )
                    : _buildAdministrationView(),
          ),
        ],
      ),
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
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

  Widget _buildSolicitudesList({required bool isPending}) {
    final solicitudes = _solicitudesFiltradas;
    
    if (solicitudes.isEmpty) {
      return _buildEmptyState(
        icon: isPending ? Icons.inbox : Icons.check_circle_outline,
        title: isPending ? 'No hay solicitudes pendientes' : 'No hay cuentas aprobadas',
        subtitle: isPending ? 'Las nuevas solicitudes aparecerán aquí' : 'Las cuentas aprobadas aparecerán aquí',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSolicitudes,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: solicitudes.length,
        itemBuilder: (context, index) {
          final solicitud = solicitudes[index];
          
          return MaestroSolicitudCard(
            solicitud: solicitud,
            onTap: () => _viewSolicitudDetails(solicitud),
            onApprove: isPending ? () => _approveSolicitud(solicitud) : null,
            onReject: isPending ? () => _rejectSolicitud(solicitud) : null,
            showActions: isPending,
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

  Widget _buildAdministrationView() {
    // Vista de administración de usuarios aprobados
    final approvedUsers = _approvedSolicitudes.where((solicitud) {
      final datosPerfil = solicitud['datos_perfil'] as Map<String, dynamic>;
      
      // Aplicar filtros de búsqueda
      if (_searchController.text.isNotEmpty) {
        final searchLower = _searchController.text.toLowerCase();
        final nombre = (datosPerfil['ecoce_nombre'] ?? '').toString().toLowerCase();
        final folio = (solicitud['folio_asignado'] ?? '').toString().toLowerCase();
        
        if (!nombre.contains(searchLower) && !folio.contains(searchLower)) {
          return false;
        }
      }
      
      return true;
    }).toList();

    if (approvedUsers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'No hay usuarios en el sistema',
        subtitle: 'Los usuarios aprobados aparecerán aquí',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: approvedUsers.length,
      itemBuilder: (context, index) {
        final usuario = approvedUsers[index];
        
        return MaestroSolicitudCard(
          solicitud: usuario,
          onTap: () => _viewSolicitudDetails(usuario),
          showActions: false,
          showAdminInfo: true,
        );
      },
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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