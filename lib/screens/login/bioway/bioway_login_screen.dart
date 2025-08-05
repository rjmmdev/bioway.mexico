import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart'; // ACTUALIZADA
import '../../../utils/ui_constants.dart';
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
  late final BioWayAuthService _bioWayAuthService;

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
      
      // Ahora es seguro crear la instancia de BioWayAuthService
      _bioWayAuthService = BioWayAuthService();
    } catch (e) {
      debugPrint('❌ Error al inicializar Firebase para BioWay: $e');
      // Por ahora no mostramos error ya que BioWay puede no tener proyecto Firebase configurado
      // Crear la instancia de todos modos para evitar errores
      _bioWayAuthService = BioWayAuthService();
    }
  }

  void _setupAnimations() {
    _formAnimationController = AnimationController(
      duration: Duration(milliseconds: UIConstants.animationDurationLong * 2),
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
    Future.delayed(Duration(milliseconds: UIConstants.animationDurationLong), () {
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
        transitionDuration: Duration(milliseconds: UIConstants.animationDurationMedium + 100),
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
                  SizedBox(width: UIConstants.spacing12),
                  Text('¡Bienvenido ${bioWayUser.nombre}!'),
                ],
              ),
              backgroundColor: BioWayColors.success,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsetsConstants.paddingAll20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UIConstants.spacing10),
              ),
              duration: Duration(seconds: 2),
            ),
          );

          // Navegar según el tipo de usuario
          await Future.delayed(Duration(milliseconds: UIConstants.animationDurationLong));
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
                  SizedBox(width: UIConstants.spacing12),
                  Expanded(
                    child: Text(errorMessage),
                  ),
                ],
              ),
              backgroundColor: BioWayColors.error,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsetsConstants.paddingAll20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UIConstants.spacing10),
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
          borderRadius: BorderRadius.circular(UIConstants.spacing10),
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
        transitionDuration: Duration(milliseconds: UIConstants.animationDurationMedium + 100),
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
              padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: UIConstants.spacing20),

                  // Logo animado con funcionalidad de switch
                  Hero(
                    tag: 'bioway_logo',
                    child: AnimatedLogo(
                      onTap: _navigateToPlatformSelector,
                      size: UIConstants.logoSize + 2,
                    ),
                  ),

                  SizedBox(height: UIConstants.spacing20),

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
                      constraints: BoxConstraints(maxWidth: UIConstants.maxWidthDialog),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Campo de correo
                            _buildEmailField(),
                            SizedBox(height: UIConstants.spacing20),

                            // Campo de contraseña
                            _buildPasswordField(),
                            SizedBox(height: UIConstants.spacing12),

                            // Remember me y Olvidé contraseña
                            _buildRememberAndForgot(),
                            SizedBox(height: UIConstants.spacing32),

                            // Botón iniciar sesión
                            _buildLoginButton(),
                            SizedBox(height: UIConstants.spacing24),

                            // Divisor
                            _buildDivider(),
                            SizedBox(height: UIConstants.spacing24),

                            // Botón registrarse
                            _buildRegisterButton(),
                            SizedBox(height: UIConstants.spacing24),

                            SizedBox(height: UIConstants.spacing20),
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
        SizedBox(height: UIConstants.spacing8),
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
              fontSize: UIConstants.fontSizeMedium,
            ),
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: BioWayColors.darkGreen,
              size: UIConstants.iconSizeSmall + 6,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: UIConstants.opacityAlmostFull),
            border: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: BorderSide(
                color: Colors.grey.shade200,
                width: UIConstants.borderWidthThin,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: const BorderSide(
                color: BioWayColors.primaryGreen,
                width: UIConstants.borderWidthThick - 0.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: const BorderSide(
                color: BioWayColors.error,
                width: UIConstants.borderWidthThick - 0.5,
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
        SizedBox(height: UIConstants.spacing8),
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
              fontSize: UIConstants.fontSizeMedium,
            ),
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: BioWayColors.darkGreen,
              size: UIConstants.iconSizeSmall + 6,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: BioWayColors.darkGreen,
                size: UIConstants.iconSizeSmall + 6,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: UIConstants.opacityAlmostFull),
            border: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: BorderSide(
                color: Colors.grey.shade200,
                width: UIConstants.borderWidthThin,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: const BorderSide(
                color: BioWayColors.primaryGreen,
                width: UIConstants.borderWidthThick - 0.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: const BorderSide(
                color: BioWayColors.error,
                width: UIConstants.borderWidthThick - 0.5,
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
              height: UIConstants.iconSizeMedium,
              width: UIConstants.iconSizeMedium,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: BioWayColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(UIConstants.spacing4),
                ),
              ),
            ),
            SizedBox(width: UIConstants.spacing8),
            Text(
              'Recordarme',
              style: TextStyle(
                color: BioWayColors.darkGreen,
                fontSize: UIConstants.fontSizeMedium,
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
              fontSize: UIConstants.fontSizeMedium,
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
      height: UIConstants.buttonHeightCompact,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: BioWayColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: _isLoading ? 0 : UIConstants.elevationLow + 1,
          shadowColor: BioWayColors.primaryGreen.withValues(alpha: UIConstants.opacityMedium + 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusConstants.borderRadiusMedium,
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          width: UIConstants.iconSizeMedium,
          height: UIConstants.iconSizeMedium,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: UIConstants.borderWidthThick,
          ),
        )
            : const Text(
          'Iniciar Sesión',
          style: TextStyle(
            fontSize: UIConstants.fontSizeBody,
            fontWeight: FontWeight.bold,
            letterSpacing: UIConstants.letterSpacingMedium,
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
            height: UIConstants.borderWidthThin,
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
          padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing16),
          child: Text(
            'o',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: UIConstants.fontSizeMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: UIConstants.borderWidthThin,
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
      height: UIConstants.buttonHeightCompact,
      child: OutlinedButton(
        onPressed: _handleRegister,
        style: OutlinedButton.styleFrom(
          foregroundColor: BioWayColors.primaryGreen,
          side: const BorderSide(
            color: BioWayColors.primaryGreen,
            width: UIConstants.borderWidthThick - 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusConstants.borderRadiusMedium,
          ),
        ),
        child: const Text(
          'Registrarse',
          style: TextStyle(
            fontSize: UIConstants.fontSizeBody,
            fontWeight: FontWeight.bold,
            letterSpacing: UIConstants.letterSpacingMedium,
          ),
        ),
      ),
    );
  }

}