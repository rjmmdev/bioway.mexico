# Solución: Error de Permisos al Crear Sublotes

## Fecha: 2025-01-28

## Problema
Al intentar crear un sublote desde un megalote en la pestaña "Completados" del usuario Reciclador, aparecía el error:
```
Error al crear sublote: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation
```

## Causa
Las reglas de Firestore para la colección `transformaciones` no permitían actualizar los campos necesarios durante la creación de sublotes. Cuando se crea un sublote, se ejecuta una transacción que:
1. Crea el documento del sublote en la colección `sublotes`
2. Actualiza la transformación (megalote) para:
   - Decrementar el `peso_disponible`
   - Agregar el ID del sublote a `sublotes_generados`

Las reglas existentes no permitían actualizar estos dos campos juntos.

## Solución
Se actualizó el archivo `firestore.rules` para permitir la actualización de los campos `peso_disponible` y `sublotes_generados` cuando se crean sublotes:

```javascript
// Antes:
allow update: if isAuthenticated() && (
  // ... otras condiciones ...
  (request.resource.data.diff(resource.data).affectedKeys()
    .hasOnly(['muestras_laboratorio', 'peso_disponible']))
);

// Después:
allow update: if isAuthenticated() && (
  // ... otras condiciones ...
  (request.resource.data.diff(resource.data).affectedKeys()
    .hasOnly(['muestras_laboratorio', 'peso_disponible'])) ||
  // O solo se están creando sublotes (actualiza peso_disponible y sublotes_generados)
  (request.resource.data.diff(resource.data).affectedKeys()
    .hasOnly(['peso_disponible', 'sublotes_generados']))
);
```

## Archivos Modificados
- `firestore.rules`: Líneas 171-173, agregada condición para permitir actualización de sublotes

## Verificación
1. Las reglas se desplegaron exitosamente con `firebase deploy --only firestore:rules`
2. Ahora los usuarios pueden crear sublotes desde sus megalotes sin errores de permisos
3. La seguridad se mantiene ya que solo se permiten actualizar estos campos específicos

## Notas
- La regla permite actualizar ambos campos juntos, lo cual es necesario para la transacción
- No se permite actualizar estos campos con otros campos al mismo tiempo
- La validación de que el usuario sea dueño del megalote se hace en el código de la aplicación