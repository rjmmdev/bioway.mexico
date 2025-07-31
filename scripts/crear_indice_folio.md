# Crear Índice para Generación de Folios

El error en la consola indica que necesitas crear un índice específico. 

## Opción 1: Usar el enlace directo (Recomendado)

Abre este enlace en tu navegador (desde la consola de error):
```
https://console.firebase.google.com/v1/r/project/trazabilidad-ecoce/firestore/indexes?create_composite=Cl5wcm9qZWN0cy90cmF6YWJpbGlkYWQtZWNvY2UvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3NvbGljaXR1ZGVzX2N1ZW50YXMvaW5kZXhlcy9fEAEaCgoGZXN0YWRvEAEaEgoOZm9saW9fYXNpZ25hZG8QAhoMCghfX25hbWVfXxAC
```

Esto creará automáticamente el índice correcto.

## Opción 2: Crear manualmente en Firebase Console

1. Ve a: https://console.firebase.google.com/project/trazabilidad-ecoce/firestore/indexes
2. Click en "Crear índice"
3. Configurar:
   - **Colección**: `solicitudes_cuentas`
   - **Campos**:
     1. `estado` - Ascendente
     2. `folio_asignado` - Ascendente
     3. `__name__` - Ascendente
   - **Ámbito de consulta**: Colección

## Tiempo de construcción

El índice puede tardar 5-10 minutos en construirse. Verás el estado en la consola de Firebase.

## Verificación

Una vez creado, la generación de folios funcionará correctamente y no verás más el error `FAILED_PRECONDITION`.