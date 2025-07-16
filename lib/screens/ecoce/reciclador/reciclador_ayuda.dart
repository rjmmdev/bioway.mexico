import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/placeholder_ayuda_screen.dart';
import 'widgets/reciclador_bottom_navigation.dart';

class RecicladorAyudaScreen extends StatelessWidget {
  const RecicladorAyudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderAyudaScreen(
      tipoUsuario: "Reciclador",
      primaryColor: BioWayColors.primaryGreen,
      bottomNavigation: RecicladorBottomNavigation(
        selectedIndex: 2,
        onItemTapped: (index) {
          if (index == 2) return; // Ya estamos en ayuda
          
          // Navegación a otras pantallas según el índice
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/reciclador_inicio');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/reciclador_lotes');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/reciclador_perfil');
              break;
          }
        },
        onFabPressed: () {
          Navigator.pushNamed(context, '/reciclador_escaneo');
        },
      ),
    );
  }
}