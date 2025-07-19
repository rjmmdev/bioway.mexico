import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/placeholder_perfil_screen.dart';

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
      child: PlaceholderPerfilScreen(
        nombreUsuario: "María González López",
        tipoUsuario: "Transformador",
        folioUsuario: "T0000001",
        iconCode: "factory",
        primaryColor: BioWayColors.ecoceGreen,
        nombreEmpresa: "La Venta S.A. de C.V.",
      ),
    );
  }
}