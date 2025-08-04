import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import '../utils/colors.dart';
import '../services/firebase/auth_service.dart';
import '../services/firebase/firebase_manager.dart';
import 'login/ecoce/ecoce_login_screen.dart';

class EcoceSplashScreen extends StatefulWidget {
  const EcoceSplashScreen({super.key});

  @override
  State<EcoceSplashScreen> createState() => _EcoceSplashScreenState();
}

class _EcoceSplashScreenState extends State<EcoceSplashScreen>
    with TickerProviderStateMixin {
  // Controladores de animación
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _leafController;
  
  // Animaciones
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _leafRotationAnimation;
  
  // Servicios
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Leaf rotation animation
    _leafController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _leafRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _leafController,
      curve: Curves.linear,
    ));
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Inicializar Firebase para ECOCE
      await _authService.initializeForPlatform(FirebasePlatform.ecoce);
      
      // Esperar un tiempo mínimo para mostrar el splash
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        // Navegar al login de ECOCE
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const ECOCELoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 0.05);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;

              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );

              var fadeAnimation = Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
              ));

              return SlideTransition(
                position: animation.drive(tween),
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // En caso de error, mostrar mensaje y navegar al login de todos modos
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inicializar: $e'),
            backgroundColor: BioWayColors.error,
          ),
        );
        
        await Future.delayed(const Duration(seconds: 2));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ECOCELoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _leafController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFF6FBF8),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF8),
      body: Stack(
        children: [
          // Fondo con patrón animado
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _leafRotationAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ECOCESplashBackgroundPainter(
                    leafRotation: _leafRotationAnimation.value,
                  ),
                );
              },
            ),
          ),

          // Contenido principal
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo animado sin círculo blanco
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: SvgPicture.asset(
                            'assets/logos/ecoce_logo.svg',
                            width: 160,
                            height: 160,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 35),

                  // Textos animados (sin título ECOCE)
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _textFadeAnimation,
                        child: SlideTransition(
                          position: _textSlideAnimation,
                          child: Column(
                            children: [
                              Text(
                                'Sistema de Trazabilidad',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: BioWayColors.ecoceDark,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Ecología y Compromiso Empresarial',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: BioWayColors.ecoceDark.withValues(alpha: 0.75),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  // Indicador de carga circular estilo BioWay
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Column(
                          children: [
                            // Indicador circular personalizado
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Fondo del indicador
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: BioWayColors.ecoceGreen.withValues(alpha: 0.2),
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  // Indicador animado
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        BioWayColors.ecoceGreen,
                                      ),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Texto de carga
                            Text(
                              'Iniciando...',
                              style: TextStyle(
                                fontSize: 15,
                                color: BioWayColors.ecoceDark.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter personalizado para el fondo del splash de ECOCE
class ECOCESplashBackgroundPainter extends CustomPainter {
  final double leafRotation;

  ECOCESplashBackgroundPainter({required this.leafRotation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Fondo gradiente principal
    final backgroundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFF8FFFE),
        const Color(0xFFF0FBF5),
        const Color(0xFFE8F8F0),
        const Color(0xFFF6FBF8),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
    
    paint.shader = backgroundGradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Círculos decorativos con efecto de profundidad
    paint.shader = null;
    
    // Círculo grande superior
    final circle1Center = Offset(size.width * 0.85, size.height * 0.15);
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.04);
    canvas.drawCircle(circle1Center, 150, paint);
    
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.02);
    canvas.drawCircle(circle1Center, 180, paint);
    
    // Círculo mediano izquierda
    final circle2Center = Offset(size.width * 0.15, size.height * 0.35);
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.03);
    canvas.drawCircle(circle2Center, 100, paint);
    
    // Círculo inferior
    final circle3Center = Offset(size.width * 0.5, size.height * 0.85);
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.05);
    canvas.drawCircle(circle3Center, 120, paint);
    
    // Hojas decorativas animadas
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    
    // Hoja 1 - superior izquierda (animada)
    _drawAnimatedLeaf(
      canvas, 
      paint, 
      Offset(size.width * 0.2, size.height * 0.25), 
      35, 
      leafRotation * 0.5,
    );
    
    // Hoja 2 - derecha media (animada)
    _drawAnimatedLeaf(
      canvas, 
      paint, 
      Offset(size.width * 0.8, size.height * 0.45), 
      30, 
      -leafRotation * 0.3,
    );
    
    // Hoja 3 - inferior izquierda (animada)
    _drawAnimatedLeaf(
      canvas, 
      paint, 
      Offset(size.width * 0.25, size.height * 0.7), 
      25, 
      leafRotation * 0.4,
    );
    
    // Elementos geométricos sutiles
    paint.style = PaintingStyle.fill;
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.02);
    
    // Hexágonos decorativos
    _drawHexagon(canvas, paint, Offset(size.width * 0.7, size.height * 0.3), 20);
    _drawHexagon(canvas, paint, Offset(size.width * 0.3, size.height * 0.6), 15);
    
    // Líneas de conexión muy sutiles
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.5;
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.03);
    
    final connectionPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.4)
      ..quadraticBezierTo(
        size.width * 0.5, size.height * 0.5,
        size.width * 0.9, size.height * 0.3,
      );
    canvas.drawPath(connectionPath, paint);
  }
  
  void _drawAnimatedLeaf(Canvas canvas, Paint paint, Offset position, double size, double rotation) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);
    
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.06);
    paint.style = PaintingStyle.fill;
    
    final leafPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size * 0.5, -size * 0.3, size, 0)
      ..quadraticBezierTo(size * 0.5, size * 0.3, 0, 0);
    
    canvas.drawPath(leafPath, paint);
    
    // Vena central
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    paint.color = BioWayColors.ecoceGreen.withValues(alpha: 0.04);
    canvas.drawLine(Offset(0, 0), Offset(size, 0), paint);
    
    // Venas secundarias
    paint.strokeWidth = 0.5;
    for (int i = 1; i <= 3; i++) {
      final x = size * (i / 4);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size * 0.1, -size * 0.1),
        paint,
      );
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size * 0.1, size * 0.1),
        paint,
      );
    }
    
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
  bool shouldRepaint(ECOCESplashBackgroundPainter oldDelegate) {
    return oldDelegate.leafRotation != leafRotation;
  }
}