# Despliegue de Reglas de Firestore - Sistema Independiente de Muestras

## Fecha: 2025-01-29

## Resumen
Se han actualizado las reglas de Firestore para implementar el sistema independiente de muestras de laboratorio, resolviendo los problemas de permisos y garantizando el aislamiento total entre usuarios de laboratorio.

## Cambios Principales

### 1. Nueva Colección: `muestras_laboratorio` (líneas 161-204)
- **Ubicación en archivo**: Sección "SISTEMA INDEPENDIENTE DE MUESTRAS DE LABORATORIO (NUEVO)"
- **Características de seguridad**:
  - Solo el laboratorio dueño puede ver sus muestras
  - Validación estricta de `laboratorio_id == auth.uid`
  - Control de transiciones de estado
  - Prohibición de eliminación para mantener historial

### 2. Actualización de Colección: `transformaciones` (líneas 206-272)
- **Ubicación en archivo**: Sección "TRANSFORMACIONES Y SUBLOTES - REGLAS ACTUALIZADAS"
- **Nuevas funcionalidades**:
  - Función `isLaboratorio()` para identificar usuarios de laboratorio
  - Laboratorio puede actualizar campos específicos del sistema independiente
  - Mantiene compatibilidad con sistema anterior

## Instrucciones de Despliegue

### Paso 1: Verificar el archivo
```bash
# Verificar que el archivo tiene las reglas correctas
cat firestore.rules | grep "muestras_laboratorio" 
```

### Paso 2: Desplegar a Firebase
```bash
# Desplegar solo las reglas de Firestore
firebase deploy --only firestore:rules
```

### Paso 3: Verificar en consola
1. Ir a [Firebase Console](https://console.firebase.google.com)
2. Seleccionar el proyecto `trazabilidad-ecoce`
3. Ir a Firestore Database → Rules
4. Verificar que las reglas incluyan la sección `muestras_laboratorio`

## Validación de Seguridad

### Test 1: Aislamiento entre Laboratorios
- Laboratorio L0000001 crea una muestra
- Laboratorio L0000002 NO debe poder leerla
- Solo L0000001 y Maestro pueden acceder

### Test 2: Validación de Campos
- Al crear muestra, debe incluir: `laboratorio_id`, `origen_id`, `origen_tipo`, `peso_muestra`, `estado`
- Estado inicial DEBE ser `pendiente_analisis`

### Test 3: Transiciones de Estado
- Solo permitidas: 
  - `pendiente_analisis` → `analisis_completado`
  - `analisis_completado` → `documentacion_completada`

## Notas Importantes

1. **NO** se requiere crear índices adicionales para las reglas básicas
2. **SÍ** se recomienda crear índices compuestos para queries eficientes:
   ```
   muestras_laboratorio:
   - laboratorio_id + fecha_toma (DESC)
   - laboratorio_id + estado
   ```

3. Las reglas mantienen compatibilidad con el sistema anterior (array `muestras_laboratorio`)

4. El sistema está diseñado para migración gradual sin interrumpir el servicio

## Rollback (si es necesario)

Si hay problemas, las reglas anteriores están respaldadas en el historial de Git:
```bash
# Ver versión anterior
git show HEAD~1:firestore.rules

# Revertir si es necesario
git checkout HEAD~1 -- firestore.rules
firebase deploy --only firestore:rules
```

## Estado Final

✅ **Reglas actualizadas y listas para despliegue**
- Archivo `firestore.rules` contiene todas las reglas necesarias
- Sistema independiente de muestras completamente configurado
- Aislamiento total entre usuarios de laboratorio garantizado
- Compatibilidad con sistema anterior mantenida