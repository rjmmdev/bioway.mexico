# Guía de Uso: UI Constants

## Introducción

Se ha implementado un sistema centralizado de constantes UI en `lib/utils/ui_constants.dart` para mantener consistencia visual en toda la aplicación BioWay México.

## ¿Por qué usar constantes UI?

1. **Consistencia**: Un solo lugar para gestionar valores de UI
2. **Mantenimiento**: Cambiar un valor actualiza toda la app
3. **Legibilidad**: `UIConstants.spacing16` es más claro que `16.0`
4. **Prevención de errores**: No más valores mágicos dispersos

## Estructura de las Constantes

### Border Radius
```dart
// Uso anterior
BorderRadius.circular(16)

// Uso con constantes
BorderRadiusConstants.borderRadiusLarge
```

Valores disponibles:
- `radiusSmall`: 8.0
- `radiusMedium`: 12.0
- `radiusLarge`: 16.0
- `radiusXLarge`: 20.0
- `radiusRound`: 30.0

### Spacing
```dart
// Uso anterior
padding: EdgeInsets.all(16)

// Uso con constantes
padding: EdgeInsetsConstants.paddingAll16

// O manualmente
padding: EdgeInsets.all(UIConstants.spacing16)
```

### Component Heights
```dart
// Uso anterior
height: 56,

// Uso con constantes
height: UIConstants.buttonHeight,
```

Valores principales:
- `buttonHeight`: 56.0
- `buttonHeightLarge`: 70.0
- `statCardHeight`: 70.0
- `headerHeightWithStats`: 320.0

### Icon Sizes
```dart
// Uso anterior
size: 60,

// Uso con constantes
size: UIConstants.iconSizeDialog,
```

### Font Sizes
```dart
// Uso anterior
fontSize: 16,

// Uso con constantes
fontSize: UIConstants.fontSizeBody,
```

## Ejemplos de Implementación

### Dialog
```dart
AlertDialog(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadiusConstants.borderRadiusLarge,
  ),
  title: Column(
    children: [
      Icon(
        Icons.check_circle,
        size: UIConstants.iconSizeDialog,
      ),
      SizedBox(height: UIConstants.spacing16),
      Text(
        'Título',
        style: TextStyle(
          fontSize: UIConstants.fontSizeXLarge,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
)
```

### Button
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    minimumSize: Size(double.infinity, UIConstants.buttonHeight),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadiusConstants.borderRadiusSmall,
    ),
    padding: EdgeInsets.symmetric(
      horizontal: UIConstants.spacing32,
      vertical: UIConstants.spacing12,
    ),
  ),
  child: Text('Acción'),
  onPressed: () {},
)
```

### Card
```dart
Container(
  padding: EdgeInsetsConstants.paddingAll16,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadiusConstants.borderRadiusLarge,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(UIConstants.opacityVeryLow),
        blurRadius: UIConstants.elevationCard,
        offset: Offset(0, UIConstants.spacing4),
      ),
    ],
  ),
  child: // contenido
)
```

## Responsive Helpers

Para valores que cambian según el tamaño de pantalla:

```dart
final screenWidth = MediaQuery.of(context).size.width;
final spacing = ResponsiveConstants.getSpacing(screenWidth);
final isCompact = ResponsiveConstants.isCompactScreen(screenWidth);

Text(
  'Texto',
  style: TextStyle(
    fontSize: ResponsiveConstants.getFontSize(
      screenWidth,
      baseSize: UIConstants.fontSizeBody,
    ),
  ),
)
```

## Migración Gradual

1. Al modificar un archivo existente, reemplaza valores hardcodeados con constantes
2. Importa: `import 'package:app/utils/ui_constants.dart';`
3. Usa las constantes apropiadas según el contexto

## Beneficios a Largo Plazo

- Cambiar el diseño de toda la app modificando solo las constantes
- Garantizar que nuevos desarrollos mantengan consistencia
- Facilitar temas claros/oscuros en el futuro
- Mejorar accesibilidad con tamaños mínimos consistentes

## Archivos Ya Migrados

- `dialog_utils.dart` - Parcialmente migrado
- `transformador_inicio_screen.dart` - Parcialmente migrado

La migración completa se realizará gradualmente para evitar cambios masivos.