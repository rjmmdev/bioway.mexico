# Flujo Bidireccional de Entrega/Recepción

## Descripción General

El sistema permite que tanto el transportista como el receptor (reciclador, transformador, etc.) completen sus formularios en cualquier orden. La transferencia del lote solo se completa cuando ambas partes han finalizado sus respectivos procesos.

## Flujo del Sistema

### 1. Escenario A: Transportista completa primero

1. **Transportista escanea QR de entrega**
   - Completa formulario con: firma, fotos, destinatario
   - Sistema marca `entrega_completada: true` en proceso transporte
   - Sistema crea/actualiza proceso destino con información parcial
   - Lote permanece en `proceso_actual: transporte`

2. **Receptor escanea QR del lote**
   - Completa formulario con: firma, peso recibido, etc.
   - Sistema marca `recepcion_completada: true` en proceso destino
   - Sistema detecta que ambas partes completaron
   - Lote se transfiere a `proceso_actual: [destino]`

### 2. Escenario B: Receptor completa primero

1. **Receptor escanea QR del lote**
   - Completa formulario de recepción
   - Sistema crea proceso destino con `recepcion_completada: true`
   - Lote permanece en `proceso_actual: transporte`

2. **Transportista completa entrega**
   - Completa formulario con firma y evidencias
   - Sistema marca `entrega_completada: true`
   - Sistema detecta que ambas partes completaron
   - Lote se transfiere a `proceso_actual: [destino]`

## Campos de Verificación

### Proceso Transporte
- `entrega_completada: true`
- `fecha_salida` != null
- `firma_entrega` != null
- `firma_conductor` != null

### Proceso Destino (Reciclador/Transformador)
- `recepcion_completada: true`
- `firma_operador` != null
- `firma_recepcion` != null
- `peso_recibido` != null
- `peso_entrada` != null

## Funciones Clave

### `verificarTransferenciaCompleta()`
- Verifica si ambos procesos existen
- Verifica si ambos han completado sus partes
- Solo retorna `true` cuando ambas condiciones se cumplen

### `transferirLote()`
- Crea/actualiza el proceso destino
- Verifica si la transferencia está completa
- Si está completa, actualiza `proceso_actual` y el historial

### `crearOActualizarProceso()`
- Crea el documento del proceso si no existe
- Actualiza los campos si ya existe
- Mantiene los datos existentes al actualizar

## Consideraciones Importantes

1. **No importa el orden**: El sistema funciona sin importar quién complete primero
2. **Datos persistentes**: Los datos se guardan aunque la transferencia no esté completa
3. **Verificación doble**: Ambas partes deben completar para transferir
4. **Compatibilidad**: Mantiene compatibilidad con colecciones legacy

## Debugging

Para verificar el estado de una transferencia:
1. Revisar `lotes/{loteId}/transporte/data` - Campo `entrega_completada`
2. Revisar `lotes/{loteId}/[destino]/data` - Campo `recepcion_completada`
3. Revisar `lotes/{loteId}/datos_generales/info` - Campo `proceso_actual`

## Mejoras Futuras

1. Notificaciones push cuando una parte completa
2. Dashboard para ver transferencias pendientes
3. Timeout para transferencias incompletas
4. Auditoría de quién completó primero