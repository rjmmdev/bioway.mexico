import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/colors.dart';
import '../../widgets/common/gradient_background.dart';
import 'ecoce/ecoce_login_screen.dart'; // ACTUALIZADA

class PlatformSelectorScreen extends StatefulWidget {
  const PlatformSelectorScreen({super.key});

  @override
  State<PlatformSelectorScreen> createState() => _PlatformSelectorScreenState();
}

class _PlatformSelectorScreenState extends State<PlatformSelectorScreen>
    with TickerProviderStateMixin {
  // Controladores de animación
  late AnimationController _headerController;
  late AnimationController _cardsController;
  late AnimationController _infoController;

  // Animaciones
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _cardsFadeAnimation;
  late Animation<double> _cardsScaleAnimation;
  late Animation<double> _infoFadeAnimation;

  // Lista de animaciones para cada tarjeta
  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _cardAnimations = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Header animations
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    ));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));

    // Cards animation
    _cardsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardsFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardsController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _cardsScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardsController,
      curve: Curves.easeOutBack,
    ));

    // Individual card animations
    for (int i = 0; i < 3; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 400 + (i * 100)),
        vsync: this,
      );
      _cardControllers.add(controller);

      _cardAnimations.add(
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
        )),
      );
    }

    // Info animation
    _infoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _infoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _infoController,
      curve: Curves.easeIn,
    ));
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _headerController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _cardsController.forward();

    // Animar tarjetas individualmente
    for (int i = 0; i < _cardControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      _cardControllers[i].forward();
    }

    await Future.delayed(const Duration(milliseconds: 200));
    _infoController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardsController.dispose();
    _infoController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _navigateBack() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  void _navigateToBioWay() {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/bioway_login');
  }

  void _navigateToECOCE() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const ECOCELoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
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

  void _showComingSoonDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: BioWayColors.info.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rocket_launch,
                    size: 40,
                    color: BioWayColors.info,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '¡Próximamente!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Estamos trabajando para integrar más plataformas de reciclaje y sostenibilidad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: BioWayColors.textGrey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
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
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: BioWayColors.darkGreen,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido principal
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Encabezado animado
                      AnimatedBuilder(
                        animation: _headerController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _headerFadeAnimation,
                            child: SlideTransition(
                              position: _headerSlideAnimation,
                              child: Column(
                                children: [
                                  // Icono principal
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          BioWayColors.primaryGreen,
                                          BioWayColors.mediumGreen,
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: BioWayColors.primaryGreen
                                              .withValues(alpha: 0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.apps,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Título
                                  const Text(
                                    'Selecciona tu Plataforma',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: BioWayColors.darkGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Subtítulo
                                  Text(
                                    'Elige el servicio al que deseas acceder',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: BioWayColors.darkGreen.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      // Lista de opciones animadas
                      AnimatedBuilder(
                        animation: _cardsController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _cardsFadeAnimation,
                            child: Transform.scale(
                              scale: _cardsScaleAnimation.value,
                              child: Column(
                                children: [
                                  // Opción BioWay
                                  AnimatedBuilder(
                                    animation: _cardAnimations[0],
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(
                                          0,
                                          50 * (1 - _cardAnimations[0].value),
                                        ),
                                        child: Opacity(
                                          opacity: _cardAnimations[0].value,
                                          child: _buildPlatformOption(
                                            iconWidget: SvgPicture.asset(
                                              'assets/logos/bioway_logo.svg',
                                              width: 35,
                                              height: 35,
                                            ),
                                            iconColor: BioWayColors.primaryGreen,
                                            title: 'BioWay',
                                            description: 'Sistema principal de reciclaje\nBrindadores y Recicladores',
                                            badge: 'Principal',
                                            badgeColor: BioWayColors.primaryGreen,
                                            onTap: _navigateToBioWay,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Opción ECOCE
                                  AnimatedBuilder(
                                    animation: _cardAnimations[1],
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(
                                          0,
                                          50 * (1 - _cardAnimations[1].value),
                                        ),
                                        child: Opacity(
                                          opacity: _cardAnimations[1].value,
                                          child: _buildPlatformOption(
                                            iconWidget: SvgPicture.asset(
                                              'assets/logos/ecoce_logo.svg',
                                              width: 35,
                                              height: 35,
                                            ),
                                            iconColor: BioWayColors.ecoceGreen,
                                            title: 'ECOCE',
                                            description: 'Sistema de trazabilidad\nde materiales reciclables',
                                            badge: 'Trazabilidad',
                                            badgeColor: BioWayColors.ecoceGreen,
                                            onTap: _navigateToECOCE,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Placeholder para futuras plataformas
                                  AnimatedBuilder(
                                    animation: _cardAnimations[2],
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(
                                          0,
                                          50 * (1 - _cardAnimations[2].value),
                                        ),
                                        child: Opacity(
                                          opacity: _cardAnimations[2].value,
                                          child: _buildPlatformOption(
                                            icon: Icons.add_circle_outline,
                                            iconColor: Colors.grey,
                                            title: 'Más Plataformas',
                                            description: 'Nuevos servicios\nserán añadidos pronto',
                                            isDisabled: true,
                                            onTap: _showComingSoonDialog,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      // Información adicional animada
                      AnimatedBuilder(
                        animation: _infoController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _infoFadeAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: BioWayColors.primaryGreen.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: BioWayColors.info.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      color: BioWayColors.info,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Múltiples sistemas, una app',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: BioWayColors.darkGreen,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Cada plataforma tiene su propio sistema de autenticación y base de datos independiente.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: BioWayColors.textGrey,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
        ),
      ),
    );
  }

  // Widget para construir las opciones de plataforma
  Widget _buildPlatformOption({
    IconData? icon,
    Widget? iconWidget,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isDisabled = false,
    String? badge,
    Color? badgeColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDisabled ? Colors.grey.shade300 : Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDisabled
                    ? Colors.grey.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icono
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDisabled
                      ? Colors.grey.shade300
                      : iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: iconWidget ?? Icon(
                  icon!,
                  color: isDisabled ? Colors.grey.shade500 : iconColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDisabled
                                ? Colors.grey.shade500
                                : BioWayColors.darkGreen,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (badgeColor ?? iconColor).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: badgeColor ?? iconColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDisabled
                            ? Colors.grey.shade400
                            : BioWayColors.textGrey,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Flecha
              if (!isDisabled)
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),

              if (isDisabled)
                Icon(
                  Icons.lock_outline,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}