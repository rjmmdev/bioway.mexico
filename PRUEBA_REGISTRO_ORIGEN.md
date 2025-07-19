# Guía de Prueba - Registro de Usuario Origen (ECOCE)

## Configuración Previa

1. Asegúrate de tener la app corriendo con `flutter run`
2. En la pantalla inicial, selecciona **ECOCE**
3. En la pantalla de login de ECOCE, toca **"Crear cuenta ECOCE"**

## Registro de Centro de Acopio

### Paso 1: Selección de Tipo
- Selecciona **"Centro de Acopio"** (icono de almacén)

### Paso 2: Información Básica
- **Nombre comercial**: Acopio San Miguel
- **RFC** (opcional): ASM240118ABC
- **Nombre de contacto**: Juan Pérez García
- **Teléfono**: 5551234567
- **Teléfono oficina**: 5557654321

### Paso 3: Ubicación
- **Dirección**: Av. Insurgentes Sur 123
- **Núm. Ext**: 456
- **Código Postal**: 03810
- **Estado**: Ciudad de México
- **Municipio**: Benito Juárez
- **Colonia**: Del Valle
- **Referencias**: Entre Calle A y Calle B
- Toca **"Buscar ubicación en el mapa"** para establecer coordenadas

### Paso 4: Operaciones
- **Materiales**: Selecciona todos (EPF - Poli, EPF - PP, EPF - Multi)
- **Transporte propio**: Activar
- **Capacidad de prensado**:
  - Largo: 10
  - Ancho: 8
  - Peso máximo: 500
- **Link red social** (opcional): https://facebook.com/acopiosanmiguel

### Paso 5: Datos Fiscales
- Selecciona al menos 2 documentos (se simularán)

### Paso 6: Crear Cuenta
- **Email**: acopio1@test.com
- **Contraseña**: Test123456
- **Confirmar contraseña**: Test123456
- Acepta términos y condiciones
- Toca **"Crear cuenta"**

**Resultado esperado**: 
- Folio generado: **A0000001** (primer centro de acopio)
- Mensaje de cuenta pendiente de aprobación

## Registro de Planta de Separación

### Paso 1: Selección de Tipo
- Selecciona **"Planta de Separación"** (icono de fábrica)

### Paso 2: Información Básica
- **Nombre comercial**: Planta Recicladora Norte
- **RFC** (opcional): PRN240118XYZ
- **Nombre de contacto**: María López Hernández
- **Teléfono**: 5559876543
- **Teléfono oficina**: 5553456789

### Paso 3: Ubicación
- **Dirección**: Blvd. Manuel Ávila Camacho 500
- **Núm. Ext**: 100
- **Código Postal**: 11000
- **Estado**: Ciudad de México
- **Municipio**: Miguel Hidalgo
- **Colonia**: Polanco
- **Referencias**: Frente al parque industrial
- Toca **"Buscar ubicación en el mapa"** para establecer coordenadas

### Paso 4: Operaciones
- **Materiales**: Selecciona todos
- **Transporte propio**: Desactivar
- **Capacidad de prensado**:
  - Largo: 20
  - Ancho: 15
  - Peso máximo: 1000

### Paso 5: Datos Fiscales
- Selecciona todos los documentos

### Paso 6: Crear Cuenta
- **Email**: planta1@test.com
- **Contraseña**: Test123456
- **Confirmar contraseña**: Test123456
- Acepta términos y condiciones
- Toca **"Crear cuenta"**

**Resultado esperado**:
- Folio generado: **P0000001** (primera planta de separación)
- Mensaje de cuenta pendiente de aprobación

## Verificación en Firebase

### Console de Firebase
1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona el proyecto **trazabilidad-ecoce**
3. Ve a **Authentication** → **Users**
   - Deberías ver los usuarios creados con sus emails
4. Ve a **Firestore Database** → **ecoce_profiles**
   - Verifica los documentos creados con:
     - `ecoce_tipo_actor: "O"`
     - `ecoce_subtipo: "A"` o `"P"`
     - `ecoce_folio: "A0000001"` o `"P0000001"`

### Campos importantes a verificar:
- Los folios sean secuenciales (A0000001, A0000002... para acopios)
- Los materiales seleccionados estén en `ecoce_lista_materiales`
- Las coordenadas estén guardadas en `ecoce_latitud` y `ecoce_longitud`
- El estado de aprobación sea `ecoce_estatus_aprobacion: 0` (pendiente)

## Pruebas adicionales

1. **Registro múltiple**: Registra varios centros de acopio para verificar que los folios incrementen correctamente (A0000001, A0000002, A0000003...)

2. **Validaciones**:
   - Email duplicado debe mostrar error
   - Contraseñas no coincidentes deben mostrar error
   - Campos obligatorios vacíos no deben permitir continuar

3. **Navegación**:
   - El botón atrás debe funcionar entre pasos
   - Al completar el registro debe regresar al login

## Notas importantes

- Los usuarios creados quedarán en estado "pendiente de aprobación" (`ecoce_estatus_aprobacion: 0`)
- Para aprobar usuarios, se necesita acceder como usuario maestro
- Los documentos se simulan por ahora (no se suben archivos reales)
- Las coordenadas del mapa se obtienen mediante geocoding de la dirección