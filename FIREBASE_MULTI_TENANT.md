# Configuración Multi-Tenant de Firebase

Esta aplicación está diseñada para trabajar con múltiples proyectos de Firebase, uno para cada plataforma (ECOCE y BioWay).

## Arquitectura

### FirebaseManager
- Gestiona múltiples instancias de Firebase
- Permite cambiar entre proyectos dinámicamente
- Evita conflictos entre diferentes configuraciones

### Estructura de archivos
```
lib/services/firebase/
├── firebase_manager.dart    # Gestor principal de instancias Firebase
├── firebase_config.dart     # Configuraciones por plataforma
└── auth_service.dart        # Servicio de autenticación multi-tenant
```

## Configuración

### 1. Proyecto ECOCE (Configurado)
- **Project ID**: `trazabilidad-ecoce`
- **Android Package**: `com.biowaymexico.app`
- **Estado**: ✅ Configurado y funcionando

### 2. Proyecto BioWay (Pendiente)
- **Project ID**: `bioway-mexico` (sugerido)
- **Android Package**: `com.biowaymexico.app`
- **Estado**: ⏳ Pendiente de crear

## Cómo agregar un nuevo proyecto Firebase

### Paso 1: Crear el proyecto en Firebase Console
1. Ir a [Firebase Console](https://console.firebase.google.com/)
2. Crear nuevo proyecto
3. Agregar app Android con package name `com.biowaymexico.app`

### Paso 2: Actualizar firebase_config.dart
```dart
static const FirebaseOptions _biowayOptions = FirebaseOptions(
  apiKey: 'TU_API_KEY_AQUI',
  appId: 'TU_APP_ID_AQUI',
  messagingSenderId: 'TU_SENDER_ID_AQUI',
  projectId: 'bioway-mexico',
  storageBucket: 'bioway-mexico.firebasestorage.app',
);
```

### Paso 3: Configurar Android
Para Android, necesitas tener SOLO UN archivo `google-services.json` que contenga la configuración de TODOS los proyectos:

1. Descarga el `google-services.json` de cada proyecto
2. Combínalos manualmente en un solo archivo
3. Coloca el archivo combinado en `android/app/`

Ejemplo de estructura combinada:
```json
{
  "project_info": {
    "project_number": "NUMERO_DEL_PROYECTO",
    "project_id": "PROYECTO_PRINCIPAL"
  },
  "client": [
    {
      // Configuración ECOCE
      "client_info": {
        "mobilesdk_app_id": "APP_ID_ECOCE",
        "android_client_info": {
          "package_name": "com.biowaymexico.app"
        }
      }
    },
    {
      // Configuración BioWay
      "client_info": {
        "mobilesdk_app_id": "APP_ID_BIOWAY",
        "android_client_info": {
          "package_name": "com.biowaymexico.app"
        }
      }
    }
  ]
}
```

## Uso en el código

### Inicializar Firebase para una plataforma
```dart
// En la pantalla de login de ECOCE
await _authService.initializeForPlatform(FirebasePlatform.ecoce);

// En la pantalla de login de BioWay
await _authService.initializeForPlatform(FirebasePlatform.bioway);
```

### Usar servicios de Firebase
```dart
// El AuthService automáticamente usa la instancia correcta
final userCredential = await _authService.signInWithEmailAndPassword(
  email: email,
  password: password,
);
```

## Importante

- **NO** inicialices Firebase en `main.dart`
- Cada plataforma inicializa su propio Firebase al entrar al login
- Los datos están completamente separados entre proyectos
- Un usuario de ECOCE no puede acceder a datos de BioWay y viceversa

## Solución de problemas

### Error: "Default Firebase app already exists"
- Esto significa que intentaste inicializar Firebase dos veces
- Verifica que NO estés inicializando en main.dart

### Error: "No Firebase app has been created"
- Asegúrate de llamar `initializeForPlatform` antes de usar servicios
- Verifica que la configuración en `firebase_config.dart` sea correcta

### Error al compilar Android
- Verifica que `google-services.json` contenga configuración para ambos proyectos
- Asegúrate de que el package name sea exactamente `com.biowaymexico.app`