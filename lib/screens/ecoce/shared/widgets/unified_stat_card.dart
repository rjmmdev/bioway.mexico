import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/ui_constants.dart';

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
        borderRadius: BorderRadiusConstants.borderRadiusLarge,
        child: card,
      );
    }

    return card;
  }

  Widget _buildVerticalLayout(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsetsConstants.paddingAll20,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadiusConstants.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow + 0.03),
            blurRadius: UIConstants.blurRadiusLarge,
            offset: Offset(0, UIConstants.spacing10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: UIConstants.buttonHeightMedium + UIConstants.spacing4 + 1,
            height: UIConstants.buttonHeightMedium + UIConstants.spacing4 + 1,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: UIConstants.opacityLow),
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: UIConstants.iconSizeMedium,
            ),
          ),
          SizedBox(height: UIConstants.spacing12),
          _buildValueWithUnit(
            fontSize: UIConstants.fontSizeXXLarge,
            unitFontSize: UIConstants.fontSizeBody + 2,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: UIConstants.spacing4),
          Text(
            label,
            style: const TextStyle(
              fontSize: UIConstants.fontSizeSmall + 1,
              color: Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    final effectiveHeight = height ?? UIConstants.buttonHeightLarge + UIConstants.spacing16;
    final isCompact = effectiveHeight < 100;
    
    return Container(
      width: width,
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadiusConstants.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
            blurRadius: UIConstants.blurRadiusMedium,
            offset: Offset(0, UIConstants.spacing4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative icon
          if (showBackgroundIcon)
            Positioned(
              right: -UIConstants.spacing10,
              bottom: -UIConstants.spacing10,
              child: Icon(
                _getOutlinedIcon(),
                size: UIConstants.iconSizeDialog,
                color: iconColor.withValues(alpha: UIConstants.opacityVeryLow),
              ),
            ),
          // Content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? UIConstants.spacing10 : UIConstants.spacing12,
              vertical: isCompact ? UIConstants.spacing8 : UIConstants.spacing10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: isCompact ? UIConstants.iconSizeLarge : UIConstants.buttonHeightSmall,
                      height: isCompact ? UIConstants.iconSizeLarge : UIConstants.buttonHeightSmall,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: UIConstants.opacityLow),
                        borderRadius: BorderRadius.circular(UIConstants.spacing10),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: isCompact ? UIConstants.iconSizeBody : UIConstants.iconSizeBody + 2,
                      ),
                    ),
                    SizedBox(width: UIConstants.spacing10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: _buildValueWithUnit(
                              fontSize: isCompact ? UIConstants.fontSizeBody + 2 : UIConstants.fontSizeLarge,
                              unitFontSize: isCompact ? UIConstants.fontSizeSmall : UIConstants.fontSizeMedium,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: UIConstants.spacing4 / 2),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeSmall - 1,
                              color: Colors.grey[600],
                              height: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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
          SizedBox(width: UIConstants.spacing4),
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