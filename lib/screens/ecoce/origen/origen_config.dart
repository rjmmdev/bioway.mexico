import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class OrigenUserConfig {
  final String nombre;
  final String folio;
  final String tipoUsuario;
  final Color color;

  const OrigenUserConfig({
    required this.nombre,
    required this.folio,
    required this.tipoUsuario,
    required this.color,
  });

  static const OrigenUserConfig acopiador = OrigenUserConfig(
    nombre: 'Centro de Acopio La Esperanza',
    folio: 'A0000001',
    tipoUsuario: 'Centro de Acopio',
    color: BioWayColors.ecoceGreen,
  );

  static const OrigenUserConfig planta = OrigenUserConfig(
    nombre: 'Planta de Separación La Esperanza',
    folio: 'P0000001',
    tipoUsuario: 'Planta de Separación',
    color: BioWayColors.ppPurple,
  );

  static OrigenUserConfig current = acopiador;
}
