# Solución: Error de API Key de Firebase

## Problema Identificado

El archivo `google-services.json` actual contiene una API key dummy que no es válida:
```
"current_key": "AIzaSyDummy-ApiKey-ForDevelopment"
```

## Solución

### Opción 1: Descargar el archivo correcto de Firebase (Recomendado)

1. Ve a la [Consola de Firebase](https://console.firebase.google.com)
2. Selecciona el proyecto **trazabilidad-ecoce**
3. Ve a **Configuración del proyecto** (ícono de engranaje)
4. En la pestaña **General**, busca la sección **Tus apps**
5. Busca la aplicación Android con package name `com.biowaymexico.app`
6. Click en **google-services.json**
7. Descarga el archivo
8. Reemplaza el archivo en `android/app/google-services.json`

### Opción 2: Crear archivo manualmente con la configuración correcta

Reemplaza el contenido de `android/app/google-services.json` con:

```json
{
  "project_info": {
    "project_number": "1098503063628",
    "project_id": "trazabilidad-ecoce",
    "storage_bucket": "trazabilidad-ecoce.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:1098503063628:android:5d4a3e73323f7a31414ce9",
        "android_client_info": {
          "package_name": "com.biowaymexico.app"
        }
      },
      "oauth_client": [],
      "api_key": [
        {
          "current_key": "AIzaSyDgKMZL6trJuXIt-gkKTn5RDzfrg_1aEyU"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ],
  "configuration_version": "1"
}
```

### Después de actualizar el archivo:

1. Ejecuta `flutter clean`
2. Ejecuta `flutter pub get`
3. Vuelve a ejecutar la aplicación

## Verificación

Para verificar que la configuración es correcta:
1. Intenta hacer login con las credenciales del maestro
2. No deberías ver el error "API key not valid"
3. El login debería funcionar correctamente

## Nota sobre App Check

El warning sobre App Check es normal y no afecta la funcionalidad básica. App Check es una capa adicional de seguridad que es opcional.