import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';
import 'required_field_label.dart';

/// Unified container widget that supports multiple layout variants
/// Combines functionality from gradient_header.dart, section_card.dart, and GradientContainer
class UnifiedContainer extends StatelessWidget {
  // Common properties
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final List<Widget>? children;
  
  // Variant-specific properties
  final ContainerVariant variant;
  
  // Header properties (for header variant)
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final List<Widget>? actions;
  final double? height;
  final List<Color>? gradientColors;
  final bool useResponsiveSizing;
  
  // Section properties (for section variant)
  final String? sectionIcon; // Emoji icon
  final Color? titleColor;
  final bool isRequired;
  
  // Styling properties
  final Color? backgroundColor;
  final Color? primaryColor;
  final bool showShadow;
  final List<BoxShadow>? customShadow;
  final bool enableTap;
  final VoidCallback? onTap;
  
  const UnifiedContainer({
    super.key,
    this.child,
    this.padding,
    this.borderRadius,
    this.children,
    this.variant = ContainerVariant.basic,
    // Header properties
    this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.actions,
    this.height,
    this.gradientColors,
    this.useResponsiveSizing = true,
    // Section properties
    this.sectionIcon,
    this.titleColor,
    this.isRequired = false,
    // Styling
    this.backgroundColor,
    this.primaryColor,
    this.showShadow = true,
    this.customShadow,
    this.enableTap = false,
    this.onTap,
  });

  // Factory constructors for backward compatibility
  factory UnifiedContainer.gradient({
    required Widget child,
    EdgeInsetsGeometry? padding,
    Color? primaryColor,
    double? borderRadius,
  }) {
    return UnifiedContainer(
      variant: ContainerVariant.gradient,
      child: child,
      padding: padding,
      primaryColor: primaryColor,
      borderRadius: BorderRadius.circular(borderRadius ?? 16),
    );
  }

  factory UnifiedContainer.header({
    required String title,
    String? subtitle,
    IconData? icon,
    List<Widget>? actions,
    double? height,
    Widget? child,
    List<Color>? gradientColors,
    Widget? trailing,
    bool useResponsiveSizing = true,
    BorderRadius? borderRadius,
  }) {
    return UnifiedContainer(
      variant: ContainerVariant.header,
      title: title,
      subtitle: subtitle,
      icon: icon,
      actions: actions,
      height: height,
      child: child,
      gradientColors: gradientColors,
      trailing: trailing,
      useResponsiveSizing: useResponsiveSizing,
      borderRadius: borderRadius,
    );
  }

  factory UnifiedContainer.section({
    required String icon,
    required String title,
    required List<Widget> children,
    Color? titleColor,
    EdgeInsetsGeometry? padding,
    bool isRequired = false,
  }) {
    return UnifiedContainer(
      variant: ContainerVariant.section,
      sectionIcon: icon,
      title: title,
      children: children,
      titleColor: titleColor,
      padding: padding,
      isRequired: isRequired,
    );
  }

  @override
  Widget build(BuildContext context) {
    final container = _buildContainer(context);
    
    if (enableTap && onTap != null) {
      return InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        borderRadius: _getEffectiveBorderRadius(context),
        child: container,
      );
    }
    
    return container;
  }

  Widget _buildContainer(BuildContext context) {
    switch (variant) {
      case ContainerVariant.basic:
        return _buildBasicContainer(context);
      case ContainerVariant.gradient:
        return _buildGradientContainer(context);
      case ContainerVariant.header:
        return _buildHeaderContainer(context);
      case ContainerVariant.section:
        return _buildSectionContainer(context);
    }
  }

  Widget _buildBasicContainer(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: _getEffectiveBorderRadius(context),
        boxShadow: showShadow 
            ? (customShadow ?? _getDefaultShadow()) 
            : null,
      ),
      child: child ?? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children ?? [],
      ),
    );
  }

  Widget _buildGradientContainer(BuildContext context) {
    final color = primaryColor ?? BioWayColors.petBlue;
    
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ?? [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: _getEffectiveBorderRadius(context),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildHeaderContainer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate responsive height if not provided
    final containerHeight = height ?? (useResponsiveSizing ? screenHeight * 0.25 : 200);
    
    // Use provided colors or default
    final colors = gradientColors ?? [
      primaryColor ?? BioWayColors.ecoceGreen,
      (primaryColor ?? BioWayColors.ecoceGreen).withValues(alpha: 0.8),
    ];
    
    // Use provided border radius or default
    final radius = borderRadius ?? const BorderRadius.only(
      bottomLeft: Radius.circular(30),
      bottomRight: Radius.circular(30),
    );
    
    return Container(
      height: containerHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: radius,
        boxShadow: showShadow ? _getHeaderShadow() : null,
      ),
      child: SafeArea(
        child: Padding(
          padding: padding ?? EdgeInsets.all(useResponsiveSizing ? screenWidth * 0.05 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (actions != null || trailing != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildHeaderContent(context),
                    ),
                    if (trailing != null) trailing!,
                    if (actions != null) ...actions!,
                  ],
                )
              else
                _buildHeaderContent(context),
              if (child != null) ...[
                SizedBox(height: useResponsiveSizing ? screenHeight * 0.02 : 20),
                Expanded(child: child!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: Colors.white,
            size: useResponsiveSizing ? screenWidth * 0.1 : 40,
          ),
          SizedBox(height: useResponsiveSizing ? screenWidth * 0.025 : 10),
        ],
        if (title != null)
          Text(
            title!,
            style: TextStyle(
              fontSize: useResponsiveSizing ? screenWidth * 0.07 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        if (subtitle != null) ...[
          SizedBox(height: useResponsiveSizing ? screenWidth * 0.012 : 5),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: useResponsiveSizing ? screenWidth * 0.04 : 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionContainer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sectionPadding = padding ?? EdgeInsets.all(screenWidth * 0.035);
    
    return Container(
      width: double.infinity,
      padding: sectionPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: _getEffectiveBorderRadius(context),
        boxShadow: showShadow ? _getDefaultShadow() : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || sectionIcon != null)
            Row(
              children: [
                if (sectionIcon != null) ...[
                  Text(
                    sectionIcon!,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 10),
                ],
                if (title != null)
                  isRequired
                    ? RequiredFieldLabel(
                        label: title!,
                        labelStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: titleColor ?? BioWayColors.darkGreen,
                        ),
                      )
                    : Text(
                        title!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: titleColor ?? BioWayColors.darkGreen,
                        ),
                      ),
              ],
            ),
          if (title != null || sectionIcon != null)
            const SizedBox(height: 20),
          if (children != null) ...children!,
          if (child != null) child!,
        ],
      ),
    );
  }

  BorderRadius _getEffectiveBorderRadius(BuildContext context) {
    if (borderRadius != null) return borderRadius!;
    
    final screenWidth = MediaQuery.of(context).size.width;
    
    switch (variant) {
      case ContainerVariant.section:
        return BorderRadius.circular(screenWidth * 0.04);
      case ContainerVariant.header:
        return const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        );
      default:
        return BorderRadius.circular(16);
    }
  }

  List<BoxShadow> _getDefaultShadow() {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ];
  }

  List<BoxShadow> _getHeaderShadow() {
    return [
      BoxShadow(
        color: (primaryColor ?? BioWayColors.ecoceGreen).withValues(alpha: 0.3),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ];
  }
}

/// Container variant types
enum ContainerVariant {
  basic,     // Simple container with optional shadow
  gradient,  // Container with gradient background (GradientContainer)
  header,    // Header with gradient and content (GradientHeader)
  section,   // Section with icon and title (SectionCard)
}

// Backward compatibility classes
class GradientContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? primaryColor;
  final double? borderRadius;

  const GradientContainer({
    super.key,
    required this.child,
    this.padding,
    this.primaryColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedContainer.gradient(
      child: child,
      padding: padding,
      primaryColor: primaryColor,
      borderRadius: borderRadius,
    );
  }
}

class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget>? actions;
  final double? height;
  final Widget? child;
  final List<Color>? gradientColors;
  final Widget? trailing;
  final bool useResponsiveSizing;
  final BorderRadius? borderRadius;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actions,
    this.height,
    this.child,
    this.gradientColors,
    this.trailing,
    this.useResponsiveSizing = true,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedContainer.header(
      title: title,
      subtitle: subtitle,
      icon: icon,
      actions: actions,
      height: height,
      child: child,
      gradientColors: gradientColors,
      trailing: trailing,
      useResponsiveSizing: useResponsiveSizing,
      borderRadius: borderRadius,
    );
  }
}

class SectionCard extends StatelessWidget {
  final String icon;
  final String title;
  final List<Widget> children;
  final Color? titleColor;
  final EdgeInsetsGeometry? padding;
  final bool isRequired;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.titleColor,
    this.padding,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedContainer.section(
      icon: icon,
      title: title,
      children: children,
      titleColor: titleColor,
      padding: padding,
      isRequired: isRequired,
    );
  }
}