import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/placeholder_perfil_screen.dart';

class RecicladorPerfilScreen extends StatelessWidget {
  const RecicladorPerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderPerfilScreen(
      nombreUsuario: "Juan Pérez García",
      tipoUsuario: "Reciclador",
      folioUsuario: "R0001234",
      iconCode: "recycling",
      primaryColor: BioWayColors.ecoceGreen,
      nombreEmpresa: "Planta Recicladora Ecológica del Norte S.A. de C.V.",
    );
  }
}