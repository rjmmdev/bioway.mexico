import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/colors.dart';
import '../../../services/user_session_service.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import 'widgets/ecoce_bottom_navigation.dart';
import 'widgets/loading_wrapper.dart';
import 'utils/user_type_helper.dart';
import 'utils/dialog_utils.dart';
import '../../login/platform_selector_screen.dart';

/// Pantalla de perfil universal que funciona para todos los tipos de usuarios
/// Obtiene la información del usuario desde Firebase y aplica los colores correspondientes
class EcocePerfilScreen extends StatefulWidget {
  const EcocePerfilScreen({super.key});

  @override
  State<EcocePerfilScreen> createState() => _EcocePerfilScreenState();
}

class _EcocePerfilScreenState extends State<EcocePerfilScreen> with SingleTickerProviderStateMixin {
  final UserSessionService _sessionService = UserSessionService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  
  EcoceProfileModel? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final profile = await _sessionService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleNavigation(int index) {
    UserTypeHelper.handleNavigation(
      context,
      _userProfile?.ecoceTipoActor,
      index,
      3, // Current index (perfil)
    );
  }

  Future<void> _logout() async {
    final confirm = await DialogUtils.showLogoutDialog(context: context);
    
    if (confirm) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const PlatformSelectorScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          DialogUtils.showErrorDialog(
            context: context,
            title: 'Error',
            message: 'Error al cerrar sesión',
          );
        }
      }
    }
  }

  Future<void> _openDocument(String? url) async {
    if (url == null || url.isEmpty) {
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Error',
        message: 'Documento no disponible',
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          DialogUtils.showErrorDialog(
            context: context,
            title: 'Error',
            message: 'No se pudo abrir el documento',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al abrir el documento',
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String? value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
          ],
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'No disponible',
              style: const TextStyle(
                fontSize: 14,
                color: BioWayColors.darkGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final primaryColor = UserTypeHelper.getPrimaryColor(_userProfile);
    final navigationItems = UserTypeHelper.getNavigationItems(_userProfile?.ecoceTipoActor);
    final fabConfig = UserTypeHelper.getFabConfig(_userProfile?.ecoceTipoActor, context);
    final iconData = UserTypeHelper.getIconData(_userProfile?.ecoceTipoActor, _userProfile?.ecoceSubtipo);
    
    return LoadingWrapper(
      isLoading: _isLoading,
      hasError: !_isLoading && _userProfile == null,
      onRetry: _loadUserData,
      errorMessage: 'Error al cargar perfil',
      primaryColor: primaryColor,
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Profile Icon and Info
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconData,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _userProfile?.ecoceNombre ?? 'Usuario ECOCE',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _userProfile?.tipoActorLabel ?? 'Usuario',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Folio: ${_userProfile?.ecoceFolio ?? 'Sin folio'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.white,
                        indicatorWeight: 3,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        tabs: const [
                          Tab(text: 'Información General'),
                          Tab(text: 'Documentos'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // General Info Tab
                    _buildGeneralInfoTab(),
                    // Documents Tab
                    _buildDocumentsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: EcoceBottomNavigation(
          selectedIndex: 3,
          onItemTapped: _handleNavigation,
          primaryColor: primaryColor,
          items: navigationItems,
          fabConfig: fabConfig,
        ),
        floatingActionButton: fabConfig != null
          ? EcoceFloatingActionButton(
              onPressed: fabConfig.onPressed,
              icon: fabConfig.icon,
              backgroundColor: primaryColor,
              tooltip: fabConfig.tooltip,
            )
          : null,
        floatingActionButtonLocation: fabConfig != null
          ? FloatingActionButtonLocation.centerDocked
          : null,
        ),
      ),
    );
  }

  Widget _buildGeneralInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.business, color: UserTypeHelper.getPrimaryColor(_userProfile)),
                    const SizedBox(width: 8),
                    const Text(
                      'Información de la Empresa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('RFC:', _userProfile?.ecoceRfc),
                _buildInfoRow('Razón Social:', _userProfile?.ecoceNombre),
                if (_userProfile?.ecoceTelEmpresa != null)
                  _buildInfoRow('Teléfono Empresa:', _userProfile?.ecoceTelEmpresa),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Contact Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: UserTypeHelper.getPrimaryColor(_userProfile)),
                    const SizedBox(width: 8),
                    const Text(
                      'Información de Contacto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Nombre:', _userProfile?.ecoceNombreContacto),
                _buildInfoRow('Teléfono:', _userProfile?.ecoceTelContacto),
                _buildInfoRow('Correo:', _userProfile?.ecoceCorreoContacto),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Address Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: UserTypeHelper.getPrimaryColor(_userProfile)),
                    const SizedBox(width: 8),
                    const Text(
                      'Dirección',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Calle:', '${_userProfile?.ecoceCalle ?? ''} ${_userProfile?.ecoceNumExt ?? ''}'),
                _buildInfoRow('Colonia:', _userProfile?.ecoceColonia),
                _buildInfoRow('Municipio:', _userProfile?.ecoceMunicipio),
                _buildInfoRow('Estado:', _userProfile?.ecoceEstado),
                _buildInfoRow('C.P.:', _userProfile?.ecoceCp),
                if (_userProfile?.ecoceRefUbi != null)
                  _buildInfoRow('Referencia:', _userProfile?.ecoceRefUbi),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Operational Info (if available)
          if (_userProfile?.ecoceListaMateriales.isNotEmpty == true || 
              _userProfile?.ecocePesoCap != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: UserTypeHelper.getPrimaryColor(_userProfile)),
                      const SizedBox(width: 8),
                      const Text(
                        'Información Operativa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_userProfile?.ecoceListaMateriales.isNotEmpty == true)
                    _buildInfoRow('Materiales:', _userProfile!.ecoceListaMateriales.join(', ')),
                  if (_userProfile?.ecocePesoCap != null)
                    _buildInfoRow('Peso Capacidad:', '${_userProfile?.ecocePesoCap} kg'),
                  if (_userProfile?.ecoceTransporte != null)
                    _buildInfoRow('Transporte:', _userProfile!.ecoceTransporte! ? 'Sí' : 'No'),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BioWayColors.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    final documents = [
      {
        'name': 'RFC',
        'icon': Icons.account_balance,
        'url': _userProfile?.ecoceConstSitFis,
        'required': true,
      },
      {
        'name': 'Constancia de Situación Fiscal',
        'icon': Icons.description,
        'url': _userProfile?.ecoceConstSitFis,
        'required': true,
      },
      {
        'name': 'Comprobante de Domicilio',
        'icon': Icons.home_work,
        'url': _userProfile?.ecoceCompDomicilio,
        'required': true,
      },
      {
        'name': 'Identificación Oficial',
        'icon': Icons.badge,
        'url': _userProfile?.ecoceIne,
        'required': true,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        final isUploaded = doc['url'] != null && (doc['url'] as String).isNotEmpty;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            child: InkWell(
              onTap: isUploaded ? () => _openDocument(doc['url'] as String) : null,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (isUploaded ? BioWayColors.success : Colors.grey).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        doc['icon'] as IconData,
                        color: isUploaded ? BioWayColors.success : Colors.grey,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc['name'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: BioWayColors.darkGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isUploaded ? 'Documento cargado' : 'Sin cargar',
                            style: TextStyle(
                              fontSize: 13,
                              color: isUploaded ? BioWayColors.success : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUploaded)
                      Icon(
                        Icons.check_circle,
                        color: BioWayColors.success,
                        size: 24,
                      )
                    else if (doc['required'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: BioWayColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Requerido',
                          style: TextStyle(
                            fontSize: 12,
                            color: BioWayColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}