# Solución: Sublotes No Visibles Después de Creación

## Fecha: 2025-01-28

## Problema
Al crear sublotes desde megalotes en la pestaña "Completados" del usuario Reciclador:
1. Se mostraba error de permisos aunque los sublotes sí se creaban
2. El peso disponible del megalote se actualizaba correctamente
3. Los IDs de sublotes aparecían en el megalote
4. **PERO los sublotes no eran visibles en ninguna parte de la interfaz**

## Causa Raíz
El sistema tenía dos problemas:

### 1. Error de Permisos (Solucionado anteriormente)
Las reglas de Firestore no permitían actualizar `peso_disponible` y `sublotes_generados` juntos.

### 2. Sublotes No Visibles (Este problema)
- Los sublotes se creaban solo en la colección `sublotes`
- La interfaz busca lotes en la colección `lotes` usando `LoteUnificadoService`
- Los sublotes nunca se agregaban a la colección `lotes`, por lo que nunca aparecían

El código original tenía este comentario revelador:
```dart
// NO crear entrada en lotes unificados para el sublote
// Los sublotes se manejan separadamente y solo se crean como lotes
// cuando se necesita transferirlos a otro proceso
```

## Solución Implementada
Se modificó `transformacion_service.dart` para crear sublotes en ambas colecciones:

1. **En colección `sublotes`**: Para mantener compatibilidad con el diseño original
2. **En colección `lotes`**: Para que sean visibles en la interfaz

### Estructura creada en `lotes/{subloteId}`:
```
lotes/{subloteId}/
├── datos_generales/info
│   ├── id: subloteId
│   ├── qr_code: 'SUBLOTE-{id}'
│   ├── tipo_lote: 'derivado'
│   ├── tipo_material: materialPredominante
│   ├── peso_original: peso
│   ├── proceso_actual: 'reciclador'
│   ├── transformacion_origen: transformacionId
│   └── composicion: {...}
└── reciclador/data
    ├── usuario_id: userId
    ├── peso_entrada: peso
    ├── tipo_proceso: 'sublote_generado'
    └── transformacion_origen: transformacionId
```

## Beneficios
1. Los sublotes ahora son visibles inmediatamente después de crearlos
2. Aparecen en la pestaña "Completados" del reciclador
3. Pueden ser transferidos como cualquier otro lote
4. Mantienen trazabilidad completa con su megalote origen
5. Se pueden generar QR codes para ellos

## Archivos Modificados
- `lib/services/transformacion_service.dart`: Método `crearSublote()`, líneas 271-312

## Verificación
1. Crear un sublote desde un megalote
2. El sublote debe aparecer inmediatamente en la pestaña "Completados"
3. El sublote debe mostrar:
   - Badge morado indicando que es sublote
   - Peso correcto
   - Composición de materiales
   - QR code funcional
   - Capacidad de ser transferido

## Corrección Adicional (2025-01-28)
Se eliminó la llamada redundante a `_loteService.crearLoteDesdeSubLote` en `reciclador_administracion_lotes.dart` (líneas 1111-1116) que causaba un error de permisos después de crear exitosamente el sublote. Esta llamada era innecesaria porque el servicio de transformación ya crea el sublote en ambas colecciones dentro de la transacción.

## Notas Técnicas
- Se usa una transacción para garantizar consistencia
- El ID del sublote se usa tanto en `sublotes` como en `lotes`
- Los campos siguen la estructura estándar de `LoteUnificadoModel`
- El campo `tipo_lote: 'derivado'` identifica que es un sublote