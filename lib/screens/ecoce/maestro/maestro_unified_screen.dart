import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/colors.dart';
import '../../../services/firebase/ecoce_profile_service.dart';
import '../../../services/firebase/firebase_manager.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/utils/dialog_utils.dart';
import 'widgets/maestro_solicitud_card.dart';
import 'widgets/delete_user_dialog.dart';
import 'maestro_solicitud_details_screen.dart';
import 'maestro_utilities_screen.dart';
import '../../login/platform_selector_screen.dart';

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
  
  // ID del usuario maestro
  String _maestroUserId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _ensureMaestroSetup(); // Configurar usuario maestro si es necesario
    _loadSolicitudes();
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    // Recargar datos cuando se cambia de pestaña
    _loadSolicitudes();
  }
  
  Future<void> _ensureMaestroSetup() async {
    try {
      // Obtener el usuario actual
      final firebaseManager = FirebaseManager();
      final app = firebaseManager.currentApp;
      if (app == null) return;
      
      final auth = FirebaseAuth.instanceFor(app: app);
      final firestore = FirebaseFirestore.instanceFor(app: app);
      final currentUser = auth.currentUser;
      
      if (currentUser == null) {
        print('No hay usuario autenticado');
        return;
      }
      
      final uid = currentUser.uid;
      print('Verificando configuración del maestro con UID: $uid');
      
      // Guardar el UID para uso posterior
      setState(() {
        _maestroUserId = uid;
      });
      
      // Verificar si existe en la colección maestros
      final maestroDoc = firestore.collection('maestros').doc(uid);
      final docSnapshot = await maestroDoc.get();
      
      if (!docSnapshot.exists) {
        print('Creando documento en colección maestros para el usuario...');
        await maestroDoc.set({
          'activo': true,
          'nombre': currentUser.displayName ?? 'Maestro ECOCE',
          'email': currentUser.email,
          'fecha_creacion': FieldValue.serverTimestamp(),
          'permisos': {
            'aprobar_solicitudes': true,
            'eliminar_usuarios': true,
            'gestionar_sistema': true,
          }
        });
        print('✅ Usuario maestro configurado correctamente');
      } else {
        print('✅ Usuario maestro ya está configurado');
      }
    } catch (e) {
      print('Error al configurar usuario maestro: $e');
    }
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
      // sin importar su estado de aprobación
      final allProfiles = await _profileService.getAllProfiles();
      
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
            'ecoce_nombre_contacto': profile.ecoceNombreContacto,
            'ecoce_tel_empresa': profile.ecoceTelEmpresa,
            'ecoce_ref_ubi': profile.ecoceRefUbi,
            'ecoce_num_int': profile.ecoceNumInt,
            'ecoce_referencias': profile.ecoceReferencias,
            // Documentos
            'ecoce_const_sit_fis': profile.ecoceConstSitFis,
            'ecoce_comp_domicilio': profile.ecoceCompDomicilio,
            'ecoce_banco_caratula': profile.ecoceBancoCaratula,
            'ecoce_ine': profile.ecoceIne,
            'ecoce_opinion_cumplimiento': profile.ecoceOpinionCumplimiento,
            'ecoce_ramir': profile.ecoceRamir,
            'ecoce_plan_manejo': profile.ecocePlanManejo,
            'ecoce_licencia_ambiental': profile.ecoceLicenciaAmbiental,
            // Información bancaria
            'ecoce_banco_nombre': profile.ecoceBancoNombre,
            'ecoce_banco_beneficiario': profile.ecoceBancoBeneficiario,
            'ecoce_banco_num_cuenta': profile.ecoceBancoNumCuenta,
            'ecoce_banco_clabe': profile.ecoceBancoClabe,
            // Actividades autorizadas
            'ecoce_act_autorizadas': profile.ecoceActAutorizadas ?? [],
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
    if (!mounted) return;
    
    final datosPerfil = solicitud['datos_perfil'] as Map<String, dynamic>;
    
    bool? confirm;
    try {
      confirm = await DialogUtils.showConfirmDialog(
        context: context,
        title: 'Aprobar Cuenta',
        message: '¿Estás seguro de aprobar la cuenta de ${datosPerfil['ecoce_nombre']}?',
        confirmText: 'Aprobar',
        cancelText: 'Cancelar',
        confirmColor: Colors.green,
      );
    } catch (e) {
      return;
    }

    if (!mounted) return;

    if (confirm == true) {
      try {
        await _profileService.approveSolicitud(
          solicitudId: solicitud['solicitud_id'],
          approvedById: _maestroUserId,
          comments: 'Documentación verificada y aprobada',
        );
        
        if (mounted) {
          final subtipo = datosPerfil['ecoce_subtipo'];
          final prefijo = _getPrefijoFolio(subtipo);
          
          _showSuccessMessage('Cuenta aprobada exitosamente\nSe asignará folio con prefijo: $prefijo');
          _loadSolicitudes();
        }
      } catch (e) {
        if (mounted) {
          _showErrorMessage('Error al aprobar la cuenta: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _rejectSolicitud(Map<String, dynamic> solicitud) async {
    if (!mounted) return;
    
    final datosPerfil = solicitud['datos_perfil'] as Map<String, dynamic>;
    
    // Mostrar diálogo de confirmación simple
    final bool? confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Rechazar Solicitud'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Está seguro que desea rechazar la solicitud de ${datosPerfil['ecoce_nombre']}?'),
              const SizedBox(height: 16),
              const Text(
                'Esta acción eliminará:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• La solicitud de registro'),
              const Text('• Los documentos subidos'),
              const Text('• El usuario de autenticación (si existe)'),
              const SizedBox(height: 16),
              const Text(
                'Esta acción no se puede deshacer.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: BioWayColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Rechazar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    
    if (confirmar == true) {
      // Mostrar indicador de carga
      DialogUtils.showLoadingDialog(
        context: context,
        message: 'Eliminando solicitud...',
      );
      
      try {
        await _profileService.rejectSolicitud(
          solicitudId: solicitud['solicitud_id'],
          rejectedById: _maestroUserId,
          reason: 'Rechazado por el administrador', // Razón genérica
        );
        
        if (mounted) {
          Navigator.of(context).pop(); // Cerrar diálogo de carga
          _showSuccessMessage('Solicitud rechazada y eliminada correctamente');
          _loadSolicitudes();
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Cerrar diálogo de carga
          _showErrorMessage('Error al rechazar la solicitud: ${e.toString()}');
        }
      }
    }
  }

  void _viewSolicitudDetails(Map<String, dynamic> solicitud) async {
    // Si es un usuario aprobado, cargar los datos completos desde Firebase
    if (solicitud['estado'] == 'aprobada' && solicitud['usuario_creado_id'] != null) {
      // Mostrar indicador de carga
      DialogUtils.showLoadingDialog(
        context: context,
        message: 'Cargando información del usuario...',
      );
      
      try {
        // Obtener datos completos del perfil
        final fullProfileData = await _profileService.getProfileDataAsMap(solicitud['usuario_creado_id']);
        
        if (fullProfileData.isNotEmpty) {
          // Actualizar los datos del perfil con los datos completos
          solicitud['datos_perfil'] = fullProfileData;
        }
      } catch (e) {
        // En caso de error, continuar con los datos que ya tenemos
        print('Error cargando datos completos: $e');
      } finally {
        // Cerrar diálogo de carga
        if (mounted) DialogUtils.hideLoadingDialog(context);
      }
    }
    
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
        
        // Actualizar la UI inmediatamente removiendo el usuario de la lista
        setState(() {
          _approvedSolicitudes.removeWhere((u) => 
            (u['usuario_creado_id'] ?? u['solicitud_id']) == userId
          );
        });
        
        _showSuccessMessage('Usuario eliminado exitosamente');
        
        // Recargar datos en segundo plano para asegurar sincronización
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

  // Métodos de migración y limpieza eliminados - Ya no son necesarios
  // La estructura de datos ahora se mantiene automáticamente correcta

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevenir que el botón atrás cierre la sesión
        return false;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: BioWayColors.ecoceGreen,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
          slivers: [
            // Header con gradiente como SliverAppBar
            SliverAppBar(
              expandedHeight: 390,
              floating: false,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: BioWayColors.ecoceGreen,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
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
                  child: SafeArea(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        children: [
                    // Título y badge
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Fila superior con título y badge ADMIN
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Panel de Administración',
                                    style: TextStyle(
                                      fontSize: 26,
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
                        const SizedBox(height: 16),
                        // Fila de botones de acción
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Botón de repositorio
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.inventory_2,
                                label: 'Repositorio',
                                onPressed: () {
                                  Navigator.pushNamed(context, '/repositorio_inicio');
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Botón de utilidades
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.build,
                                label: 'Utilidades',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MaestroUtilitiesScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Botón de cerrar sesión
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.logout,
                                label: 'Cerrar Sesión',
                                onPressed: () async {
                                // Mostrar diálogo de confirmación
                                final shouldLogout = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Text('Cerrar Sesión'),
                                      content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: BioWayColors.error,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Cerrar Sesión',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                
                                if (shouldLogout == true) {
                                  try {
                                    // Cerrar sesión en Firebase
                                    final firebaseManager = FirebaseManager();
                                    final app = firebaseManager.currentApp;
                                    if (app != null) {
                                      final auth = FirebaseAuth.instanceFor(app: app);
                                      await auth.signOut();
                                    }
                                    
                                    // Navegar a la pantalla de selección de plataforma
                                    if (mounted) {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (context) => const PlatformSelectorScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      _showErrorMessage('Error al cerrar sesión: ${e.toString()}');
                                    }
                                  }
                                }
                              },
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                  ),
                ),
              ),
            ),
            
            // Contenido
            _isLoading
                ? SliverFillRemaining(
                    child: const Center(child: LoadingIndicator()),
                  )
                : _filteredSolicitudes.isEmpty
                    ? SliverFillRemaining(
                        child: _buildEmptyState(),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final solicitud = _filteredSolicitudes[index];
                              return MaestroSolicitudCard(
                                solicitud: solicitud,
                                onTap: () {
                                  if (mounted) _viewSolicitudDetails(solicitud);
                                },
                                onApprove: _selectedIndex == 0 ? () {
                                  if (mounted) _approveSolicitud(solicitud);
                                } : null,
                                onReject: _selectedIndex == 0 ? () {
                                  if (mounted) _rejectSolicitud(solicitud);
                                } : null,
                                onDelete: _selectedIndex == 1 ? () {
                                  if (mounted) _deleteUser(solicitud);
                                } : null,
                                showActions: true,
                                showAdminInfo: _selectedIndex == 1,
                              );
                            },
                            childCount: _filteredSolicitudes.length,
                          ),
                        ),
                      ),
          ],
        ),
        // Removed bottom navigation since ECOCE user only needs the dashboard
        ),
      ),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}