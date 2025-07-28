# Uso de la Misma Cuenta en Múltiples Dispositivos

## Resumen
El sistema BioWay México está diseñado para permitir que **la misma cuenta de usuario** sea utilizada en **múltiples dispositivos** simultáneamente. Cuando se usa el mismo email y contraseña, todos los dispositivos verán los mismos megalotes y sublotes.

## Cómo Funciona

### 1. Autenticación con Firebase
- Firebase Auth genera un **UID único** para cada cuenta de usuario
- Este UID es **siempre el mismo** sin importar desde qué dispositivo se haga login
- Ejemplo: Si el usuario con email `reciclador1@empresa.com` hace login:
  - En el teléfono A: UID = `abc123xyz789`
  - En el teléfono B: UID = `abc123xyz789`
  - En la tablet: UID = `abc123xyz789`

### 2. Filtrado de Megalotes
Los megalotes (transformaciones) se filtran por `usuario_id` en Firebase:
```dart
.where('usuario_id', isEqualTo: userData['uid'])
```

Esto significa que:
- Todos los dispositivos con la misma cuenta verán los **mismos megalotes**
- Los megalotes creados en un dispositivo aparecerán en todos los demás
- Los sublotes también se compartirán entre dispositivos

## Instrucciones de Uso

### Para Ver los Mismos Megalotes en Múltiples Dispositivos:

1. **Usar las Mismas Credenciales**
   - Email: Usar exactamente el mismo email
   - Contraseña: Usar exactamente la misma contraseña
   - Folio: También funciona con el mismo folio (ej: R0000001)

2. **Proceso de Login**
   ```
   Dispositivo 1:
   - Email: reciclador1@empresa.com
   - Contraseña: miPassword123
   
   Dispositivo 2:
   - Email: reciclador1@empresa.com
   - Contraseña: miPassword123
   ```

3. **Verificación**
   - Ir a la pestaña "Completados" en ambos dispositivos
   - Deberían verse los mismos megalotes
   - Los sublotes también serán visibles en ambos

## Solución de Problemas

### Si NO se ven los mismos megalotes:

1. **Verificar las credenciales**
   - Asegurarse de usar EXACTAMENTE el mismo email
   - La contraseña debe ser idéntica
   - Mayúsculas y minúsculas importan

2. **Verificar el UID (Debug)**
   - Al abrir la pestaña Completados, revisar la consola
   - Buscar: `=== DEBUG TRANSFORMACIONES ===`
   - Comparar el UID en ambos dispositivos
   - Si son diferentes, se están usando cuentas diferentes

3. **Actualizar la vista**
   - Hacer pull-to-refresh en la pestaña Completados
   - Cerrar y volver a abrir la aplicación
   - Verificar conexión a internet

## Notas Importantes

1. **Seguridad**: Cada reciclador solo ve SUS propios megalotes
2. **Sincronización**: Los cambios se sincronizan en tiempo real
3. **Sin límite de dispositivos**: Puedes usar la cuenta en tantos dispositivos como necesites
4. **Sesiones activas**: Todos los dispositivos pueden estar activos simultáneamente

## Configuración Alternativa (Por Organización)

Si se necesita que TODOS los recicladores de una organización vean TODOS los megalotes, se puede usar el método `obtenerTransformacionesPorFolio()` que filtra por prefijo de folio en lugar de usuario individual.