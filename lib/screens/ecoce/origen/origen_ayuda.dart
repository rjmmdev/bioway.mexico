import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../utils/optimized_navigation.dart';
import '../shared/placeholder_ayuda_screen.dart';
import 'widgets/origen_bottom_navigation.dart';

class OrigenAyudaScreen extends StatelessWidget {
  const OrigenAyudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderAyudaScreen(
      tipoUsuario: 'Centro de Acopio',
      primaryColor: BioWayColors.ecoceGreen,
      bottomNavigation: OrigenBottomNavigation(
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
        onFabPressed: () {
          OptimizedNavigation.navigateToNamed(context, '/origen_crear_lote');
        },
      ),
      floatingActionButton: OrigenFloatingActionButton(
        onPressed: () {
          OptimizedNavigation.navigateToNamed(context, '/origen_crear_lote');
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}