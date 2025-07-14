import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';

/// Tarjeta interactiva para mostrar opciones de plataforma
class PlatformOptionCard extends StatefulWidget {
  /// Icono de la plataforma
  final IconData icon;

  /// Color del icono y elementos destacados
  final Color iconColor;

  /// Título de la plataforma
  final String title;

  /// Descripción de la plataforma
  final String description;

  /// Callback al tocar la tarjeta
  final VoidCallback onTap;

  /// Si la tarjeta está deshabilitada
  final bool isDisabled;

  /// Etiqueta opcional (badge)
  final String? badge;

  /// Color de la etiqueta
  final Color? badgeColor;

  /// Si debe mostrar una flecha
  final bool showArrow;

  const PlatformOptionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
    this.isDisabled = false,
    this.badge,
    this.badgeColor,
    this.showArrow = true,
  });

  @override
  State<PlatformOptionCard> createState() => _PlatformOptionCardState();
}

class _PlatformOptionCardState extends State<PlatformOptionCard>
    with SingleTickerProviderStateMixin {
  // Controlador de animación
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  // Estados
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isDisabled) {
      HapticFeedback.lightImpact();
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isDisabled) {
      setState(() => _isPressed = false);
      _animationController.reverse();
      widget.onTap();
    }
  }

  void _handleTapCancel() {
    if (!widget.isDisabled) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: EdgeInsets.only(
                  bottom: 8.0 * _elevationAnimation.value,
                ),
                child: Stack(
                  children: [
                    // Sombra animada
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: widget.isDisabled
                                  ? Colors.grey.withOpacity(0.1)
                                  : widget.iconColor.withOpacity(
                                  0.2 + (0.1 * _elevationAnimation.value)),
                              blurRadius: 20 + (10 * _elevationAnimation.value),
                              offset: Offset(
                                0,
                                8 + (4 * _elevationAnimation.value),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tarjeta principal
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: widget.isDisabled
                            ? Colors.grey.shade100
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.isDisabled
                              ? Colors.grey.shade300
                              : _isHovered || _isPressed
                              ? widget.iconColor.withOpacity(0.3)
                              : Colors.grey.shade200,
                          width: _isHovered || _isPressed ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icono con fondo
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: widget.isDisabled
                                  ? Colors.grey.shade300
                                  : widget.iconColor.withOpacity(
                                  _isHovered || _isPressed ? 0.15 : 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.isDisabled
                                  ? Colors.grey.shade500
                                  : widget.iconColor,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Contenido de texto
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.title,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: widget.isDisabled
                                            ? Colors.grey.shade500
                                            : BioWayColors.darkGreen,
                                      ),
                                    ),
                                    if (widget.badge != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (widget.badgeColor ?? widget.iconColor)
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          widget.badge!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: widget.badgeColor ?? widget.iconColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: widget.isDisabled
                                        ? Colors.grey.shade400
                                        : BioWayColors.textGrey,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Flecha o icono de estado
                          if (!widget.isDisabled && widget.showArrow)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (_isHovered || _isPressed)
                                    ? widget.iconColor.withOpacity(0.1)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: (_isHovered || _isPressed)
                                    ? widget.iconColor
                                    : Colors.grey.shade400,
                                size: 18,
                              ),
                            ),

                          if (widget.isDisabled)
                            Icon(
                              Icons.lock_outline,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                        ],
                      ),
                    ),

                    // Badge de "Nuevo" o destacado
                    if (!widget.isDisabled && widget.badge == null)
                      Positioned(
                        top: -5,
                        right: 20,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _isHovered ? 1.0 : 0.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.iconColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.iconColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Seleccionar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Versión simplificada de la tarjeta para listas
class SimplePlatformCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isSelected;

  const SimplePlatformCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? iconColor.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? iconColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: BioWayColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: BioWayColors.success,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}