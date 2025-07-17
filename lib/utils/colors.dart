import 'package:flutter/material.dart';

/// Clase que contiene todos los colores utilizados en la aplicación BioWay
class BioWayColors {
  // Constructor privado para evitar instanciación
  BioWayColors._();

  // ===== COLORES PRINCIPALES DE BIOWAY (BASADOS EN XML) =====

  /// Verde principal de la marca BioWay - desde background_1.xml
  static const Color primaryGreen = Color(0xFF70D997);

  /// Verde oscuro para textos y elementos destacados - desde background_1.xml
  static const Color darkGreen = Color(0xFF3DB388);

  /// Verde más oscuro para textos importantes - desde background_3.xml
  static const Color deepGreen = Color(0xFF00896F);

  /// Verde claro para fondos y elementos sutiles - desde background_2.xml
  static const Color lightGreen = Color(0xFFA3FFA6);

  /// Verde medio - desde background_11.xml
  static const Color mediumGreen = Color(0xFF90EE80);

  /// Verde agua pastel - desde background_11.xml
  static const Color aquaGreen = Color(0xFFC3FACC);

  /// Turquesa brillante - desde background_11.xml y otros
  static const Color turquoise = Color(0xFF3FD9FF);

  /// Verde lima brillante para acentos
  static const Color limeGreen = Color(0xFF90EE80);

  // ===== COLORES DE ECOCE (BASADOS EN XML) =====

  /// Verde característico de ECOCE - basado en colores XML
  static const Color ecoceGreen = Color(0xFF3DB388);

  /// Verde claro de ECOCE para fondos
  static const Color ecoceLight = Color(0xFFC3FACC);

  /// Verde oscuro de ECOCE para textos
  static const Color ecoceDark = Color(0xFF00896F);

  // ===== COLOR DEL INDICADOR DE SWITCH (BASADO EN XML) =====

  /// Turquesa para el indicador de cambio de plataforma - desde background_11.xml
  static const Color switchBlue = Color(0xFF3FD9FF);

  /// Azul medio para estados hover del switch - desde background_22.xml
  static const Color switchBlueLight = Color(0xFF1F97E7);

  /// Morado para elementos especiales - desde background_22.xml
  static const Color switchPurple = Color(0xFF6957BD);

  // ===== GRADIENTES BASADOS EN XML =====

  /// Gradiente principal de fondo - desde background_11.xml
  static const List<Color> backgroundGradient = [
    Color(0xFF90EE80), // Verde lime
    Color(0xFFC3FACC), // Verde agua pastel
    Color(0xFF3FD9FF), // Turquesa brillante
  ];

  /// Gradiente suave verde - desde background_1.xml
  static const List<Color> softGradient = [
    Color(0xFF3DB388), // Verde oscuro
    Color(0xFF70D997), // Verde principal
  ];

  /// Gradiente verde claro - desde background_2.xml
  static const List<Color> accentGradient = [
    Color(0xFF70D997), // Verde principal
    Color(0xFFA3FFA6), // Verde claro
  ];

  /// Gradiente turquesa-morado - desde background_22.xml
  static const List<Color> aquaGradient = [
    Color(0xFF3FD9FF), // Turquesa brillante
    Color(0xFF1F97E7), // Azul medio
    Color(0xFF6957BD), // Morado
  ];

  /// Gradiente principal inverso - desde background_33.xml
  static const List<Color> mainGradient = [
    Color(0xFF3FD9FF), // Turquesa brillante
    Color(0xFFC3FACC), // Verde agua pastel
    Color(0xFF90EE80), // Verde lime
  ];

  /// Gradiente cálido - desde background_3.xml
  static const List<Color> warmGradient = [
    Color(0xFFF4DF9E), // Amarillo suave
    Color(0xFF00896F), // Verde profundo
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

  /// Verde para estados de éxito - más vibrante
  static const Color success = Color(0xFF00D665);

  /// Rojo para errores y alertas
  static const Color error = Color(0xFFEF4444);

  /// Amarillo/naranja para advertencias
  static const Color warning = Color(0xFFF59E0B);

  /// Azul turquesa para información
  static const Color info = Color(0xFF00C4E5);

  // ===== COLORES DE MATERIALES (RECICLAJE) - ACTUALIZADOS =====

  /// Color para PEBD - rosa
  static const Color pebdPink = Color(0xFFEC4899); // Rosa

  /// Color para PP - morado
  static const Color ppPurple = Color(0xFF9333EA); // Morado

  /// Color para Multilaminado - café
  static const Color multilaminadoBrown = Color(0xFF92400E); // Café

  /// Color para vidrio - verde esmeralda
  static const Color glassGreen = Color(0xFF00D665);

  /// Color para metal - gris metálico
  static const Color metalGrey = Color(0xFF6B7280);
  
  /// Color para reciclaje - naranja reciclaje
  static const Color recycleOrange = Color(0xFFFF6B00);

  // ===== COLORES ESPECIALES PARA LA INTERFAZ =====

  /// Rosa para elementos destacados (como se ve en la imagen)
  static const Color accentPink = Color(0xFFFF6B9D);
  
  // ===== COLORES LEGACY (para compatibilidad) =====
  /// Estos colores se mantienen para evitar errores en código existente
  static const Color petBlue = Color(0xFF0085FF);
  static const Color hdpeGreen = Color(0xFF00A854);
  static const Color ppOrange = Color(0xFFFF7A00);
  static const Color otherPurple = Color(0xFF9333EA);
  static const Color pvcRed = Color(0xFFE53935);
  static const Color psYellow = Color(0xFFFFB300);

  /// Amarillo vibrante para notificaciones
  static const Color brightYellow = Color(0xFFFFD93D);

  /// Azul profundo para elementos de navegación
  static const Color deepBlue = Color(0xFF0066CC);

  // ===== SOMBRAS Y OVERLAYS =====

  /// Color para sombras suaves
  static Color shadowColor = Colors.black.withValues(alpha: 0.1);

  /// Color para overlays oscuros
  static Color darkOverlay = Colors.black.withValues(alpha: 0.5);

  /// Color para overlays claros
  static Color lightOverlay = Colors.white.withValues(alpha: 0.8);

  /// Sombra verde para elementos principales
  static Color greenShadow = primaryGreen.withValues(alpha: 0.3);

  /// Sombra turquesa para elementos secundarios
  static Color aquaShadow = aquaGreen.withValues(alpha: 0.3);

  // ===== MÉTODOS ÚTILES =====

  /// Obtiene un color con opacidad
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
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

  /// Obtiene el gradiente principal basado en el contexto
  static LinearGradient getMainGradient({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: mainGradient,
    );
  }

  /// Obtiene el gradiente acuático/turquesa
  static LinearGradient getAquaGradient({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: aquaGradient,
    );
  }
}