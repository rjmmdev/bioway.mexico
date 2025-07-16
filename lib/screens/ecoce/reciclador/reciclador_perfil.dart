import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/placeholder_perfil_screen.dart';

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
      nombreEmpresa: "Reciclaje Sustentable MX",
    );
  }
}