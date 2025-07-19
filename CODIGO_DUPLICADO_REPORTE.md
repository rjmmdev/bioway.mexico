# Reporte de Código Duplicado - BioWay México

## Resumen Ejecutivo

Se han identificado múltiples patrones de código duplicado en el proyecto que pueden ser refactorizados para mejorar la mantenibilidad y reducir la redundancia.

## 1. Funciones de Formateo de Fecha

### Duplicación Encontrada
- **material_utils.dart**: `formatDate()`, `formatDateString()`, `formatDateTime()`
- **maestro_administracion_perfiles.dart**: `_formatDate()` (línea 776)
- **maestro_aprobaciones_screen.dart**: `_formatDate()` (línea 728)
- **origen_lote_detalle_screen.dart**: `_fechaFormateada` getter (línea 81)
- **reciclador_lote_qr_screen.dart**: `_fechaEntradaFormateada`, `_fechaSalidaFormateada` getters

### Patrón Común
```dart
// Patrón repetido en múltiples archivos
'${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
```

### Solución Propuesta
Centralizar todas las funciones de formateo de fecha en `MaterialUtils` o crear una nueva clase `DateFormatUtils`.

## 2. Funciones de Colores de Materiales

### Duplicación Encontrada
- **material_utils.dart**: `getMaterialColor()` (línea 4)
- **material_selector.dart**: `_getColorForMaterial()` (línea 63)
- **transporte_entregar_screen.dart**: `_getMaterialColor()` (línea 289)
- **placeholder_perfil_screen.dart**: `_getMaterialColor()` (línea 746)
- **reciclador_lotes_registro.dart**: `_getMaterialColor()` (línea 154)
- **reciclador_lote_qr_screen.dart**: `_getMaterialColor()` (línea 136)

### Patrón Común
```dart
switch (material) {
  case 'PEBD':
    return BioWayColors.pebdPink;
  case 'PP':
    return BioWayColors.ppPurple;
  case 'Multilaminado':
    return BioWayColors.multilaminadoBrown;
  default:
    return Colors.grey;
}
```

### Solución Propuesta
Usar la función existente en `material_utils.dart` en todos los lugares.

## 3. Funciones de Iconos de Materiales

### Duplicación Encontrada
- **material_utils.dart**: `getMaterialIcon()` (línea 17)
- **laboratorio_muestra_card.dart**: `_getMaterialIcon()` (línea 293)
- **transporte_entregar_screen.dart**: `_getMaterialIcon()` (línea 312)

### Patrón Común
```dart
switch (material) {
  case 'PEBD':
    return Icons.shopping_bag;
  case 'PP':
    return Icons.kitchen;
  case 'Multilaminado':
    return Icons.layers;
  default:
    return Icons.recycling;
}
```

## 4. Diálogos y Alertas Comunes

### Duplicación Potencial
- **dialog_utils.dart**: Contiene implementaciones centralizadas de diálogos
- Sin embargo, muchas pantallas implementan sus propios diálogos personalizados

### Funciones Disponibles en DialogUtils
- `showSuccessDialog()`
- `showErrorDialog()`
- `showConfirmDialog()`
- `showLoadingDialog()`
- `showInfoDialog()`

### Recomendación
Auditar todas las pantallas para usar `DialogUtils` en lugar de implementaciones personalizadas.

## 5. Validadores de Formularios

### Centralización Existente
- **validation_utils.dart**: Ya contiene validadores centralizados
  - `validateRequired()`
  - `validateEmail()`
  - `validatePhoneNumber()`
  - `validateRFC()`
  - `validatePostalCode()`
  - `validateWeight()`

### Problema Identificado
Algunas pantallas pueden estar implementando sus propias validaciones en lugar de usar `ValidationUtils`.

## 6. Formateadores de Input

### Duplicación Encontrada
- **form_widgets.dart**: `_PhoneNumberFormatter` (línea 491)
- **input_formatters.dart**: `_PhoneNumberFormatter` (línea 33)

### Solución Propuesta
Eliminar la duplicación y usar solo la implementación en `input_formatters.dart`.

## 7. Funciones de Navegación

### Patrón Común
```dart
Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => Screen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  ),
);
```

### Solución Existente
- **navigation_utils.dart**: Ya existe `NavigationUtils.navigateWithFade()`

### Recomendación
Auditar y reemplazar todas las navegaciones personalizadas con `NavigationUtils`.

## 8. Formateo de Peso

### Patrón Común
```dart
'${weight.toStringAsFixed(0)} kg'
```

### Recomendación
Crear una función centralizada `formatWeight()` en `MaterialUtils`:
```dart
static String formatWeight(double weight) {
  if (weight >= 1000) {
    return '${(weight / 1000).toStringAsFixed(1)}T';
  }
  return '${weight.toStringAsFixed(0)} kg';
}
```

## 9. Manejo de Imágenes y Documentos

### Centralización Existente
- **image_service.dart**: Manejo centralizado de imágenes
- **document_service.dart**: Manejo centralizado de documentos

### Funciones Disponibles
- `ImageService.takePhoto()`
- `ImageService.pickFromGallery()`
- `ImageService.compressImage()`
- `DocumentService.pickDocument()`
- `DocumentService.uploadDocument()`

## Recomendaciones de Acción

1. **Prioridad Alta**:
   - Refactorizar todas las funciones de color de materiales para usar `MaterialUtils.getMaterialColor()`
   - Eliminar la duplicación de `_PhoneNumberFormatter`
   - Centralizar el formateo de fechas

2. **Prioridad Media**:
   - Crear función `formatWeight()` centralizada
   - Auditar y reemplazar diálogos personalizados con `DialogUtils`
   - Reemplazar navegaciones personalizadas con `NavigationUtils`

3. **Prioridad Baja**:
   - Documentar las utilidades existentes para aumentar su uso
   - Crear tests unitarios para todas las funciones de utilidad

## Impacto Estimado

- **Reducción de líneas de código**: ~500-800 líneas
- **Mejora en mantenibilidad**: Cambios centralizados en un solo lugar
- **Reducción de bugs**: Menos probabilidad de inconsistencias
- **Facilidad de testing**: Funciones centralizadas más fáciles de probar

## Próximos Pasos

1. Revisar este reporte con el equipo
2. Priorizar las refactorizaciones según el impacto
3. Crear tareas específicas para cada refactorización
4. Implementar cambios de forma incremental
5. Actualizar la documentación del proyecto