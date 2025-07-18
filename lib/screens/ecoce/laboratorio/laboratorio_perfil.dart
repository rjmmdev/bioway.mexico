import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/placeholder_perfil_screen.dart';

class LaboratorioPerfilScreen extends StatelessWidget {
  const LaboratorioPerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPerfilScreen(
      nombreUsuario: "Laboratorio Central de Análisis",
      tipoUsuario: "Laboratorio",
      folioUsuario: "L0000001",
      iconCode: "science",
      primaryColor: BioWayColors.ecoceGreen,
      nombreEmpresa: "Laboratorio Central de Análisis SA de CV",
    );
  }
}