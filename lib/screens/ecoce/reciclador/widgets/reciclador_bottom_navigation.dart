import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';

class RecicladorBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onFabPressed;

  const RecicladorBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onFabPressed,
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
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            color: Colors.white,
            child: SizedBox(
              height: 65,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBottomNavItem(Icons.home_outlined, Icons.home, 'Inicio', 0),
                  _buildBottomNavItem(Icons.inventory_2_outlined, Icons.inventory_2, 'Lotes', 1),
                  const SizedBox(width: 80), // Espacio para el FAB
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
                color: isSelected ? BioWayColors.ecoceGreen : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? BioWayColors.ecoceGreen : Colors.grey,
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

class RecicladorFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const RecicladorFloatingActionButton({
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
            BioWayColors.ecoceGreen,
            BioWayColors.ecoceGreen.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: BioWayColors.ecoceGreen.withValues(alpha: 0.3),
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
          Icons.add,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Función helper para navegación con transiciones suaves
class NavigationHelper {
  static Future<T?> navigateWithSlideTransition<T>({
    required BuildContext context,
    required Widget destination,
    Offset begin = const Offset(1.0, 0.0),
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: duration,
      ),
    );
  }

  static Future<T?> navigateWithFadeTransition<T>({
    required BuildContext context,
    required Widget destination,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: duration,
      ),
    );
  }

  static Future<T?> navigateWithReplacement<T>({
    required BuildContext context,
    required Widget destination,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return Navigator.pushReplacement<T, T>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: duration,
      ),
    );
  }
}