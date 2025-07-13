import 'package:flutter/material.dart';

/// Clase que contiene todos los colores utilizados en la aplicación BioWay
class BioWayColors {
  // Constructor privado para evitar instanciación
  BioWayColors._();

  // ===== COLORES PRINCIPALES DE BIOWAY =====

  /// Verde principal de la marca BioWay
  static const Color primaryGreen = Color(0xFF22C55E);

  /// Verde oscuro para textos y elementos destacados
  static const Color darkGreen = Color(0xFF166534);

  /// Verde claro para fondos y elementos sutiles
  static const Color lightGreen = Color(0xFFD1FAE5);

  /// Verde medio para gradientes y efectos
  static const Color mediumGreen = Color(0xFF6EE7B7);

  /// Verde brillante para estados activos
  static const Color brightGreen = Color(0xFF4ADE80);

  // ===== COLORES DE ECOCE =====

  /// Verde característico de ECOCE
  static const Color ecoceGreen = Color(0xFF059669);

  /// Verde claro de ECOCE para fondos
  static const Color ecoceLight = Color(0xFFF0FDF4);

  /// Verde oscuro de ECOCE para textos
  static const Color ecoceDark = Color(0xFF064E3B);

  // ===== COLOR DEL INDICADOR DE SWITCH =====

  /// Azul para el indicador de cambio de plataforma
  static const Color switchBlue = Color(0xFF3B82F6);

  /// Azul claro para estados hover del switch
  static const Color switchBlueLight = Color(0xFF60A5FA);

  // ===== GRADIENTES =====

  /// Gradiente principal de fondo para BioWay
  static const List<Color> backgroundGradient = [
    Color(0xFFD1FAE5), // Verde agua claro
    Color(0xFF6EE7B7), // Verde más vibrante
  ];

  /// Gradiente alternativo más suave
  static const List<Color> softGradient = [
    Color(0xFFF0FDF4), // Casi blanco verdoso
    Color(0xFFD1FAE5), // Verde agua claro
  ];

  /// Gradiente para elementos destacados
  static const List<Color> accentGradient = [
    primaryGreen,
    Color(0xFF16A34A), // Verde más oscuro
  ];

  // ===== COLORES NEUTROS =====

  /// Gris para textos secundarios
  static const Color textGrey = Color(0xFF666666);

  /// Gris claro para bordes y divisores
  static const Color lightGrey = Color(0xFFE5E5E5);

  /// Gris muy claro para fondos
  static const Color backgroundGrey = Color(0xFFF9FAFB);

  /// Gris oscuro para textos importantes
  static const Color darkGrey = Color(0xFF333333);

  /// Negro suave para textos
  static const Color softBlack = Color(0xFF1F2937);

  // ===== COLORES DE ESTADO =====

  /// Verde para estados de éxito
  static const Color success = Color(0xFF10B981);

  /// Rojo para errores y alertas
  static const Color error = Color(0xFFEF4444);

  /// Amarillo/naranja para advertencias
  static const Color warning = Color(0xFFF59E0B);

  /// Azul para información
  static const Color info = Color(0xFF3B82F6);

  // ===== COLORES DE MATERIALES (RECICLAJE) =====

  /// Color para PET
  static const Color petBlue = Color(0xFF2563EB);

  /// Color para HDPE
  static const Color hdpeGreen = Color(0xFF059669);

  /// Color para PP
  static const Color ppOrange = Color(0xFFF97316);

  /// Color para otros materiales
  static const Color otherPurple = Color(0xFF9333EA);

  /// Color para vidrio
  static const Color glassGreen = Color(0xFF10B981);

  /// Color para metal
  static const Color metalGrey = Color(0xFF6B7280);

  // ===== SOMBRAS Y OVERLAYS =====

  /// Color para sombras suaves
  static Color shadowColor = Colors.black.withOpacity(0.1);

  /// Color para overlays oscuros
  static Color darkOverlay = Colors.black.withOpacity(0.5);

  /// Color para overlays claros
  static Color lightOverlay = Colors.white.withOpacity(0.8);

  // ===== MÉTODOS ÚTILES =====

  /// Obtiene un color con opacidad
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Obtiene una versión más clara de un color
  static Color lighten(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );

    return hslLight.toColor();
  }

  /// Obtiene una versión más oscura de un color
  static Color darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );

    return hslDark.toColor();
  }
}