import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../utils/optimized_navigation.dart';
import '../shared/placeholder_ayuda_screen.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import 'origen_config.dart';

class OrigenAyudaScreen extends StatelessWidget {
  const OrigenAyudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = OrigenUserConfig.current;
    return PlaceholderAyudaScreen(
      tipoUsuario: config.tipoUsuario,
      primaryColor: config.color,
      bottomNavigation: EcoceBottomNavigation(
        selectedIndex: 2,
        onItemTapped: (index) {
          if (index == 2) return; // Ya estamos en ayuda
          
          // Navegación a otras pantallas según el índice
          switch (index) {
            case 0:
              OptimizedNavigation.navigateToNamed(context, '/origen_inicio', replacement: true);
              break;
            case 1:
              OptimizedNavigation.navigateToNamed(context, '/origen_lotes', replacement: true);
              break;
            case 3:
              OptimizedNavigation.navigateToNamed(context, '/origen_perfil', replacement: true);
              break;
          }
        },
        primaryColor: BioWayColors.ecoceGreen,
        items: EcoceNavigationConfigs.origenItems,
        fabConfig: FabConfig(
          icon: Icons.add,
          onPressed: () {
            OptimizedNavigation.navigateToNamed(context, '/origen_crear_lote');
          },
          tooltip: 'Nuevo Lote',
        ),
      ),
      floatingActionButton: EcoceFloatingActionButton(
        onPressed: () {
          OptimizedNavigation.navigateToNamed(context, '/origen_crear_lote');
        },
        icon: Icons.add,
        backgroundColor: BioWayColors.ecoceGreen,
        tooltip: 'Nuevo Lote',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}