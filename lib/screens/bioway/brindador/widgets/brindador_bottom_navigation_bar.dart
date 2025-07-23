import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../utils/colors.dart';

class BrindadorBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BrindadorBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Inicio',
                isSelected: currentIndex == 0,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.store_rounded,
                label: 'Comercio',
                isSelected: currentIndex == 1,
              ),
              _buildNavItem(
                index: 2,
                svgAsset: 'assets/logos/bioway_logo.svg',
                label: 'Perfil',
                isSelected: currentIndex == 2,
                isSvg: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    IconData? icon,
    String? svgAsset,
    required String label,
    required bool isSelected,
    bool isSvg = false,
  }) {
    final color = isSelected ? BioWayColors.primaryGreen : Colors.grey.shade600;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? BioWayColors.primaryGreen.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSvg && svgAsset != null)
                SvgPicture.asset(
                  svgAsset,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}