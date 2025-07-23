# Instrucciones para Configurar Firebase Storage

## ⚠️ IMPORTANTE: Configuración Requerida

El sistema de carga de documentos requiere que Firebase Storage esté correctamente configurado. Actualmente el archivo `google-services.json` contiene valores dummy que deben ser reemplazados con los valores reales del proyecto Firebase.

## Pasos para Configurar:

### 1. Obtener el archivo google-services.json real

1. Ir a la [Consola de Firebase](https://console.firebase.google.com/)
2. Seleccionar el proyecto `trazabilidad-ecoce`
3. Hacer clic en el ícono de Android en la página principal del proyecto
4. Si ya existe la app Android:
   - Hacer clic en el ícono de engranaje ⚙️ junto a "Configuración del proyecto"
   - Ir a la pestaña "General"
   - En la sección "Tus apps", buscar la app Android
   - Descargar el archivo `google-services.json`
5. Si NO existe la app Android:
   - Hacer clic en "Agregar app" > "Android"
   - Package name: `com.biowaymexico.app`
   - App nickname: `BioWay México`
   - Descargar el archivo `google-services.json`

### 2. Reemplazar el archivo

1. Copiar el archivo descargado a: `android/app/google-services.json`
2. Sobrescribir el archivo existente

### 3. Habilitar Firebase Storage

1. En la consola de Firebase, ir a "Storage" en el menú lateral
2. Si no está habilitado, hacer clic en "Comenzar"
3. Seleccionar la ubicación del servidor (recomendado: `us-central1`)
4. Aceptar las reglas de seguridad por defecto (las cambiaremos después)

### 4. Configurar las Reglas de Seguridad

1. En Firebase Console > Storage > Rules
2. Reemplazar las reglas por defecto con las del archivo `firebase_storage_rules.txt`
3. Hacer clic en "Publicar"

### 5. Verificar la Configuración

El archivo `google-services.json` debe contener:

```json
{
  "project_info": {
    "project_number": "[NÚMERO REAL]",
    "project_id": "trazabilidad-ecoce",
    "storage_bucket": "trazabilidad-ecoce.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "[ID REAL]",
        "android_client_info": {
          "package_name": "com.biowaymexico.app"
        }
      },
      "api_key": [
        {
          "current_key": "[API KEY REAL]"
        }
      ]
    }
  ]
}
```

### 6. Para Web (si aplica)

Si también se ejecuta en web, configurar en `lib/services/firebase/firebase_config.dart`:

```dart
static FirebaseOptions get ecoceWeb => const FirebaseOptions(
  apiKey: "[API KEY REAL]",
  authDomain: "trazabilidad-ecoce.firebaseapp.com",
  projectId: "trazabilidad-ecoce",
  storageBucket: "trazabilidad-ecoce.appspot.com",
  messagingSenderId: "[SENDER ID REAL]",
  appId: "[APP ID REAL]",
);
```

## Solución de Problemas

### Error: "Firebase Storage no inicializado"
- Verificar que `google-services.json` tenga valores reales
- Verificar que Storage esté habilitado en Firebase Console

### Error: "Permission denied"
- Verificar las reglas de seguridad en Firebase Console
- Asegurarse de que el usuario esté autenticado

### Documentos no se suben
- Verificar la consola del navegador/IDE para ver logs detallados
- Verificar que el archivo no exceda 5MB
- Verificar que sea un tipo de archivo permitido (PDF, imágenes, Word)

## Contacto

Si necesitas las credenciales reales del proyecto Firebase, contacta al administrador del proyecto.