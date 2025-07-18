import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

class FieldLabel extends StatelessWidget {
  final String text;
  final bool isRequired;
  final Color? color;
  final double? fontSize;

  const FieldLabel({
    super.key,
    required this.text,
    this.isRequired = false,
    this.color,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize ?? 14,
            fontWeight: FontWeight.w600,
            color: color ?? BioWayColors.textGrey,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              fontSize: fontSize ?? 14,
              fontWeight: FontWeight.w600,
              color: BioWayColors.error,
            ),
          ),
        ],
      ],
    );
  }
}