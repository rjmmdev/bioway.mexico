import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

class SectionCard extends StatelessWidget {
  final String icon;
  final String title;
  final List<Widget> children;
  final Color? titleColor;
  final EdgeInsetsGeometry? padding;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.titleColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sectionPadding = padding ?? EdgeInsets.all(screenWidth * 0.035);
    
    return Container(
      width: double.infinity,
      padding: sectionPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor ?? BioWayColors.darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}