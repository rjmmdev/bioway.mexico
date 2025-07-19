import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

class SharedInputDecorations {
  static InputDecoration buildInputDecoration({
    required BuildContext context,
    required String hintText,
    Color? primaryColor,
    bool showCounter = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final borderRadius = screenWidth * 0.03;
    final color = primaryColor ?? BioWayColors.ecoceGreen;
    
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: BioWayColors.backgroundGrey,
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
}