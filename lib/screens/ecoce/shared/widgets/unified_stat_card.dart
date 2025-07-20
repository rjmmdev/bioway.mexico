import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Unified stat card widget that supports multiple layout variants
/// Combines functionality from stat_card.dart and statistic_card.dart
class UnifiedStatCard extends StatelessWidget {
  // Common properties
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  
  // Optional properties
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final String? unit;
  final StatCardVariant variant;
  final bool showBackgroundIcon;
  final bool enableHaptic;
  
  const UnifiedStatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.backgroundColor,
    this.onTap,
    this.width,
    this.height,
    this.unit,
    this.variant = StatCardVariant.vertical,
    this.showBackgroundIcon = false,
    this.enableHaptic = true,
  });

  // Factory constructors for backward compatibility
  factory UnifiedStatCard.vertical({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    Color? backgroundColor,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return UnifiedStatCard(
      icon: icon,
      iconColor: iconColor,
      value: value,
      label: label,
      backgroundColor: backgroundColor,
      onTap: onTap,
      width: width,
      height: height,
      variant: StatCardVariant.vertical,
    );
  }

  factory UnifiedStatCard.horizontal({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    double? width,
    double? height,
    String? unit,
    bool showBackgroundIcon = true,
  }) {
    return UnifiedStatCard(
      icon: icon,
      iconColor: color,
      value: value,
      label: title,
      onTap: onTap,
      width: width,
      height: height,
      unit: unit,
      variant: StatCardVariant.horizontal,
      showBackgroundIcon: showBackgroundIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = variant == StatCardVariant.vertical
        ? _buildVerticalLayout(context)
        : _buildHorizontalLayout(context);

    if (onTap != null) {
      return InkWell(
        onTap: () {
          if (enableHaptic) {
            HapticFeedback.lightImpact();
          }
          onTap!();
        },
        borderRadius: BorderRadius.circular(20),
        child: card,
      );
    }

    return card;
  }

  Widget _buildVerticalLayout(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          _buildValueWithUnit(
            fontSize: 32,
            unitFontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    final effectiveHeight = height ?? 70;
    final isCompact = effectiveHeight < 100;
    
    // Determine background gradient color
    final backgroundGradientColor = _getBackgroundGradientColor();
    
    return Container(
      width: width,
      height: effectiveHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor ?? Colors.white,
            backgroundGradientColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative icon
          if (showBackgroundIcon)
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                _getOutlinedIcon(),
                size: 60,
                color: iconColor.withValues(alpha: 0.05),
              ),
            ),
          // Content
          Padding(
            padding: EdgeInsets.all(isCompact ? 12.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: isCompact ? 32 : 32,
                      height: isCompact ? 32 : 32,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: isCompact ? 18 : 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildValueWithUnit(
                            fontSize: isCompact ? 20 : 20,
                            unitFontSize: isCompact ? 14 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: isCompact ? 11 : 11,
                              color: Colors.grey[600],
                              height: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueWithUnit({
    required double fontSize,
    required double unitFontSize,
    required FontWeight fontWeight,
  }) {
    if (unit != null) {
      return Row(
        textBaseline: TextBaseline.alphabetic,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: Colors.black87,
              height: 1,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            unit!,
            style: TextStyle(
              fontSize: unitFontSize,
              fontWeight: FontWeight.w600,
              color: iconColor,
              height: 1,
            ),
          ),
        ],
      );
    }
    
    return Text(
      value,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: Colors.black87,
        height: 1,
      ),
    );
  }

  Color _getBackgroundGradientColor() {
    if (iconColor == Colors.blue) {
      return Colors.blue.shade50;
    } else if (iconColor == Colors.green) {
      return Colors.green.shade50;
    } else if (iconColor == Colors.purple) {
      return Colors.purple.shade50;
    } else if (iconColor == Colors.orange) {
      return Colors.orange.shade50;
    } else {
      return iconColor.withValues(alpha: 0.05);
    }
  }

  IconData _getOutlinedIcon() {
    switch (icon) {
      case Icons.inbox:
        return Icons.inbox_outlined;
      case Icons.add_box:
        return Icons.add_box_outlined;
      case Icons.scale:
        return Icons.scale_outlined;
      case Icons.inventory_2:
        return Icons.inventory_2_outlined;
      default:
        return icon;
    }
  }
}

/// Layout variant for the stat card
enum StatCardVariant {
  vertical,   // Original stat_card.dart layout
  horizontal, // Original statistic_card.dart layout
}

// Backward compatibility typedefs
typedef StatCard = UnifiedStatCard;
typedef StatisticCard = UnifiedStatCard;