import 'package:flutter/material.dart';
import 'dart:math';
import '../../../utils/colors.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';

/// Centralized services and utilities for transporte screens
class TransporteServices {
  // Private constructor to prevent instantiation
  TransporteServices._();

  // Constants
  static const int qrExpirationMinutes = 15;
  static const double maxCargoWeight = 10000.0; // kg
  
  // Transport vehicle types
  static const List<String> vehicleTypes = [
    'Camioneta',
    'Camión 3.5 ton',
    'Camión 5 ton',
    'Tráiler',
    'Otro',
  ];

  // Validation methods
  static String? validateTransportNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es requerido';
    }
    if (!RegExp(r'^[A-Z0-9\-]+$').hasMatch(value)) {
      return 'Solo letras mayúsculas, números y guiones';
    }
    if (value.length < 3) {
      return 'Mínimo 3 caracteres';
    }
    return null;
  }

  static String? validatePlateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es requerido';
    }
    if (!RegExp(r'^[A-Z0-9\-]+$').hasMatch(value.toUpperCase())) {
      return 'Formato de placa inválido';
    }
    return null;
  }

  static String? validateOperatorName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es requerido';
    }
    if (value.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return 'Solo se permiten letras';
    }
    return null;
  }

  static String? validateRecipientId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es requerido';
    }
    // Validate folio format or ID
    if (!RegExp(r'^[A-Z]\d{7}$').hasMatch(value) && value.length < 5) {
      return 'Ingrese un folio válido o ID';
    }
    return null;
  }

  // Formatting methods
  static String formatWeight(double weight) {
    if (weight >= 1000) {
      return '${(weight / 1000).toStringAsFixed(1)} ton';
    }
    return '${weight.toStringAsFixed(1)} kg';
  }

  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  static String getTimeRemaining(DateTime expirationTime) {
    final now = DateTime.now();
    final difference = expirationTime.difference(now);
    
    if (difference.isNegative) {
      return 'Expirado';
    }
    
    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // QR Code generation
  static String generateDeliveryQR({
    required List<String> lotIds,
    required String transportId,
    required String recipientId,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = {
      'tipo': 'ENTREGA',
      'lotes': lotIds.join(','),
      'transporte': transportId,
      'destinatario': recipientId,
      'timestamp': timestamp,
      'expira': timestamp + (qrExpirationMinutes * 60 * 1000),
    };
    
    // Convert to string format
    return data.entries.map((e) => '${e.key}:${e.value}').join('|');
  }

  // Lot grouping by origin
  static Map<String, List<Map<String, dynamic>>> groupLotsByOrigin(
    List<Map<String, dynamic>> lots,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (final lot in lots) {
      final origin = lot['origen'] ?? 'Sin origen';
      grouped.putIfAbsent(origin, () => []).add(lot);
    }
    
    return grouped;
  }

  // Calculate total weight
  static double calculateTotalWeight(List<Map<String, dynamic>> lots) {
    return lots.fold(0.0, (sum, lot) => sum + (lot['peso'] ?? 0.0));
  }

  // Material colors and icons
  static Color getMaterialColor(String material) {
    switch (material.toUpperCase()) {
      case 'PEBD':
      case 'POLI':
        return BioWayColors.petBlue;
      case 'PP':
        return BioWayColors.ppPurple;
      case 'MULTI':
      case 'MULTILAMINADO':
        return BioWayColors.recycleOrange;
      default:
        return BioWayColors.ecoceGreen;
    }
  }

  static IconData getMaterialIcon(String material) {
    switch (material.toUpperCase()) {
      case 'PEBD':
      case 'POLI':
        return Icons.square;
      case 'PP':
        return Icons.hexagon_outlined;
      case 'MULTI':
      case 'MULTILAMINADO':
        return Icons.layers;
      default:
        return Icons.recycling;
    }
  }

  // Form type enum
  static String getFormTitle(TransportFormType type) {
    switch (type) {
      case TransportFormType.pickup:
        return 'Formulario de Recolección';
      case TransportFormType.delivery:
        return 'Formulario de Entrega';
    }
  }

  static Color getFormColor(TransportFormType type) {
    switch (type) {
      case TransportFormType.pickup:
        return BioWayColors.ecoceGreen;
      case TransportFormType.delivery:
        return BioWayColors.petBlue;
    }
  }

  // Mock recipient search (in production, this would query Firestore)
  static Future<Map<String, dynamic>?> searchRecipient(String query) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data
    final mockRecipients = [
      {
        'id': 'R0000001',
        'nombre': 'Recicladora del Norte S.A.',
        'tipo': 'Reciclador',
        'direccion': 'Av. Industrial 123, Monterrey',
      },
      {
        'id': 'T0000001',
        'nombre': 'Transformadora Eco Solutions',
        'tipo': 'Transformador',
        'direccion': 'Parque Industrial Sur, Guadalajara',
      },
    ];
    
    try {
      return mockRecipients.firstWhere(
        (r) => r['id'] == query.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Generate transport ID
  static String generateTransportId() {
    final random = Random();
    final letters = String.fromCharCodes(
      List.generate(3, (_) => random.nextInt(26) + 65),
    );
    final numbers = random.nextInt(9000) + 1000;
    return 'T-$letters-$numbers';
  }

  // Navigation items for transporte
  static const List<NavigationItem> navigationItems = [
    NavigationItem(icon: Icons.download_rounded, label: 'Recoger'),
    NavigationItem(icon: Icons.upload_rounded, label: 'Entregar'),
    NavigationItem(icon: Icons.help_outline_rounded, label: 'Ayuda'),
    NavigationItem(icon: Icons.person_rounded, label: 'Perfil'),
  ];
}

// Enums
enum TransportFormType { pickup, delivery }

enum DeliveryState { selecting, qrGenerated, formCompleted }

// Lot state for transport
enum TransportLotState {
  collected('Recolectado', BioWayColors.success),
  inTransit('En Tránsito', BioWayColors.warning),
  delivered('Entregado', BioWayColors.info);
  
  final String label;
  final Color color;
  
  const TransportLotState(this.label, this.color);
}