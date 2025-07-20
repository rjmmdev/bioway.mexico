import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';

/// Navigation configuration for Transformador screens
class TransformadorNavigation {
  static const List<NavigationItem> navigationItems = [
    NavigationItem(
      icon: Icons.home_rounded,
      label: 'Inicio',
    ),
    NavigationItem(
      icon: Icons.factory_rounded,
      label: 'Producción',
    ),
    NavigationItem(
      icon: Icons.help_outline_rounded,
      label: 'Ayuda',
    ),
    NavigationItem(
      icon: Icons.person_rounded,
      label: 'Perfil',
    ),
  ];

  static FabConfig getFabConfig(BuildContext context) {
    return FabConfig(
      icon: Icons.add,
      onPressed: () => Navigator.pushNamed(context, '/transformador_recibir_lote'),
      tooltip: 'Recibir Lote',
    );
  }

  static Widget buildBottomNavigation({
    required int selectedIndex,
    required Function(int) onItemTapped,
  }) {
    return EcoceBottomNavigation(
      selectedIndex: selectedIndex,
      onItemTapped: onItemTapped,
      primaryColor: BioWayColors.petBlue,
      items: navigationItems,
    );
  }

  static Widget buildFloatingActionButton(BuildContext context) {
    return EcoceFloatingActionButton(
      onPressed: () => Navigator.pushNamed(context, '/transformador_recibir_lote'),
      icon: Icons.add,
      backgroundColor: BioWayColors.petBlue,
      tooltip: 'Recibir Lote',
    );
  }

  static void handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/transformador_inicio');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/transformador_produccion');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/transformador_ayuda');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/transformador_perfil');
        break;
    }
  }

  /// Get icon for material type
  static IconData getMaterialIcon(String material) {
    switch (material.toLowerCase()) {
      case 'pet':
        return Icons.local_drink;
      case 'hdpe':
        return Icons.cleaning_services;
      case 'pvc':
        return Icons.plumbing;
      case 'ldpe':
        return Icons.shopping_bag;
      case 'pp':
        return Icons.kitchen;
      case 'ps':
        return Icons.fastfood;
      case 'otro':
        return Icons.help_outline;
      default:
        return Icons.category;
    }
  }

  /// Get color for material type
  static Color getMaterialColor(String material) {
    switch (material.toLowerCase()) {
      case 'pet':
        return BioWayColors.petBlue;
      case 'hdpe':
        return BioWayColors.hdpeGreen;
      case 'pvc':
        return BioWayColors.pvcRed;
      case 'ldpe':
        return BioWayColors.success;
      case 'pp':
        return BioWayColors.ppPurple;
      case 'ps':
        return BioWayColors.psYellow;
      case 'otro':
        return BioWayColors.otherPurple;
      default:
        return BioWayColors.textGrey;
    }
  }

  /// Get label for material type
  static String getMaterialLabel(String material) {
    switch (material.toLowerCase()) {
      case 'pet':
        return 'PET - Polietileno Tereftalato';
      case 'hdpe':
        return 'HDPE - Polietileno de Alta Densidad';
      case 'pvc':
        return 'PVC - Policloruro de Vinilo';
      case 'ldpe':
        return 'LDPE - Polietileno de Baja Densidad';
      case 'pp':
        return 'PP - Polipropileno';
      case 'ps':
        return 'PS - Poliestireno';
      case 'otro':
        return 'Otros Plásticos';
      default:
        return material;
    }
  }
}