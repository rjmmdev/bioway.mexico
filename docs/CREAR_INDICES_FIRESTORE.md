# Crear Índices en Firestore

## Índices Requeridos

### 1. Índice para lotes_reciclador (compatibilidad legacy)
Este índice es necesario para consultas en la colección `lotes_reciclador` filtrando por `userId` y ordenando por `fecha_creacion`.

**Crear manualmente:**
https://console.firebase.google.com/v1/r/project/trazabilidad-ecoce/firestore/indexes?create_composite=Cltwcm9qZWN0cy90cmF6YWJpbGlkYWQtZWNvY2UvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2xvdGVzX3JlY2ljbGFkb3IvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaEgoOZmVjaGFfY3JlYWNpb24QAhoMCghfX25hbWVfXxAC

### 2. Índice para datos_generales (sistema unificado)
Este índice es necesario para consultas en el collection group `datos_generales` filtrando por `proceso_actual`.

**Crear manualmente:**
https://console.firebase.google.com/v1/r/project/trazabilidad-ecoce/firestore/indexes?create_exemption=CmZwcm9qZWN0cy90cmF6YWJpbGlkYWQtZWNvY2UvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2RhdG9zX2dlbmVyYWxlcy9maWVsZHMvcHJvY2Vzb19hY3R1YWwQAhoSCg5wcm9jZXNvX2FjdHVhbBAB

## Desplegar Índices con Firebase CLI

Si tienes Firebase CLI instalado, puedes desplegar todos los índices ejecutando:

```bash
firebase deploy --only firestore:indexes
```

## Verificar Índices

Puedes verificar el estado de los índices en:
https://console.firebase.google.com/project/trazabilidad-ecoce/firestore/indexes

Los índices pueden tardar varios minutos en construirse, especialmente si hay muchos documentos en las colecciones.