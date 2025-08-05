import 'package:flutter/material.dart';

/// Constantes de UI para mantener consistencia visual en toda la aplicación
/// Estos valores han sido extraídos del código existente para centralizar
/// la gestión de dimensiones, espaciados y otros valores de UI.
class UIConstants {
  // Prevenir instanciación
  UIConstants._();
  
  // ===== BORDER RADIUS =====
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusRound = 30.0;
  
  // ===== SPACING (basado en múltiplos de 4) =====
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing15 = 15.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  
  // ===== COMPONENT HEIGHTS =====
  static const double buttonHeight = 56.0;
  static const double buttonHeightLarge = 70.0;
  static const double buttonHeightSmall = 44.0;
  static const double buttonHeightCompact = 52.0;
  static const double textFieldHeight = 56.0;
  static const double statCardHeight = 70.0;
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 60.0;
  static const double headerHeight = 280.0;
  static const double headerHeightWithStats = 320.0;
  
  // ===== ICON SIZES =====
  static const double iconSizeXSmall = 12.0;
  static const double iconSizeSmall = 16.0;
  static const double iconSizeBody = 18.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double buttonHeightMedium = 48.0;
  static const double iconSizeXLarge = 48.0;
  static const double iconSizeDialog = 60.0;
  static const double iconSizeEmpty = 64.0;
  
  // ===== FONT SIZES =====
  static const double fontSizeXSmall = 11.0;
  static const double fontSizeSmall = 13.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeTitle = 24.0;
  static const double fontSizeXXLarge = 28.0;
  
  // ===== ELEVATION =====
  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  static const double elevationXHigh = 12.0;
  static const double elevationCard = 10.0;
  
  // ===== OPACITY VALUES =====
  static const double opacityDisabled = 0.38;
  static const double opacityVeryLow = 0.05;
  static const double opacityLow = 0.1;
  static const double opacityMediumLow = 0.2;
  static const double opacityMedium = 0.3;
  static const double opacityMediumHigh = 0.5;
  static const double opacityHigh = 0.6;
  static const double opacityVeryHigh = 0.8;
  static const double opacityAlmostFull = 0.9;
  static const double lineHeightMedium = 1.4;
  static const double offsetY = 2.0;
  static const double opacityFull = 1.0;
  
  // ===== ANIMATION DURATIONS =====
  static const int animationDurationFast = 200;
  static const int animationDurationShort = 150;
  static const int animationDurationMedium = 300;
  static const int animationDurationLong = 500;
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800);
  
  // ===== CONTAINER CONSTRAINTS =====
  static const double maxWidthDialog = 400.0;
  static const double maxWidthForm = 600.0;
  static const double minTouchTarget = 44.0; // Material Design guideline
  static const double maxWidthCard = 500.0;
  
  // ===== QR CODE SIZES =====
  static const double qrSizeSmall = 150.0;
  static const double qrSizeMedium = 200.0;
  static const double qrSizeLarge = 250.0;
  static const double qrSizeDisplay = 218.0;
  
  // ===== COMMON WIDTHS =====
  static const double iconContainerSmall = 40.0;
  static const double iconContainerMedium = 48.0;
  static const double iconContainerLarge = 56.0;
  static const double iconContainerXLarge = 120.0;
  
  // ===== LIST ITEM DIMENSIONS =====
  static const double listItemImageSize = 48.0;
  static const double listItemImageSizeSmall = 42.0;
  
  // ===== SIGNATURE DIMENSIONS =====
  static const double signatureWidth = 300.0;
  static const double signatureHeight = 120.0;
  static const double signatureAspectRatio = 2.5;
  
  // ===== LOGO DIMENSIONS =====
  static const double logoWidthSmall = 70.0;
  static const double logoHeightSmall = 35.0;
  static const double logoSize = 140.0;
  
  // ===== CHIP DIMENSIONS =====
  static const double chipPaddingHorizontal = 8.0;
  static const double chipPaddingVertical = 4.0;
  static const double chipPaddingHorizontalCompact = 6.0;
  static const double chipPaddingVerticalCompact = 3.0;
  
  // ===== BORDER WIDTHS =====
  static const double borderWidthThin = 1.0;
  static const double borderWidthMedium = 1.5;
  static const double borderWidthThick = 2.5;
  
  // ===== BLUR RADIUS =====
  static const double blurRadiusSmall = 4.0;
  static const double blurRadiusMedium = 12.0;
  static const double blurRadiusLarge = 20.0;
  static const double blurRadiusXLarge = 30.0;
  
  // ===== STROKE WIDTH =====
  static const double strokeWidth = 2.0;
  
  // ===== ADDITIONAL SIZES =====
  static const double signatureSize = 100.0;
  static const double elevationSmall = 2.0;
  static const double tabBarHeight = 48.0;
  static const double indicatorWeight = 3.0;
  static const double dividerThickness = 1.0;
  static const double iconSizeButton = 40.0;
  static const double spacing80 = 80.0;
  static const double borderRadiusXL = 24.0;
  static const double borderRadiusTiny = 4.0;
  static const double maxContentWidth = 1200.0;
  static const double lineHeightDefault = 1.2;
  
  // ===== LETTER SPACING =====
  static const double letterSpacingSmall = 0.3;
  static const double letterSpacingMedium = 0.5;
  
  // ===== MAP CONSTANTS =====
  static const double mapZoomDefault = 17.0;
}

/// Helper extension para BorderRadius comunes
extension BorderRadiusConstants on UIConstants {
  static BorderRadius get borderRadiusSmall => 
    BorderRadius.circular(UIConstants.radiusSmall);
    
  static BorderRadius get borderRadiusMedium => 
    BorderRadius.circular(UIConstants.radiusMedium);
    
  static BorderRadius get borderRadiusLarge => 
    BorderRadius.circular(UIConstants.radiusLarge);
    
  static BorderRadius get borderRadiusXLarge => 
    BorderRadius.circular(UIConstants.radiusXLarge);
    
  static BorderRadius get borderRadiusRound => 
    BorderRadius.circular(UIConstants.radiusRound);
}

/// Helper extension para EdgeInsets comunes
extension EdgeInsetsConstants on UIConstants {
  static EdgeInsets get paddingAll4 => 
    EdgeInsets.all(UIConstants.spacing4);
    
  static EdgeInsets get paddingAll8 => 
    EdgeInsets.all(UIConstants.spacing8);
    
  static EdgeInsets get paddingAll12 => 
    EdgeInsets.all(UIConstants.spacing12);
    
  static EdgeInsets get paddingAll16 => 
    EdgeInsets.all(UIConstants.spacing16);
    
  static EdgeInsets get paddingAll20 => 
    EdgeInsets.all(UIConstants.spacing20);
    
  static EdgeInsets get paddingAll24 => 
    EdgeInsets.all(UIConstants.spacing24);
    
  static EdgeInsets get paddingAll32 => 
    EdgeInsets.all(UIConstants.spacing32);
    
  static EdgeInsets get paddingHorizontal8 => 
    EdgeInsets.symmetric(horizontal: UIConstants.spacing8);
    
  static EdgeInsets get paddingHorizontal12 => 
    EdgeInsets.symmetric(horizontal: UIConstants.spacing12);
    
  static EdgeInsets get paddingHorizontal16 => 
    EdgeInsets.symmetric(horizontal: UIConstants.spacing16);
    
  static EdgeInsets get paddingHorizontal20 => 
    EdgeInsets.symmetric(horizontal: UIConstants.spacing20);
    
  static EdgeInsets get paddingVertical8 => 
    EdgeInsets.symmetric(vertical: UIConstants.spacing8);
    
  static EdgeInsets get paddingVertical12 => 
    EdgeInsets.symmetric(vertical: UIConstants.spacing12);
    
  static EdgeInsets get paddingVertical16 => 
    EdgeInsets.symmetric(vertical: UIConstants.spacing16);
    
  static EdgeInsets get paddingNone => 
    EdgeInsets.zero;
    
  static EdgeInsets get paddingH8V4 => 
    EdgeInsets.symmetric(horizontal: UIConstants.spacing8, vertical: UIConstants.spacing4);
    
  static EdgeInsets get paddingH12V8 => 
    EdgeInsets.symmetric(horizontal: UIConstants.spacing12, vertical: UIConstants.spacing8);
    
  static EdgeInsets get paddingH16V8 => 
    EdgeInsets.symmetric(horizontal: UIConstants.spacing16, vertical: UIConstants.spacing8);
    
  static EdgeInsets get paddingH16V12 => 
    EdgeInsets.symmetric(horizontal: UIConstants.spacing16, vertical: UIConstants.spacing12);
    
  static EdgeInsets get paddingH20V16 => 
    EdgeInsets.symmetric(horizontal: UIConstants.spacing20, vertical: UIConstants.spacing16);
    
  static EdgeInsets get paddingH24V16 => 
    EdgeInsets.symmetric(horizontal: UIConstants.spacing24, vertical: UIConstants.spacing16);
    
  static EdgeInsets get paddingLTRB16_8_16_16 => 
    EdgeInsets.fromLTRB(UIConstants.spacing16, UIConstants.spacing8, UIConstants.spacing16, UIConstants.spacing16);
    
  static EdgeInsets get paddingLTRB20_12_20_8 => 
    EdgeInsets.fromLTRB(UIConstants.spacing20, UIConstants.spacing12, UIConstants.spacing20, UIConstants.spacing8);
}

/// Helper para valores responsive
class ResponsiveConstants {
  /// Obtiene el espaciado apropiado según el ancho de pantalla
  static double getSpacing(double screenWidth) {
    if (screenWidth < 360) return UIConstants.spacing12;
    if (screenWidth < 414) return UIConstants.spacing16;
    return UIConstants.spacing20;
  }
  
  /// Obtiene el tamaño de fuente ajustado según el ancho de pantalla
  static double getFontSize(double screenWidth, {required double baseSize}) {
    if (screenWidth < 360) return baseSize * 0.9;
    if (screenWidth < 414) return baseSize;
    return baseSize * 1.1;
  }
  
  /// Determina si la pantalla es compacta
  static bool isCompactScreen(double screenWidth) {
    return screenWidth < 360;
  }
  
  /// Obtiene el número de columnas para grids
  static int getGridColumns(double screenWidth) {
    if (screenWidth < 600) return 2;
    if (screenWidth < 900) return 3;
    return 4;
  }
}