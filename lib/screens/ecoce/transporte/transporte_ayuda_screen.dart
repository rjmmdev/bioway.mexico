import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/placeholder_ayuda_screen.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/utils/navigation_utils.dart';
import 'transporte_inicio_screen.dart';
import 'transporte_entregar_screen.dart';
import 'transporte_perfil_screen.dart';

class TransporteAyudaScreen extends StatelessWidget {
  const TransporteAyudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderAyudaScreen(
      tipoUsuario: 'Transportista',
      primaryColor: BioWayColors.deepBlue,
      bottomNavigation: EcoceBottomNavigation(
        selectedIndex: 2,
        onItemTapped: (index) {
          if (index == 2) return; // Ya estamos en ayuda
          
          switch (index) {
            case 0:
              NavigationUtils.navigateWithFade(
                context,
                const TransporteInicioScreen(),
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
            case 3:
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