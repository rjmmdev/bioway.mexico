import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart'; // ACTUALIZADA
import '../../../widgets/common/gradient_background.dart'; // ACTUALIZADA
import '../../../services/firebase/auth_service.dart';
import '../../../services/firebase/firebase_manager.dart';
import '../../../services/bioway/bioway_auth_service.dart';
import '../../../widgets/login/animated_logo.dart'; // ACTUALIZADA
import '../platform_selector_screen.dart'; // ACTUALIZADA
import 'bioway_register_screen.dart'; // ACTUALIZADA
import '../../bioway/brindador/brindador_main_screen.dart';
import '../../bioway/recolector/recolector_main_screen.dart';

class BioWayLoginScreen extends StatefulWidget {
  const BioWayLoginScreen({super.key});

  @override
  State<BioWayLoginScreen> createState() => _BioWayLoginScreenState();
}

class _BioWayLoginScreenState extends State<BioWayLoginScreen>
    with SingleTickerProviderStateMixin {
  // Controladores del formulario
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // Estados
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  // Animación para el formulario
  late AnimationController _formAnimationController;
  late Animation<double> _formFadeAnimation;
  late Animation<Offset> _formSlideAnimation;

  // Instancia del servicio de autenticación
  final AuthService _authService = AuthService();
  final BioWayAuthService _bioWayAuthService = BioWayAuthService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      // Inicializar Firebase para BioWay
      await _authService.initializeForPlatform(FirebasePlatform.bioway);
      debugPrint('✅ Firebase inicializado para BioWay');
    } catch (e) {
      debugPrint('❌ Error al inicializar Firebase para BioWay: $e');
      // Por ahora no mostramos error ya que BioWay puede no tener proyecto Firebase configurado
    }
  }

  void _setupAnimations() {
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _formFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _formAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _formAnimationController.dispose();
    super.dispose();
  }

  void _navigateToPlatformSelector() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const PlatformSelectorScreen(),
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

  Future<void> _handleLogin() async {
    // Ocultar teclado
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Intentar autenticación con Firebase
        final email = _emailController.text.trim();
        final password = _passwordController.text;

        // Intentar login con BioWay
        final bioWayUser = await _bioWayAuthService.iniciarSesion(
          email: email,
          password: password,
        );

        if (bioWayUser != null && mounted) {
          // Login exitoso
          setState(() {
            _isLoading = false;
          });

          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('¡Bienvenido ${bioWayUser.nombre}!'),
                ],
              ),
              backgroundColor: BioWayColors.success,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );

          // Navegar según el tipo de usuario
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            if (bioWayUser.isBrindador) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const BrindadorMainScreen(),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecolectorMainScreen(),
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          String errorMessage = 'Error al iniciar sesión';
          if (e.toString().contains('user-not-found')) {
            errorMessage = 'No existe un usuario con este correo';
          } else if (e.toString().contains('wrong-password')) {
            errorMessage = 'Contraseña incorrecta';
          } else if (e.toString().contains('invalid-email')) {
            errorMessage = 'Correo electrónico inválido';
          } else if (e.toString().contains('network-request-failed')) {
            errorMessage = 'Error de conexión. Verifica tu internet';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(errorMessage),
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

  void _handleForgotPassword() {
    // TODO: Implementar recuperación de contraseña
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Función en desarrollo'),
        backgroundColor: BioWayColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _handleRegister() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const BioWayRegisterScreen(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Logo animado con funcionalidad de switch
                  Hero(
                    tag: 'bioway_logo',
                    child: AnimatedLogo(
                      onTap: _navigateToPlatformSelector,
                      size: 142,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Formulario animado
                  AnimatedBuilder(
                    animation: _formAnimationController,
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Campo de correo
                            _buildEmailField(),
                            const SizedBox(height: 20),

                            // Campo de contraseña
                            _buildPasswordField(),
                            const SizedBox(height: 12),

                            // Remember me y Olvidé contraseña
                            _buildRememberAndForgot(),
                            const SizedBox(height: 32),

                            // Botón iniciar sesión
                            _buildLoginButton(),
                            const SizedBox(height: 24),

                            // Divisor
                            _buildDivider(),
                            const SizedBox(height: 24),

                            // Botón registrarse
                            _buildRegisterButton(),
                            const SizedBox(height: 24),

                            // Divisor para accesos temporales
                            _buildDivider(),
                            const SizedBox(height: 24),

                            // Accesos temporales (SOLO PARA DESARROLLO)
                            _buildTemporaryAccessSection(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correo electrónico',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_passwordFocusNode);
          },
          decoration: InputDecoration(
            hintText: 'correo@ejemplo.com',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: BioWayColors.darkGreen,
              size: 22,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: BioWayColors.primaryGreen,
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
              return 'Por favor ingresa tu correo';
            }
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Por favor ingresa un correo válido';
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
          style: Theme.of(context).textTheme.labelLarge,
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
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: BioWayColors.darkGreen,
              size: 22,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: BioWayColors.darkGreen,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: BioWayColors.primaryGreen,
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

  Widget _buildRememberAndForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember me
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: BioWayColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Recordarme',
              style: TextStyle(
                color: BioWayColors.darkGreen,
                fontSize: 14,
              ),
            ),
          ],
        ),

        // Forgot password
        TextButton(
          onPressed: _handleForgotPassword,
          style: TextButton.styleFrom(
            foregroundColor: BioWayColors.primaryGreen,
            padding: EdgeInsets.zero,
          ),
          child: const Text(
            '¿Olvidaste tu contraseña?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
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
          backgroundColor: BioWayColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: _isLoading ? 0 : 3,
          shadowColor: BioWayColors.primaryGreen.withValues(alpha: 0.4),
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
          foregroundColor: BioWayColors.primaryGreen,
          side: const BorderSide(
            color: BioWayColors.primaryGreen,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Registrarse',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTemporaryAccessSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BioWayColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BioWayColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: BioWayColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ACCESOS TEMPORALES (Solo Desarrollo)',
                  style: TextStyle(
                    color: BioWayColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTempAccessButton(
                  label: 'Brindador',
                  icon: Icons.volunteer_activism,
                  onTap: _navigateToBrindadorDashboard,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTempAccessButton(
                  label: 'Recolector',
                  icon: Icons.local_shipping,
                  onTap: _navigateToRecolectorDashboard,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTempAccessButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: BioWayColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: BioWayColors.primaryGreen.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: BioWayColors.primaryGreen,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: BioWayColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToBrindadorDashboard() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Accediendo como Brindador (modo desarrollo)'),
        backgroundColor: BioWayColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const BrindadorMainScreen(),
          ),
        );
      }
    });
  }

  void _navigateToRecolectorDashboard() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Accediendo como Recolector (modo desarrollo)'),
        backgroundColor: BioWayColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RecolectorMainScreen(),
          ),
        );
      }
    });
  }
}