import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../services/firebase/ecoce_profile_service.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/utils/dialog_utils.dart';
import 'widgets/maestro_solicitud_card.dart';
import 'widgets/delete_user_dialog.dart';
import 'maestro_solicitud_details_screen.dart';

/// Pantalla unificada para la gestión de usuarios maestro ECOCE
/// Combina la funcionalidad de aprobación y administración de usuarios
class MaestroUnifiedScreen extends StatefulWidget {
  const MaestroUnifiedScreen({super.key});

  @override
  State<MaestroUnifiedScreen> createState() => _MaestroUnifiedScreenState();
}

class _MaestroUnifiedScreenState extends State<MaestroUnifiedScreen> 
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadSolicitudes();
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    // Recargar datos cuando se cambia de pestaña
    _loadSolicitudes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recargar cuando la app vuelve al primer plano
      _loadSolicitudes();
    }
  }

  Future<void> _loadSolicitudes() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar solicitudes pendientes desde Firebase
      final pendientes = await _profileService.getPendingSolicitudes();
      
      // Para la pestaña de administración, obtener TODOS los usuarios de ecoce_profiles
      // no solo las solicitudes aprobadas
      final allProfiles = await _profileService.getAllActiveProfiles();
      
      // Convertir perfiles a formato de solicitud para mantener compatibilidad con la UI
      final approvedUsers = allProfiles.map((profile) {
        return {
          'solicitud_id': profile.id,
          'usuario_creado_id': profile.id,
          'folio_asignado': profile.ecoceFolio,
          'estado': 'aprobada',
          'datos_perfil': {
            'ecoce_nombre': profile.ecoceNombre,
            'ecoce_rfc': profile.ecoceRfc,
            'ecoce_correo_contacto': profile.ecoceCorreoContacto,
            'ecoce_tel_contacto': profile.ecoceTelContacto,
            'ecoce_subtipo': profile.ecoceSubtipo,
            'ecoce_tipo_actor': profile.ecoceTipoActor,
            'ecoce_calle': profile.ecoceCalle,
            'ecoce_num_ext': profile.ecoceNumExt,
            'ecoce_colonia': profile.ecoceColonia,
            'ecoce_municipio': profile.ecoceMunicipio,
            'ecoce_estado': profile.ecoceEstado,
            'ecoce_cp': profile.ecoceCp,
          },
          'fecha_revision': profile.ecoceFechaAprobacion?.toIso8601String(),
          'fecha_solicitud': profile.ecoceFechaReg.toIso8601String(),
        };
      }).toList();
      
      setState(() {
        _pendingSolicitudes = pendientes;
        _approvedSolicitudes = approvedUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Error al cargar solicitudes: ${e.toString()}');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BioWayColors.error,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BioWayColors.success,
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredSolicitudes {
    List<Map<String, dynamic>> solicitudes = 
        _selectedIndex == 0 ? _pendingSolicitudes : _approvedSolicitudes;
    
    final searchQuery = _searchController.text.toLowerCase();
    
    return solicitudes.where((solicitud) {
      final datosPerfil = solicitud['datos_perfil'] as Map<String, dynamic>;
      final matchesSearch = searchQuery.isEmpty ||
          datosPerfil['ecoce_nombre'].toString().toLowerCase().contains(searchQuery) ||
          datosPerfil['ecoce_rfc'].toString().toLowerCase().contains(searchQuery) ||
          datosPerfil['ecoce_correo_contacto'].toString().toLowerCase().contains(searchQuery) ||
          (solicitud['folio_asignado'] ?? '').toString().toLowerCase().contains(searchQuery);
      
      final matchesFilter = _filtrosTipoUsuario.isEmpty ||
          _filtrosTipoUsuario.contains(datosPerfil['ecoce_subtipo']);
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _approveSolicitud(Map<String, dynamic> solicitud) async {
    final datosPerfil = solicitud['datos_perfil'] as Map<String, dynamic>;
    final bool confirm = await DialogUtils.showConfirmDialog(
      context: context,
      title: 'Aprobar Cuenta',
      message: '¿Estás seguro de aprobar la cuenta de ${datosPerfil['ecoce_nombre']}?',
      confirmText: 'Aprobar',
      cancelText: 'Cancelar',
      confirmColor: Colors.green,
    );

    if (confirm) {
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
    final String? reason = await DialogUtils.showInputDialog(
      context: context,
      title: 'Rechazar Cuenta',
      message: 'Por favor, indica el motivo del rechazo para ${datosPerfil['ecoce_nombre']}:',
      hintText: 'Motivo del rechazo',
      confirmText: 'Rechazar',
      cancelText: 'Cancelar',
      maxLines: 3,
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

  void _viewSolicitudDetails(Map<String, dynamic> solicitud) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaestroSolicitudDetailsScreen(solicitud: solicitud),
      ),
    );
    // Recargar por si se hicieron cambios
    _loadSolicitudes();
  }

  String _getPrefijoFolio(String subtipo) {
    final Map<String, String> prefijos = {
      'A': 'A',  // Acopiador
      'P': 'P',  // Planta de separación
      'R': 'R',  // Reciclador
      'T': 'T',  // Transformador
      'V': 'V',  // Transportista
      'L': 'L',  // Laboratorio
    };
    return prefijos[subtipo] ?? 'X';
  }

  Future<void> _deleteUser(Map<String, dynamic> usuario) async {
    final datosPerfil = usuario['datos_perfil'] as Map<String, dynamic>;
    final userId = usuario['usuario_creado_id'] ?? usuario['solicitud_id'];
    final folio = usuario['folio_asignado'] ?? 'SIN FOLIO';
    
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteUserDialog(
        userName: datosPerfil['ecoce_nombre'] ?? 'Usuario sin nombre',
        userFolio: folio,
        userId: userId,
      ),
    );
    
    if (shouldDelete == true) {
      try {
        // Mostrar indicador de carga
        if (!mounted) return;
        DialogUtils.showLoadingDialog(
          context: context,
          message: 'Eliminando usuario...',
        );
        
        // Eliminar usuario
        await _profileService.deleteUserCompletely(
          userId: userId,
          deletedBy: _maestroUserId,
        );
        
        // Cerrar diálogo de carga
        if (mounted) DialogUtils.hideLoadingDialog(context);
        
        _showSuccessMessage('Usuario eliminado exitosamente');
        _loadSolicitudes();
      } catch (e) {
        // Cerrar diálogo de carga si hay error
        if (mounted) DialogUtils.hideLoadingDialog(context);
        
        _showErrorMessage('Error al eliminar usuario: ${e.toString()}');
      }
    }
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
                    _buildFilterChip('A', 'Acopiador', setDialogState),
                    _buildFilterChip('P', 'Planta de Separación', setDialogState),
                    _buildFilterChip('R', 'Reciclador', setDialogState),
                    _buildFilterChip('T', 'Transformador', setDialogState),
                    _buildFilterChip('V', 'Transportista', setDialogState),
                    _buildFilterChip('L', 'Laboratorio', setDialogState),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _filtrosTipoUsuario.clear();
                    });
                    setState(() {});
                  },
                  child: const Text('Limpiar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.ecoceGreen,
                  ),
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label, StateSetter setDialogState) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FilterChip(
        label: Text(label),
        selected: _filtrosTipoUsuario.contains(value),
        onSelected: (selected) {
          setDialogState(() {
            if (selected) {
              _filtrosTipoUsuario.add(value);
            } else {
              _filtrosTipoUsuario.remove(value);
            }
          });
        },
        selectedColor: BioWayColors.ecoceGreen.withValues(alpha: 0.2),
        checkmarkColor: BioWayColors.ecoceGreen,
      ),
    );
  }

  // Función para migrar usuarios existentes
  Future<void> _migrateExistingUsers() async {
    final bool confirm = await DialogUtils.showConfirmDialog(
      context: context,
      title: 'Migrar Usuarios',
      message: '¿Deseas migrar los usuarios existentes a la nueva estructura de carpetas?\n\nEsto organizará los usuarios por tipo en subcarpetas.',
      confirmText: 'Migrar',
      cancelText: 'Cancelar',
      confirmColor: BioWayColors.warning,
    );
    
    if (confirm) {
      DialogUtils.showLoadingDialog(
        context: context,
        message: 'Migrando usuarios...',
      );
      
      try {
        await _profileService.migrateExistingUsersToSubcollections();
        
        Navigator.pop(context); // Cerrar loading
        
        _showSuccessMessage('Usuarios migrados exitosamente');
        _loadSolicitudes(); // Recargar datos
      } catch (e) {
        Navigator.pop(context); // Cerrar loading
        _showErrorMessage('Error al migrar usuarios: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header con gradiente
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BioWayColors.ecoceGreen,
                    BioWayColors.ecoceGreen.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Título y badge
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Panel de Administración',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Gestión de usuarios ECOCE',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            // Botón de opciones
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                              ),
                              onSelected: (value) {
                                if (value == 'migrate') {
                                  _migrateExistingUsers();
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem<String>(
                                  value: 'migrate',
                                  child: Row(
                                    children: [
                                      Icon(Icons.sync, size: 20),
                                      SizedBox(width: 8),
                                      Text('Migrar usuarios existentes'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.admin_panel_settings,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
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
                  
                  // Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedIndex = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedIndex == 0
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.pending_actions,
                                    size: 20,
                                    color: _selectedIndex == 0
                                        ? BioWayColors.ecoceGreen
                                        : Colors.white70,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pendientes',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedIndex == 0
                                          ? BioWayColors.ecoceGreen
                                          : Colors.white70,
                                    ),
                                  ),
                                  if (_pendingSolicitudes.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _selectedIndex == 0
                                            ? BioWayColors.warning
                                            : Colors.white30,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${_pendingSolicitudes.length}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedIndex = 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedIndex == 1
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 20,
                                    color: _selectedIndex == 1
                                        ? BioWayColors.ecoceGreen
                                        : Colors.white70,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Usuarios',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedIndex == 1
                                          ? BioWayColors.ecoceGreen
                                          : Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedIndex == 1
                                          ? BioWayColors.success
                                          : Colors.white30,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_approvedSolicitudes.length}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Barra de búsqueda y filtros
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: _selectedIndex == 0
                                    ? 'Buscar solicitudes pendientes...'
                                    : 'Buscar por nombre, RFC o folio...',
                                hintStyle: const TextStyle(fontSize: 14),
                                prefixIcon: const Icon(Icons.search, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 2,
                          child: InkWell(
                            onTap: _mostrarFiltroTipoUsuario,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    color: _filtrosTipoUsuario.isNotEmpty
                                        ? BioWayColors.ecoceGreen
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  if (_filtrosTipoUsuario.isNotEmpty) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: BioWayColors.ecoceGreen,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${_filtrosTipoUsuario.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido
            Expanded(
              child: _isLoading
                  ? const Center(child: LoadingIndicator())
                  : _filteredSolicitudes.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: _filteredSolicitudes.length,
                          itemBuilder: (context, index) {
                            final solicitud = _filteredSolicitudes[index];
                            return MaestroSolicitudCard(
                              solicitud: solicitud,
                              onTap: () => _viewSolicitudDetails(solicitud),
                              onApprove: _selectedIndex == 0 ? () => _approveSolicitud(solicitud) : null,
                              onReject: _selectedIndex == 0 ? () => _rejectSolicitud(solicitud) : null,
                              onDelete: _selectedIndex == 1 ? () => _deleteUser(solicitud) : null,
                              showActions: true,
                              showAdminInfo: _selectedIndex == 1,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      // Removed bottom navigation since ECOCE user only needs the dashboard
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedIndex == 0 ? Icons.inbox : Icons.people_outline,
            size: 80,
            color: BioWayColors.lightGrey,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedIndex == 0
                ? 'No hay solicitudes pendientes'
                : 'No se encontraron usuarios',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          if (_searchController.text.isNotEmpty ||
              _filtrosTipoUsuario.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Intenta con otros filtros de búsqueda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              _searchController.clear();
              _filtrosTipoUsuario.clear();
              setState(() {});
            },
            icon: const Icon(Icons.clear),
            label: const Text('Limpiar filtros'),
            style: OutlinedButton.styleFrom(
              foregroundColor: BioWayColors.ecoceGreen,
            ),
          ),
        ],
      ),
    );
  }

}