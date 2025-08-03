# Sistema Independiente de Muestras de Laboratorio

## Fecha de Identificación del Problema
**2025-01-28**

## Problema Actual

### Descripción del Problema
El sistema de muestras de Laboratorio actualmente no funciona correctamente debido a una arquitectura inadecuada:

1. **Almacenamiento Incorrecto**: Las muestras se están guardando como elementos de un array dentro del documento de transformación del Reciclador, en lugar de tener documentos independientes.

2. **Problemas de Permisos**: El Laboratorio no puede leer las transformaciones de otros usuarios debido a las reglas de Firestore, lo que impide que vea sus propias muestras.

3. **Falta de Independencia**: Las muestras no tienen su propio ciclo de vida ni colección independiente, lo que va en contra del patrón establecido en el sistema.

### Estructura Actual (Problemática)
```javascript
transformaciones/[transformacionId]/
  └── muestras_laboratorio: [
        {
          fecha_toma: "2025-01-28T...",
          peso_muestra: 5.0,
          usuario_id: "labUserId",
          estado: "pendiente_analisis",
          // Todos los datos embebidos en el array
        }
      ]
```

### Síntomas del Problema
- Las muestras se registran correctamente (el peso se descuenta del megalote)
- El Laboratorio NO puede ver las muestras en la pestaña "Análisis"
- Error en consola: `PERMISSION_DENIED` al intentar leer transformaciones
- No hay trazabilidad independiente del proceso de laboratorio

## Solución Propuesta: Sistema de Muestras Independiente

### Concepto General
Crear una colección independiente para las muestras de laboratorio, siguiendo el mismo patrón que otros procesos del sistema (transporte, reciclador, transformador), manteniendo la trazabilidad completa con el sistema de lotes unificados.

### 1. Nueva Estructura de Base de Datos

#### A. Colección Principal de Muestras
```
muestras_laboratorio/[muestraId]/
├── id: string (auto-generado)
├── tipo: "megalote" | "lote"
├── origen_id: string (transformacionId o loteId)
├── origen_tipo: "transformacion" | "lote"
├── laboratorio_id: string (userId del laboratorio)
├── laboratorio_folio: string
├── peso_muestra: number
├── estado: "pendiente_analisis" | "analisis_completado" | "documentacion_completada"
├── fecha_toma: timestamp
├── firma_operador: string (URL)
├── evidencias_foto: string[]
├── datos_analisis: {
│   ├── humedad: number
│   ├── pellets_gramo: number
│   ├── tipo_polimero: string
│   ├── temperatura_fusion: {
│   │   ├── tipo: "unica" | "rango"
│   │   ├── unidad: "C°" | "K°" | "F°"
│   │   ├── valor?: number (si es única)
│   │   ├── minima?: number (si es rango)
│   │   └── maxima?: number (si es rango)
│   ├── }
│   ├── contenido_organico: number
│   ├── contenido_inorganico: number
│   ├── oit: string
│   ├── mfi: string
│   ├── densidad: string
│   ├── norma: string
│   ├── observaciones: string
│   ├── cumple_requisitos: boolean
│   └── analista: string
├── }
├── documentos: {
│   └── certificado_analisis: string (URL)
├── }
├── fecha_analisis: timestamp
├── fecha_documentacion: timestamp
└── qr_code: string
```

#### B. Referencias en Transformaciones (Simplificado)
```
transformaciones/[transformacionId]/
├── muestras_laboratorio_ids: ["muestraId1", "muestraId2"]  // Solo IDs
├── tiene_muestra_laboratorio: boolean
└── peso_muestras_total: number  // Suma acumulada
```

#### C. Integración con Sistema de Lotes Unificados
```
lotes/[loteId]/
├── datos_generales/
├── origen/
├── transporte/
├── reciclador/
├── laboratorio/          // Nueva subcollección
│   └── muestras/
│       └── [muestraId]/ // Referencia a muestras_laboratorio
└── transformador/
```

### 2. Flujo de Implementación

#### Fase 1: Toma de Muestra
1. Laboratorio escanea código QR del megalote
2. Completa formulario de toma de muestra (peso, firma, fotos)
3. Sistema crea documento en `muestras_laboratorio/` con estado `pendiente_analisis`
4. Sistema actualiza transformación:
   - Añade muestraId a `muestras_laboratorio_ids[]`
   - Resta peso de `peso_disponible`
   - Actualiza `peso_muestras_total`
   - Marca `tiene_muestra_laboratorio: true`

#### Fase 2: Análisis
1. Laboratorio abre muestra desde pestaña "Análisis"
2. Completa formulario con resultados
3. Sistema actualiza documento de muestra con `datos_analisis`
4. Cambia `estado` a `analisis_completado`

#### Fase 3: Documentación
1. Laboratorio sube certificado de análisis
2. Sistema guarda URL en `documentos.certificado_analisis`
3. Cambia `estado` a `documentacion_completada`

### 3. Servicios a Implementar

#### A. Nuevo Servicio: `MuestraLaboratorioService`
```dart
class MuestraLaboratorioService {
  // Crear nueva muestra
  Future<String> crearMuestra({
    required String origenId,
    required String origenTipo,
    required double pesoMuestra,
    required String firmaOperador,
    required List<String> evidenciasFoto,
  });
  
  // Obtener muestras del usuario
  Stream<List<MuestraLaboratorio>> obtenerMuestrasUsuario();
  
  // Obtener muestra específica
  Future<MuestraLaboratorio?> obtenerMuestraPorId(String muestraId);
  
  // Actualizar con resultados de análisis
  Future<void> actualizarAnalisis(String muestraId, Map<String, dynamic> datosAnalisis);
  
  // Actualizar con documentación
  Future<void> actualizarDocumentacion(String muestraId, Map<String, String> documentos);
}
```

#### B. Modificaciones a `TransformacionService`
- `registrarTomaMuestra()`: Cambiar para llamar a `MuestraLaboratorioService.crearMuestra()`
- Guardar solo referencias (IDs) en lugar de objetos completos

#### C. Modificaciones a `LoteUnificadoService`
- `actualizarAnalisisMuestraMegalote()`: Actualizar para trabajar con documentos independientes

### 4. Pantallas a Ajustar

#### A. `laboratorio_gestion_muestras.dart`
```dart
// Query actual (problemática):
final transformacionesSnapshot = await _firestore
    .collection('transformaciones')
    .get();  // PERMISSION_DENIED

// Nueva query (independiente):
final muestrasSnapshot = await _firestore
    .collection('muestras_laboratorio')
    .where('laboratorio_id', isEqualTo: userId)
    .orderBy('fecha_toma', descending: true)
    .get();
```

#### B. `laboratorio_formulario.dart`
- Trabajar directamente con `muestraId`
- No necesita `transformacionId` para actualizar

#### C. `laboratorio_documentacion.dart`
- Similar, trabajar con documento independiente de muestra

### 5. Reglas de Firestore

```javascript
// Reglas para muestras independientes
match /muestras_laboratorio/{muestraId} {
  // Laboratorio puede leer sus propias muestras
  allow read: if isAuthenticated() && 
    (resource.data.laboratorio_id == request.auth.uid || isAdmin());
  
  // Crear muestra
  allow create: if isAuthenticated() &&
    request.resource.data.laboratorio_id == request.auth.uid &&
    request.resource.data.keys().hasAll(['laboratorio_id', 'origen_id', 'peso_muestra']);
  
  // Actualizar solo si es el dueño
  allow update: if isAuthenticated() &&
    resource.data.laboratorio_id == request.auth.uid;
  
  // No permitir eliminación (mantener historial)
  allow delete: if false;
}

// Ajuste a reglas de transformaciones
match /transformaciones/{transformacionId} {
  // Permitir lectura general para consultas de existencia
  allow read: if isAuthenticated();
  
  // Update limitado para laboratorio
  allow update: if isAuthenticated() && (
    resource.data.usuario_id == request.auth.uid ||
    // Laboratorio solo puede actualizar campos específicos
    (request.resource.data.diff(resource.data).affectedKeys().hasOnly(
      ['muestras_laboratorio_ids', 'tiene_muestra_laboratorio', 'peso_muestras_total', 'peso_disponible']
    ))
  );
}
```

### 6. Ventajas de Esta Implementación

1. **Independencia Total**: El Laboratorio no depende de permisos sobre transformaciones ajenas
2. **Escalabilidad**: Queries más eficientes al no tener que leer todas las transformaciones
3. **Consistencia**: Sigue el mismo patrón que otros usuarios del sistema
4. **Trazabilidad Completa**: Cada muestra tiene su historial independiente
5. **Flexibilidad**: Fácil añadir campos específicos del laboratorio sin afectar otras colecciones
6. **Permisos Claros**: Cada usuario solo puede leer/escribir sus propios datos

### 7. Consideraciones de Implementación

#### Transacciones
Usar transacciones de Firestore al crear muestras para asegurar consistencia entre:
- Creación del documento de muestra
- Actualización del peso en transformación
- Actualización de referencias

#### Índices de Firestore
Crear índices compuestos para queries eficientes:
- `laboratorio_id + fecha_toma (DESC)`
- `laboratorio_id + estado`

#### Validación
- Verificar peso disponible antes de crear muestra
- Validar que la transformación existe y está activa
- Asegurar que el QR no se ha usado previamente

#### Migración de Datos Existentes
Si hay muestras existentes en el formato antiguo:
1. Script para extraer muestras de arrays en transformaciones
2. Crear documentos independientes en `muestras_laboratorio/`
3. Actualizar transformaciones con referencias (IDs)
4. Verificar integridad de datos

### 8. Plan de Implementación por Fases

#### Fase 1: Backend (Día 1)
- [ ] Crear `MuestraLaboratorioService`
- [ ] Modificar `TransformacionService`
- [ ] Actualizar reglas de Firestore
- [ ] Crear índices necesarios

#### Fase 2: Toma de Muestra (Día 1-2)
- [ ] Modificar `laboratorio_toma_muestra_megalote_screen.dart`
- [ ] Actualizar para crear documento independiente
- [ ] Mantener actualización de peso en transformación

#### Fase 3: Gestión de Muestras (Día 2)
- [ ] Modificar `laboratorio_gestion_muestras.dart`
- [ ] Cambiar queries para leer de colección independiente
- [ ] Ajustar clasificación por estados

#### Fase 4: Análisis y Documentación (Día 2-3)
- [ ] Actualizar `laboratorio_formulario.dart`
- [ ] Actualizar `laboratorio_documentacion.dart`
- [ ] Trabajar con documentos independientes

#### Fase 5: Pruebas y Validación (Día 3)
- [ ] Pruebas de flujo completo
- [ ] Verificar trazabilidad
- [ ] Validar permisos
- [ ] Migrar datos existentes si los hay

### 9. Compatibilidad con Sistema Actual

Esta solución mantiene completa compatibilidad con:
- **Sistema de Lotes Unificados**: Las muestras siguen siendo parte de la trazabilidad
- **Proceso de Transformaciones**: El peso sigue descontándose correctamente
- **Flujo de Usuario**: La experiencia del usuario permanece igual
- **Reportes y Estadísticas**: Fácil integración con sistemas de reporteo

### 10. Conclusión

Esta arquitectura independiente resuelve todos los problemas actuales mientras mantiene la coherencia con el diseño general del sistema. El Laboratorio tendrá control total sobre sus procesos sin depender de permisos sobre datos de otros usuarios, mejorando la seguridad, escalabilidad y mantenibilidad del sistema.

## Estado Actual
**Pendiente de Implementación**

Fecha programada de inicio: **2025-01-29**