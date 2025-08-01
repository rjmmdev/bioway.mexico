import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/colors.dart';
import '../../../services/user_session_service.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import 'widgets/ecoce_bottom_navigation.dart';
import 'widgets/loading_wrapper.dart';
import 'utils/user_type_helper.dart';
import 'utils/dialog_utils.dart';

/// Pantalla de ayuda universal que funciona para todos los tipos de usuarios
/// Obtiene la información del usuario desde la base de datos y aplica los colores correspondientes
class EcoceAyudaScreen extends StatefulWidget {
  const EcoceAyudaScreen({super.key});

  @override
  State<EcoceAyudaScreen> createState() => _EcoceAyudaScreenState();
}

class _EcoceAyudaScreenState extends State<EcoceAyudaScreen> {
  final UserSessionService _sessionService = UserSessionService();
  EcoceProfileModel? _userProfile;
  bool _isLoading = true;

  // TODO: These should come from Firestore collections
  final List<Map<String, dynamic>> _videosTutoriales = [
    {
      'titulo': 'Cómo escanear un código QR',
      'descripcion': 'Aprende a usar el escáner de códigos QR para registrar lotes',
      'duracion': '2:45',
      'vistas': '1.2k',
      'url': 'https://youtube.com/watch?v=example1',
    },
    {
      'titulo': 'Crear y gestionar lotes',
      'descripcion': 'Tutorial completo sobre la creación y administración de lotes',
      'duracion': '5:30',
      'vistas': '856',
      'url': 'https://youtube.com/watch?v=example2',
    },
    {
      'titulo': 'Subir documentación',
      'descripcion': 'Cómo cargar y gestionar tus documentos en la plataforma',
      'duracion': '3:15',
      'vistas': '624',
      'url': 'https://youtube.com/watch?v=example3',
    },
    {
      'titulo': 'Navegación en la app',
      'descripcion': 'Conoce todas las funciones y pantallas disponibles',
      'duracion': '4:00',
      'vistas': '432',
      'url': 'https://youtube.com/watch?v=example4',
    },
  ];

  final List<Map<String, dynamic>> _faqsPopulares = [
    {
      'pregunta': '¿Cómo puedo recuperar mi contraseña?',
      'respuesta': 'Puedes recuperar tu contraseña desde la pantalla de inicio de sesión usando la opción "¿Olvidaste tu contraseña?". Te enviaremos un correo con las instrucciones.',
      'votos': 45,
    },
    {
      'pregunta': '¿Qué hago si el código QR no se escanea?',
      'respuesta': 'Asegúrate de que el código esté bien iluminado y limpio. Si el problema persiste, puedes ingresar el código manualmente usando la opción en la parte inferior del escáner.',
      'votos': 38,
    },
    {
      'pregunta': '¿Cómo actualizo mi información de perfil?',
      'respuesta': 'Ve a la sección de Perfil desde el menú inferior, luego selecciona "Editar perfil" para actualizar tu información personal y de contacto.',
      'votos': 27,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
      2, // Current index (ayuda)
    );
  }

  Future<void> _openWhatsApp() async {
    const phoneNumber = '+525512345678'; // TODO: Get from config
    final whatsappUrl = Uri.parse('https://wa.me/$phoneNumber');
    
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          DialogUtils.showErrorDialog(
            context: context,
            title: 'Error',
            message: 'No se pudo abrir WhatsApp. Asegúrate de tener la aplicación instalada.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al abrir WhatsApp',
        );
      }
    }
  }

  Future<void> _downloadManual() async {
    // TODO: Implement actual manual download from Firebase Storage
    const manualUrl = 'https://example.com/manual-usuario-ecoce.pdf';
    
    try {
      final url = Uri.parse(manualUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          DialogUtils.showErrorDialog(
            context: context,
            title: 'Error',
            message: 'No se pudo descargar el manual',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al descargar el manual',
        );
      }
    }
  }

  Future<void> _openVideo(String videoUrl) async {
    try {
      final url = Uri.parse(videoUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudo abrir el video',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = UserTypeHelper.getPrimaryColor(_userProfile);
    final navigationItems = UserTypeHelper.getNavigationItems(_userProfile?.ecoceTipoActor);
    final fabConfig = UserTypeHelper.getFabConfig(_userProfile?.ecoceTipoActor, context);
    
    return LoadingWrapper(
      isLoading: _isLoading,
      hasError: !_isLoading && _userProfile == null,
      onRetry: _loadUserData,
      errorMessage: 'Error al cargar datos',
      primaryColor: primaryColor,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          // Prevent back navigation on help screen
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
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
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.help_outline_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Centro de Ayuda',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Usuario ${_userProfile?.tipoActorLabel ?? 'ECOCE'}',
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
                ),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.chat,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onTap: _openWhatsApp,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.picture_as_pdf,
                          label: 'Manual PDF',
                          color: const Color(0xFFE53935),
                          onTap: _downloadManual,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Video Tutorials
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tutoriales en Video',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._videosTutoriales.map((video) => _buildVideoCard(video)),
                    ],
                  ),
                ),
              ),

              // FAQs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preguntas Frecuentes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._faqsPopulares.map((faq) => _buildFAQCard(faq)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: EcoceBottomNavigation(
          selectedIndex: 2,
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

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
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
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BioWayColors.darkGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: () => _openVideo(video['url']),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    color: BioWayColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_filled,
                        color: BioWayColors.primaryGreen,
                        size: 32,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video['titulo'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        video['descripcion'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            video['duracion'],
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.visibility, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${video['vistas']} vistas',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQCard(Map<String, dynamic> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              faq['pregunta'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: BioWayColors.darkGreen,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      faq['respuesta'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${faq['votos']} personas encontraron esto útil',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}