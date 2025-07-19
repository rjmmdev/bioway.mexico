import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Header con gradiente reutilizable
class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Color> gradientColors;
  final Widget? trailing;
  final List<Widget>? actions;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.gradientColors,
    this.trailing,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.02,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: screenHeight * 0.005),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
          if (actions != null) ...[
            SizedBox(height: screenHeight * 0.01),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Modal bottom sheet estándar
class StandardBottomSheet extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;

  const StandardBottomSheet({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Content
            content,
            if (actions != null) ...[
              const SizedBox(height: 20),
              ...actions!,
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de información con estilo consistente
class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: iconColor ?? Colors.grey[600],
                size: 24,
              ),
              SizedBox(width: screenWidth * 0.03),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: const Color(0xFF606060),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip de estado reutilizable
class StatusChip extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final String? testKey;

  const StatusChip({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.testKey,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      key: testKey != null ? Key(testKey!) : null,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenHeight * 0.005,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: screenWidth * 0.03,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Botón con haptic feedback integrado
class HapticButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;

  const HapticButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      style: style,
      child: child,
    );
  }
}

/// InkWell con haptic feedback integrado
class HapticInkWell extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final BorderRadius? borderRadius;

  const HapticInkWell({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: borderRadius,
      child: child,
    );
  }
}