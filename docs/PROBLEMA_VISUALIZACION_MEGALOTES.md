# Problema de Visualización de Megalotes (Transformaciones)

## Estado Actual del Problema

### Síntomas
- ✅ Los usuarios pueden ver: lotes originales, sublotes, estadísticas
- ❌ Los usuarios NO pueden ver: megalotes (transformaciones)
- Error: `PERMISSION_DENIED` al consultar transformaciones

### Diagnóstico Realizado

#### 1. Diferencia en las Consultas

**Lotes (FUNCIONAN):**
```dart
// Obtienen TODOS los documentos primero
.collectionGroup(DATOS_GENERALES)
.where('proceso_actual', isEqualTo: 'reciclador')
// Luego filtran en código
if (lote.reciclador?.usuarioId == userId) {
  lotes.add(lote);
}
```

**Transformaciones (NO FUNCIONAN):**
```dart
// Filtran directamente en Firestore
.collection('transformaciones')
.where('usuario_id', isEqualTo: userData['uid'])
```

#### 2. Problema de Reglas de Seguridad

Las reglas de Firebase Firestore evalúan los permisos ANTES de ejecutar la consulta `where`. Esto significa que:

1. Para lotes: Se permite leer todos, luego el código filtra
2. Para transformaciones: Se intenta filtrar primero, pero las reglas bloquean

### Intentos de Solución

#### 1. Actualización de Reglas (IMPLEMENTADO - NO FUNCIONÓ)
Se crearon reglas específicas para transformaciones:
```javascript
match /transformaciones/{transformacionId} {
  allow read: if request.auth != null && 
    resource.data.usuario_id == request.auth.uid;
}
```

**Resultado**: El problema persiste porque Firebase no puede evaluar `resource.data.usuario_id` antes de leer el documento.

### Soluciones Propuestas (PENDIENTES)

#### Opción 1: Cambiar la Estrategia de Consulta
Modificar `TransformacionService` para obtener todas las transformaciones y filtrar en código:

```dart
// En lugar de:
.where('usuario_id', isEqualTo: userData['uid'])

// Usar:
.snapshots()
.map((snapshot) {
  // Filtrar aquí por usuario_id
  final userTransformaciones = snapshot.docs
    .where((doc) => doc.data()['usuario_id'] == userData['uid'])
    .map((doc) => TransformacionModel.fromFirestore(doc))
    .toList();
})
```

#### Opción 2: Usar Índices Compuestos
Crear un índice compuesto en Firebase para `usuario_id` y permitir lectura basada en la existencia del índice.

#### Opción 3: Reestructurar los Datos
Almacenar las transformaciones bajo una subcolección del usuario:
```
users/{userId}/transformaciones/{transformacionId}
```

### Información Adicional

#### Debug Agregado
Se agregaron logs en `TransformacionService.obtenerTransformacionesUsuario()`:
```dart
print('=== DEBUG TRANSFORMACIONES ===');
print('Usuario actual UID: ${userData['uid']}');
print('Transformaciones encontradas: ${snapshot.docs.length}');
```

#### Comportamiento Esperado
- Mismo usuario, mismos megalotes en todos los dispositivos
- Cada usuario solo ve SUS propios megalotes
- Sin errores de permisos

### Estado: PENDIENTE DE IMPLEMENTACIÓN

La solución más viable es la Opción 1, pero se está esperando confirmación para proceder con los cambios.