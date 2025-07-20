import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/format_utils.dart';

/// Utilidades para manejo de materiales y fechas
class MaterialUtils {
  /// Formatea una fecha a formato dd/mm/yyyy
  static String formatDate(DateTime date) {
    return FormatUtils.formatDate(date);
  }
  
  /// Convierte una fecha string (yyyy-mm-dd) a formato dd/mm/yyyy
  static String formatDateString(String dateString) {
    try {
      final parts = dateString.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }
  
  /// Formatea una fecha con hora a formato dd/mm/yyyy HH:mm
  static String formatDateTime(DateTime dateTime) {
    return FormatUtils.formatDateTime(dateTime);
  }
  
  /// Obtiene el color asociado a un material
  static Color getMaterialColor(String material) {
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
  
  /// Obtiene el icono asociado a un material
  static IconData getMaterialIcon(String material) {
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
}
