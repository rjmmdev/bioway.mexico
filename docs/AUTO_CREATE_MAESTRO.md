# Auto-creación de Usuario Maestro (TEMPORAL)

## Configuración Temporal

Se ha implementado una funcionalidad temporal para auto-crear el perfil del usuario maestro en Firestore.

### Credenciales Configuradas:
- **Email**: `maestro@ecoce.mx`
- **Password**: `master123`
- **UID**: `0XOboM6ej6fR1iFXt6DwqnffqkW2`

### Funcionamiento:

1. Cuando se detecta un login con el UID específico (`0XOboM6ej6fR1iFXt6DwqnffqkW2`) y el email `maestro@ecoce.mx`
2. El sistema automáticamente crea:
   - El documento índice en `/ecoce_profiles/{userId}`
   - El perfil completo en `/ecoce_profiles/maestro/usuarios/{userId}`

### Datos del Perfil Auto-creado:

```json
{
  "ecoce_tipo_actor": "M",
  "ecoce_nombre": "Administrador ECOCE",
  "ecoce_correo_contacto": "maestro@ecoce.mx",
  "ecoce_folio": "M0000001",
  "ecoce_nombre_contacto": "Admin",
  "ecoce_tel_contacto": "5551234567",
  "ecoce_estatus_aprobacion": 1,
  "fecha_creacion": "[Timestamp actual]",
  "activo": true
}
```

### Cómo Usar:

1. Asegúrate de que el usuario con UID `0XOboM6ej6fR1iFXt6DwqnffqkW2` existe en Firebase Auth
2. Inicia sesión con `maestro@ecoce.mx` y `master123`
3. El perfil se creará automáticamente en el primer login
4. Podrás acceder al panel de administración maestro

### IMPORTANTE:

- Esta es una solución **TEMPORAL** para facilitar el desarrollo
- **DEBE REMOVERSE** antes de ir a producción
- En producción, el usuario maestro debe crearse manualmente siguiendo procedimientos seguros

### Archivo Modificado:
- `lib/screens/login/ecoce/ecoce_login_screen.dart` (líneas 231-233 y método `_autoCreateMaestroProfile`)

### Para Remover:
1. Elimina las líneas 231-233 en `ecoce_login_screen.dart`
2. Elimina el método `_autoCreateMaestroProfile` (líneas 560-609)
3. Elimina este archivo de documentación