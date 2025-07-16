import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/placeholder_perfil_screen.dart';
import 'widgets/transporte_bottom_navigation.dart';

class TransportePerfilScreen extends StatelessWidget {
  const TransportePerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderPerfilScreen(
      nombreUsuario: "Carlos Mendoza López",
      tipoUsuario: "Transportista",
      folioUsuario: "V0000001",
      iconCode: "local_shipping",
      primaryColor: BioWayColors.deepBlue,
      bottomNavigation: TransporteBottomNavigation(
        selectedIndex: 3,
        onItemTapped: (index) {
          if (index == 3) return; // Ya estamos en perfil
          
          // Navegación a otras pantallas según el índice
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/transporte_inicio');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/transporte_entregar');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/transporte_ayuda');
              break;
          }
        },
      ),
      nombreEmpresa: "Transportes EcoLogistics S.A. de C.V.",
    );
  }
}