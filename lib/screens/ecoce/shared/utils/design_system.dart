import 'package:flutter/material.dart';

/// Sistema de diseño para mantener consistencia en toda la aplicación ECOCE
class EcoceDesignSystem {
  // Prevenir instanciación
  EcoceDesignSystem._();
  
  /// Espaciados estándar
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  
  /// Border radius estándar
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusCircular = 999.0;
  
  /// Opacidades estándar
  static const double opacitySubtle = 0.02;
  static const double opacityLight = 0.05;
  static const double opacityMedium = 0.1;
  static const double opacityStrong = 0.2;
  static const double opacityIntense = 0.3;
  static const double opacityHalf = 0.5;
  static const double opacityDark = 0.9;
  
  /// Tamaños de fuente estándar
  static const double fontSizeXSmall = 11.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 13.0;
  static const double fontSizeBase = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 20.0;
  static const double fontSizeTitle = 24.0;
  
  /// Alturas de línea
  static const double lineHeightTight = 1.2;
  static const double lineHeightBase = 1.5;
  static const double lineHeightRelaxed = 1.8;
  
  /// Duraciones de animación
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 600);
  
  /// Sombras estándar
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];
  
  /// Responsive breakpoints
  static const double breakpointMobile = 360;
  static const double breakpointTablet = 600;
  static const double breakpointDesktop = 1200;
  
  /// Funciones de utilidad responsive
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < breakpointTablet;
      
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= breakpointTablet &&
      MediaQuery.of(context).size.width < breakpointDesktop;
      
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= breakpointDesktop;
  
  /// Función para obtener valores responsive
  static double responsiveValue(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= breakpointDesktop) {
      return desktop ?? tablet ?? mobile;
    } else if (width >= breakpointTablet) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
  
  /// Función para calcular valores basados en porcentaje de pantalla
  static double screenPercentage(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }
  
  /// Padding responsive
  static EdgeInsets responsivePadding(BuildContext context) {
    return EdgeInsets.all(
      responsiveValue(
        context,
        mobile: spacing16,
        tablet: spacing20,
        desktop: spacing24,
      ),
    );
  }
  
  /// Margen responsive
  static EdgeInsets responsiveMargin(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: responsiveValue(
        context,
        mobile: spacing16,
        tablet: spacing20,
        desktop: spacing24,
      ),
      vertical: spacing12,
    );
  }
  
  /// Border radius responsive
  static double responsiveRadius(BuildContext context) {
    return screenPercentage(context, 0.03).clamp(radiusSmall, radiusLarge);
  }
}

/// Extension para facilitar el uso del design system
extension ResponsiveExtension on BuildContext {
  /// Ancho de la pantalla
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Alto de la pantalla
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Obtener un porcentaje del ancho
  double widthPercent(double percent) => screenWidth * percent;
  
  /// Obtener un porcentaje del alto
  double heightPercent(double percent) => screenHeight * percent;
  
  /// Verificar si es móvil
  bool get isMobile => EcoceDesignSystem.isMobile(this);
  
  /// Verificar si es tablet
  bool get isTablet => EcoceDesignSystem.isTablet(this);
  
  /// Verificar si es desktop
  bool get isDesktop => EcoceDesignSystem.isDesktop(this);
  
  /// Obtener padding responsive
  EdgeInsets get responsivePadding => EcoceDesignSystem.responsivePadding(this);
  
  /// Obtener margen responsive
  EdgeInsets get responsiveMargin => EcoceDesignSystem.responsiveMargin(this);
  
  /// Obtener radio responsive
  double get responsiveRadius => EcoceDesignSystem.responsiveRadius(this);
}