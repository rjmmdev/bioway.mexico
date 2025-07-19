import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/colors.dart';

/// Logo animado de BioWay con indicador de switch para cambiar de plataforma
class AnimatedLogo extends StatefulWidget {
  /// Callback cuando se toca el logo
  final VoidCallback onTap;

  /// Tamaño del logo (ancho y alto)
  final double size;

  /// Si debe mostrar el indicador de switch
  final bool showSwitchIndicator;

  /// Si debe mostrar el texto debajo del logo
  final bool showText;

  const AnimatedLogo({
    super.key,
    required this.onTap,
    this.size = 80,
    this.showSwitchIndicator = true,
    this.showText = true,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  // Controladores de animación
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _bounceController;

  // Animaciones
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _bounceAnimation;

  // Estados
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Controlador para el pulso del indicador
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Controlador para la rotación del icono de switch
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Controlador para el efecto bounce al presionar
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
    _bounceController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _bounceController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _bounceController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo con indicador
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _bounceAnimation.value,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Sombra animada del logo
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: BioWayColors.primaryGreen.withValues(
                                alpha: _isPressed ? 0.6 : _isHovered ? 0.5 : 0.3,
                              ),
                              blurRadius: _isPressed ? 30 : _isHovered ? 25 : 20,
                              spreadRadius: _isPressed ? 8 : _isHovered ? 6 : 4,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),

                      // Logo principal
                      SvgPicture.asset(
                        'assets/logos/bioway_logo.svg',
                        width: widget.size,
                        height: widget.size,
                      ),

                      // Indicador de switch animado
                      if (widget.showSwitchIndicator)
                        Positioned(
                          right: -widget.size * 0.05,
                          top: -widget.size * 0.05,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: widget.size * 0.25,
                                  height: widget.size * 0.25,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        BioWayColors.switchBlue,
                                        BioWayColors.switchBlueLight,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: BioWayColors.switchBlue.withValues(alpha: 0.6),
                                        blurRadius: 12,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _rotationAnimation,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _rotationAnimation.value,
                                        child: Icon(
                                          Icons.sync,
                                          size: widget.size * 0.12,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // Anillos decorativos animados
                      if (_isHovered || _isPressed)
                        ...List.generate(2, (index) {
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 300 + (index * 100)),
                            width: widget.size + ((index + 1) * 20),
                            height: widget.size + ((index + 1) * 20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: BioWayColors.primaryGreen.withValues(
                                  alpha: 0.3 - (index * 0.15),
                                ),
                                width: 1,
                              ),
                            ),
                          );
                        }),
                    ],
                    alignment: Alignment.center,
                  ),
                );
              },
            ),

            if (widget.showText) ...[
              const SizedBox(height: 6),

              // Texto BioWay con indicador
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _isHovered || _isPressed
                          ? BioWayColors.primaryGreen
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'BioWay',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Subtítulo con instrucción
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 14,
                  color: _isHovered || _isPressed
                      ? BioWayColors.primaryGreen
                      : BioWayColors.darkGreen.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
                child: const Text('Toca para cambiar plataforma'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}