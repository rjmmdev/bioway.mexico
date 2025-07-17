import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../utils/optimized_navigation.dart';
import '../shared/placeholder_ayuda_screen.dart';
import 'widgets/transporte_bottom_navigation.dart';

class TransporteAyudaScreen extends StatelessWidget {
  const TransporteAyudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderAyudaScreen(
      tipoUsuario: 'Transportista',
      primaryColor: BioWayColors.deepBlue,
      bottomNavigation: TransporteBottomNavigation(
        selectedIndex: 2,
        onItemTapped: (index) {
          if (index == 2) return; // Ya estamos en ayuda
          
          // Navegación a otras pantallas según el índice
          switch (index) {
            case 0:
              OptimizedNavigation.navigateToNamed(context, '/transporte_inicio', replacement: true, duration: const Duration(milliseconds: 200));
              break;
            case 1:
              OptimizedNavigation.navigateToNamed(context, '/transporte_entregar', replacement: true, duration: const Duration(milliseconds: 200));
              break;
            case 3:
              OptimizedNavigation.navigateToNamed(context, '/transporte_perfil', replacement: true, duration: const Duration(milliseconds: 200));
              break;
          }
        },
      ),
    );
  }
}