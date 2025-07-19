# Flujo de Aprobación de Cuentas ECOCE

## Resumen del Sistema

El sistema implementa un flujo de aprobación de 3 estados para las cuentas de proveedores ECOCE:

- **0 = Pendiente**: Cuenta creada pero no puede acceder
- **1 = Aprobado**: Cuenta activa con acceso completo
- **2 = Rechazado**: Cuenta denegada, se puede eliminar

## Flujo de Registro y Aprobación

### 1. Registro del Proveedor

1. El proveedor completa el formulario de registro (5 pasos)
2. Al finalizar, se crea:
   - Usuario en Firebase Auth
   - Perfil en Firestore con `ecoce_estatus_aprobacion: 0`
3. Se muestra dialog confirmando:
   - Folio asignado (ej: A0000001)
   - Estado: "Cuenta pendiente de aprobación"
   - Próximos pasos del proceso

### 2. Intento de Login (Estado Pendiente)

Si un usuario pendiente intenta hacer login:

1. Se valida email/contraseña correctamente
2. Se verifica el perfil y su estado
3. Si `ecoce_estatus_aprobacion == 0`:
   - Se muestra dialog "Aprobación Pendiente"
   - Se cierra la sesión automáticamente
   - No puede acceder a las pantallas

### 3. Panel del Maestro ECOCE

El usuario maestro accede a la pantalla de aprobaciones:

```
Ruta: ECOCE Login → Usuario: maestro → Pantalla: Aprobaciones
```

#### Funcionalidades:

1. **Vista de solicitudes pendientes**
   - Lista todos los perfiles con estado 0
   - Muestra información completa del proveedor
   - Permite ver documentos adjuntos

2. **Acciones disponibles**:
   
   **APROBAR**:
   - Actualiza `ecoce_estatus_aprobacion` a 1
   - Registra fecha, usuario aprobador y comentarios
   - El proveedor puede hacer login inmediatamente

   **RECHAZAR**:
   - Actualiza `ecoce_estatus_aprobacion` a 2
   - Solicita razón del rechazo (obligatorio)
   - Opción de eliminar la cuenta completamente

### 4. Estados Finales

#### Usuario Aprobado (estado 1)
- Login exitoso
- Acceso completo a sus pantallas según tipo:
  - Origen → origen_inicio
  - Reciclador → reciclador_inicio
  - Transporte → transporte_inicio
  - etc.

#### Usuario Rechazado (estado 2)
- Si intenta login: mensaje de rechazo con razón
- No puede acceder a las pantallas
- Cuenta puede ser eliminada por el maestro

## Implementación Técnica

### Modelo de Datos

```dart
// En EcoceProfileModel
final int ecoceEstatusAprobacion; // 0, 1, o 2
final DateTime? ecoceFechaAprobacion;
final String? ecoceAprobadoPor;
final String? ecoceComentariosRevision;
```

### Métodos del Servicio

```dart
// EcoceProfileService
approveProfile(profileId, approvedById, comments)
rejectProfile(profileId, rejectedById, reason)
deleteRejectedProfile(profileId)
getPendingProfiles() // Obtiene perfiles con estado 0
```

### Validación en Login

```dart
// En ecoce_login_screen.dart
if (profile.isPending) {
  _showPendingApprovalDialog();
  await _authService.signOut();
  return;
} else if (profile.isRejected) {
  _showRejectedDialog(profile.ecoceComentariosRevision);
  await _authService.signOut();
  return;
}
```

## Casos de Prueba

### 1. Registro y Estado Pendiente
1. Registrar nuevo centro de acopio
2. Intentar login con las credenciales
3. Verificar dialog "Aprobación Pendiente"
4. Verificar que no puede acceder

### 2. Aprobación por Maestro
1. Login como maestro
2. Ver lista de pendientes
3. Aprobar una cuenta
4. Verificar que el usuario ahora puede acceder

### 3. Rechazo y Eliminación
1. Login como maestro
2. Rechazar una cuenta con razón
3. Verificar que el usuario ve mensaje de rechazo
4. Opcionalmente eliminar la cuenta

## Credenciales de Prueba

### Usuario Maestro (Aprobador)
- Usuario: maestro
- Contraseña: master123
- Acceso: Panel de aprobaciones

### Proveedores de Prueba
- Centro Acopio: acopio1@test.com / Test123456
- Planta: planta1@test.com / Test123456

## Notas Importantes

1. **Seguridad**: Solo usuarios tipo "maestro" pueden aprobar/rechazar
2. **Auditoría**: Se registra quién y cuándo aprobó/rechazó
3. **Comunicación**: Los comentarios de revisión se muestran al usuario
4. **Limpieza**: Las cuentas rechazadas pueden eliminarse completamente
5. **Estado inicial**: Todas las cuentas nuevas inician en pendiente (0)