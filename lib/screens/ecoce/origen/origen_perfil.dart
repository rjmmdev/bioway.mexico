import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/placeholder_perfil_screen.dart';
import 'origen_config.dart';

class OrigenPerfilScreen extends StatelessWidget {
  const OrigenPerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = OrigenUserConfig.current;
    return PlaceholderPerfilScreen(
      nombreUsuario: config.nombre,
      tipoUsuario: config.tipoUsuario,
      folioUsuario: config.folio,
      iconCode: "store",
      primaryColor: config.color,
      nombreEmpresa: "${config.nombre} S.A. de C.V.",
    );
  }
}