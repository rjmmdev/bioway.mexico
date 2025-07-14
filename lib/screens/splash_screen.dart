import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../utils/colors.dart';
import 'login/bioway/bioway_login_screen.dart'; // ACTUALIZADA

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controladores de animación
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;

  // Animaciones
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _loadingFadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Logo Controller (escala, rotación y fade)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Text Controller (fade y slide)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Loading Controller
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Logo Scale Animation - efecto elástico
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Logo Rotation Animation - rotación suave
    _logoRotationAnimation = Tween<double>(
      begin: -0.5,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutCubic,
    ));

    // Logo Fade Animation
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    // Text Fade Animation
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    // Text Slide Animation
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Loading Fade Animation
    _loadingFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeIn,
    ));
  }

  void _startAnimationSequence() async {
    // Iniciar animación del logo
    await _logoController.forward();

    // Pequeña pausa
    await Future.delayed(const Duration(milliseconds: 200));

    // Iniciar animación del texto
    await _textController.forward();

    // Otra pequeña pausa
    await Future.delayed(const Duration(milliseconds: 300));

    // Mostrar indicador de carga
    await _loadingController.forward();

    // Simular carga de datos/inicialización
    await Future.delayed(const Duration(seconds: 2));

    // Navegar al login
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          const BioWayLoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Configurar la barra de estado
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: BioWayColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Espacio superior flexible
                const Spacer(flex: 2),

                // Logo animado
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _logoFadeAnimation,
                      child: Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: Transform.rotate(
                          angle: _logoRotationAnimation.value,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  BioWayColors.primaryGreen,
                                  BioWayColors.primaryGreen.withOpacity(0.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: BioWayColors.primaryGreen.withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Ícono principal
                                const Icon(
                                  Icons.eco,
                                  size: 70,
                                  color: Colors.white,
                                ),
                                // Anillo decorativo animado
                                ...List.generate(2, (index) {
                                  return AnimatedBuilder(
                                    animation: _logoController,
                                    builder: (context, child) {
                                      return Container(
                                        width: 140 + (index * 30),
                                        height: 140 + (index * 30),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: BioWayColors.primaryGreen
                                                .withOpacity(0.2 - (index * 0.1)),
                                            width: 2,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Texto animado
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _textFadeAnimation,
                      child: SlideTransition(
                        position: _textSlideAnimation,
                        child: Column(
                          children: [
                            // Logo text
                            Text(
                              'BioWay',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.darkGreen,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.1),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Subtítulo
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: BioWayColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'MÉXICO',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: BioWayColors.darkGreen,
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Espacio medio
                const Spacer(flex: 1),

                // Indicador de carga
                AnimatedBuilder(
                  animation: _loadingController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _loadingFadeAnimation,
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
                                      color: BioWayColors.primaryGreen.withOpacity(0.2),
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
                                      BioWayColors.primaryGreen,
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
                              fontSize: 14,
                              color: BioWayColors.darkGreen.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Espacio inferior
                const Spacer(flex: 2),

                // Versión de la app
                FadeTransition(
                  opacity: _loadingFadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: BioWayColors.darkGreen.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}