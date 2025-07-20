import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

/// Decoraciones de entrada compartidas para mantener consistencia en toda la app
class SharedInputDecorations {
  // Radios de borde predefinidos
  static const double defaultBorderRadius = 12.0;
  static const double largeBorderRadius = 15.0;
  static const double smallBorderRadius = 8.0;
  
  /// Decoración estándar para campos de texto en ECOCE
  static InputDecoration ecoceStyle({
    required String hintText,
    String? labelText,
    String? helperText,
    String? errorText,
    String? suffixText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconTap,
    Color? primaryColor,
    bool showCounter = false,
    double borderRadius = defaultBorderRadius,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final color = primaryColor ?? BioWayColors.ecoceGreen;
    
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      suffixText: suffixText,
      filled: true,
      fillColor: BioWayColors.backgroundGrey,
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: color.withValues(alpha: 0.7)) : null,
      suffixIcon: suffixIcon != null 
        ? IconButton(
            icon: Icon(suffixIcon, color: color.withValues(alpha: 0.7)),
            onPressed: onSuffixIconTap,
          ) 
        : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: color,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: BioWayColors.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: BioWayColors.error,
          width: 2,
        ),
      ),
      counterText: showCounter ? null : '',
    );
  }
  
  /// Decoración para campos de login/registro de BioWay
  static InputDecoration biowayStyle({
    required String hintText,
    String? labelText,
    String? errorText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconTap,
    bool showCounter = false,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      errorText: errorText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      prefixIcon: prefixIcon != null 
        ? Icon(prefixIcon, color: BioWayColors.primaryGreen.withValues(alpha: 0.7))
        : null,
      suffixIcon: suffixIcon != null 
        ? IconButton(
            icon: Icon(suffixIcon, color: BioWayColors.primaryGreen.withValues(alpha: 0.7)),
            onPressed: onSuffixIconTap,
          )
        : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(largeBorderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(largeBorderRadius),
        borderSide: BorderSide(
          color: BioWayColors.primaryGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(largeBorderRadius),
        borderSide: BorderSide(
          color: BioWayColors.primaryGreen,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(largeBorderRadius),
        borderSide: BorderSide(
          color: BioWayColors.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(largeBorderRadius),
        borderSide: BorderSide(
          color: BioWayColors.error,
          width: 2,
        ),
      ),
      counterText: showCounter ? null : '',
    );
  }
  
  /// Decoración para campos con etiqueta (estilo Material)
  static InputDecoration transportStyle({
    required String labelText,
    String? hintText,
    String? helperText,
    String? errorText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconTap,
    Color? primaryColor,
    bool showCounter = false,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final color = primaryColor ?? BioWayColors.ecoceGreen;
    
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      filled: true,
      fillColor: BioWayColors.backgroundGrey,
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: color.withValues(alpha: 0.7)) : null,
      suffixIcon: suffixIcon != null 
        ? IconButton(
            icon: Icon(suffixIcon, color: color.withValues(alpha: 0.7)),
            onPressed: onSuffixIconTap,
          )
        : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(smallBorderRadius),
        borderSide: BorderSide(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(smallBorderRadius),
        borderSide: BorderSide(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(smallBorderRadius),
        borderSide: BorderSide(
          color: color,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(smallBorderRadius),
        borderSide: BorderSide(
          color: BioWayColors.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(smallBorderRadius),
        borderSide: BorderSide(
          color: BioWayColors.error,
          width: 2,
        ),
      ),
      counterText: showCounter ? null : '',
    );
  }
  
  /// Decoración simple sin bordes (para diálogos, etc)
  static InputDecoration simpleStyle({
    required String hintText,
    String? labelText,
    String? errorText,
    double borderRadius = defaultBorderRadius,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      errorText: errorText,
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
  
  /// Método legacy para compatibilidad hacia atrás
  @Deprecated('Use ecoceStyle() instead')
  static InputDecoration buildInputDecoration({
    required BuildContext context,
    required String hintText,
    Color? primaryColor,
    bool showCounter = false,
  }) {
    return ecoceStyle(
      hintText: hintText,
      primaryColor: primaryColor,
      showCounter: showCounter,
    );
  }
}