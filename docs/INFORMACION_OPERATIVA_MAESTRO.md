# Información Operativa en Pantalla del Maestro

## Fecha: 2025-08-04

## Problema Identificado
La información del Paso 3 del registro (Información Operativa) se estaba guardando correctamente en Firebase pero NO se mostraba en las pantallas del Usuario Maestro.

## Solución Implementada

### Nueva Tarjeta de Información Operativa
Se agregó una nueva sección en la pantalla de detalles de solicitud que muestra:

1. **Materiales que maneja** (`ecoce_lista_materiales`)
   - Lista de materiales configurados dinámicamente
   - Se muestra como texto separado por comas

2. **Transporte propio** (`ecoce_transporte`)
   - Indicador Sí/No
   - Icono de camión

3. **Redes sociales** (`ecoce_link_red_social`)
   - Link o nombre de red social
   - Icono de compartir
   - Copiable al portapapeles

4. **Capacidad de prensado** (Solo para Acopiador y Planta de Separación)
   - **Dimensiones**: Largo × Ancho × Alto en metros
   - **Peso**: Capacidad en kilogramos

### Características de la Implementación

#### Consistencia Visual
- Utiliza el componente existente `MaestroInfoSection`
- Color distintivo: `BioWayColors.ppPurple`
- Icono de fábrica para representar información operativa
- Formato consistente con otras tarjetas de información

#### Lógica de Visualización
- **Transportistas**: No muestra la sección (no manejan materiales)
- **Sección adaptativa**: Solo aparece si hay datos para mostrar
- **Capacidad de prensado**: Solo visible para Acopiador (A) y Planta de Separación (P)

### Archivos Modificados
```
lib/screens/ecoce/maestro/maestro_solicitud_details_screen.dart
├── Línea 195: Agregada llamada a _buildInformacionOperativa()
└── Líneas 564-651: Nuevo método _buildInformacionOperativa()
```

### Estructura de Datos en Firebase
```javascript
solicitudes_cuentas/{solicitudId}/datos_perfil/
├── ecoce_lista_materiales: ["material1", "material2", ...]
├── ecoce_transporte: true/false
├── ecoce_link_red_social: "https://facebook.com/empresa"
├── ecoce_dim_cap: {
│   ├── largo: 10.5
│   ├── ancho: 8.0
│   └── alto: 3.0
│ }
└── ecoce_peso_cap: 1000.0
```

### Orden de Visualización en Pantalla
1. Header con información principal
2. Estado de la solicitud
3. Información de Contacto
4. Información de Ubicación
5. **Información Operativa** ← Nueva sección
6. Información Bancaria (si existe)
7. Documentos
8. Actividades Autorizadas (si existen)

## Casos de Uso

### Acopiador/Planta de Separación
Muestra:
- ✅ Materiales que maneja
- ✅ Transporte propio
- ✅ Redes sociales (si tiene)
- ✅ Dimensiones de prensado
- ✅ Capacidad de prensado (kg)

### Reciclador/Transformador/Laboratorio
Muestra:
- ✅ Materiales que maneja
- ✅ Transporte propio
- ✅ Redes sociales (si tiene)
- ❌ Dimensiones de prensado (no aplica)
- ❌ Capacidad de prensado (no aplica)

### Transportista
- ❌ No muestra la sección completa (no maneja materiales)

## Beneficios

1. **Visibilidad completa**: El Maestro ahora puede ver toda la información operativa de los proveedores
2. **Mejor toma de decisiones**: Información clave visible durante el proceso de aprobación
3. **Consistencia**: Mantiene el diseño visual existente
4. **Adaptabilidad**: Se ajusta según el tipo de usuario

## Pruebas Recomendadas

1. Ver solicitud de **Acopiador** → Verificar capacidad de prensado visible
2. Ver solicitud de **Planta de Separación** → Verificar capacidad de prensado visible
3. Ver solicitud de **Reciclador** → Verificar que NO muestra capacidad de prensado
4. Ver solicitud de **Transportista** → Verificar que NO muestra la sección
5. Ver solicitud sin datos operativos → Verificar que NO muestra la sección

## Notas Técnicas

- La información se obtiene de `datos_perfil` en la solicitud
- Los materiales ahora son dinámicos (cargados desde Firestore)
- La sección es completamente responsiva y se adapta al contenido
- No requiere cambios en el backend ni en el proceso de registro