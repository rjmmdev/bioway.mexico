# Instrucciones para crear el usuario maestro ECOCE

## Pasos para crear el usuario maestro manualmente:

### 1. Crear el usuario en Firebase Auth:
1. Ve a la consola de Firebase: https://console.firebase.google.com
2. Selecciona el proyecto `trazabilidad-ecoce`
3. Ve a Authentication → Users
4. Click en "Add user"
5. Ingresa:
   - Email: `maestro@ecoce.mx` (o el email que prefieras)
   - Password: `master123` (o la contraseña que prefieras)
6. Click en "Add user"
7. Copia el User UID que se genera (lo necesitarás en el siguiente paso)

### 2. Crear el perfil en Firestore:

1. Ve a Firestore Database en la consola
2. Navega a la colección `ecoce_profiles`
3. Si no existe, créala
4. Dentro de `ecoce_profiles`, crea un documento con:
   - Document ID: [El User UID que copiaste]
   - Campos:
     ```json
     {
       "path": "ecoce_profiles/maestro/usuarios/[USER_UID]",
       "tipo_actor": "maestro",
       "ecoce_tipo_actor": "M",
       "ecoce_nombre": "Administrador ECOCE",
       "ecoce_correo_contacto": "maestro@ecoce.mx",
       "ecoce_folio": "M0000001",
       "ecoce_estatus_aprobacion": 1,
       "fecha_creacion": [Timestamp actual],
       "activo": true
     }
     ```

5. Ahora crea la estructura completa:
   - Ve a la raíz de Firestore
   - Crea la colección: `ecoce_profiles`
   - Dentro, crea el documento: `maestro`
   - Dentro de `maestro`, crea la subcolección: `usuarios`
   - Dentro de `usuarios`, crea un documento con ID: [USER_UID]
   - Agrega estos campos:
     ```json
     {
       "ecoce_tipo_actor": "M",
       "ecoce_nombre": "Administrador ECOCE",
       "ecoce_correo_contacto": "maestro@ecoce.mx",
       "ecoce_folio": "M0000001",
       "ecoce_nombre_contacto": "Admin",
       "ecoce_tel_contacto": "5551234567",
       "ecoce_estatus_aprobacion": 1,
       "fecha_creacion": [Timestamp actual],
       "activo": true
     }
     ```

### 3. Verificar el acceso:

1. Abre la aplicación
2. Selecciona ECOCE
3. Inicia sesión con las credenciales del maestro
4. Deberías poder acceder al panel de administración

## Nota importante:
Una vez que tengas acceso como maestro, podrás aprobar las solicitudes de otros usuarios que se registren a través del flujo normal de la aplicación.