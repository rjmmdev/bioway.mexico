import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/placeholder_perfil_screen.dart';
import 'widgets/reciclador_bottom_navigation.dart';

class RecicladorPerfilScreen extends StatelessWidget {
  const RecicladorPerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderPerfilScreen(
      nombreUsuario: "María González Hernández",
      tipoUsuario: "Reciclador",
      folioUsuario: "R0000001",
      iconCode: "recycling",
      primaryColor: BioWayColors.primaryGreen,
      bottomNavigation: RecicladorBottomNavigation(
        selectedIndex: 3,
        onItemTapped: (index) {
          if (index == 3) return; // Ya estamos en perfil
          
          // Navegación a otras pantallas según el índice
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/reciclador_inicio');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/reciclador_lotes');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/reciclador_ayuda');
              break;
          }
        },
        onFabPressed: () {
          Navigator.pushNamed(context, '/reciclador_escaneo');
        },
      ),
      nombreEmpresa: "Reciclaje Sustentable MX",
    );
  }
}