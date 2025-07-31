import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

class RequiredFieldLabel extends StatelessWidget {
  final String label;
  final TextStyle? labelStyle;
  
  const RequiredFieldLabel({
    Key? key,
    required this.label,
    this.labelStyle,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: labelStyle ?? TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '*',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: BioWayColors.error,
          ),
        ),
      ],
    );
  }
}

/// Extension para facilitar el uso con InputDecoration
extension RequiredFieldExtension on String {
  Widget toRequiredLabel({TextStyle? style}) {
    return RequiredFieldLabel(label: this, labelStyle: style);
  }
  
  /// Crea un InputDecoration con label obligatorio
  InputDecoration toRequiredInputDecoration({
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool filled = true,
    Color? fillColor,
  }) {
    return InputDecoration(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(this),
          Text(
            ' *',
            style: TextStyle(
              color: BioWayColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: filled,
      fillColor: fillColor ?? Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: BioWayColors.primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: BioWayColors.error),
      ),
    );
  }
}