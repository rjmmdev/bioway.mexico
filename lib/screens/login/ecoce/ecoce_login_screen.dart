import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import '../../../utils/colors.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../services/firebase/firebase_manager.dart';
import '../../../services/firebase/ecoce_profile_service.dart';
import '../../ecoce/shared/utils/dialog_utils.dart';
import 'ecoce_tipo_proveedor_selector.dart';
import '../../ecoce/shared/pending_approval_screen.dart';

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

  // Animaciones
  late AnimationController _logoController;
  late AnimationController _formController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _formFadeAnimation;
  late Animation<Offset> _formSlideAnimation;

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
    super.dispose();
  }

  void _navigateBack() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }


  Future<void> _handleLogin({bool goToRepository = false}) async {
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
            
            // TEMPORAL: Auto-crear perfil maestro - DESHABILITADO
            // Ahora se usa la pantalla de registro temporal
            // if (userId == '0XOboM6ej6fR1iFXt6DwqnffqkW2' && email == 'maestro@ecoce.mx') {
            //   await _autoCreateMaestroProfile(userId);
            // }
            
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

            // Navegar según el tipo de usuario o al repositorio
            if (goToRepository) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/repositorio_inicio',
                (route) => false,
              );
            } else {
              _navigateToUserScreen(profile.ecoceTipoActor, profile);
            }
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


  void _showErrorDialog(String title, String message) {
    DialogUtils.showErrorDialog(
      context: context,
      title: title,
      message: message,
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
        Navigator.pushReplacementNamed(context, '/transporte_inicio');
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

  Widget _buildBackButton() {
    return IconButton(
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
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _logoFadeAnimation,
          child: Transform.scale(
            scale: _logoScaleAnimation.value,
            child: SvgPicture.asset(
              'assets/logos/ecoce_logo.svg',
              width: 140,
              height: 140,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      _buildBackButton(),
                    ],
                  ),
                ),

                // Contenido scrollable
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 0),

                        // Logo animado
                        _buildLogo(),

                        const SizedBox(height: 16),

                        // Título principal
                        Text(
                          'Sistema de Trazabilidad',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: BioWayColors.ecoceDark,
                            letterSpacing: 0.2,
                          ),
                        ),

                        const SizedBox(height: 24),

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
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: BioWayColors.ecoceGreen.withValues(alpha: 0.25),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: BioWayColors.ecoceGreen.withValues(alpha: 0.12),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                  spreadRadius: -5,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
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
                                  const SizedBox(height: 12),
                                  
                                  // Botón de repositorio
                                  _buildRepositoryButton(),
                                  const SizedBox(height: 20),

                                  // Divisor
                                  _buildDivider(),
                                  const SizedBox(height: 20),

                                  // Botón de registro
                                  _buildRegisterButton(),
                                  const SizedBox(height: 16),


                                  // Información adicional
                                  const SizedBox(height: 20),
                                  _buildInfoSection(),
                                ],
                              ),
                            ),
                          ),
                        ),


                        const SizedBox(height: 20),
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
        Row(
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 16,
              color: BioWayColors.ecoceGreen,
            ),
            const SizedBox(width: 6),
            Text(
              'Correo o Folio',
              style: TextStyle(
                color: BioWayColors.ecoceDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
            fillColor: const Color(0xFFF6FBF8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: BioWayColors.ecoceGreen.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: BioWayColors.ecoceGreen,
                width: 2.5,
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
        Row(
          children: [
            Icon(
              Icons.lock_outlined,
              size: 16,
              color: BioWayColors.ecoceGreen,
            ),
            const SizedBox(width: 6),
            Text(
              'Contraseña',
              style: TextStyle(
                color: BioWayColors.ecoceDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(goToRepository: false),
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
            fillColor: const Color(0xFFF6FBF8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: BioWayColors.ecoceGreen.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: BioWayColors.ecoceGreen,
                width: 2.5,
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
        onPressed: _isLoading ? null : () => _handleLogin(),
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

  Widget _buildRepositoryButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _handleLogin(goToRepository: true),
        icon: const Icon(Icons.inventory_2_outlined, size: 20),
        label: const Text(
          'Acceder al Repositorio',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: BioWayColors.ecoceDark,
          foregroundColor: Colors.white,
          elevation: _isLoading ? 0 : 3,
          shadowColor: BioWayColors.ecoceDark.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
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
          backgroundColor: BioWayColors.ecoceGreen.withValues(alpha: 0.05),
          side: BorderSide(
            color: BioWayColors.ecoceGreen.withValues(alpha: 0.3),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 20,
              color: BioWayColors.ecoceGreen,
            ),
            const SizedBox(width: 8),
            const Text(
              'Registrar Proveedor',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
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

    // Fondo gradiente principal
    final backgroundGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFF8FFFE),
        const Color(0xFFF0FBF5),
        const Color(0xFFE8F8F0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    
    paint.shader = backgroundGradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Círculos flotantes con efecto de profundidad
    paint.shader = null;
    
    // Círculo grande superior
    final circle1Center = Offset(size.width * 0.8, size.height * 0.1);
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.05);
    canvas.drawCircle(circle1Center, 120, paint);
    
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.03);
    canvas.drawCircle(circle1Center, 140, paint);
    
    // Círculo mediano centro-izquierda
    final circle2Center = Offset(size.width * 0.1, size.height * 0.4);
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.04);
    canvas.drawCircle(circle2Center, 80, paint);
    
    // Círculo pequeño inferior-derecha
    final circle3Center = Offset(size.width * 0.9, size.height * 0.8);
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.06);
    canvas.drawCircle(circle3Center, 60, paint);
    
    // Patrón de hojas estilizadas
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    
    // Hoja 1 - superior izquierda
    _drawLeaf(canvas, paint, Offset(size.width * 0.15, size.height * 0.2), 30, -0.5);
    
    // Hoja 2 - centro derecha
    _drawLeaf(canvas, paint, Offset(size.width * 0.85, size.height * 0.5), 25, 0.8);
    
    // Hoja 3 - inferior izquierda
    _drawLeaf(canvas, paint, Offset(size.width * 0.2, size.height * 0.75), 20, -0.3);
    
    // Elementos geométricos flotantes
    paint.style = PaintingStyle.fill;
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.03);
    
    // Triángulo superior
    final triangle1 = Path()
      ..moveTo(size.width * 0.5, size.height * 0.15)
      ..lineTo(size.width * 0.52, size.height * 0.18)
      ..lineTo(size.width * 0.48, size.height * 0.18)
      ..close();
    canvas.drawPath(triangle1, paint);
    
    // Hexágono centro
    _drawHexagon(canvas, paint, Offset(size.width * 0.7, size.height * 0.35), 15);
    
    // Líneas de conexión sutiles
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.5;
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.05);
    
    final connectionPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.5, size.height * 0.4,
        size.width * 0.9, size.height * 0.6,
      );
    canvas.drawPath(connectionPath, paint);
  }
  
  void _drawLeaf(Canvas canvas, Paint paint, Offset position, double size, double rotation) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);
    
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.08);
    
    final leafPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size * 0.5, -size * 0.3, size, 0)
      ..quadraticBezierTo(size * 0.5, size * 0.3, 0, 0);
    
    canvas.drawPath(leafPath, paint);
    
    // Vena central
    paint.strokeWidth = 1;
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.06);
    canvas.drawLine(Offset(0, 0), Offset(size, 0), paint);
    
    canvas.restore();
  }
  
  void _drawHexagon(Canvas canvas, Paint paint, Offset center, double radius) {
    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * (3.14159 / 180);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();
    canvas.drawPath(hexPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}