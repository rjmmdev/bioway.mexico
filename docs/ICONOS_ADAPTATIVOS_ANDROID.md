# Iconos Adaptativos para Android

## Resumen

Se ha implementado soporte para iconos adaptativos en Android 8.0+ (API 26+) que permite que el ícono de la aplicación se adapte a diferentes formas según el dispositivo (círculo, cuadrado redondeado, squircle, etc.).

## Estructura Implementada

### 1. Archivos de Configuración

#### `mipmap-anydpi-v26/ic_launcher.xml`
```xml
<adaptive-icon>
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
```

#### `values/ic_launcher_background.xml`
```xml
<resources>
    <color name="ic_launcher_background">#70D997</color>
</resources>
```
- Color de fondo: Verde principal de BioWay (#70D997)

### 2. Foreground (Logo)

Se crearon dos versiones:

#### Versión Estándar (`drawable/ic_launcher_foreground.xml`)
- Logo con círculo blanco de fondo
- Letra "B" estilizada en verde oscuro
- Hoja decorativa en verde claro
- Mejor para dispositivos que no recortan mucho

#### Versión Moderna (`drawable-v24/ic_launcher_foreground.xml`)
- Logo sin círculo para máximo aprovechamiento del espacio
- Letra "B" y hoja en blanco
- Mejor contraste con el fondo verde
- Optimizada para Android 7.0+

### 3. AndroidManifest.xml

Se agregó soporte para íconos redondos:
```xml
android:icon="@mipmap/ic_launcher"
android:roundIcon="@mipmap/ic_launcher_round"
```

## Cómo Funciona

1. **Android 8.0+ (API 26+)**: Usa los íconos adaptativos que se ajustan a la forma del launcher
2. **Android 7.1 (API 25)**: Usa los íconos round si el launcher los soporta
3. **Android < 7.1**: Usa los íconos PNG tradicionales en las carpetas mipmap

## Personalización con Íconos Propios

### Opción 1: Usar una Imagen PNG (Recomendado)

1. **Preparar la imagen**:
   - Tamaño recomendado: 512x512px o mayor
   - Formato: PNG con transparencia
   - El logo debe ocupar aproximadamente el 60% del canvas
   - Dejar margen alrededor para el recorte adaptativo

2. **Convertir a recursos**:
   ```bash
   # Instalar Android Studio o usar herramientas online como:
   # - https://romannurik.github.io/AndroidAssetStudio/icons-launcher.html
   # - https://www.appicon.co/
   ```

3. **Reemplazar archivos**:
   - Colocar el foreground en: `drawable-xxxhdpi/ic_launcher_foreground.png`
   - Android escalará automáticamente para otras densidades

### Opción 2: Usar el Logo SVG de BioWay

1. **Convertir SVG a Vector Drawable**:
   ```xml
   <!-- Reemplazar el contenido de ic_launcher_foreground.xml -->
   <vector xmlns:android="http://schemas.android.com/apk/res/android"
       android:width="108dp"
       android:height="108dp"
       android:viewportWidth="108"
       android:viewportHeight="108">
       <!-- Pegar aquí el path del SVG convertido -->
   </vector>
   ```

2. **Herramientas de conversión**:
   - Android Studio: File → New → Vector Asset
   - Online: https://svg2vector.com/

### Opción 3: Usar Flutter Launcher Icons

1. **Agregar dependencia** en `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     flutter_launcher_icons: ^0.13.1
   
   flutter_launcher_icons:
     android: true
     ios: true
     image_path: "assets/icon/app_icon.png"
     adaptive_icon_background: "#70D997"
     adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
   ```

2. **Ejecutar**:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

## Guías de Diseño

### Área Segura
- El contenido principal debe estar en el centro 66dp de los 108dp totales
- Esto asegura que no se corte en ninguna forma de máscara

### Colores Recomendados
- Background: `#70D997` (Verde BioWay)
- Foreground: Blanco o colores que contrasten bien

### Formas de Máscara
Los dispositivos pueden aplicar diferentes formas:
- Círculo (Pixel)
- Cuadrado redondeado (Samsung)
- Squircle (OnePlus)
- Lágrima (algunos launchers)

## Testing

### En Emulador
1. Crear AVD con Android 8.0+
2. Instalar la app
3. Mantener presionado el ícono → Editar → Cambiar forma

### En Dispositivo Real
1. Instalar la app
2. Verificar en el launcher
3. Probar diferentes launchers (Nova, Pixel, etc.)

## Solución de Problemas

### El ícono se ve pixelado
- Aumentar la resolución de las imágenes fuente
- Verificar que se estén usando vectores cuando sea posible

### El ícono se ve cortado
- Reducir el tamaño del contenido al 60% del canvas
- Centrar mejor el diseño

### No se ven los cambios
1. Limpiar el proyecto: `flutter clean`
2. Desinstalar la app del dispositivo
3. Reinstalar: `flutter run`

## Recursos

- [Documentación oficial de Adaptive Icons](https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive)
- [Material Design - Product Icons](https://material.io/design/iconography/product-icons.html)
- [Android Asset Studio](https://romannurik.github.io/AndroidAssetStudio/)

## Notas Finales

Los íconos adaptativos mejoran significativamente la apariencia de la aplicación en dispositivos modernos, proporcionando una experiencia visual consistente con el sistema operativo y permitiendo efectos visuales como parallax y animaciones del sistema.