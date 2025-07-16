import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/placeholder_perfil_screen.dart';

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
      nombreEmpresa: "Transportes EcoLogistics S.A. de C.V.",
    );
  }
}