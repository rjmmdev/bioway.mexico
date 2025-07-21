import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../services/firebase/firebase_manager.dart';
import '../../../services/firebase/ecoce_profile_service.dart';
import '../../ecoce/shared/utils/dialog_utils.dart';
import 'ecoce_tipo_proveedor_selector.dart';
import '../../ecoce/reciclador/reciclador_inicio.dart';
// TEMPORAL: Importar pantallas de inicio
import '../../ecoce/origen/origen_inicio_screen.dart';
import '../../ecoce/maestro/maestro_unified_screen.dart';
import '../../ecoce/repositorio/repositorio_lotes_screen.dart';
import '../../ecoce/shared/pending_approval_screen.dart';
import '../../ecoce/laboratorio/laboratorio_inicio.dart';

class ECOCELoginScreen extends StatefulWidget {
  const ECOCELoginScreen({super.key});

  @override
  State<ECOCELoginScreen> createState() => _ECOCELoginScreenState();
}

class _ECOCELoginScreenState extends State<ECOCELoginScreen>
    with TickerProviderStateMixin {
  // Controladores del formulario
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // Estados
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showUserTypeButtons = false; // Nuevo estado para mostrar/ocultar botones

  // Animaciones
  late AnimationController _logoController;
  late AnimationController _formController;
  late AnimationController _userTypeController; // Nueva animación para botones
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _formFadeAnimation;
  late Animation<Offset> _formSlideAnimation;
  late Animation<double> _userTypeFadeAnimation; // Nueva animación

  // Instancia del servicio de autenticación
  final AuthService _authService = AuthService();
  final EcoceProfileService _profileService = EcoceProfileService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      // Inicializar Firebase para ECOCE
      await _authService.initializeForPlatform(FirebasePlatform.ecoce);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al conectar con el servidor: $e'),
            backgroundColor: BioWayColors.error,
          ),
        );
      }
    }
  }

  void _setupAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));

    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    ));

    // Form animations
    _formController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _formFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOutCubic,
    ));

    // User type buttons animation
    _userTypeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _userTypeFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _userTypeController,
      curve: Curves.easeIn,
    ));
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _formController.forward();
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    _userFocusNode.dispose();
    _passwordFocusNode.dispose();
    _logoController.dispose();
    _formController.dispose();
    _userTypeController.dispose();
    super.dispose();
  }

  void _navigateBack() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  void _toggleUserTypeButtons() {
    setState(() {
      _showUserTypeButtons = !_showUserTypeButtons;
    });
    
    if (_showUserTypeButtons) {
      _userTypeController.forward();
    } else {
      _userTypeController.reverse();
    }
  }

  Future<void> _handleLogin() async {
    // Ocultar teclado
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Intentar autenticación con Firebase
        final userInput = _userController.text.trim();
        final userPassword = _passwordController.text;
        
        // Determinar si es un email o un folio
        String email = userInput;
        
        // Verificar si es un folio (formato: letra seguida de números, ej: A0000001)
        final folioPattern = RegExp(r'^[A-Z]\d{7}$');
        if (folioPattern.hasMatch(userInput.toUpperCase())) {
          // Es un folio, buscar el email asociado
          final emailFromFolio = await _profileService.getEmailByFolio(userInput.toUpperCase());
          if (emailFromFolio == null) {
            setState(() {
              _isLoading = false;
            });
            _showErrorDialog(
              'Folio no encontrado',
              'No se encontró una cuenta asociada con el folio $userInput',
            );
            return;
          }
          email = emailFromFolio;
        } else if (!userInput.contains('@')) {
          // No es un email ni un folio válido
          setState(() {
            _isLoading = false;
          });
          _showErrorDialog(
            'Formato inválido',
            'Por favor ingresa un correo electrónico válido o un folio (ej: A0000001)',
          );
          return;
        }

        // Intentar autenticación con Firebase Auth primero
        try {
          final userCredential = await _authService.signInWithEmailAndPassword(
            email: email,
            password: userPassword,
          );

          if (userCredential.user != null && mounted) {
            final userId = userCredential.user!.uid;
            
            // Primero verificar si existe una solicitud
            final solicitud = await _profileService.checkAccountRequestStatus(email);
            
            if (solicitud != null) {
              // Existe una solicitud, verificar su estado
              final estado = solicitud['estado'];
              
              if (estado == 'pendiente') {
                // Cuenta pendiente de aprobación
                await _authService.signOut();
                setState(() {
                  _isLoading = false;
                });
                
                final datosPerfil = solicitud['datos_perfil'] as Map<String, dynamic>;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PendingApprovalScreen(
                      userName: datosPerfil['ecoce_nombre'] ?? 'Usuario',
                      userEmail: email,
                    ),
                  ),
                );
                return;
              } else if (estado == 'rechazada') {
                // Cuenta rechazada
                await _authService.signOut();
                setState(() {
                  _isLoading = false;
                });
                
                final razon = solicitud['comentarios_revision'] ?? 'Tu solicitud fue rechazada.';
                _showRejectedDialog(razon);
                return;
              }
            }
            
            // Si no hay solicitud o está aprobada, obtener el perfil
            final profile = await _profileService.getProfile(userId);
            
            setState(() {
              _isLoading = false;
            });

            if (profile == null) {
              // No se encontró el perfil del usuario
              _showErrorDialog(
                'Perfil no encontrado',
                'No se encontró información de tu cuenta. Contacta al administrador.',
              );
              await _authService.signOut();
              return;
            }
            
            // Verificar si el perfil está aprobado (para usuarios antiguos sin solicitud)
            if (profile.ecoceEstatusAprobacion == 0) {
              // Usuario pendiente de aprobación (caso antiguo)
              await _authService.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PendingApprovalScreen(
                    userName: profile.ecoceNombre,
                    userEmail: email,
                  ),
                ),
              );
              return;
            }

            // Usuario aprobado - mostrar mensaje de éxito
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Login ECOCE exitoso'),
                  ],
                ),
                backgroundColor: BioWayColors.ecoceGreen,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 2),
              ),
            );

            // Navegar según el tipo de usuario
            _navigateToUserScreen(profile.ecoceTipoActor, profile);
          }
        } catch (firebaseError) {
          setState(() {
            _isLoading = false;
          });
          
          // Error de autenticación - verificar el tipo de error
          String errorMessage = 'Usuario o contraseña incorrectos.';
          
          if (firebaseError.toString().contains('user-not-found')) {
            errorMessage = 'No existe una cuenta con este correo electrónico.';
          } else if (firebaseError.toString().contains('wrong-password')) {
            errorMessage = 'La contraseña es incorrecta.';
          } else if (firebaseError.toString().contains('invalid-email')) {
            errorMessage = 'El formato del correo electrónico es inválido.';
          } else if (firebaseError.toString().contains('user-disabled')) {
            errorMessage = 'Esta cuenta ha sido deshabilitada.';
          }
          
          _showErrorDialog(
            'Error de autenticación',
            errorMessage,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Error: ${e.toString()}'),
                  ),
                ],
              ),
              backgroundColor: BioWayColors.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  void _handleRegister() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const ECOCETipoProveedorSelector(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _handleForgotPassword() {
    // TODO: Implementar recuperación de contraseña para ECOCE
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Función en desarrollo para ECOCE'),
        backgroundColor: BioWayColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _handleUserTypeLogin(String userType, Color color) {
    HapticFeedback.mediumImpact();

    Widget? targetScreen;

    switch (userType.toLowerCase()) {
      case 'reciclador':
        targetScreen = const RecicladorInicio();
        break;
      case 'acopiador':
        targetScreen = const OrigenInicioScreen();
        break;
      case 'planta de separación':
        targetScreen = const OrigenInicioScreen();
        break;
      case 'transformador':
        targetScreen = const OrigenInicioScreen(); // TEMPORAL
        break;
      case 'transportista':
        // Transportista va directo a recoger material
        Navigator.pushReplacementNamed(context, '/transporte_recoger');
        return;
      case 'laboratorio':
        targetScreen = const LaboratorioInicioScreen();
        break;
      case 'repositorio':
        targetScreen = RepositorioLotesScreen(
          primaryColor: BioWayColors.metalGrey,
          tipoUsuario: 'repositorio',
        );
        break;
      case 'maestro ecoce':
        targetScreen = const MaestroUnifiedScreen();
        break;
    }

    if (targetScreen != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => targetScreen!,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      // Si no hay pantalla definida, mostrar mensaje temporal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pantalla de $userType en desarrollo'),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  IconData _getUserTypeIcon(String userType) {
    switch (userType.toLowerCase()) {
      case 'acopiador':
        return Icons.warehouse;
      case 'planta de separación':
        return Icons.sort;
      case 'reciclador':
        return Icons.recycling;
      case 'transformador':
        return Icons.factory;
      case 'transportista':
        return Icons.local_shipping;
      case 'laboratorio':
        return Icons.science;
      case 'repositorio':
        return Icons.storage; // Icono específico para repositorio
      case 'maestro ecoce':
        return Icons.admin_panel_settings; // Icono para Usuario Maestro
      default:
        return Icons.business;
    }
  }

  Color _getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'acopiador':
        return BioWayColors.petBlue;
      case 'planta de separación':
        return BioWayColors.hdpeGreen;
      case 'reciclador':
        return BioWayColors.ecoceGreen;
      case 'transformador':
        return BioWayColors.ppOrange;
      case 'transportista':
        return BioWayColors.info;
      case 'laboratorio':
        return BioWayColors.otherPurple;
      case 'repositorio':
        return BioWayColors.metalGrey; // Color gris metálico para repositorio
      case 'maestro ecoce':
        return BioWayColors.ecoceGreen; // Color verde ECOCE para Usuario Maestro
      default:
        return BioWayColors.ecoceGreen;
    }
  }

  void _showPendingApprovalDialog() {
    DialogUtils.showInfoDialog(
      context: context,
      title: 'Aprobación Pendiente',
      message: 'Tu cuenta está siendo revisada por ECOCE.\n\nRecibirás una notificación por correo cuando tu cuenta sea aprobada.',
      buttonText: 'Entendido',
      icon: Icons.hourglass_empty,
      iconColor: BioWayColors.warning,
    );
  }

  void _showRejectedDialog(String reason) {
    DialogUtils.showErrorDialog(
      context: context,
      title: 'Solicitud Rechazada',
      message: 'Razón: $reason\n\nPara más información, contacta a:\nsoporte@ecoce.mx',
      buttonText: 'Cerrar',
    );
  }

  void _showErrorDialog(String title, String message) {
    DialogUtils.showErrorDialog(
      context: context,
      title: title,
      message: message,
    );
  }

  void _navigateToUserScreen(String tipoActor, dynamic profile) {
    // Navegar según el tipo de usuario
    switch (tipoActor) {
      case 'O': // Origen (Acopiador o Planta)
      case 'A': // A veces viene como 'A' para Acopiador
        Navigator.pushReplacementNamed(context, '/origen_inicio');
        break;
      case 'R': // Reciclador
        Navigator.pushReplacementNamed(context, '/reciclador_inicio');
        break;
      case 'V': // Transportista
        Navigator.pushReplacementNamed(context, '/transporte_recoger');
        break;
      case 'T': // Transformador
        Navigator.pushReplacementNamed(context, '/transformador_inicio');
        break;
      case 'L': // Laboratorio
        Navigator.pushReplacementNamed(context, '/laboratorio_inicio');
        break;
      case 'M': // Maestro ECOCE
        Navigator.pushReplacementNamed(context, '/maestro_dashboard');
        break;
      default:
        // Si no se reconoce el tipo, mostrar error
        _showErrorDialog(
          'Tipo de usuario no reconocido',
          'Tu tipo de usuario ($tipoActor) no está configurado en el sistema. Contacta al administrador.',
        );
        // Cerrar sesión por seguridad
        _authService.signOut();
    }
  }

  void _showTemporarySuccessDialog() {
    DialogUtils.showSuccessDialog(
      context: context,
      title: '¡Bienvenido a ECOCE!',
      message: 'Has ingresado correctamente al sistema de trazabilidad ECOCE.\n\nNota: Las pantallas del sistema ECOCE están en desarrollo.',
      buttonText: 'Volver al selector',
      onPressed: () {
        Navigator.pop(context); // Volver al selector
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.ecoceLight,
      body: SafeArea(
        child: Stack(
          children: [
            // Fondo con patrón
            Positioned.fill(
              child: CustomPaint(
                painter: ECOCEBackgroundPainter(),
              ),
            ),

            // Contenido principal
            Column(
              children: [
                // Header con botón de regreso
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _navigateBack,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: BioWayColors.ecoceGreen,
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Logo pequeño de ECOCE
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: BioWayColors.ecoceGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ECOCE',
                          style: TextStyle(
                            color: BioWayColors.ecoceGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido scrollable
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Logo animado
                        AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _logoFadeAnimation,
                              child: Transform.scale(
                                scale: _logoScaleAnimation.value,
                                child: SvgPicture.asset(
                                  'assets/logos/ecoce_logo.svg',
                                  width: 120,
                                  height: 120,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Título y subtítulo
                        const Text(
                          'ECOCE',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.ecoceGreen,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sistema de Trazabilidad',
                          style: TextStyle(
                            fontSize: 18,
                            color: BioWayColors.ecoceDark.withValues(alpha: 0.7),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Formulario animado
                        AnimatedBuilder(
                          animation: _formController,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _formFadeAnimation,
                              child: SlideTransition(
                                position: _formSlideAnimation,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Campo de usuario
                                  _buildUserField(),
                                  const SizedBox(height: 20),

                                  // Campo de contraseña
                                  _buildPasswordField(),
                                  const SizedBox(height: 12),

                                  // Enlace ¿Olvidaste tu contraseña?
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _handleForgotPassword,
                                      style: TextButton.styleFrom(
                                        foregroundColor: BioWayColors.ecoceGreen,
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Text(
                                        '¿Olvidaste tu contraseña?',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Botón de inicio de sesión
                                  _buildLoginButton(),
                                  const SizedBox(height: 20),

                                  // Divisor
                                  _buildDivider(),
                                  const SizedBox(height: 20),

                                  // Botón de registro
                                  _buildRegisterButton(),
                                  const SizedBox(height: 16),

                                  // Botón para mostrar tipos de usuario (TEMPORAL)
                                  _buildUserTypeToggleButton(),

                                  // Información adicional
                                  const SizedBox(height: 20),
                                  _buildInfoSection(),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Botones de tipos de usuario (TEMPORALES)
                        if (_showUserTypeButtons)
                          AnimatedBuilder(
                            animation: _userTypeFadeAnimation,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _userTypeFadeAnimation,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 20),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: BioWayColors.warning.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Advertencia
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: BioWayColors.warning.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.warning_amber_rounded,
                                              color: BioWayColors.warning,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Acceso temporal - Estos botones serán removidos',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: BioWayColors.warning,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      const Text(
                                        'Acceso directo por tipo de usuario:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: BioWayColors.darkGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Grid de botones de tipos de usuario
                                      _buildUserTypeButtonsGrid(),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correo o Folio',
          style: TextStyle(
            color: BioWayColors.ecoceDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _userController,
          focusNode: _userFocusNode,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_passwordFocusNode);
          },
          decoration: InputDecoration(
            hintText: 'correo@ejemplo.com o A0000001',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.person_outline,
              color: BioWayColors.ecoceGreen,
              size: 22,
            ),
            filled: true,
            fillColor: BioWayColors.ecoceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: BioWayColors.ecoceGreen.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: BioWayColors.ecoceGreen,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: BioWayColors.error,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu correo o folio';
            }
            
            // Validar formato de email o folio
            final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            final folioPattern = RegExp(r'^[A-Z]\d{7}$', caseSensitive: false);
            
            if (!emailPattern.hasMatch(value) && !folioPattern.hasMatch(value.toUpperCase())) {
              return 'Formato inválido. Usa tu correo o folio (ej: A0000001)';
            }
            
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contraseña',
          style: TextStyle(
            color: BioWayColors.ecoceDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: BioWayColors.ecoceGreen,
              size: 22,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: BioWayColors.ecoceGreen,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            filled: true,
            fillColor: BioWayColors.ecoceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: BioWayColors.ecoceGreen.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: BioWayColors.ecoceGreen,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: BioWayColors.error,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu contraseña';
            }
            if (value.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: BioWayColors.ecoceGreen,
          foregroundColor: Colors.white,
          elevation: _isLoading ? 0 : 3,
          shadowColor: BioWayColors.ecoceGreen.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        )
            : const Text(
          'Iniciar Sesión',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.shade300,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'o',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade300,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _handleRegister,
        style: OutlinedButton.styleFrom(
          foregroundColor: BioWayColors.ecoceGreen,
          side: BorderSide(
            color: BioWayColors.ecoceGreen,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Registrar Proveedor',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeToggleButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _toggleUserTypeButtons,
        icon: Icon(
          _showUserTypeButtons ? Icons.expand_less : Icons.expand_more,
          size: 20,
        ),
        label: Text(
          _showUserTypeButtons ? 'Ocultar tipos de usuario' : 'Acceso por tipo de usuario',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: BioWayColors.warning,
          side: BorderSide(
            color: BioWayColors.warning.withValues(alpha: 0.5),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildUserTypeButtonsGrid() {
    final userTypes = [
      'Acopiador',
      'Planta de Separación',
      'Reciclador',
      'Transformador',
      'Transportista',
      'Laboratorio',
      'Repositorio', // Nueva opción agregada
      'Maestro ECOCE', // Usuario Maestro ECOCE
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: userTypes.map((userType) {
        final color = _getUserTypeColor(userType);
        final icon = _getUserTypeIcon(userType);
        
        return ElevatedButton.icon(
          onPressed: () => _handleUserTypeLogin(userType, color),
          icon: Icon(icon, size: 18),
          label: Text(
            userType,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BioWayColors.ecoceGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BioWayColors.ecoceGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: BioWayColors.ecoceGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sistema exclusivo para proveedores de ECOCE',
              style: TextStyle(
                fontSize: 12,
                color: BioWayColors.ecoceDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter personalizado para el fondo de ECOCE
class ECOCEBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Círculo decorativo superior
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.05);
    canvas.drawCircle(
      Offset(size.width * 0.8, -50),
      150,
      paint,
    );

    // Círculo decorativo inferior
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.03);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height + 100),
      200,
      paint,
    );

    // Líneas decorativas
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.02);
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;

    for (int i = 0; i < 5; i++) {
      final y = size.height * 0.2 * i;
      final path = Path();
      path.moveTo(0, y);
      path.quadraticBezierTo(
        size.width * 0.5,
        y + 50,
        size.width,
        y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}