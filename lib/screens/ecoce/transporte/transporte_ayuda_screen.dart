import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../shared/placeholder_ayuda_screen.dart';
import 'widgets/transporte_bottom_navigation.dart';
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
      bottomNavigation: TransporteBottomNavigation(
        selectedIndex: 2,
        onItemTapped: (index) {
          HapticFeedback.lightImpact();
          
          if (index == 2) return; // Ya estamos en ayuda
          
          // Navegación a otras pantallas según el índice
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const TransporteInicioScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const TransporteEntregarScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const TransportePerfilScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
              break;
          }
        },
      ),
    );
  }
}