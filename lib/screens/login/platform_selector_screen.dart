import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/colors.dart';
import '../../utils/ui_constants.dart';
import '../../widgets/common/gradient_background.dart';
import 'ecoce/ecoce_login_screen.dart'; // ACTUALIZADA
import 'bioway/bioway_login_screen.dart'; // AGREGADO

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
      duration: Duration(milliseconds: UIConstants.animationDurationLong),
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
      duration: Duration(milliseconds: UIConstants.animationDurationLong + 200),
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
        duration: Duration(milliseconds: UIConstants.animationDurationMedium + (i * UIConstants.animationDurationFast)),
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
      duration: Duration(milliseconds: UIConstants.animationDurationLong),
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
    await Future.delayed(Duration(milliseconds: UIConstants.animationDurationFast));
    _headerController.forward();

    await Future.delayed(Duration(milliseconds: UIConstants.animationDurationShort));
    _cardsController.forward();

    // Animar tarjetas individualmente
    for (int i = 0; i < _cardControllers.length; i++) {
      await Future.delayed(Duration(milliseconds: UIConstants.animationDurationFast));
      _cardControllers[i].forward();
    }

    await Future.delayed(Duration(milliseconds: UIConstants.animationDurationShort));
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
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const BioWayLoginScreen(),
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
        transitionDuration: Duration(milliseconds: UIConstants.animationDurationMedium),
      ),
    );
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
        transitionDuration: Duration(milliseconds: UIConstants.animationDurationMedium),
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
            borderRadius: BorderRadiusConstants.borderRadiusLarge,
          ),
          child: Container(
            padding: EdgeInsetsConstants.paddingAll24,
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: UIConstants.iconSizeDialog + UIConstants.spacing20,
                  height: UIConstants.iconSizeDialog + UIConstants.spacing20,
                  decoration: BoxDecoration(
                    color: BioWayColors.info.withValues(alpha: UIConstants.opacityLow),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rocket_launch,
                    size: UIConstants.buttonHeightMedium,
                    color: BioWayColors.info,
                  ),
                ),
                SizedBox(height: UIConstants.spacing20),
                const Text(
                  '¡Próximamente!',
                  style: TextStyle(
                    fontSize: UIConstants.fontSizeXLarge,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
                SizedBox(height: UIConstants.spacing12),
                Text(
                  'Estamos trabajando para integrar más plataformas de reciclaje y sostenibilidad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: UIConstants.fontSizeBody,
                    color: BioWayColors.textGrey,
                    height: UIConstants.lineHeightMedium,
                  ),
                ),
                SizedBox(height: UIConstants.spacing24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UIConstants.spacing10),
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
                padding: EdgeInsetsConstants.paddingAll16,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _navigateBack,
                      icon: Container(
                        padding: EdgeInsetsConstants.paddingAll8,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: UIConstants.opacityAlmostFull),
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: UIConstants.opacityLow),
                              blurRadius: UIConstants.blurRadiusMedium,
                              offset: Offset(0, UIConstants.offsetY),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: BioWayColors.darkGreen,
                          size: UIConstants.iconSizeSmall,
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
                  padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing24),
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
                                    width: UIConstants.iconSizeDialog + UIConstants.spacing20,
                                    height: UIConstants.iconSizeDialog + UIConstants.spacing20,
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
                                              .withValues(alpha: UIConstants.opacityMedium),
                                          blurRadius: UIConstants.blurRadiusLarge,
                                          offset: Offset(0, UIConstants.spacing8),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.apps,
                                      size: UIConstants.buttonHeightMedium,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: UIConstants.spacing24),

                                  // Título
                                  const Text(
                                    'Selecciona tu Plataforma',
                                    style: TextStyle(
                                      fontSize: UIConstants.fontSizeXXLarge,
                                      fontWeight: FontWeight.bold,
                                      color: BioWayColors.darkGreen,
                                    ),
                                  ),
                                  SizedBox(height: UIConstants.spacing12),

                                  // Subtítulo
                                  Text(
                                    'Elige el servicio al que deseas acceder',
                                    style: TextStyle(
                                      fontSize: UIConstants.fontSizeBody,
                                      color: BioWayColors.darkGreen.withValues(alpha: UIConstants.opacityVeryHigh - 0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: UIConstants.spacing40),

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
                                              width: UIConstants.iconSizeLarge + 3,
                                              height: UIConstants.iconSizeLarge + 3,
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
                                  SizedBox(height: UIConstants.spacing16),

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
                                              width: UIConstants.iconSizeLarge + 3,
                                              height: UIConstants.iconSizeLarge + 3,
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
                                  SizedBox(height: UIConstants.spacing16),

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

                      SizedBox(height: UIConstants.spacing40),

                      // Información adicional animada
                      AnimatedBuilder(
                        animation: _infoController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _infoFadeAnimation,
                            child: Container(
                              padding: EdgeInsetsConstants.paddingAll20,
                              margin: EdgeInsets.only(bottom: UIConstants.spacing20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: UIConstants.opacityAlmostFull),
                                borderRadius: BorderRadiusConstants.borderRadiusLarge,
                                border: Border.all(
                                  color: BioWayColors.primaryGreen.withValues(alpha: UIConstants.opacityMediumLow),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(UIConstants.spacing8 + 2),
                                    decoration: BoxDecoration(
                                      color: BioWayColors.info.withValues(alpha: UIConstants.opacityLow),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      color: BioWayColors.info,
                                      size: UIConstants.iconSizeMedium,
                                    ),
                                  ),
                                  SizedBox(width: UIConstants.spacing16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Múltiples sistemas, una app',
                                          style: TextStyle(
                                            fontSize: UIConstants.fontSizeMedium,
                                            fontWeight: FontWeight.bold,
                                            color: BioWayColors.darkGreen,
                                          ),
                                        ),
                                        SizedBox(height: UIConstants.spacing4),
                                        Text(
                                          'Cada plataforma tiene su propio sistema de autenticación y base de datos independiente.',
                                          style: TextStyle(
                                            fontSize: UIConstants.fontSizeXSmall + 1,
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
        borderRadius: BorderRadiusConstants.borderRadiusLarge,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadiusConstants.borderRadiusLarge,
            border: Border.all(
              color: isDisabled ? Colors.grey.shade300 : Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDisabled
                    ? Colors.grey.withValues(alpha: UIConstants.opacityLow)
                    : Colors.black.withValues(alpha: UIConstants.opacityLow),
                blurRadius: UIConstants.elevationCard,
                offset: Offset(0, UIConstants.spacing4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icono
              Container(
                width: UIConstants.iconSizeDialog,
                height: UIConstants.iconSizeDialog,
                decoration: BoxDecoration(
                  color: isDisabled
                      ? Colors.grey.shade300
                      : iconColor.withValues(alpha: UIConstants.opacityLow),
                  shape: BoxShape.circle,
                ),
                child: iconWidget ?? Icon(
                  icon!,
                  color: isDisabled ? Colors.grey.shade500 : iconColor,
                  size: UIConstants.iconSizeLarge - 2,
                ),
              ),
              SizedBox(width: UIConstants.spacing16),

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
                            fontSize: UIConstants.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: isDisabled
                                ? Colors.grey.shade500
                                : BioWayColors.darkGreen,
                          ),
                        ),
                        if (badge != null) ...[
                          SizedBox(width: UIConstants.spacing8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: UIConstants.spacing8,
                              vertical: UIConstants.spacing4 / 2,
                            ),
                            decoration: BoxDecoration(
                              color: (badgeColor ?? iconColor).withValues(alpha: UIConstants.opacityLow),
                              borderRadius: BorderRadiusConstants.borderRadiusMedium,
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeXSmall,
                                fontWeight: FontWeight.w600,
                                color: badgeColor ?? iconColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeSmall,
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