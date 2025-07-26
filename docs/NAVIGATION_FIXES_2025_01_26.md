# Correcciones de Navegación y Flujo de Pantallas
**Fecha**: 2025-01-26

## Resumen
Se corrigieron múltiples problemas de navegación que causaban pantallas negras y flujos incorrectos en varios usuarios del sistema ECOCE.

## Problemas y Soluciones

### 1. Pantalla Negra en Documentación del Transformador

#### Problema
Al presionar el botón de retroceso en la pantalla de carga de documentación, aparecía una pantalla negra.

#### Causa
El uso de `pushNamedAndRemoveUntil` con `(route) => false` eliminaba toda la pila de navegación.

#### Solución
```dart
// ANTES - Elimina toda la pila
Navigator.of(context).pushNamedAndRemoveUntil(
  '/transformador_produccion',
  (route) => false,
);

// DESPUÉS - Mantiene la ruta inicial
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(
    builder: (context) => TransformadorProduccionScreen(
      initialTab: 1, // Ir directo a pestaña Documentación
    ),
  ),
  (route) => route.isFirst,
);
```

### 2. Navegación con Callback para Actualización de Datos

#### Implementación
Se agregó un patrón de callback para actualizar las listas después de completar acciones:

```dart
// En transformador_documentacion_screen.dart
Navigator.pop(context, true); // Retorna true cuando se completa

// En transformador_produccion_screen.dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TransformadorDocumentacionScreen(...),
  ),
).then((result) {
  if (result == true) {
    _loadLotes(); // Recargar datos
  }
});
```

### 3. Navegación Después de Formularios

#### Problema
Los formularios navegaban a la pantalla de login en lugar del inicio del usuario.

#### Solución
Usar rutas nombradas específicas por usuario:
```dart
// CORRECTO - Va al inicio del usuario
Navigator.of(context).pushNamedAndRemoveUntil(
  '/transformador_inicio',
  (route) => false,
);

// INCORRECTO - Va al login
Navigator.of(context).popUntil((route) => route.isFirst);
```

### 4. FAB Navigation en Laboratorio

#### Cambios en Perfil y Ayuda
Se corrigió el floating action button para que navegue al escáner:

```dart
// laboratorio_perfil_screen.dart y laboratorio_ayuda_screen.dart
floatingActionButton: FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SharedQRScannerScreen(),
      ),
    );
  },
  backgroundColor: BioWayColors.laboratoryYellow,
  child: const Icon(Icons.qr_code_scanner, color: Colors.white),
),
```

## Patrón de Navegación Recomendado

### 1. Para Volver con Datos
```dart
// Pantalla que retorna datos
Navigator.pop(context, resultado);

// Pantalla que recibe datos
final resultado = await Navigator.push(...);
if (resultado != null) {
  // Procesar resultado
}
```

### 2. Para Reemplazar Toda la Pila
```dart
Navigator.pushNamedAndRemoveUntil(
  context,
  '/ruta_destino',
  (route) => false,
);
```

### 3. Para Mantener Ruta Inicial
```dart
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => PantallaDestino()),
  (route) => route.isFirst,
);
```

### 4. Para Navegación con Parámetros
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PantallaDestino(
      parametro1: valor1,
      parametro2: valor2,
    ),
  ),
);
```

## Stack de Navegación por Usuario

### Transformador
```
1. /transformador_inicio
2. TransformadorProduccionScreen
3. TransformadorFormularioSalida / TransformadorDocumentacionScreen
```

### Laboratorio
```
1. /laboratorio_inicio
2. SharedQRScannerScreen
3. LaboratorioTomaRecepcionScreen
```

### Repositorio
```
1. /repositorio_inicio (desde cualquier usuario)
2. RepositorioLotesScreen
3. LoteDetalleScreen
```

## Mejores Prácticas

1. **Siempre verificar mounted antes de setState**:
```dart
if (mounted) {
  setState(() {
    // Actualizar estado
  });
}
```

2. **Usar MaterialPageRoute para navegación dinámica**:
```dart
// Permite pasar parámetros complejos
MaterialPageRoute(
  builder: (context) => Pantalla(parametros),
)
```

3. **Documentar el flujo esperado**:
```dart
// Navega a documentación y espera resultado
// true = documentación completada
// false/null = cancelado
```

4. **Evitar navegación circular**:
- No navegar a la misma pantalla actual
- Verificar la ruta actual antes de navegar
- Usar `pushReplacement` cuando sea apropiado

## Testing de Navegación

### Casos de Prueba
1. **Flujo Completo sin Retrocesos**
   - Completar todo el proceso sin usar botón back
   - Verificar que llegue al final correctamente

2. **Flujo con Cancelaciones**
   - Cancelar en cada paso del proceso
   - Verificar que vuelva a la pantalla correcta

3. **Navegación entre Usuarios**
   - Cambiar de usuario desde el repositorio
   - Verificar que mantenga el contexto correcto

4. **Rotación de Pantalla**
   - Rotar en medio de un formulario
   - Verificar que no pierda datos ni navegación

## Conclusiones

Las correcciones de navegación mejoran significativamente la experiencia del usuario al:
- Eliminar las pantallas negras
- Mantener un flujo lógico y predecible
- Actualizar datos automáticamente después de acciones
- Preservar el contexto del usuario

Es crucial seguir estos patrones para mantener la consistencia en toda la aplicación.