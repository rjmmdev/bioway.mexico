import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Services and utilities specific to reciclador functionality
class RecicladorServices {
  // Singleton pattern
  static final RecicladorServices _instance = RecicladorServices._internal();
  factory RecicladorServices() => _instance;
  RecicladorServices._internal();

  /// Document picker service for reciclador document uploads
  Future<Map<String, dynamic>?> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        int sizeInBytes = await file.length();
        double sizeInMB = sizeInBytes / (1024 * 1024);

        // Validate file size (max 10MB)
        if (sizeInMB > 10) {
          throw Exception('El archivo es demasiado grande. Máximo 10MB.');
        }

        return {
          'file': file,
          'name': result.files.single.name,
          'size': sizeInMB,
          'extension': result.files.single.extension ?? '',
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error picking document: $e');
      return null;
    }
  }

  /// Lot state enum
  static const Map<String, LotState> lotStates = {
    'salida': LotState.salida,
    'documentacion': LotState.documentacion,
    'finalizado': LotState.finalizado,
  };

  /// Calculate material shrinkage (merma)
  static double calculateMerma(double pesoEntrada, double pesoSalida) {
    if (pesoEntrada <= 0) return 0;
    return ((pesoEntrada - pesoSalida) / pesoEntrada) * 100;
  }

  /// Validate lot weight
  static String? validateWeight(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Este campo es requerido';
    }
    
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Ingrese un número válido';
    }
    
    if (min != null && weight < min) {
      return 'El peso debe ser mayor a $min kg';
    }
    
    if (max != null && weight > max) {
      return 'El peso debe ser menor a $max kg';
    }
    
    return null;
  }

  /// Validate operator name
  static String? validateOperatorName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es requerido';
    }
    
    if (value.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return 'Solo se permiten letras y espacios';
    }
    
    return null;
  }

  /// Format weight display
  static String formatWeight(double weight) {
    if (weight >= 1000) {
      return '${(weight / 1000).toStringAsFixed(2)} t';
    }
    return '${weight.toStringAsFixed(2)} kg';
  }

  /// Get material color
  static Color getMaterialColor(String material) {
    switch (material.toLowerCase()) {
      case 'poli':
      case 'polietileno':
        return Colors.blue;
      case 'pp':
      case 'polipropileno':
        return Colors.purple;
      case 'multi':
      case 'multilaminado':
        return Colors.brown;
      case 'pet':
        return Colors.lightBlue;
      case 'hdpe':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Get material icon
  static IconData getMaterialIcon(String material) {
    switch (material.toLowerCase()) {
      case 'poli':
      case 'polietileno':
        return Icons.water_drop;
      case 'pp':
      case 'polipropileno':
        return Icons.category;
      case 'multi':
      case 'multilaminado':
        return Icons.layers;
      case 'pet':
        return Icons.local_drink;
      case 'hdpe':
        return Icons.cleaning_services;
      default:
        return Icons.recycling;
    }
  }

  /// Process types for salida form
  static const List<String> processTypes = [
    'Clasificación',
    'Molienda',
    'Lavado',
    'Peletizado',
    'Compactación',
    'Trituración',
    'Separación',
    'Embalaje',
  ];

  /// Polymer types for entrada form
  static const List<Map<String, dynamic>> polymerTypes = [
    {
      'id': 'poli',
      'name': 'Polietileno (PE)',
      'description': 'HDPE, LDPE, LLDPE',
      'color': Colors.blue,
      'icon': Icons.water_drop,
    },
    {
      'id': 'pp',
      'name': 'Polipropileno (PP)',
      'description': 'Rígido y flexible',
      'color': Colors.purple,
      'icon': Icons.category,
    },
    {
      'id': 'multi',
      'name': 'Multilaminado',
      'description': 'Materiales compuestos',
      'color': Colors.brown,
      'icon': Icons.layers,
    },
    {
      'id': 'pet',
      'name': 'PET',
      'description': 'Botellas y envases',
      'color': Colors.lightBlue,
      'icon': Icons.local_drink,
    },
    {
      'id': 'ps',
      'name': 'Poliestireno (PS)',
      'description': 'Expandido y rígido',
      'color': Colors.orange,
      'icon': Icons.widgets,
    },
    {
      'id': 'pvc',
      'name': 'PVC',
      'description': 'Rígido y flexible',
      'color': Colors.red,
      'icon': Icons.plumbing,
    },
    {
      'id': 'otros',
      'name': 'Otros',
      'description': 'Otros polímeros',
      'color': Colors.grey,
      'icon': Icons.help_outline,
    },
  ];

  /// Generate lot ID
  static String generateLotId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();
    return 'REC${timestamp.substring(timestamp.length - 8)}';
  }

  /// Format date for display
  static String formatDate(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  /// Get time ago string
  static String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return formatDate(date);
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return 'Hace un momento';
    }
  }
}

/// Lot state enum
enum LotState {
  salida('Salida', Colors.orange),
  documentacion('Documentación', Colors.blue),
  finalizado('Finalizado', Colors.green);

  final String label;
  final Color color;
  
  const LotState(this.label, this.color);
}