# Estructura de Datos del Reciclador - Sistema Unificado

## Ubicación de Datos

Todos los datos del reciclador se guardan en la estructura unificada de lotes:

```
lotes/
└── {loteId}/
    └── reciclador/
        └── data/
            ├── // Datos de entrada (recepción)
            ├── usuario_id
            ├── usuario_folio
            ├── fecha_recepcion
            ├── peso_entrada
            ├── peso_recibido
            ├── peso_neto
            ├── merma_recepcion
            ├── firma_operador
            ├── recepcion_completada
            ├── operador_nombre
            ├── 
            ├── // Datos de salida (formulario)
            ├── peso_neto_salida
            ├── merma
            ├── procesos_aplicados[]
            ├── tipo_poli_salida
            ├── presentacion_salida
            ├── operador_salida_nombre
            ├── firma_salida
            ├── evidencias_foto_salida[]
            ├── comentarios_salida
            ├── fecha_salida
            ├── 
            ├── // Documentación
            ├── f_tecnica_pellet
            ├── rep_result_reci
            └── fecha_documentos
```

## Estados del Lote

El estado se determina dinámicamente según los campos completados:

1. **"salida"** (Pendiente de formulario)
   - Recién recibido del transportista
   - Solo tiene datos de entrada/recepción
   - Falta completar formulario de salida

2. **"documentado"** (Pendiente de documentación)
   - Formulario de salida completo
   - Todos los campos requeridos tienen valor:
     - peso_neto_salida
     - operador_salida_nombre
     - firma_salida
     - procesos_aplicados (al menos uno)
     - tipo_poli_salida
     - presentacion_salida
   - Falta cargar documentos

3. **"finalizado"** (Listo para transferir)
   - Documentación completa:
     - f_tecnica_pellet (URL del documento)
     - rep_result_reci (URL del documento)
   - Puede mostrar código QR

## Flujo de Datos

### 1. Recepción del Transportista
```javascript
// Se crea/actualiza en reciclador/data
{
  usuario_id: "xxx",
  fecha_recepcion: timestamp,
  peso_entrada: 100,
  peso_recibido: 98,
  merma_recepcion: 2,
  firma_operador: "url_firma",
  recepcion_completada: true
}
```

### 2. Formulario de Salida
```javascript
// Se actualiza el mismo documento
{
  ...datosAnteriores,
  peso_neto_salida: 95,
  merma: 3,
  procesos_aplicados: ["Lavado", "Triturado"],
  tipo_poli_salida: "PEBD",
  presentacion_salida: "Pacas",
  operador_salida_nombre: "Juan Pérez",
  firma_salida: "url_firma",
  evidencias_foto_salida: ["url1", "url2"],
  comentarios_salida: "Sin observaciones"
}
```

### 3. Carga de Documentación
```javascript
// Se actualiza el mismo documento
{
  ...datosAnteriores,
  f_tecnica_pellet: "url_documento",
  rep_result_reci: "url_documento",
  fecha_documentos: timestamp
}
```

## Guardado Parcial

El formulario de salida permite guardado parcial:
- No valida campos obligatorios
- Guarda solo los campos con datos
- El estado permanece en "salida"
- El usuario puede volver y continuar

## Guardado Completo

Al hacer clic en "Siguiente":
- Valida todos los campos obligatorios
- Guarda todos los datos
- Cambia el estado a "documentado"
- Navega a la pantalla de documentación

## Ventajas de la Estructura Unificada

1. **Un solo lugar**: Todos los datos en `lotes/{loteId}/reciclador/data`
2. **Sin duplicación**: No se crean documentos en colecciones separadas
3. **Trazabilidad completa**: Todo el historial en el mismo lote
4. **Estados dinámicos**: Se calculan según los campos completados
5. **Consistencia**: Mismo patrón para todos los procesos

## Migración

El sistema ya está configurado para:
- Leer de la estructura unificada primero
- Fallback a colecciones legacy si es necesario
- Guardar siempre en la estructura unificada