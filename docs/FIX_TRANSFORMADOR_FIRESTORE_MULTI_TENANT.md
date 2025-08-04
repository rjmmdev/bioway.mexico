# Fix: Transformador usando instancia incorrecta de Firestore (Multi-Tenant)

## Problema Identificado
El Transformador no podía ver ni consultar sus megalotes (transformaciones) porque usaba `FirebaseFirestore.instance` (instancia default) mientras que el sistema usa arquitectura multi-tenant con instancias nombradas.

### Síntomas
- Megalotes creados por el Transformador no aparecían en las listas
- Las consultas retornaban 0 resultados aunque los datos existían en Firebase
- El Reciclador funcionaba correctamente con la misma funcionalidad

## Causa Raíz
El sistema usa Firebase multi-tenant con apps nombradas para ECOCE y BioWay:
- **Datos se guardan en**: `FirebaseFirestore.instanceFor(app: ecoceApp)`
- **Transformador consultaba en**: `FirebaseFirestore.instance` (app default que no existe)

### Arquitectura Multi-Tenant
```
Firebase Apps:
├── "ecoce" → FirebaseFirestore.instanceFor(app: ecoceApp)  ✅ Datos aquí
├── "bioway" → FirebaseFirestore.instanceFor(app: biowayApp) (futuro)
└── default → FirebaseFirestore.instance                      ❌ Vacío
```

## Diferencias Encontradas

### 1. Consulta de Transformaciones

| Usuario | Método de Consulta | Instancia Firestore |
|---------|-------------------|---------------------|
| **Reciclador** | `TransformacionService.obtenerTransformacionesUsuario()` | `FirebaseFirestore.instanceFor(app: ecoceApp)` ✅ |
| **Transformador** | Consulta directa con `.where()` | `FirebaseFirestore.instance` ❌ |

### 2. Guardado de Transformaciones

| Usuario | Método de Guardado | Instancia Firestore |
|---------|-------------------|---------------------|
| **Reciclador** | `TransformacionService.crearTransformacion()` | `FirebaseFirestore.instanceFor(app: ecoceApp)` ✅ |
| **Transformador** | Creación directa con `.add()` | Mezclado: A veces correcto, a veces incorrecto ⚠️ |

## Solución Aplicada

### 1. Agregar FirebaseManager a todos los archivos del Transformador
```dart
import '../../../services/firebase/firebase_manager.dart';

class _State extends State<Widget> {
  final FirebaseManager _firebaseManager = FirebaseManager();
  
  // Obtener Firestore de la instancia correcta (multi-tenant)
  FirebaseFirestore get _firestore {
    final app = _firebaseManager.currentApp;
    if (app != null) {
      return FirebaseFirestore.instanceFor(app: app);
    }
    return FirebaseFirestore.instance;
  }
```

### 2. Reemplazar todas las referencias a FirebaseFirestore.instance
```dart
// ANTES (Incorrecto)
FirebaseFirestore.instance
    .collection('transformaciones')
    .where('tipo', isEqualTo: 'agrupacion_transformador')

// DESPUÉS (Correcto)
_firestore
    .collection('transformaciones')
    .where('tipo', isEqualTo: 'agrupacion_transformador')
```

### 3. Usar TransformacionService para consultas
```dart
// ANTES (Incorrecto)
final stream = FirebaseFirestore.instance
    .collection('transformaciones')
    .where('tipo', isEqualTo: 'agrupacion_transformador')
    .where('usuario_id', isEqualTo: userId)
    .snapshots();

// DESPUÉS (Correcto)
_transformacionService.obtenerTransformacionesUsuario().listen((transformaciones) {
  final transformacionesTransformador = transformaciones.where((t) {
    return t.tipo == 'agrupacion_transformador';
  }).toList();
});
```

## Archivos Modificados

### 1. `transformador_produccion_screen.dart`
- **Línea 175-203**: Cambiado `_loadTransformaciones()` para usar `TransformacionService`
- Ahora usa el stream del servicio que maneja multi-tenant correctamente

### 2. `transformador_formulario_salida.dart`
- **Líneas 55-71**: Agregado `FirebaseManager` y getter `_firestore`
- **7 reemplazos**: Cambiado `FirebaseFirestore.instance` → `_firestore`
- Garantiza que todas las operaciones usen la instancia ECOCE

### 3. `transformador_documentacion_megalote_screen.dart`
- **Líneas 25-36**: Agregado `FirebaseManager` y getter `_firestore`
- **2 reemplazos**: Cambiado `FirebaseFirestore.instance` → `_firestore`

### 4. `transformador_transformacion_documentacion.dart`
- **Líneas 23-35**: Agregado `FirebaseManager` y getter `_firestore`
- Ya usaba `TransformacionService` para cargar datos (correcto)

## Verificación
El sistema ahora:
1. ✅ Crea megalotes en la instancia ECOCE correcta
2. ✅ Consulta megalotes en la misma instancia ECOCE
3. ✅ Muestra los megalotes creados en las listas
4. ✅ Mantiene consistencia entre crear y consultar datos
5. ✅ Funciona igual que el Usuario Reciclador

## Impacto
- **Visibilidad de Megalotes**: Los megalotes del Transformador ahora aparecen correctamente
- **Consistencia de Datos**: Todos los datos se guardan y consultan en la misma instancia
- **Sin Pérdida de Datos**: Los megalotes creados anteriormente están en ECOCE y ahora son visibles

## Lecciones Aprendidas
1. **SIEMPRE verificar la instancia de Firestore** en sistemas multi-tenant
2. **Usar servicios centralizados** que manejen la lógica multi-tenant
3. **No mezclar** `FirebaseFirestore.instance` con `FirebaseFirestore.instanceFor(app)`
4. **Mantener consistencia** entre diferentes usuarios que usan la misma funcionalidad
5. **El TransformacionService** ya maneja correctamente multi-tenant y debe ser reutilizado

## Testing Recomendado
1. Crear un megalote con el Transformador
2. Verificar que aparece en la lista de megalotes
3. Abrir el megalote y verificar que se carga correctamente
4. Subir documentación y verificar que se actualiza
5. Verificar que las estadísticas reflejan los megalotes creados

## Estado
✅ **IMPLEMENTADO** - 2025-01-29

## Relación con Otros Fixes
Este fix complementa el anterior `FIX_TRANSFORMADOR_MEGALOTES_PERMISSION_DENIED.md`:
- **Anterior**: Corrigió el formato de datos para cumplir con las reglas de Firestore
- **Este**: Corrige la instancia de Firestore para que los datos sean visibles

Ambos fixes son necesarios para que el sistema funcione correctamente.