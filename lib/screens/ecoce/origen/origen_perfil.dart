import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/placeholder_perfil_screen.dart';
import 'widgets/origen_bottom_navigation.dart';

class OrigenPerfilScreen extends StatelessWidget {
  const OrigenPerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderPerfilScreen(
      nombreUsuario: "Centro de Acopio La Esperanza",
      tipoUsuario: "Centro de Acopio",
      folioUsuario: "A0000001",
      iconCode: "store",
      primaryColor: BioWayColors.ecoceGreen,
      bottomNavigation: OrigenBottomNavigation(
        selectedIndex: 3,
        onItemTapped: (index) {
          if (index == 3) return; // Ya estamos en perfil
          
          // Navegación a otras pantallas según el índice
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/origen_inicio');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/origen_lotes');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/origen_ayuda');
              break;
          }
        },
        onFabPressed: () {
          Navigator.pushNamed(context, '/origen_crear_lote');
        },
      ),
      nombreEmpresa: "Centro de Acopio La Esperanza S.A. de C.V.",
    );
  }
}