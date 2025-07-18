import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/utils/navigation_utils.dart';
import 'origen_inicio_screen.dart';
import 'origen_lotes_screen.dart';
import 'origen_perfil.dart';
import 'origen_crear_lote_screen.dart';
import '../shared/placeholder_ayuda_screen.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import 'origen_config.dart';
import '../repositorio/repositorio_lotes_screen.dart';

class OrigenAyudaScreen extends StatelessWidget {
  const OrigenAyudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = OrigenUserConfig.current;
    return PlaceholderAyudaScreen(
      tipoUsuario: config.tipoUsuario,
      primaryColor: config.color,
      bottomNavigation: EcoceBottomNavigation(
        selectedIndex: 3,
        onItemTapped: (index) {
          if (index == 3) return; // Ya estamos en ayuda
          
          // Navegación a otras pantallas según el índice
          switch (index) {
            case 0:
              NavigationUtils.navigateWithFade(
                context,
                const OrigenInicioScreen(),
                replacement: true,
              );
              break;
            case 1:
              NavigationUtils.navigateWithFade(
                context,
                const OrigenLotesScreen(),
                replacement: true,
              );
              break;
            case 2:
              NavigationUtils.navigateWithFade(
                context,
                RepositorioLotesScreen(
                  primaryColor: config.color,
                  tipoUsuario: config.tipoUsuario,
                ),
                replacement: true,
              );
              break;
            case 4:
              NavigationUtils.navigateWithFade(
                context,
                const OrigenPerfilScreen(),
                replacement: true,
              );
              break;
          }
        },
        primaryColor: BioWayColors.ecoceGreen,
        items: EcoceNavigationConfigs.origenItems,
        fabConfig: FabConfig(
          icon: Icons.add,
          onPressed: () {
            NavigationUtils.navigateWithFade(
              context,
              const OrigenCrearLoteScreen(),
            );
          },
          tooltip: 'Nuevo Lote',
        ),
      ),
      floatingActionButton: EcoceFloatingActionButton(
        onPressed: () {
          NavigationUtils.navigateWithFade(
            context,
            const OrigenCrearLoteScreen(),
          );
        },
        icon: Icons.add,
        backgroundColor: BioWayColors.ecoceGreen,
        tooltip: 'Nuevo Lote',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}