import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/placeholder_perfil_screen.dart';

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
      nombreEmpresa: "Centro de Acopio La Esperanza S.A. de C.V.",
    );
  }
}