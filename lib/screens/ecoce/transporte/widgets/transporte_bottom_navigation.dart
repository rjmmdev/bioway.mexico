import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';

class TransporteBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback? onFabPressed;

  const TransporteBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.onFabPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Bottom Navigation Bar
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomAppBar(
            shape: onFabPressed != null ? const CircularNotchedRectangle() : null,
            notchMargin: 8,
            color: Colors.white,
            child: SizedBox(
              height: 65,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBottomNavItem(Icons.qr_code_scanner_outlined, Icons.qr_code_scanner, 'Recoger', 0),
                  _buildBottomNavItem(Icons.local_shipping_outlined, Icons.local_shipping, 'Entregar', 1),
                  if (onFabPressed != null) const SizedBox(width: 80), // Espacio para el FAB
                  _buildBottomNavItem(Icons.help_outline, Icons.help, 'Ayuda', 2),
                  _buildBottomNavItem(Icons.person_outline, Icons.person, 'Perfil', 3),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onItemTapped(index);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? BioWayColors.deepBlue : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? BioWayColors.deepBlue : Colors.grey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransporteFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const TransporteFloatingActionButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BioWayColors.deepBlue,
            BioWayColors.deepBlue.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: BioWayColors.deepBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.qr_code_scanner,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }
}