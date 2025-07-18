import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Configuración para el FAB (Floating Action Button)
class FabConfig {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const FabConfig({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });
}

/// Item de navegación personalizable
class NavigationItem {
  final IconData icon;
  final String label;
  final String? testKey;

  const NavigationItem({
    required this.icon,
    required this.label,
    this.testKey,
  });
}

/// Widget de navegación inferior reutilizable para todos los tipos de usuario ECOCE
class EcoceBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final Color primaryColor;
  final List<NavigationItem> items;
  final FabConfig? fabConfig;

  const EcoceBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.primaryColor,
    required this.items,
    this.fabConfig,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth > 600;
    
    // Adaptive heights based on screen size
    final bottomBarHeight = isTablet ? 75.0 : (isSmallScreen ? 55.0 : 65.0);
    final notchMargin = fabConfig != null ? (isTablet ? 10.0 : 8.0) : 0.0;
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomAppBar(
        color: Colors.white,
        elevation: 0,
        notchMargin: notchMargin,
        shape: fabConfig != null ? const CircularNotchedRectangle() : null,
        child: Container(
          height: bottomBarHeight,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : (isSmallScreen ? 4 : 8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _buildNavigationItems(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNavigationItems(BuildContext context) {
    List<Widget> widgets = [];
    
    for (int i = 0; i < items.length; i++) {
      // Si hay FAB y estamos en el medio de los items, agregar espacio
      if (fabConfig != null && i == items.length ~/ 2) {
        widgets.add(const SizedBox(width: 40));
      }
      
      widgets.add(
        _buildNavItem(
          context: context,
          icon: items[i].icon,
          label: items[i].label,
          index: i,
          testKey: items[i].testKey,
        ),
      );
    }
    
    return widgets;
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    String? testKey,
  }) {
    final isSelected = selectedIndex == index;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth > 600;
    
    // Adaptive sizes
    final iconSize = isTablet ? 28.0 : (isSmallScreen ? 20.0 : 24.0);
    final fontSize = isTablet ? 14.0 : (isSmallScreen ? 10.0 : 12.0);
    final horizontalPadding = isSelected 
        ? (isTablet ? 24.0 : (isSmallScreen ? 16.0 : 20.0))
        : (isTablet ? 16.0 : (isSmallScreen ? 8.0 : 12.0));
    final verticalPadding = isTablet ? 10.0 : (isSmallScreen ? 6.0 : 8.0);
    
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onItemTapped(index);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          key: testKey != null ? Key(testKey) : null,
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 4 : 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? primaryColor : Colors.grey,
                  size: iconSize,
                ),
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? primaryColor : Colors.grey,
                    fontSize: fontSize,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget FAB reutilizable para ECOCE
class EcoceFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color backgroundColor;
  final String? tooltip;
  final String? heroTag;

  const EcoceFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.backgroundColor,
    this.tooltip,
    this.heroTag,
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
            backgroundColor,
            backgroundColor.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
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
        heroTag: heroTag ?? UniqueKey(),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
        shape: const CircleBorder(),
        tooltip: tooltip,
      ),
    );
  }
}

/// Configuraciones predefinidas para cada tipo de usuario
class EcoceNavigationConfigs {
  static List<NavigationItem> get origenItems => const [
    NavigationItem(
      icon: Icons.home,
      label: 'Inicio',
      testKey: 'origen_nav_inicio',
    ),
    NavigationItem(
      icon: Icons.inventory_2,
      label: 'Lotes',
      testKey: 'origen_nav_lotes',
    ),
    NavigationItem(
      icon: Icons.help_outline,
      label: 'Ayuda',
      testKey: 'origen_nav_ayuda',
    ),
    NavigationItem(
      icon: Icons.person,
      label: 'Perfil',
      testKey: 'origen_nav_perfil',
    ),
  ];

  static List<NavigationItem> get recicladorItems => const [
    NavigationItem(
      icon: Icons.home,
      label: 'Inicio',
      testKey: 'reciclador_nav_inicio',
    ),
    NavigationItem(
      icon: Icons.inventory_2,
      label: 'Lotes',
      testKey: 'reciclador_nav_lotes',
    ),
    NavigationItem(
      icon: Icons.help_outline,
      label: 'Ayuda',
      testKey: 'reciclador_nav_ayuda',
    ),
    NavigationItem(
      icon: Icons.person,
      label: 'Perfil',
      testKey: 'reciclador_nav_perfil',
    ),
  ];

  static List<NavigationItem> get transporteItems => const [
    NavigationItem(
      icon: Icons.qr_code_scanner,
      label: 'Recoger',
      testKey: 'transporte_nav_recoger',
    ),
    NavigationItem(
      icon: Icons.local_shipping,
      label: 'Entregar',
      testKey: 'transporte_nav_entregar',
    ),
    NavigationItem(
      icon: Icons.help_outline,
      label: 'Ayuda',
      testKey: 'transporte_nav_ayuda',
    ),
    NavigationItem(
      icon: Icons.person,
      label: 'Perfil',
      testKey: 'transporte_nav_perfil',
    ),
  ];
}