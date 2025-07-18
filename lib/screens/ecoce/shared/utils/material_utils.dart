import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

class MaterialUtils {
  // Formateo de fechas
  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  // Obtener color según tipo de material
  static Color getMaterialColor(String material) {
    switch (material.toUpperCase()) {
      case 'PEBD':
        return AppColors.pebd;
      case 'PP':
        return AppColors.pp;
      case 'MULTILAMINADO':
        return AppColors.multilaminado;
      default:
        return Colors.grey;
    }
  }

  // Obtener icono según tipo de material
  static IconData getMaterialIcon(String material) {
    switch (material.toUpperCase()) {
      case 'PEBD':
        return Icons.local_drink;
      case 'PP':
        return Icons.category;
      case 'MULTILAMINADO':
        return Icons.layers;
      default:
        return Icons.help_outline;
    }
  }

  // Obtener color según presentación
  static Color getPresentationColor(String presentacion) {
    switch (presentacion.toLowerCase()) {
      case 'pacas':
        return Colors.brown;
      case 'sacos':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Obtener icono según presentación
  static IconData getPresentationIcon(String presentacion) {
    switch (presentacion.toLowerCase()) {
      case 'pacas':
        return Icons.inventory_2;
      case 'sacos':
        return Icons.shopping_bag;
      default:
        return Icons.help_outline;
    }
  }

  // Calcular merma
  static double calcularMerma(double pesoInicial, double pesoFinal) {
    if (pesoInicial <= 0) return 0;
    return ((pesoInicial - pesoFinal) / pesoInicial) * 100;
  }

  // Validar peso
  static bool validarPeso(String peso) {
    if (peso.isEmpty) return false;
    final pesoNum = double.tryParse(peso);
    return pesoNum != null && pesoNum > 0;
  }

  // Obtener estado del lote con formato
  static String getEstadoFormateado(String estado) {
    switch (estado.toLowerCase()) {
      case 'salida':
        return 'Pendiente de Salida';
      case 'documentacion':
        return 'Pendiente de Documentación';
      case 'finalizado':
        return 'Finalizado';
      default:
        return estado;
    }
  }

  // Obtener color del estado
  static Color getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'salida':
        return Colors.orange;
      case 'documentacion':
        return Colors.blue;
      case 'finalizado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Obtener icono del estado
  static IconData getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'salida':
        return Icons.output;
      case 'documentacion':
        return Icons.description;
      case 'finalizado':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }
}