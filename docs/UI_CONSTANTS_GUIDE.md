# UI Constants Guide - BioWay México

Este documento describe el sistema de constantes UI centralizado implementado en el proyecto BioWay México para garantizar consistencia visual y facilitar el mantenimiento.

## Visión General

El sistema de constantes UI centraliza todos los valores de diseño en un único archivo (`lib/utils/ui_constants.dart`), eliminando valores hardcodeados dispersos por el código y facilitando cambios globales de diseño.

## Estructura de UIConstants

### Importación
```dart
import 'package:app/utils/ui_constants.dart';
```

### Categorías de Constantes

#### 1. Border Radius
```dart
// Valores base
UIConstants.radiusSmall     // 8.0
UIConstants.radiusMedium    // 12.0
UIConstants.radiusLarge     // 16.0
UIConstants.radiusXLarge    // 20.0
UIConstants.radiusRound     // 30.0

// Helper extension
BorderRadiusConstants.borderRadiusSmall
BorderRadiusConstants.borderRadiusMedium
BorderRadiusConstants.borderRadiusLarge
BorderRadiusConstants.borderRadiusXLarge
BorderRadiusConstants.borderRadiusRound
```

#### 2. Spacing (múltiplos de 4)
```dart
UIConstants.spacing4    // 4.0
UIConstants.spacing8    // 8.0
UIConstants.spacing10   // 10.0
UIConstants.spacing12   // 12.0
UIConstants.spacing15   // 15.0
UIConstants.spacing16   // 16.0
UIConstants.spacing20   // 20.0
UIConstants.spacing24   // 24.0
UIConstants.spacing32   // 32.0
UIConstants.spacing40   // 40.0
UIConstants.spacing48   // 48.0
```

#### 3. Component Heights
```dart
UIConstants.buttonHeight              // 56.0
UIConstants.buttonHeightLarge         // 70.0
UIConstants.buttonHeightSmall         // 44.0
UIConstants.buttonHeightCompact       // 52.0
UIConstants.buttonHeightMedium        // 48.0
UIConstants.textFieldHeight           // 56.0
UIConstants.statCardHeight            // 70.0
UIConstants.appBarHeight              // 56.0
UIConstants.bottomNavHeight           // 60.0
UIConstants.headerHeight              // 280.0
UIConstants.headerHeightWithStats     // 320.0
```

#### 4. Icon Sizes
```dart
UIConstants.iconSizeXSmall    // 12.0
UIConstants.iconSizeSmall     // 16.0
UIConstants.iconSizeBody      // 18.0
UIConstants.iconSizeMedium    // 24.0
UIConstants.iconSizeLarge     // 32.0
UIConstants.iconSizeXLarge    // 48.0
UIConstants.iconSizeDialog    // 64.0
```

#### 5. Font Sizes
```dart
UIConstants.fontSizeXSmall    // 10.0
UIConstants.fontSizeSmall     // 12.0
UIConstants.fontSizeBody      // 14.0
UIConstants.fontSizeMedium    // 16.0
UIConstants.fontSizeLarge     // 18.0
UIConstants.fontSizeXLarge    // 20.0
UIConstants.fontSizeXXLarge   // 24.0
UIConstants.fontSizeTitle     // 32.0
UIConstants.fontSizeDisplay   // 48.0
```

#### 6. Elevation
```dart
UIConstants.elevationNone      // 0.0
UIConstants.elevationSmall     // 2.0
UIConstants.elevationMedium    // 4.0
UIConstants.elevationLarge     // 8.0
UIConstants.elevationXLarge    // 16.0
```

#### 7. Opacity
```dart
UIConstants.opacityVeryLow    // 0.1
UIConstants.opacityLow        // 0.2
UIConstants.opacityMedium     // 0.5
UIConstants.opacityHigh       // 0.7
UIConstants.opacityVeryHigh   // 0.9
```

#### 8. Animation Durations
```dart
UIConstants.animationDurationFast      // 150ms
UIConstants.animationDurationShort     // 200ms
UIConstants.animationDurationMedium    // 300ms
UIConstants.animationDurationLong      // 500ms
UIConstants.animationDurationXLong     // 800ms
```

#### 9. Container Sizes
```dart
UIConstants.iconContainerSmall     // 40.0
UIConstants.iconContainerMedium    // 48.0
UIConstants.iconContainerLarge     // 56.0
UIConstants.iconContainerXLarge    // 80.0
```

#### 10. Constantes Específicas
```dart
// QR Code Sizes
UIConstants.qrSizeSmall     // 100.0
UIConstants.qrSizeMedium    // 150.0
UIConstants.qrSizeLarge     // 200.0

// Dialog Dimensions
UIConstants.maxWidthDialog     // 400.0
UIConstants.minHeightDialog    // 200.0

// Signature Dimensions
UIConstants.signatureWidth         // 300.0
UIConstants.signatureHeight        // 120.0
UIConstants.signatureAspectRatio   // 2.5

// Map Constants
UIConstants.mapZoomDefault    // 17.0

// Border Widths
UIConstants.borderWidthThin     // 1.0
UIConstants.borderWidthMedium   // 1.5
UIConstants.borderWidthThick    // 2.5

// Letter Spacing
UIConstants.letterSpacingSmall    // 0.3
UIConstants.letterSpacingMedium   // 0.5

// Blur Radius
UIConstants.blurRadiusSmall     // 4.0
UIConstants.blurRadiusMedium    // 12.0
UIConstants.blurRadiusLarge     // 20.0
UIConstants.blurRadiusXLarge    // 30.0
```

### Helper Extensions

#### EdgeInsetsConstants
```dart
EdgeInsetsConstants.paddingAll4
EdgeInsetsConstants.paddingAll8
EdgeInsetsConstants.paddingAll12
EdgeInsetsConstants.paddingAll16
EdgeInsetsConstants.paddingAll20
EdgeInsetsConstants.paddingAll24
EdgeInsetsConstants.paddingAll32

EdgeInsetsConstants.paddingH8V4
EdgeInsetsConstants.paddingH12V8
EdgeInsetsConstants.paddingH16V8
EdgeInsetsConstants.paddingH16V12
EdgeInsetsConstants.paddingH20V16
EdgeInsetsConstants.paddingH24V16

EdgeInsetsConstants.paddingLTRB16_8_16_16
EdgeInsetsConstants.paddingLTRB20_12_20_8
```

## Patrones de Uso

### 1. Padding y Margin
```dart
// Antes
padding: EdgeInsets.all(16)

// Después
padding: EdgeInsetsConstants.paddingAll16
```

### 2. Border Radius
```dart
// Antes
borderRadius: BorderRadius.circular(12)

// Después
borderRadius: BorderRadiusConstants.borderRadiusMedium
```

### 3. Spacing
```dart
// Antes
SizedBox(height: 16)

// Después
SizedBox(height: UIConstants.spacing16)
```

### 4. Tamaños de Fuente
```dart
// Antes
fontSize: 18

// Después
fontSize: UIConstants.fontSizeLarge
```

### 5. Opacidad
```dart
// Antes
color: Colors.black.withValues(alpha: 0.5)

// Después
color: Colors.black.withValues(alpha: UIConstants.opacityMedium)
```

### 6. Animaciones
```dart
// Antes
duration: Duration(milliseconds: 300)

// Después
duration: Duration(milliseconds: UIConstants.animationDurationMedium)
```

## Beneficios

1. **Consistencia**: Todos los componentes usan los mismos valores
2. **Mantenibilidad**: Cambios globales desde un único lugar
3. **Legibilidad**: Código autodocumentado con nombres descriptivos
4. **Escalabilidad**: Fácil agregar nuevas constantes
5. **Type Safety**: Valores tipados correctamente

## Migración de Código Existente

Para migrar código existente:

1. Importar `ui_constants.dart`
2. Identificar valores hardcodeados
3. Reemplazar con la constante apropiada
4. Si no existe la constante, considerar si es un valor único o reutilizable

### Ejemplo de Migración
```dart
// Código original
Container(
  padding: EdgeInsets.all(20),
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Text(
    'Hola',
    style: TextStyle(fontSize: 16),
  ),
)

// Código migrado
Container(
  padding: EdgeInsetsConstants.paddingAll20,
  margin: EdgeInsetsConstants.paddingH16V8,
  decoration: BoxDecoration(
    borderRadius: BorderRadiusConstants.borderRadiusMedium,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
        blurRadius: UIConstants.blurRadiusMedium,
        offset: Offset(0, UIConstants.spacing4),
      ),
    ],
  ),
  child: Text(
    'Hola',
    style: TextStyle(fontSize: UIConstants.fontSizeMedium),
  ),
)
```

## Convenciones

1. **Nombres descriptivos**: Los nombres deben indicar claramente el propósito
2. **Agrupación lógica**: Las constantes se agrupan por categoría
3. **Valores base**: Usar múltiplos de 4 para spacing cuando sea posible
4. **Documentación**: Agregar comentarios para valores no obvios
5. **No duplicar**: Verificar si existe una constante antes de crear una nueva

## Mantenimiento

Al agregar nuevas constantes:

1. Verificar que no exista una similar
2. Colocarla en la categoría apropiada
3. Seguir la convención de nombres
4. Documentar si el uso no es obvio
5. Considerar si necesita helper extensions

## Notas Importantes

- Los colores se mantienen en `BioWayColors` (archivo separado)
- Las rutas de navegación están en el sistema de routing
- Los textos y strings localizables no se incluyen aquí
- Valores únicos que no se repiten no necesitan ser constantes