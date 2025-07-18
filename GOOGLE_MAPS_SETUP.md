# Configuración de Google Maps

## Pasos para configurar Google Maps API

### 1. Obtener API Keys de Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita las siguientes APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
   - Places API (opcional, para búsquedas mejoradas)
4. Crea credenciales (API Keys) para Android e iOS

### 2. Configurar las API Keys en el proyecto

#### Android
Edita el archivo `android/app/src/main/AndroidManifest.xml` y reemplaza `YOUR_GOOGLE_MAPS_API_KEY_HERE` con tu API key de Android:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_DE_ANDROID_AQUI"/>
```

#### iOS
Edita el archivo `ios/Runner/AppDelegate.swift` y reemplaza `YOUR_GOOGLE_MAPS_API_KEY_HERE` con tu API key de iOS:

```swift
GMSServices.provideAPIKey("TU_API_KEY_DE_IOS_AQUI")
```

### 3. Actualizar la configuración central

Edita el archivo `lib/config/google_maps_config.dart` y actualiza las API keys:

```dart
class GoogleMapsConfig {
  static const String androidApiKey = 'TU_API_KEY_DE_ANDROID_AQUI';
  static const String iosApiKey = 'TU_API_KEY_DE_IOS_AQUI';
  // ...
}
```

### 4. Restricciones de API Key (Recomendado)

#### Para Android:
1. En Google Cloud Console, ve a Credenciales
2. Selecciona tu API Key de Android
3. En "Restricciones de aplicación", selecciona "Apps para Android"
4. Agrega tu huella digital SHA-1 y el nombre del paquete: `com.biowaymexico.app`

#### Para iOS:
1. En Google Cloud Console, ve a Credenciales
2. Selecciona tu API Key de iOS
3. En "Restricciones de aplicación", selecciona "Apps para iOS"
4. Agrega el Bundle ID de tu app iOS

## Uso del Widget de Selección de Ubicación

### Importar el widget:

```dart
import 'package:app/widgets/common/location_picker_widget.dart';
```

### Ejemplo de uso básico:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LocationPickerWidget(
      title: 'Seleccionar ubicación del proveedor',
      onLocationSelected: (LatLng location, String address) {
        // Guardar la ubicación seleccionada
        setState(() {
          _selectedLocation = location;
          _selectedAddress = address;
        });
      },
    ),
  ),
);
```

### Ejemplo con ubicación inicial:

```dart
LocationPickerWidget(
  title: 'Actualizar ubicación',
  initialLocation: LatLng(19.4326, -99.1332),
  initialAddress: 'Ciudad de México',
  showSearchBar: true,
  onLocationSelected: (LatLng location, String address) {
    // Procesar la ubicación
  },
)
```

## Permisos necesarios

Los permisos ya están configurados en el proyecto:

### Android (AndroidManifest.xml):
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`

### iOS (Info.plist):
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`

## Características del widget LocationPickerWidget

- **Búsqueda de direcciones**: Campo de búsqueda integrado
- **Ubicación actual**: Botón para obtener la ubicación GPS actual
- **Selección por toque**: Toca el mapa para seleccionar una ubicación
- **Dirección automática**: Geocodificación inversa para obtener la dirección
- **Marcador visual**: Muestra la ubicación seleccionada
- **Confirmación**: Botón flotante para confirmar la selección

## Solución de problemas

### El mapa no carga
- Verifica que las API Keys estén correctamente configuradas
- Asegúrate de que las APIs necesarias estén habilitadas en Google Cloud Console
- Revisa la consola de Flutter para mensajes de error

### Error de permisos
- En Android: Asegúrate de aceptar los permisos de ubicación
- En iOS: Ve a Configuración > Privacidad > Ubicación y habilita los permisos

### Búsqueda no funciona
- Verifica que la Geocoding API esté habilitada
- Revisa los límites de cuota en Google Cloud Console

## Notas importantes

1. **Seguridad**: Nunca subas las API Keys al repositorio. Considera usar variables de entorno o archivos de configuración excluidos del control de versiones.

2. **Costos**: Google Maps tiene un modelo de precios por uso. Configura alertas de facturación en Google Cloud Console.

3. **Límites**: Las API tienen límites de solicitudes. Para producción, considera implementar caché de geocodificación.

4. **Modo offline**: El mapa requiere conexión a internet. Considera agregar manejo de errores para modo offline.