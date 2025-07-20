import 'package:flutter/material.dart';
import '../shared/ecoce_perfil_screen.dart';

class TransformadorPerfilScreen extends StatelessWidget {
  const TransformadorPerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Detectar swipe hacia la derecha (volver a ayuda)
        if (details.primaryVelocity! > 100) {
          Navigator.pushReplacementNamed(context, '/transformador_ayuda');
        }
        // No hay pantalla a la izquierda desde perfil
      },
      child: const EcocePerfilScreen(),
    );
  }
}