import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

Color getMaterialColor(String material) {
  switch (material) {
    case 'PEBD':
      return BioWayColors.pebdPink;
    case 'PP':
      return BioWayColors.ppPurple;
    case 'Multilaminado':
      return BioWayColors.multilaminadoBrown;
    default:
      return Colors.grey;
  }
}

IconData getMaterialIcon(String material) {
  switch (material) {
    case 'PEBD':
      return Icons.shopping_bag;
    case 'PP':
      return Icons.kitchen;
    case 'Multilaminado':
      return Icons.layers;
    default:
      return Icons.recycling;
  }
}
