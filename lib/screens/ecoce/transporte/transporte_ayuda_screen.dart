import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/placeholder_ayuda_screen.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/utils/navigation_utils.dart';
import 'transporte_escaneo.dart';
import 'transporte_entregar_screen.dart';
import 'transporte_perfil_screen.dart';
import '../repositorio/repositorio_lotes_screen.dart';

class TransporteAyudaScreen extends StatelessWidget {
  const TransporteAyudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderAyudaScreen(
      tipoUsuario: 'Transportista',
      primaryColor: BioWayColors.deepBlue,
      bottomNavigation: EcoceBottomNavigation(
        selectedIndex: 3,
        onItemTapped: (index) {
          if (index == 3) return; // Ya estamos en ayuda
          
          switch (index) {
            case 0:
              NavigationUtils.navigateWithFade(
                context,
                const TransporteEscaneoScreen(),
                replacement: true,
              );
              break;
            case 1:
              NavigationUtils.navigateWithFade(
                context,
                const TransporteEntregarScreen(),
                replacement: true,
              );
              break;
            case 2:
              NavigationUtils.navigateWithFade(
                context,
                RepositorioLotesScreen(
                  primaryColor: BioWayColors.deepBlue,
                  tipoUsuario: 'transportista',
                ),
                replacement: true,
              );
              break;
            case 4:
              NavigationUtils.navigateWithFade(
                context,
                const TransportePerfilScreen(),
                replacement: true,
              );
              break;
          }
        },
        primaryColor: BioWayColors.deepBlue,
        items: EcoceNavigationConfigs.transporteItems,
      ),
    );
  }
}