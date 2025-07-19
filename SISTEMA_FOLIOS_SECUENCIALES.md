# Sistema de Folios Secuenciales ECOCE

## Resumen

El sistema de folios ha sido actualizado para garantizar que no existan espacios vacíos en la numeración. Los folios ahora se asignan **únicamente cuando el usuario maestro aprueba la cuenta**, no al momento del registro.

## Cambios Implementados

### 1. Registro sin Folio

Al registrarse, los usuarios:
- Completan todos sus datos normalmente
- Se crea su cuenta en Firebase con `ecoce_folio: "PENDIENTE"`
- El dialog de confirmación muestra:
  - ✅ "Solicitud enviada exitosamente"
  - ℹ️ "Tu folio se asignará una vez aprobada tu cuenta"
- NO se genera ningún número de folio

### 2. Asignación de Folio al Aprobar

Cuando el maestro aprueba una cuenta:
1. Se ejecuta `approveProfile()`
2. El método obtiene el tipo y subtipo del usuario
3. Genera el siguiente folio secuencial disponible
4. Actualiza el perfil con:
   - El folio asignado
   - Estado aprobado (1)
   - Fecha y usuario aprobador
5. Muestra mensaje: "Cuenta aprobada exitosamente\nFolio asignado: [X0000001]"

### 3. Formato de Folios por Tipo

Los folios mantienen el formato de 1 letra + 7 dígitos:

- **A0000001**: Centro de Acopio (Origen)
- **P0000001**: Planta de Separación (Origen)
- **R0000001**: Reciclador
- **T0000001**: Transformador
- **V0000001**: Transporte
- **L0000001**: Laboratorio

## Ventajas del Nuevo Sistema

1. **Sin espacios vacíos**: Los números son consecutivos solo para cuentas aprobadas
2. **Orden cronológico**: El orden de los folios refleja el orden de aprobación
3. **Auditoría clara**: Se puede ver cuándo se aprobó cada cuenta por su folio
4. **Sin desperdicio**: Las cuentas rechazadas no consumen números

## Flujo Completo

```
1. Usuario se registra
   └─> Perfil creado con folio="PENDIENTE"

2. Usuario intenta login
   └─> Mensaje: "Cuenta pendiente de aprobación"

3. Maestro revisa solicitud
   ├─> APRUEBA
   │   ├─> Genera folio secuencial (ej: A0000001)
   │   ├─> Actualiza perfil con folio y estado=1
   │   └─> Usuario puede hacer login
   │
   └─> RECHAZA
       ├─> Actualiza estado=2
       ├─> NO se asigna folio
       └─> Opción de eliminar cuenta
```

## Implementación Técnica

### Método `createOrigenProfile`
```dart
// No genera folio
final folio = 'PENDIENTE';
```

### Método `approveProfile`
```dart
// Obtiene tipo y subtipo
final tipoActor = profileData['ecoce_tipo_actor'];
final subtipo = profileData['ecoce_subtipo'];

// Genera folio secuencial
final folio = await _generateFolio(tipoActor, subtipo);

// Actualiza con folio y aprobación
await _profilesCollection.doc(profileId).update({
  'ecoce_folio': folio,
  'ecoce_estatus_aprobacion': 1,
  // ... otros campos
});
```

### Visualización en Maestro
```dart
// Muestra "Se asignará al aprobar" para pendientes
profile.ecoceFolio == 'PENDIENTE' 
  ? 'Se asignará al aprobar' 
  : profile.ecoceFolio
```

## Casos de Uso

### Ejemplo 1: Tres Centros de Acopio
1. Se registran 3 centros de acopio
2. Todos tienen folio="PENDIENTE"
3. Maestro aprueba en orden:
   - Centro 2 → Asignado: A0000001
   - Centro 3 → Asignado: A0000002
   - Centro 1 → Asignado: A0000003
4. La numeración es consecutiva sin importar el orden de registro

### Ejemplo 2: Mezcla de Aprobaciones y Rechazos
1. Se registran 5 usuarios origen
2. Maestro procesa:
   - Usuario 1 (Acopio): APROBADO → A0000001
   - Usuario 2 (Planta): RECHAZADO → Sin folio
   - Usuario 3 (Acopio): APROBADO → A0000002
   - Usuario 4 (Planta): APROBADO → P0000001
   - Usuario 5 (Acopio): APROBADO → A0000003
3. No hay espacios en la numeración

## Consideraciones

1. **Migración**: Usuarios existentes mantienen sus folios actuales
2. **Búsqueda**: Los usuarios pueden buscar por email hasta tener folio
3. **Notificaciones**: Al aprobar, se podría enviar email con el folio asignado
4. **Reportes**: Los folios secuenciales facilitan estadísticas y auditorías