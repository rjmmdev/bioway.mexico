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
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final bottomPadding = mediaQuery.padding.bottom;
    final viewPadding = mediaQuery.viewPadding.bottom;
    
    // Detectar diferentes tamaños de pantalla
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 360;
    final isVerySmallScreen = screenWidth < 320;
    final isCompactHeight = screenHeight < 700;
    final isVeryCompactHeight = screenHeight < 600;
    
    // Calcular altura adaptativa con más márgenes de seguridad
    double baseHeight;
    if (isVeryCompactHeight) {
      baseHeight = 56.0;
    } else if (isCompactHeight) {
      baseHeight = 60.0;
    } else if (isTablet) {
      baseHeight = 80.0;
    } else if (isSmallScreen) {
      baseHeight = 64.0;
    } else {
      baseHeight = 70.0;
    }
    
    // Ajustar el notch margin según el tamaño
    final notchMargin = fabConfig != null 
        ? (isTablet ? 12.0 : (isSmallScreen ? 6.0 : 8.0)) 
        : 0.0;
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomAppBar(
        color: Colors.white,
        elevation: 0,
        notchMargin: notchMargin,
        shape: fabConfig != null ? const CircularNotchedRectangle() : null,
        height: baseHeight + bottomPadding,
        padding: EdgeInsets.zero,
        child: Container(
          height: baseHeight + bottomPadding,
          padding: EdgeInsets.only(
            bottom: bottomPadding,
            left: isVerySmallScreen ? 2 : (isSmallScreen ? 4 : 8),
            right: isVerySmallScreen ? 2 : (isSmallScreen ? 4 : 8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
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
        widgets.add(const SizedBox(width: 56)); // Espacio para el FAB
      }
      
      widgets.add(
        Expanded(
          child: _buildNavItem(
            context: context,
            icon: items[i].icon,
            label: items[i].label,
            index: i,
            testKey: items[i].testKey,
          ),
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
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // Detectar tamaños de pantalla
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 360;
    final isVerySmallScreen = screenWidth < 320;
    final isCompactHeight = screenHeight < 700;
    final isVeryCompactHeight = screenHeight < 600;
    
    // Tamaños adaptativos optimizados para prevenir overflow
    double iconSize;
    double fontSize;
    double containerPadding;
    double spaceBetweenIconAndText;
    
    if (isVeryCompactHeight) {
      iconSize = 18.0;
      fontSize = 9.0;
      containerPadding = 4.0;
      spaceBetweenIconAndText = 2.0;
    } else if (isCompactHeight) {
      iconSize = 20.0;
      fontSize = 10.0;
      containerPadding = 6.0;
      spaceBetweenIconAndText = 2.0;
    } else if (isVerySmallScreen) {
      iconSize = 20.0;
      fontSize = 10.0;
      containerPadding = 6.0;
      spaceBetweenIconAndText = 3.0;
    } else if (isSmallScreen) {
      iconSize = 22.0;
      fontSize = 11.0;
      containerPadding = 8.0;
      spaceBetweenIconAndText = 3.0;
    } else if (isTablet) {
      iconSize = 28.0;
      fontSize = 13.0;
      containerPadding = 12.0;
      spaceBetweenIconAndText = 4.0;
    } else {
      iconSize = 24.0;
      fontSize = 12.0;
      containerPadding = 10.0;
      spaceBetweenIconAndText = 4.0;
    }
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onItemTapped(index);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          key: testKey != null ? Key(testKey) : null,
          padding: EdgeInsets.symmetric(
            vertical: containerPadding,
            horizontal: 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  color: isSelected ? primaryColor : Colors.grey[600],
                  size: iconSize,
                ),
              ),
              
              // Espacio entre icono y texto
              SizedBox(height: spaceBetweenIconAndText),
              
              // Texto con manejo de overflow
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isSelected ? primaryColor : Colors.grey[600],
                    fontSize: fontSize,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    height: 1.0, // Reducir altura de línea
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            backgroundColor.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
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
          size: isSmallScreen ? 24 : 28,
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
      icon: Icons.home_rounded,
      label: 'Inicio',
      testKey: 'origen_nav_inicio',
    ),
    NavigationItem(
      icon: Icons.inventory_2_rounded,
      label: 'Lotes',
      testKey: 'origen_nav_lotes',
    ),
    NavigationItem(
      icon: Icons.help_outline_rounded,
      label: 'Ayuda',
      testKey: 'origen_nav_ayuda',
    ),
    NavigationItem(
      icon: Icons.person_rounded,
      label: 'Perfil',
      testKey: 'origen_nav_perfil',
    ),
  ];

  static List<NavigationItem> get recicladorItems => const [
    NavigationItem(
      icon: Icons.home_rounded,
      label: 'Inicio',
      testKey: 'reciclador_nav_inicio',
    ),
    NavigationItem(
      icon: Icons.inventory_2_rounded,
      label: 'Lotes',
      testKey: 'reciclador_nav_lotes',
    ),
    NavigationItem(
      icon: Icons.help_outline_rounded,
      label: 'Ayuda',
      testKey: 'reciclador_nav_ayuda',
    ),
    NavigationItem(
      icon: Icons.person_rounded,
      label: 'Perfil',
      testKey: 'reciclador_nav_perfil',
    ),
  ];

  static List<NavigationItem> get transporteItems => const [
    NavigationItem(
      icon: Icons.qr_code_scanner_rounded,
      label: 'Recoger',
      testKey: 'transporte_nav_recoger',
    ),
    NavigationItem(
      icon: Icons.local_shipping_rounded,
      label: 'Entregar',
      testKey: 'transporte_nav_entregar',
    ),
    NavigationItem(
      icon: Icons.help_outline_rounded,
      label: 'Ayuda',
      testKey: 'transporte_nav_ayuda',
    ),
    NavigationItem(
      icon: Icons.person_rounded,
      label: 'Perfil',
      testKey: 'transporte_nav_perfil',
    ),
  ];
  
  static List<NavigationItem> get plantaSeparacionItems => const [
    NavigationItem(
      icon: Icons.home_rounded,
      label: 'Inicio',
      testKey: 'planta_nav_inicio',
    ),
    NavigationItem(
      icon: Icons.sort_rounded,
      label: 'Clasificar',
      testKey: 'planta_nav_clasificar',
    ),
    NavigationItem(
      icon: Icons.help_outline_rounded,
      label: 'Ayuda',
      testKey: 'planta_nav_ayuda',
    ),
    NavigationItem(
      icon: Icons.person_rounded,
      label: 'Perfil',
      testKey: 'planta_nav_perfil',
    ),
  ];
  
  static List<NavigationItem> get transformadorItems => const [
    NavigationItem(
      icon: Icons.home_rounded,
      label: 'Inicio',
      testKey: 'transformador_nav_inicio',
    ),
    NavigationItem(
      icon: Icons.factory_rounded,
      label: 'Producción',
      testKey: 'transformador_nav_produccion',
    ),
    NavigationItem(
      icon: Icons.help_outline_rounded,
      label: 'Ayuda',
      testKey: 'transformador_nav_ayuda',
    ),
    NavigationItem(
      icon: Icons.person_rounded,
      label: 'Perfil',
      testKey: 'transformador_nav_perfil',
    ),
  ];
  
  static List<NavigationItem> get laboratorioItems => const [
    NavigationItem(
      icon: Icons.home_rounded,
      label: 'Inicio',
      testKey: 'lab_nav_inicio',
    ),
    NavigationItem(
      icon: Icons.science_rounded,
      label: 'Muestras',
      testKey: 'lab_nav_muestras',
    ),
    NavigationItem(
      icon: Icons.help_outline_rounded,
      label: 'Ayuda',
      testKey: 'lab_nav_ayuda',
    ),
    NavigationItem(
      icon: Icons.person_rounded,
      label: 'Perfil',
      testKey: 'lab_nav_perfil',
    ),
  ];
  
  static List<NavigationItem> get maestroItems => const [
    NavigationItem(
      icon: Icons.dashboard_rounded,
      label: 'Panel',
      testKey: 'maestro_nav_panel',
    ),
    NavigationItem(
      icon: Icons.people_rounded,
      label: 'Usuarios',
      testKey: 'maestro_nav_usuarios',
    ),
    NavigationItem(
      icon: Icons.analytics_rounded,
      label: 'Reportes',
      testKey: 'maestro_nav_reportes',
    ),
    NavigationItem(
      icon: Icons.person_rounded,
      label: 'Perfil',
      testKey: 'maestro_nav_perfil',
    ),
  ];
}