import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/ui_constants.dart';

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
          topLeft: Radius.circular(UIConstants.borderRadiusXL),
          topRight: Radius.circular(UIConstants.borderRadiusXL),
        ),
      ),
      child: Padding(
        padding: EdgeInsetsConstants.paddingAll20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: UIConstants.buttonHeightMedium,
              height: UIConstants.spacing4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusTiny),
              ),
            ),
            SizedBox(height: UIConstants.spacing20),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: UIConstants.fontSizeBody + 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: UIConstants.spacing20),
            // Content
            content,
            if (actions != null) ...[
              SizedBox(height: UIConstants.spacing20),
              ...actions!,
            ],
            SizedBox(height: UIConstants.spacing10),
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
      borderRadius: BorderRadiusConstants.borderRadiusSmall,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadiusConstants.borderRadiusSmall,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
              blurRadius: UIConstants.blurRadiusSmall,
              offset: Offset(0, UIConstants.offsetY),
            ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: iconColor ?? Colors.grey[600],
                size: UIConstants.iconSizeMedium,
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
                  SizedBox(height: UIConstants.spacing4),
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
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: borderColor,
          width: UIConstants.borderWidthThin,
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