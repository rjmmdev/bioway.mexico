import 'package:flutter/material.dart';
import 'colors.dart';

/// Clase helper para manejar los niveles de BioWay
class BioWayLevels {
  /// Mapeo de niveles antiguos a nuevos nombres más acordes con la temática de reciclaje
  static String getDisplayName(String oldLevel) {
    switch (oldLevel) {
      case 'BioBaby':
        return 'Semilla Verde';
      case 'BioMidWay':
        return 'Brote Eco';
      case 'BioWay':
        return 'Guardián Verde';
      case 'BioExpert':
        return 'Héroe Ambiental';
      case 'BioGod':
        return 'Leyenda Eco';
      case 'Admin':
        return 'Administrador';
      default:
        return oldLevel;
    }
  }

  /// Obtiene el color asociado a un nivel
  static Color getLevelColor(String level) {
    // Manejar tanto nombres antiguos como nuevos
    switch (level) {
      case 'BioBaby':
      case 'Semilla Verde':
        return BioWayColors.info;
      case 'BioMidWay':
      case 'Brote Eco':
        return BioWayColors.warning;
      case 'BioWay':
      case 'Guardián Verde':
        return BioWayColors.primaryGreen;
      case 'BioExpert':
      case 'Héroe Ambiental':
        return BioWayColors.success;
      case 'BioGod':
      case 'Leyenda Eco':
        return Colors.purple;
      case 'Admin':
      case 'Administrador':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obtiene el ícono asociado a un nivel
  static IconData getLevelIcon(String level) {
    switch (level) {
      case 'BioBaby':
      case 'Semilla Verde':
        return Icons.eco;
      case 'BioMidWay':
      case 'Brote Eco':
        return Icons.local_florist;
      case 'BioWay':
      case 'Guardián Verde':
        return Icons.nature_people;
      case 'BioExpert':
      case 'Héroe Ambiental':
        return Icons.star;
      case 'BioGod':
      case 'Leyenda Eco':
        return Icons.emoji_events;
      case 'Admin':
      case 'Administrador':
        return Icons.admin_panel_settings;
      default:
        return Icons.recycling;
    }
  }

  /// Obtiene la descripción del nivel
  static String getLevelDescription(String level) {
    switch (level) {
      case 'BioBaby':
      case 'Semilla Verde':
        return 'Estás comenzando tu viaje ecológico';
      case 'BioMidWay':
      case 'Brote Eco':
        return 'Tu compromiso ambiental está creciendo';
      case 'BioWay':
      case 'Guardián Verde':
        return 'Eres un protector activo del medio ambiente';
      case 'BioExpert':
      case 'Héroe Ambiental':
        return 'Tu impacto ambiental es extraordinario';
      case 'BioGod':
      case 'Leyenda Eco':
        return 'Eres una inspiración para la comunidad';
      case 'Admin':
      case 'Administrador':
        return 'Gestor del sistema BioWay';
      default:
        return 'Usuario de BioWay';
    }
  }
  
  /// Obtiene el nivel basado en kg de CO2 evitado
  static String getLevelByCO2(double kgCO2) {
    for (final level in levels) {
      if (kgCO2 >= level.minCO2 && (level.maxCO2 == null || kgCO2 <= level.maxCO2!)) {
        return level.name;
      }
    }
    return 'Semilla Verde';
  }
  
  /// Obtiene la información del impacto para un nivel
  static String getImpactInfo(double kgCO2) {
    // Cálculos realistas basados en datos ambientales
    final kgCO2Int = kgCO2.toInt();
    if (kgCO2 < 50) {
      final trees = (kgCO2 / 22).toStringAsFixed(1); // Un árbol absorbe ~22kg CO2/año
      return 'Has evitado $kgCO2Int kg de CO₂\nEquivale a plantar $trees árboles';
    } else if (kgCO2 < 200) {
      final carDays = (kgCO2 / 4.6).toStringAsFixed(0); // Auto promedio emite 4.6kg CO2/día
      return 'Has evitado $kgCO2Int kg de CO₂\nComo sacar 1 auto de circulación por $carDays días';
    } else if (kgCO2 < 500) {
      final carMonths = (kgCO2 / 138).toStringAsFixed(1); // Auto promedio emite ~138kg CO2/mes
      return 'Has evitado $kgCO2Int kg de CO₂\nIgual a $carMonths meses sin usar auto';
    } else if (kgCO2 < 1000) {
      final trees = (kgCO2 / 22).toStringAsFixed(0);
      return 'Has evitado $kgCO2Int kg de CO₂\nComo plantar un bosque de $trees árboles';
    } else {
      final habitat = (kgCO2 / 100).toStringAsFixed(0); // Estimación conservadora
      return 'Has evitado $kgCO2Int kg de CO₂\nEquivale a preservar el hábitat de $habitat especies';
    }
  }

  /// Lista de todos los niveles con sus rangos de kg CO2 evitado
  static final List<LevelInfo> levels = [
    LevelInfo(
      'Semilla Verde', 
      0, 
      49, 
      BioWayColors.info,
      'Equivale a plantar 2 árboles',
    ),
    LevelInfo(
      'Brote Eco', 
      50, 
      199, 
      BioWayColors.warning,
      'Como sacar 1 auto de circulación por 1 mes',
    ),
    LevelInfo(
      'Guardián Verde', 
      200, 
      499, 
      BioWayColors.primaryGreen,
      'Igual a 6 meses sin usar auto',
    ),
    LevelInfo(
      'Héroe Ambiental', 
      500, 
      999, 
      BioWayColors.success,
      'Como plantar un pequeño bosque de 40 árboles',
    ),
    LevelInfo(
      'Leyenda Eco', 
      1000, 
      null, 
      Colors.purple,
      'Equivale a salvar el hábitat de 15 especies',
    ),
  ];
}

/// Información de un nivel
class LevelInfo {
  final String name;
  final int minCO2;
  final int? maxCO2;
  final Color color;
  final String impactDescription;

  const LevelInfo(this.name, this.minCO2, this.maxCO2, this.color, this.impactDescription);
}