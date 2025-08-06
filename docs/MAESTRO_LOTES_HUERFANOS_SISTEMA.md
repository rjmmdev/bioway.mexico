# Sistema de Detección y Eliminación de Lotes Huérfanos - Usuario Maestro ECOCE

## Descripción General

El sistema de lotes huérfanos permite al usuario Maestro ECOCE detectar y eliminar documentos en Firebase cuyo usuario creador ya no existe en el sistema. Esta funcionalidad es crítica para mantener la integridad de la base de datos y liberar espacio de documentos obsoletos.

## Fecha de Implementación
- **Implementación inicial**: 2025-01-06
- **Última actualización**: 2025-01-06 (Agregado soporte para sublotes)

## Ubicación en la Aplicación
- **Ruta**: Maestro Inicio → Utilidades → Detectar y Eliminar Lotes Huérfanos
- **Archivo**: `lib/screens/ecoce/maestro/maestro_orphan_lots_screen.dart`

## Funcionalidades Principales

### 1. Detección de Documentos Huérfanos

El sistema detecta los siguientes tipos de documentos huérfanos:

#### a) **Lotes Regulares**
- Busca en `collectionGroup('datos_generales')`
- Verifica el campo `creado_por`
- Identifica lotes cuyo creador no existe en `ecoce_profiles`

#### b) **Transformaciones (Megalotes)**
- Busca directamente en `collection('transformaciones')`
- Verifica el campo `usuario_id`
- Distingue entre megalotes de reciclador y transformador

#### c) **Sublotes**
- Busca en `collection('sublotes')`
- Verifica el campo `creado_por`
- Muestra información de la transformación origen

#### d) **Cargas de Transporte**
- Busca en `collection('cargas_transporte')`
- Verifica el campo `transportista_id`

#### e) **Entregas de Transporte**
- Busca en `collection('entregas_transporte')`
- Verifica el campo `transportista_id`

#### f) **Muestras de Laboratorio**
- Busca en `collectionGroup('analisis_laboratorio')`
- Verifica el campo `usuario_laboratorio`
- Agrupa por lote para evitar duplicados

### 2. Proceso de Búsqueda de Usuarios

El sistema busca usuarios en las siguientes ubicaciones:

```javascript
// Estructura de búsqueda de usuarios
ecoce_profiles/
├── {userId} (índice principal)
└── origen/
    ├── centro_acopio/{userId}
    └── planta_separacion/{userId}
└── reciclador/usuarios/{userId}
└── transformador/usuarios/{userId}
└── transporte/usuarios/{userId}
└── laboratorio/usuarios/{userId}
└── maestro/usuarios/{userId}
```

**Nota importante**: Los usuarios de origen (centro_acopio y planta_separacion) se encuentran directamente en sus carpetas, NO en una subcarpeta `/usuarios`.

### 3. Interfaz de Usuario

#### Estadísticas en Tiempo Real
- Total de elementos huérfanos
- Desglose por tipo
- Peso total de material
- Tiempo desde creación

#### Filtros Disponibles
- **Por Material**: Todos, EPF-Poli, EPF-PP, EPF-Multi, Megalotes, Transporte
- **Por Tiempo**: Todos, Última semana, Último mes, Últimos 3 meses, Más de 3 meses

#### Funciones de Selección
- Selección individual con checkbox
- Seleccionar/Deseleccionar todos
- Contador de elementos seleccionados

### 4. Proceso de Eliminación

#### Confirmación de Doble Paso
1. Primera confirmación: Advertencia general
2. Segunda confirmación: Lista detallada de elementos a eliminar

#### Eliminación por Tipo
- **Lotes**: Elimina documento principal y todas las subcolecciones
- **Transformaciones**: Elimina documento principal y subcolecciones (datos_generales, sublotes, documentacion)
- **Sublotes**: Elimina solo el documento principal
- **Cargas/Entregas**: Elimina solo el documento principal
- **Muestras Lab**: Elimina solo los documentos de análisis del laboratorio huérfano

#### Registro de Auditoría
Cada eliminación se registra en `audit_logs` con:
- Acción realizada
- ID del documento eliminado
- Fecha y hora
- Usuario que realizó la acción
- Razón de eliminación
- ID del usuario original

## Arquitectura Técnica

### 1. Consultas Paralelas

El sistema ejecuta todas las consultas en paralelo para máxima eficiencia:

```dart
final results = await Future.wait([
  _firestore.collection('ecoce_profiles').get(),
  _firestore.collectionGroup('datos_generales').get(),
  _firestore.collection('transformaciones').get(),
  _firestore.collectionGroup('analisis_laboratorio').get(),
  _firestore.collection('sublotes').get(),
]);
```

### 2. Optimización de Memoria

- Usa `Set<String>` para búsqueda O(1) de usuarios
- Procesa documentos en streaming cuando es posible
- Limita consultas grandes a 500 documentos

### 3. Manejo de Sesión

Utiliza `UserSessionService` para mantener la autenticación del maestro:
- Verifica autenticación antes de cada operación
- Mantiene la sesión activa durante todo el proceso
- No requiere excepciones especiales para el maestro

## Correcciones Implementadas

### 1. Búsqueda de Usuarios Origen
**Problema**: Los usuarios origen no se encontraban porque se buscaban en `/usuarios`
**Solución**: Buscar directamente en `centro_acopio` y `planta_separacion`

### 2. Consulta de Transformaciones sin Índice
**Problema**: La consulta `collectionGroup` con `where` requería un índice complejo
**Solución**: Cambiar a consulta directa de `collection('transformaciones')`

### 3. Autenticación del Maestro
**Problema**: El maestro perdía autenticación al navegar
**Solución**: Implementar `UserSessionService` para mantener sesión persistente

### 4. Permisos de Eliminación
**Problema**: Las reglas de Firestore no permitían eliminar ciertos documentos
**Solución**: Actualizar todas las reglas para permitir `delete: if isMaestro()`

### 5. Detección de Sublotes
**Problema**: Los sublotes huérfanos no se detectaban
**Solución**: Agregar consulta específica para la colección `sublotes`

## Reglas de Firestore Requeridas

```javascript
// Permisos necesarios para el maestro
allow delete: if isMaestro();

// Aplicado a:
- lotes/{loteId}
- lotes/{loteId}/{document=**}
- cargas_transporte/{cargaId}
- entregas_transporte/{entregaId}
- transformaciones/{transformacionId}
- sublotes/{subloteId}
- /{path=**}/datos_generales/{docId}
- /{path=**}/analisis_laboratorio/{docId}
```

## Modelo de Datos

```dart
class OrphanLotInfo {
  final String loteId;
  final String userId;
  final DateTime? fechaCreacion;
  final String tipoMaterial;
  final double peso;
  final String procesoActual;
  final String folio;
  final bool isTransformacion;
  final bool isSublote;
}
```

## Consideraciones de Seguridad

1. **Doble Confirmación**: Previene eliminaciones accidentales
2. **Verificación de Maestro**: Solo usuarios maestro pueden acceder
3. **Registro de Auditoría**: Todas las acciones quedan registradas
4. **Validación de Existencia**: Verifica que los documentos existen antes de eliminar

## Limitaciones Conocidas

1. **Sin Paginación**: La detección inicial carga todos los documentos
2. **Tiempo de Procesamiento**: Puede ser lento con grandes volúmenes de datos
3. **Sin Deshacer**: Las eliminaciones son permanentes

## Casos de Uso

### Caso 1: Limpieza Rutinaria
El maestro ejecuta mensualmente para eliminar lotes de usuarios que fueron eliminados del sistema.

### Caso 2: Auditoría de Sistema
Verificar cuántos documentos huérfanos existen sin necesariamente eliminarlos.

### Caso 3: Limpieza Selectiva
Usar filtros para eliminar solo documentos antiguos (más de 3 meses) de usuarios inexistentes.

## Mejoras Futuras Sugeridas

1. **Paginación**: Implementar carga progresiva para grandes volúmenes
2. **Programación**: Permitir ejecución automática programada
3. **Exportación**: Generar reporte de elementos huérfanos antes de eliminar
4. **Recuperación**: Sistema de papelera temporal antes de eliminación permanente

## Conclusión

El sistema de detección y eliminación de lotes huérfanos es una herramienta esencial para el mantenimiento de la base de datos de BioWay México. Permite al maestro mantener la integridad de los datos eliminando referencias a usuarios que ya no existen, liberando espacio y mejorando el rendimiento general del sistema.