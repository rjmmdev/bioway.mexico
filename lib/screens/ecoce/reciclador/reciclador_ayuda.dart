import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../utils/optimized_navigation.dart';
import '../shared/placeholder_ayuda_screen.dart';
import 'widgets/reciclador_bottom_navigation.dart';

class RecicladorAyudaScreen extends StatelessWidget {
  const RecicladorAyudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderAyudaScreen(
      tipoUsuario: 'Reciclador',
      primaryColor: BioWayColors.primaryGreen,
      bottomNavigation: RecicladorBottomNavigation(
        selectedIndex: 2,
        onItemTapped: (index) {
          if (index == 2) return; // Ya estamos en ayuda
          
          // Navegación a otras pantallas según el índice
          switch (index) {
            case 0:
              OptimizedNavigation.navigateToNamed(context, '/reciclador_inicio', replacement: true, duration: const Duration(milliseconds: 200));
              break;
            case 1:
              OptimizedNavigation.navigateToNamed(context, '/reciclador_lotes', replacement: true, duration: const Duration(milliseconds: 200));
              break;
            case 3:
              OptimizedNavigation.navigateToNamed(context, '/reciclador_perfil', replacement: true, duration: const Duration(milliseconds: 200));
              break;
          }
        },
        onFabPressed: () {
          OptimizedNavigation.navigateToNamed(context, '/reciclador_escaneo');
        },
      ),
      floatingActionButton: RecicladorFloatingActionButton(
        onPressed: () {
          OptimizedNavigation.navigateToNamed(context, '/reciclador_escaneo');
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}