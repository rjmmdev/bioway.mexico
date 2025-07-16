import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

// Modelo para los items de navegación
class NavigationItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  NavigationItem({
    required this.icon,
    required this.label,
    this.onTap,
  });
}

class CustomBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final List<NavigationItem> items;
  final Color selectedColor;
  final Color unselectedColor;
  final bool hasFloatingButton;
  final Widget? floatingButton;
  final FloatingActionButtonLocation? floatingButtonLocation;

  const CustomBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.items,
    this.selectedColor = BioWayColors.ecoceGreen,
    this.unselectedColor = Colors.grey,
    this.hasFloatingButton = false,
    this.floatingButton,
    this.floatingButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sombra del bottom navigation
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
            shape: hasFloatingButton ? const CircularNotchedRectangle() : null,
            notchMargin: hasFloatingButton ? 8 : 0,
            color: Colors.white,
            child: SizedBox(
              height: 65,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _buildNavigationItems(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildNavigationItems() {
    List<Widget> widgets = [];
    
    for (int i = 0; i < items.length; i++) {
      // Si hay un botón flotante en el centro y estamos en la mitad
      if (hasFloatingButton && i == items.length ~/ 2) {
        widgets.add(const SizedBox(width: 80)); // Espacio para el FAB
      }
      
      widgets.add(
        _buildNavItem(
          icon: items[i].icon,
          label: items[i].label,
          isSelected: selectedIndex == i,
          onTap: items[i].onTap,
        ),
      );
    }
    
    return widgets;
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? selectedColor : unselectedColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? selectedColor : unselectedColor,
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

// Widget que combina el Scaffold con la navegación inferior y el FAB opcional
class ScaffoldWithBottomNavigation extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final int selectedIndex;
  final List<NavigationItem> navigationItems;
  final Color selectedColor;
  final Color unselectedColor;
  final bool hasFloatingButton;
  final Widget? floatingButton;
  final FloatingActionButtonLocation floatingButtonLocation;

  const ScaffoldWithBottomNavigation({
    super.key,
    required this.body,
    this.appBar,
    this.backgroundColor,
    required this.selectedIndex,
    required this.navigationItems,
    this.selectedColor = BioWayColors.ecoceGreen,
    this.unselectedColor = Colors.grey,
    this.hasFloatingButton = false,
    this.floatingButton,
    this.floatingButtonLocation = FloatingActionButtonLocation.centerDocked,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: body,
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: selectedIndex,
        items: navigationItems,
        selectedColor: selectedColor,
        unselectedColor: unselectedColor,
        hasFloatingButton: hasFloatingButton,
      ),
      floatingActionButton: hasFloatingButton ? floatingButton : null,
      floatingActionButtonLocation: hasFloatingButton ? floatingButtonLocation : null,
    );
  }
}