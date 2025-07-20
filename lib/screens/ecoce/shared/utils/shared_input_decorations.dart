import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

/// Shared input decorations for consistent form styling across the app
class SharedInputDecorations {
  /// ECOCE style input decoration with customizable colors
  static InputDecoration ecoceStyle({
    String? hintText,
    String? labelText,
    String? helperText,
    String? errorText,
    dynamic prefixIcon,
    Widget? suffixIcon,
    Color primaryColor = BioWayColors.ecoceGreen,
    bool filled = true,
    Color? fillColor,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon is IconData
          ? Icon(prefixIcon as IconData, color: primaryColor.withValues(alpha: 0.7))
          : prefixIcon,
      suffixIcon: suffixIcon,
      filled: filled,
      fillColor: fillColor ?? Colors.grey[50],
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: BioWayColors.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: BioWayColors.error,
          width: 2,
        ),
      ),
      labelStyle: TextStyle(
        color: primaryColor.withValues(alpha: 0.8),
        fontSize: 14,
      ),
      hintStyle: TextStyle(
        color: Colors.grey[500],
        fontSize: 14,
      ),
      errorStyle: const TextStyle(
        color: BioWayColors.error,
        fontSize: 12,
      ),
    );
  }

  /// Minimal style for search fields
  static InputDecoration searchStyle({
    String? hintText,
    dynamic prefixIcon,
    Widget? suffixIcon,
    Color primaryColor = BioWayColors.ecoceGreen,
  }) {
    return InputDecoration(
      hintText: hintText ?? 'Buscar...',
      prefixIcon: prefixIcon ?? const Icon(Icons.search),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),
      hintStyle: TextStyle(
        color: Colors.grey[500],
        fontSize: 14,
      ),
    );
  }

  /// Underline style for minimal forms
  static InputDecoration underlineStyle({
    String? hintText,
    String? labelText,
    dynamic prefixIcon,
    Widget? suffixIcon,
    Color primaryColor = BioWayColors.ecoceGreen,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      border: UnderlineInputBorder(
        borderSide: BorderSide(
          color: Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: BioWayColors.error,
        ),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: BioWayColors.error,
          width: 2,
        ),
      ),
      labelStyle: TextStyle(
        color: primaryColor.withValues(alpha: 0.8),
        fontSize: 14,
      ),
      hintStyle: TextStyle(
        color: Colors.grey[500],
        fontSize: 14,
      ),
    );
  }
}