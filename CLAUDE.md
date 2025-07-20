# BioWay México - Documentación Completa del Proyecto

## Tabla de Contenidos

1. [Resumen General del Proyecto](#resumen-general-del-proyecto)
2. [Arquitectura y Estructura](#arquitectura-y-estructura)
3. [Configuración de Firebase Multi-Tenant](#configuración-de-firebase-multi-tenant)
4. [Sistema ECOCE](#sistema-ecoce)
5. [Optimizaciones Realizadas](#optimizaciones-realizadas)
6. [Configuraciones Técnicas](#configuraciones-técnicas)
7. [Validaciones y Flujos](#validaciones-y-flujos)
8. [Guías de Desarrollo](#guías-de-desarrollo)
9. [Documentos de Referencia](#documentos-de-referencia)

---

## Resumen General del Proyecto

BioWay México es una aplicación Flutter móvil para reciclaje y gestión de residuos con soporte dual de plataforma (BioWay y ECOCE). La aplicación implementa un sistema completo de seguimiento de cadena de suministro para materiales reciclables con acceso basado en roles y arquitectura Firebase multi-tenant.

### Características Principales
- **Dual Platform**: BioWay y ECOCE en una sola aplicación
- **Multi-Tenant Firebase**: Proyectos separados por plataforma
- **Role-Based Access**: Diferentes tipos de usuarios con permisos específicos
- **Material Tracking**: Seguimiento completo de materiales reciclables
- **QR Code System**: Generación y escaneo de códigos QR para lotes
- **Document Management**: Subida y gestión de documentos con compresión
- **Geolocation**: Selección de ubicación sin permisos GPS requeridos

---

## Arquitectura y Estructura

### Comandos de Desarrollo

```bash
# Desarrollo
flutter clean && flutter pub get
flutter run -d emulator-5554
flutter run
flutter run -v

# Construcción
flutter build apk --debug
flutter build apk --release
flutter build appbundle
flutter build ios
flutter build apk --obfuscate --split-debug-info=./symbols

# Testing
flutter test
flutter test --coverage
flutter test test/widget_test.dart
flutter test --name="Login"
flutter drive --target=test_driver/app.dart

# Calidad de Código
flutter analyze
dart format .
dart format lib/main.dart
flutter pub outdated
flutter pub upgrade

# Debugging
flutter run --observatory-port=8888
flutter run --flavor development
flutter clean && rm -rf build/
flutter create --platforms=android,ios .
```

### Organización de Pantallas

```
lib/screens/
├── splash_screen.dart              # Punto de entrada con animación
├── platform_selector_screen.dart   # Selección BioWay vs ECOCE
├── login/
│   ├── bioway/                    # Autenticación BioWay
│   └── ecoce/                     # Autenticación ECOCE
│       └── providers/             # Registro específico por rol
└── ecoce/
    ├── origen/                    # Pantallas de Acopiador
    ├── reciclador/               # Pantallas de Reciclador
    ├── transporte/               # Pantallas de Transporte
    ├── planta_separacion/        # Pantallas de Planta de Separación
    ├── transformador/            # Pantallas de Transformador
    ├── laboratorio/              # Pantallas de Laboratorio
    ├── maestro/                  # Pantallas de Administrador Master
    ├── repositorio/              # Pantallas de Repositorio
    └── shared/                   # Componentes compartidos ECOCE
```

### Arquitectura de Servicios

Los servicios manejan la lógica de negocio y las integraciones externas:

- **AuthService**: Autenticación multi-tenant con cambio de plataforma
- **EcoceProfileService**: Gestión de perfiles de usuario ECOCE con datos basados en roles y sistema de solicitudes
- **ImageService**: Compresión de imágenes (máx 50KB) y gestión
- **DocumentService**: Subida de documentos con compresión e integración Firebase Storage
- **FirebaseManager**: Gestión centralizada de instancias Firebase

### Patrón de Reutilización de Widgets

Widgets comunes organizados para máxima reutilización:

- `lib/widgets/common/`: Widgets agnósticos de plataforma (gradientes, mapas, etc.)
- `lib/screens/ecoce/shared/widgets/`: Componentes compartidos específicos de ECOCE
- Convención de nomenclatura: `[Feature][Type]Widget` (ej., `LocationPickerWidget`)

---

## Configuración de Firebase Multi-Tenant

### Arquitectura Multi-Tenant

Esta aplicación está diseñada para trabajar con múltiples proyectos de Firebase, uno para cada plataforma (ECOCE y BioWay).

#### FirebaseManager
- Gestiona múltiples instancias de Firebase
- Permite cambiar entre proyectos dinámicamente
- Evita conflictos entre diferentes configuraciones

#### Estructura de archivos
```
lib/services/firebase/
├── firebase_manager.dart    # Gestor principal de instancias Firebase
├── firebase_config.dart     # Configuraciones por plataforma
└── auth_service.dart        # Servicio de autenticación multi-tenant
```

### Configuración de Proyectos

#### 1. Proyecto ECOCE (Configurado)
- **Project ID**: `trazabilidad-ecoce`
- **Android Package**: `com.biowaymexico.app`
- **Estado**: ✅ Configurado y funcionando

#### 2. Proyecto BioWay (Pendiente)
- **Project ID**: `bioway-mexico` (sugerido)
- **Android Package**: `com.biowaymexico.app`
- **Estado**: ⏳ Pendiente de crear

### Cómo agregar un nuevo proyecto Firebase

#### Paso 1: Crear el proyecto en Firebase Console
1. Ir a [Firebase Console](https://console.firebase.google.com/)
2. Crear nuevo proyecto
3. Agregar app Android con package name `com.biowaymexico.app`

#### Paso 2: Actualizar firebase_config.dart
```dart
static const FirebaseOptions _biowayOptions = FirebaseOptions(
  apiKey: 'TU_API_KEY_AQUI',
  appId: 'TU_APP_ID_AQUI',
  messagingSenderId: 'TU_SENDER_ID_AQUI',
  projectId: 'bioway-mexico',
  storageBucket: 'bioway-mexico.firebasestorage.app',
);
```

#### Paso 3: Configurar Android
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

### Uso en el código

#### Inicializar Firebase para una plataforma
```dart
// En la pantalla de login de ECOCE
await _authService.initializeForPlatform(FirebasePlatform.ecoce);

// En la pantalla de login de BioWay
await _authService.initializeForPlatform(FirebasePlatform.bioway);
```

#### Usar servicios de Firebase
```dart
// El AuthService automáticamente usa la instancia correcta
final userCredential = await _authService.signInWithEmailAndPassword(
  email: email,
  password: password,
);
```

### Importante

- **NO** inicialices Firebase en `main.dart`
- Cada plataforma inicializa su propio Firebase al entrar al login
- Los datos están completamente separados entre proyectos
- Un usuario de ECOCE no puede acceder a datos de BioWay y viceversa

### Solución de problemas

#### Error: "Default Firebase app already exists"
- Esto significa que intentaste inicializar Firebase dos veces
- Verifica que NO estés inicializando en main.dart

#### Error: "No Firebase app has been created"
- Asegúrate de llamar `initializeForPlatform` antes de usar servicios
- Verifica que la configuración en `firebase_config.dart` sea correcta

#### Error al compilar Android
- Verifica que `google-services.json` contenga configuración para ambos proyectos
- Asegúrate de que el package name sea exactamente `com.biowaymexico.app`

---

## Sistema ECOCE

### Configuración de Autenticación en Firebase

#### Problema Actual
El error que estás viendo indica que la autenticación por email/contraseña no está habilitada en Firebase:

```
This operation is not allowed. This may be because the given sign-in provider is disabled for this Firebase project.
```

#### Solución: Habilitar Autenticación por Email/Contraseña

1. Ve a la [Consola de Firebase](https://console.firebase.google.com)
2. Selecciona el proyecto **trazabilidad-ecoce**
3. En el menú lateral, ve a **Authentication**
4. Click en la pestaña **Sign-in method**
5. Busca **Email/Password** en la lista
6. Click en el ícono de editar (lápiz)
7. Activa el switch de **Enable**
8. Click en **Save**

### Sistema de Folios Secuenciales

#### Resumen

El sistema de folios ha sido actualizado para garantizar que no existan espacios vacíos en la numeración. Los folios ahora se asignan **únicamente cuando el usuario maestro aprueba la cuenta**, no al momento del registro.

#### Cambios Implementados

##### 1. Registro sin Folio

Al registrarse, los usuarios:
- Completan todos sus datos normalmente
- Se crea su cuenta en Firebase con `ecoce_folio: "PENDIENTE"`
- El dialog de confirmación muestra:
  - ✅ "Solicitud enviada exitosamente"
  - ℹ️ "Tu folio se asignará una vez aprobada tu cuenta"
- NO se genera ningún número de folio

##### 2. Asignación de Folio al Aprobar

Cuando el maestro aprueba una cuenta:
1. Se ejecuta `approveProfile()`
2. El método obtiene el tipo y subtipo del usuario
3. Genera el siguiente folio secuencial disponible
4. Actualiza el perfil con:
   - El folio asignado
   - Estado aprobado (1)
   - Fecha y usuario aprobador
5. Muestra mensaje: "Cuenta aprobada exitosamente\nFolio asignado: [X0000001]"

##### 3. Formato de Folios por Tipo

Los folios mantienen el formato de 1 letra + 7 dígitos:

- **A0000001**: Centro de Acopio (Origen)
- **P0000001**: Planta de Separación (Origen)
- **R0000001**: Reciclador
- **T0000001**: Transformador
- **V0000001**: Transporte
- **L0000001**: Laboratorio

#### Ventajas del Nuevo Sistema

1. **Sin espacios vacíos**: Los números son consecutivos solo para cuentas aprobadas
2. **Orden cronológico**: El orden de los folios refleja el orden de aprobación
3. **Auditoría clara**: Se puede ver cuándo se aprobó cada cuenta por su folio
4. **Sin desperdicio**: Las cuentas rechazadas no consumen números

#### Flujo Completo

```
1. Usuario se registra
   └─> Perfil creado con folio="PENDIENTE"

2. Usuario intenta login
   └─> Mensaje: "Cuenta pendiente de aprobación"

3. Maestro revisa solicitud
   ├─> APRUEBA
   │   ├─> Genera folio secuencial (ej: A0000001)
   │   ├─> Actualiza perfil con folio y estado=1
   │   └─> Usuario puede hacer login
   │
   └─> RECHAZA
       ├─> Actualiza estado=2
       ├─> NO se asigna folio
       └─> Opción de eliminar cuenta
```

### Flujo de Aprobación de Cuentas

#### Resumen del Sistema

El sistema implementa un flujo de aprobación de 3 estados para las cuentas de proveedores ECOCE:

- **0 = Pendiente**: Cuenta creada pero no puede acceder
- **1 = Aprobado**: Cuenta activa con acceso completo
- **2 = Rechazado**: Cuenta denegada, se puede eliminar

#### Flujo de Registro y Aprobación

##### 1. Registro del Proveedor

1. El proveedor completa el formulario de registro (5 pasos)
2. Al finalizar, se crea:
   - Usuario en Firebase Auth
   - Perfil en Firestore con `ecoce_estatus_aprobacion: 0`
3. Se muestra dialog confirmando:
   - Folio asignado (ej: A0000001)
   - Estado: "Cuenta pendiente de aprobación"
   - Próximos pasos del proceso

##### 2. Intento de Login (Estado Pendiente)

Si un usuario pendiente intenta hacer login:

1. Se valida email/contraseña correctamente
2. Se verifica el perfil y su estado
3. Si `ecoce_estatus_aprobacion == 0`:
   - Se muestra dialog "Aprobación Pendiente"
   - Se cierra la sesión automáticamente
   - No puede acceder a las pantallas

##### 3. Panel del Maestro ECOCE

El usuario maestro accede a la pantalla de aprobaciones:

```
Ruta: ECOCE Login → Usuario: maestro → Pantalla: Aprobaciones
```

**Funcionalidades**:

1. **Vista de solicitudes pendientes**
   - Lista todos los perfiles con estado 0
   - Muestra información completa del proveedor
   - Permite ver documentos adjuntos

2. **Acciones disponibles**:
   
   **APROBAR**:
   - Actualiza `ecoce_estatus_aprobacion` a 1
   - Registra fecha, usuario aprobador y comentarios
   - El proveedor puede hacer login inmediatamente

   **RECHAZAR**:
   - Actualiza `ecoce_estatus_aprobacion` a 2
   - Solicita razón del rechazo (obligatorio)
   - Opción de eliminar la cuenta completamente

### Estructura de Base de Datos

#### Colección: `solicitudes_cuentas`
```json
{
  "id": "auto-generated-id",
  "tipo": "origen",
  "subtipo": "A" | "P",
  "email": "usuario@ejemplo.com",
  "password": "contraseña-temporal",
  "datos_perfil": {
    "ecoce_tipo_actor": "O",
    "ecoce_subtipo": "A" | "P",
    "ecoce_nombre": "Nombre Comercial",
    "ecoce_folio": "PENDIENTE",
    "ecoce_rfc": "RFC123456789",
    // ... todos los demás campos del perfil
  },
  "estado": "pendiente" | "aprobada" | "rechazada",
  "fecha_solicitud": "timestamp",
  "fecha_revision": null,
  "revisado_por": null,
  "comentarios_revision": null
}
```

#### Estructura Completa de Firebase

```
solicitudes_cuentas/           # Account requests pending approval
├── [solicitudId]
│   ├── estado: "pendiente"/"aprobada"/"rechazada"
│   ├── datos_perfil: {...}
│   └── documentos: {...}

ecoce_profiles/                # Main user profiles (index)
├── [userId]
│   ├── path: "ecoce_profiles/[type]/usuarios/[userId]"
│   ├── folio: "A0000001"
│   └── aprobado: true

ecoce_profiles/[type]/usuarios/  # Actual profile data by type
├── origen/centro_acopio/
├── origen/planta_separacion/
├── reciclador/usuarios/
├── transformador/usuarios/
├── transporte/usuarios/
└── laboratorio/usuarios/

users_pending_deletion/        # Users marked for Auth deletion
├── [userId]
│   └── status: "pending"/"completed"/"failed"
```

### Ejemplo de Registro de Usuario Origen

#### Estructura de Base de Datos

```json
{
  "ecoce_profiles": {
    "userId123": {
      "ecoce_tipo_actor": "O",        // ✅ ORIGEN (para ambos)
      "ecoce_subtipo": "A",           // ✅ A = Acopiador, P = Planta
      "ecoce_folio": "A0000001",      // ✅ Folio con prefijo del subtipo
      "ecoce_nombre": "Centro Acopio XYZ",
      "ecoce_correo_contacto": "contacto@acopio.com",
      // ... resto de datos
    }
  }
}
```

#### Folios Generados

- **Acopiador**: A0000001, A0000002, A0000003...
- **Planta de Separación**: P0000001, P0000002, P0000003...

#### Identificación de Usuarios

```dart
// ✅ Verificar si es Usuario Origen (accede a pantallas origen)
if (profile.isOrigen) {
  // Navegar a OrigenInicioScreen
}

// ✅ Identificar subtipo específico
if (profile.isAcopiador) {
  // Es un Acopiador (subtipo A)
}

if (profile.isPlantaSeparacion) {
  // Es una Planta de Separación (subtipo P)
}

// ✅ Obtener etiqueta descriptiva
print(profile.tipoActorLabel); // "Acopiador" o "Planta de Separación"
```

---

## Optimizaciones Realizadas

### ECOCE Code Refactoring Summary

#### Overview
Este documento resume la refactorización de código y consolidación realizada en el módulo ECOCE para reducir la duplicación de código y mejorar la mantenibilidad.

#### 1. Componentes Compartidos Creados

##### Navigation & UI Components
- **`shared/widgets/ecoce_bottom_navigation.dart`** - Navegación inferior unificada para todos los tipos de usuario
- **`shared/widgets/loading_indicator.dart`** - Estados de carga reutilizables (3 variantes)
- **`shared/widgets/statistic_card.dart`** - Tarjeta de visualización de estadísticas
- **`shared/widgets/common_widgets.dart`** - Contiene múltiples widgets compartidos:
  - GradientHeader
  - StandardBottomSheet
  - InfoCard
  - StatusChip
  - HapticButton
  - HapticInkWell

##### Utility Classes
- **`shared/utils/validation_utils.dart`** - Funciones de validación de formularios comunes
  - validateRequired
  - validateMinLength
  - validateWeight
  - validateInteger
  - validateEmail
  - validatePhoneNumber
  - validateRFC
  - validatePostalCode
  - validateSelection
  - validateNotFutureDate

- **`shared/utils/dialog_utils.dart`** - Patrones de diálogos comunes
  - showSuccessDialog
  - showErrorDialog
  - showConfirmDialog
  - showSignatureDialog
  - showLoadingDialog
  - showInfoDialog

- **`shared/utils/navigation_utils.dart`** - Helpers de navegación
  - navigateWithFade
  - navigateWithSlide
  - navigateWithScale
  - showCustomBottomSheet
  - handleBottomNavigation

- **`shared/utils/material_utils.dart`** - Utilidades de material y fecha
  - formatDate
  - formatDateString
  - getMaterialColor
  - getMaterialIcon

#### 2. Componentes Eliminados (Duplicados)

##### Bottom Navigation Components
- ✅ Eliminado `origen/widgets/origen_bottom_navigation.dart`
- ✅ Eliminado `reciclador/widgets/reciclador_bottom_navigation.dart`
- ✅ Eliminado `laboratorio/widgets/laboratorio_bottom_navigation.dart`

##### Replaced Components
- Todos los `OrigenFloatingActionButton` → `EcoceFloatingActionButton`
- Todos los `RecicladorFloatingActionButton` → `EcoceFloatingActionButton`
- Todos los `LaboratorioFloatingActionButton` → `EcoceFloatingActionButton`
- Todas las llamadas a `NavigationHelper` → `NavigationUtils`
- Todos los métodos locales `_formatDate` → `MaterialUtils.formatDate/formatDateString`

#### Estimación de Reducción de Código

##### Antes de la Refactorización
- 3 implementaciones separadas de navegación inferior (~450 líneas cada una)
- 3 implementaciones separadas de FAB (~100 líneas cada una)
- Múltiples implementaciones de formatDate (~15 líneas cada una × 5 archivos)
- Lógica de validación duplicada en formularios
- Implementaciones de diálogos duplicadas

##### Después de la Refactorización
- 1 navegación inferior compartida (~260 líneas)
- 1 FAB compartido (~40 líneas)
- 1 utilidad de formatDate compartida
- Utilidades de validación centralizadas
- Utilidades de diálogos centralizadas

##### Reducción de Código Estimada
- **~1,800 líneas eliminadas** (componentes de navegación duplicados)
- **~300 líneas eliminadas** (componentes FAB duplicados)
- **~75 líneas eliminadas** (métodos formatDate duplicados)
- **Total: ~2,175 líneas de código duplicado eliminadas**

### Optimizaciones Completadas Detalladas

#### Fecha: 19/07/2025

##### 1. **Funciones de Material (Color e Ícono)**
**Archivos modificados**: 14 archivos
- ✅ Eliminadas todas las implementaciones locales de `_getMaterialColor()` y `_getMaterialIcon()`
- ✅ Actualizados para usar `MaterialUtils.getMaterialColor()` y `MaterialUtils.getMaterialIcon()`
- ✅ Corregida recursión infinita en `material_utils.dart`

##### 2. **Formateo de Fechas**
**Archivos modificados**: 8 archivos
- ✅ Reemplazadas todas las implementaciones manuales de formateo de fecha
- ✅ Actualizados para usar `FormatUtils.formatDate()` y `FormatUtils.formatDateTime()`
- ✅ Eliminadas funciones locales `_formatDate()` y getters `_fechaFormateada`

##### 3. **Widgets de Lote Card**
**Consolidación completa**: 
- ✅ Eliminados 3 archivos de lote_card duplicados
- ✅ Consolidado en un único `lote_card_unified.dart`
- ✅ Actualizadas 9 pantallas para usar el widget unificado
- ✅ Implementados constructores especializados (`.reciclador()`, `.repositorio()`, `.simple()`)

##### 4. **GradientHeader Widget**
- ✅ Consolidadas 2 implementaciones en una sola
- ✅ Mejorado con parámetros personalizables (colores, responsivo, radio)
- ✅ Eliminada duplicación en `common_widgets.dart`
- ✅ Actualizado para soportar más casos de uso

### Reporte de Código Duplicado

#### Resumen Ejecutivo

Se han identificado múltiples patrones de código duplicado en el proyecto que pueden ser refactorizados para mejorar la mantenibilidad y reducir la redundancia.

#### 1. Funciones de Formateo de Fecha

##### Duplicación Encontrada
- **material_utils.dart**: `formatDate()`, `formatDateString()`, `formatDateTime()`
- **maestro_administracion_perfiles.dart**: `_formatDate()` (línea 776)
- **maestro_aprobaciones_screen.dart**: `_formatDate()` (línea 728)
- **origen_lote_detalle_screen.dart**: `_fechaFormateada` getter (línea 81)
- **reciclador_lote_qr_screen.dart**: `_fechaEntradaFormateada`, `_fechaSalidaFormateada` getters

##### Patrón Común
```dart
// Patrón repetido en múltiples archivos
'${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
```

##### Solución Propuesta
Centralizar todas las funciones de formateo de fecha en `MaterialUtils` o crear una nueva clase `DateFormatUtils`.

#### 2. Funciones de Colores de Materiales

##### Duplicación Encontrada
- **material_utils.dart**: `getMaterialColor()` (línea 4)
- **material_selector.dart**: `_getColorForMaterial()` (línea 63)
- **transporte_entregar_screen.dart**: `_getMaterialColor()` (línea 289)
- **placeholder_perfil_screen.dart**: `_getMaterialColor()` (línea 746)
- **reciclador_lotes_registro.dart**: `_getMaterialColor()` (línea 154)
- **reciclador_lote_qr_screen.dart**: `_getMaterialColor()` (línea 136)

##### Patrón Común
```dart
switch (material) {
  case 'PEBD':
    return BioWayColors.pebdPink;
  case 'PP':
    return BioWayColors.ppPurple;
  case 'Multilaminado':
    return BioWayColors.multilaminadoBrown;
  default:
    return Colors.grey;
}
```

#### Impacto Estimado

- **Reducción de líneas de código**: ~500-800 líneas
- **Mejora en mantenibilidad**: Cambios centralizados en un solo lugar
- **Reducción de bugs**: Menos probabilidad de inconsistencias
- **Facilidad de testing**: Funciones centralizadas más fáciles de probar

---

## Configuraciones Técnicas

### Google Maps Setup

#### Pasos para configurar Google Maps API

##### 1. Obtener API Keys de Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita las siguientes APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
   - Places API (opcional, para búsquedas mejoradas)
4. Crea credenciales (API Keys) para Android e iOS

##### 2. Configurar las API Keys en el proyecto

###### Android
Edita el archivo `android/app/src/main/AndroidManifest.xml` y reemplaza `YOUR_GOOGLE_MAPS_API_KEY_HERE` con tu API key de Android:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_DE_ANDROID_AQUI"/>
```

###### iOS
Edita el archivo `ios/Runner/AppDelegate.swift` y reemplaza `YOUR_GOOGLE_MAPS_API_KEY_HERE` con tu API key de iOS:

```swift
GMSServices.provideAPIKey("TU_API_KEY_DE_IOS_AQUI")
```

##### 3. Actualizar la configuración central

Edita el archivo `lib/config/google_maps_config.dart` y actualiza las API keys:

```dart
class GoogleMapsConfig {
  static const String androidApiKey = 'TU_API_KEY_DE_ANDROID_AQUI';
  static const String iosApiKey = 'TU_API_KEY_DE_IOS_AQUI';
  // ...
}
```

#### Uso del Widget de Selección de Ubicación

##### Importar el widget:

```dart
import 'package:app/widgets/common/location_picker_widget.dart';
```

##### Ejemplo de uso básico:

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

#### Características del widget LocationPickerWidget

- **Búsqueda de direcciones**: Campo de búsqueda integrado
- **Ubicación actual**: Botón para obtener la ubicación GPS actual
- **Selección por toque**: Toca el mapa para seleccionar una ubicación
- **Dirección automática**: Geocodificación inversa para obtener la dirección
- **Marcador visual**: Muestra la ubicación seleccionada
- **Confirmación**: Botón flotante para confirmar la selección

### Integración con Firebase

#### Archivos de Configuración
- Android: `android/app/google-services.json` (contiene configuraciones de ECOCE y BioWay)
- iOS: `ios/Runner/GoogleService-Info.plist` (por plataforma)

#### Reglas de Seguridad Recomendadas

Para la colección `solicitudes_cuentas`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Solicitudes de cuentas
    match /solicitudes_cuentas/{document} {
      // Cualquiera puede crear una solicitud
      allow create: if true;
      
      // Solo usuarios autenticados pueden leer
      allow read: if request.auth != null;
      
      // Solo maestros pueden actualizar
      allow update: if request.auth != null && 
        get(/databases/$(database)/documents/ecoce_profiles/$(request.auth.uid)).data.ecoce_tipo_actor == 'M';
      
      // Nadie puede eliminar
      allow delete: if false;
    }
  }
}
```

---

## Validaciones y Flujos

### Validaciones Implementadas en Registro de Usuario Origen

#### Sistema de Validaciones Completo

Las pantallas de registro ahora **validan todos los campos obligatorios** antes de permitir continuar al siguiente paso.

##### **Paso 1: Información Básica**

**Campos Obligatorios:**
- ✅ Nombre Comercial (no vacío)
- ✅ Nombre del Contacto (no vacío) 
- ✅ Teléfono Móvil (al menos 10 dígitos)

**Validaciones:**
- Formato de teléfono (mínimo 10 dígitos numéricos)
- Campos no pueden estar vacíos
- Mensaje de error específico por campo

##### **Paso 2: Ubicación**

**Campos Obligatorios:**
- ✅ Dirección/Calle
- ✅ Número Exterior  
- ✅ Código Postal
- ✅ Estado
- ✅ Municipio
- ✅ Colonia
- ✅ Referencias de ubicación
- ✅ Ubicación confirmada en mapa

##### **Paso 3: Operaciones**

**Campos Obligatorios:**
- ✅ Al menos un material seleccionado
- ✅ Dimensiones completas (solo para Acopiador/Planta):
  - Largo > 0
  - Ancho > 0  
  - Peso > 0

##### **Paso 4: Documentos Fiscales**

**Estado:** ✅ **Sin validaciones estrictas**
- Los documentos son opcionales según CLAUDE.md
- Usuario puede continuar sin subir documentos

##### **Paso 5: Credenciales**

**Campos Obligatorios:**
- ✅ Email válido (formato correcto)
- ✅ Contraseña (mínimo 6 caracteres)
- ✅ Confirmación de contraseña (coincidente)
- ✅ Términos y condiciones aceptados

#### Comportamiento de Validación

##### Bloqueo de Navegación
- El botón "Continuar" **no funciona** hasta completar todos los campos
- Mensajes de error **específicos** por campo faltante
- **Feedback inmediato** al intentar continuar

##### Mensajes de Error
```dart
// Ejemplos de mensajes mostrados:
"El nombre comercial es obligatorio"
"El teléfono debe tener al menos 10 dígitos"
"Campo requerido: Número exterior"
"Debes seleccionar al menos un tipo de material"
"Las contraseñas no coinciden"
```

### Características Clave del Sistema

#### Registro de Usuario & Flujo de Aprobación
1. Usuarios llenan formulario de registro multi-paso (5 pasos)
2. Solicitud guardada en colección `solicitudes_cuentas` (NO se crea usuario Auth todavía)
3. Usuario Maestro revisa en dashboard unificado
4. Al aprobar: Usuario Auth creado, folio asignado, perfil movido a `ecoce_profiles`
5. Al rechazar: Solicitud eliminada completamente

#### Sistema de Códigos QR
- **Scanner**: `QrScannerWidget` usando el paquete `mobile_scanner`
- **Generador**: `qr_flutter` para crear códigos QR
- **Formato**: `LOTE-[MATERIAL]-[ID]` para seguimiento de lotes

#### Gestión de Documentos
- **Subida**: `DocumentUploadWidget` con soporte multi-archivo
- **Compresión**: Imágenes comprimidas a ~100KB objetivo, PDFs validados (5MB máx)
- **Almacenamiento**: Firebase Storage organizado por solicitud/ID de usuario
- **Tipos Soportados**: PDF, imágenes (JPG, PNG)

#### Servicios de Ubicación
- **No GPS Requerido**: Usa geocodificación sin permisos de ubicación del dispositivo
- **Diálogo de Mapa**: `MapSelectorDialog` con pin central fijo
- **Búsqueda de Direcciones**: `SimpleMapWidget` para selección de ubicación basada en dirección

#### Seguimiento de Materiales
Los materiales son específicos por rol:
- **Origen**: Tipos EPF (Poli, PP, Multi)
- **Reciclador**: Estados de procesamiento (separados, pacas, sacos)
- **Transformador**: Pellets y escamas
- **Laboratorio**: Tipos de muestras

#### Eliminación de Usuarios (Maestro)
- Eliminación completa de `ecoce_profiles` y `solicitudes_cuentas`
- Archivos de almacenamiento eliminados
- Marcado para eliminación Auth en colección `users_pending_deletion`
- Requiere Cloud Function para eliminación real de Auth

---

## Guías de Desarrollo

### Navegación & Routing

#### Patrón de Rutas Nombradas
Todas las rutas están definidas en `main.dart` siguiendo el patrón: `/[rol]_[pantalla]`

Ejemplos de flujos:
- ECOCE Origen: `/origen_inicio` → `/origen_lotes` → `/origen_crear_lote`
- Transporte: `/transporte_inicio` → `/transporte_recoger` → `/transporte_entregar`

#### Utilidades de Navegación
- `NavigationUtils.navigateWithFade()`: Transiciones de fade consistentes
- `Navigator.pushReplacementNamed()`: Para flujos de login
- `PopScope`: Para manejo del comportamiento del botón atrás

### Gestión de Estado

#### Enfoque Actual
- StatefulWidget puro + setState()
- Sin librerías externas de gestión de estado
- Estado pasado vía parámetros del constructor
- Validación de formularios en el estado del widget

#### Flujo de Datos
1. Widgets padre pasan callbacks a hijos
2. Hijos llaman callbacks con datos
3. Padre actualiza estado y reconstruye
4. Estado compartido almacenado en widgets de nivel de ruta

### Integración con Google Maps

#### Configuración de API
- API Key: Almacenada en clase `GoogleMapsConfig`
- APIs Requeridas: Maps SDK, Geocoding API
- No se requieren permisos de ubicación

#### Componentes de Mapa
- `MapSelectorDialog`: Mapa de pantalla completa con viewport arrastrable
- `SimpleMapWidget`: Flujo de búsqueda de direcciones y confirmación
- Formato de coordenadas: Precisión de 6 decimales

### Directrices de Desarrollo

#### Gestión de Colores
- Siempre usar constantes `BioWayColors`
- Nunca hardcodear colores
- Colores específicos de plataforma: `ecoceGreen`, `primaryGreen`

#### Diseño Responsivo
```dart
// Usar porcentajes de MediaQuery
final screenWidth = MediaQuery.of(context).size.width;
padding: EdgeInsets.all(screenWidth * 0.04),
fontSize: screenWidth * 0.045,

// Breakpoints
isTablet: screenWidth > 600
isCompact: screenHeight < 700
```

#### Manejo de Imágenes
- Auto-compresión a 50KB para almacenamiento
- Usar `ImageService.optimizeImageForDatabase()`
- Soportar fuentes de cámara y galería

#### Validación de Formularios
- Validar a nivel de campo con TextEditingController
- Mostrar mensajes de error inline
- Deshabilitar envío hasta que sea válido

### Tareas Comunes

#### Agregar un Nuevo Tipo de Proveedor ECOCE
1. Crear pantalla de registro en `lib/screens/login/ecoce/providers/`
2. Extender `BaseProviderRegisterScreen`
3. Sobrescribir propiedades requeridas (tipo, título, ícono, etc.)
4. Agregar a `ECOCETipoProveedorSelector._providerTypes`
5. Actualizar `_getTipoUsuario()` y `_getSubtipo()` en clase base
6. Agregar materiales en `_getMaterialesBySubtipo()`

#### Implementar una Nueva Pantalla
1. Crear en carpeta de característica apropiada
2. Seguir convención de nomenclatura: `[Feature][Action]Screen`
3. Usar widgets compartidos de `ecoce/shared/widgets/`
4. Agregar ruta nombrada en `main.dart`
5. Actualizar navegación en pantalla padre

### Solución de Problemas

#### Problemas de Firebase
- "Default app already exists": Verificar inicialización duplicada
- "No Firebase app": Asegurar inicialización de plataforma antes del uso
- Errores de Auth: Verificar configuración del proyecto Firebase

#### Problemas de Construcción
- Construcción limpia: `flutter clean && flutter pub get`
- iOS pods: `cd ios && pod install`
- Android gradle: `cd android && ./gradlew clean`

#### Problemas de Mapa
- Verificar API key en `google_maps_config.dart`
- Verificar habilitación de API en Google Cloud Console
- Asegurar conectividad a internet para geocodificación

---

## Documentos de Referencia

### Guía de Prueba - Registro de Usuario Origen (ECOCE)

#### Configuración Previa

1. Asegúrate de tener la app corriendo con `flutter run`
2. En la pantalla inicial, selecciona **ECOCE**
3. En la pantalla de login de ECOCE, toca **"Crear cuenta ECOCE"**

#### Registro de Centro de Acopio

##### Paso 1: Selección de Tipo
- Selecciona **"Centro de Acopio"** (icono de almacén)

##### Paso 2: Información Básica
- **Nombre comercial**: Acopio San Miguel
- **RFC** (opcional): ASM240118ABC
- **Nombre de contacto**: Juan Pérez García
- **Teléfono**: 5551234567
- **Teléfono oficina**: 5557654321

##### Paso 3: Ubicación
- **Dirección**: Av. Insurgentes Sur 123
- **Núm. Ext**: 456
- **Código Postal**: 03810
- **Estado**: Ciudad de México
- **Municipio**: Benito Juárez
- **Colonia**: Del Valle
- **Referencias**: Entre Calle A y Calle B
- Toca **"Buscar ubicación en el mapa"** para establecer coordenadas

##### Paso 4: Operaciones
- **Materiales**: Selecciona todos (EPF - Poli, EPF - PP, EPF - Multi)
- **Transporte propio**: Activar
- **Capacidad de prensado**:
  - Largo: 10
  - Ancho: 8
  - Peso máximo: 500
- **Link red social** (opcional): https://facebook.com/acopiosanmiguel

##### Paso 5: Datos Fiscales
- Selecciona al menos 2 documentos (se simularán)

##### Paso 6: Crear Cuenta
- **Email**: acopio1@test.com
- **Contraseña**: Test123456
- **Confirmar contraseña**: Test123456
- Acepta términos y condiciones
- Toca **"Crear cuenta"**

**Resultado esperado**: 
- Folio generado: **A0000001** (primer centro de acopio)
- Mensaje de cuenta pendiente de aprobación

#### Casos de Prueba

##### 1. Registro y Estado Pendiente
1. Registrar nuevo centro de acopio
2. Intentar login con las credenciales
3. Verificar dialog "Aprobación Pendiente"
4. Verificar que no puede acceder

##### 2. Aprobación por Maestro
1. Login como maestro
2. Ver lista de pendientes
3. Aprobar una cuenta
4. Verificar que el usuario ahora puede acceder

##### 3. Rechazo y Eliminación
1. Login como maestro
2. Rechazar una cuenta con razón
3. Verificar que el usuario ve mensaje de rechazo
4. Opcionalmente eliminar la cuenta

#### Credenciales de Prueba

##### Usuario Maestro (Aprobador)
- Usuario: maestro
- Contraseña: master123
- Acceso: Panel de aprobaciones

##### Proveedores de Prueba
- Centro Acopio: acopio1@test.com / Test123456
- Planta: planta1@test.com / Test123456

### Optimización del Usuario Maestro

#### RESUMEN EJECUTIVO

El análisis de los 5 archivos del usuario maestro reveló **duplicación significativa de código** que puede reducirse en aproximadamente **40-50%** mediante la creación de componentes reutilizables.

#### DUPLICACIONES ENCONTRADAS

##### 1. **Funciones Duplicadas**

###### `_formatDate()` - Duplicada en 2 archivos
```dart
// maestro_aprobaciones_screen.dart
String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

// maestro_administracion_perfiles.dart - Versión mejorada con padding
String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
```
**Solución**: Usar `FormatUtils.formatDate()` ya creado

###### `_buildPaginationButtons()` - Duplicada idénticamente
- En: `maestro_aprobacion.dart` y `maestro_administracion_perfiles.dart`
- Líneas duplicadas: ~50 líneas cada una
**Solución**: Crear widget `MaestroPaginationWidget`

#### COMPONENTES REUTILIZABLES PROPUESTOS

##### 1. **BaseMaestroScreen**
```dart
class BaseMaestroScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
}
```

##### 2. **MaestroPaginationWidget**
```dart
class MaestroPaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
}
```

#### ESTIMACIÓN DE IMPACTO

##### Líneas de Código Actuales
- `maestro_administracion_datos.dart`: ~540 líneas
- `maestro_administracion_perfiles.dart`: ~830 líneas
- `maestro_aprobacion.dart`: ~760 líneas
- `maestro_aprobacion_datos.dart`: ~520 líneas
- `maestro_aprobaciones_screen.dart`: ~950 líneas
- **TOTAL**: ~3,600 líneas

##### Después de la Optimización
- Reducción estimada: **1,500-1,800 líneas** (40-50%)
- **TOTAL ESTIMADO**: ~1,800-2,100 líneas

### Claude.md - Guía para Asistente de Código

#### Descripción del Proyecto

BioWay México es una aplicación Flutter para reciclaje y gestión de residuos con soporte dual de plataforma (BioWay y ECOCE). La app implementa un sistema completo de seguimiento de cadena de suministro para materiales reciclables con acceso basado en roles y arquitectura Firebase multi-tenant.

#### Cuando NO usar la herramienta de análisis
**PREDETERMINADO: La mayoría de las tareas no necesitan la herramienta de análisis.**
- Los usuarios a menudo quieren que Claude escriba código que puedan ejecutar y reutilizar ellos mismos. Para estas solicitudes, la herramienta de análisis no es necesaria; solo proporciona código.
- La herramienta de análisis es SOLO para JavaScript, así que nunca la uses para solicitudes de código en otros lenguajes que no sean JavaScript.
- La herramienta de análisis agrega latencia significativa, así que úsala solo cuando la tarea requiera específicamente ejecución de código en tiempo real.

#### Restricción CRÍTICA de Almacenamiento del Navegador
**NUNCA uses localStorage, sessionStorage, o CUALQUIER API de almacenamiento del navegador en artefactos.** Estas APIs NO están soportadas y causarán que los artefactos fallen en el entorno Claude.ai.

En su lugar, DEBES:
- Usar estado de React (useState, useReducer) para componentes React
- Usar variables u objetos JavaScript para artefactos HTML
- Almacenar todos los datos en memoria durante la sesión

#### Leyendo archivos en la herramienta de análisis
- Al leer un archivo en la herramienta de análisis, puedes usar la API `window.fs.readFile`. Este es un entorno de navegador, así que no puedes leer un archivo sincrónicamente. Por lo tanto, en lugar de usar `window.fs.readFileSync`, usa `await window.fs.readFile`.
- Parsea CSVs con Papaparse usando {dynamicTyping: true, skipEmptyLines: true, delimitersToGuess: [',', '\t', '|', ';']}; siempre elimina espacios en blanco de los headers; usa lodash para operaciones como groupBy en lugar de escribir funciones personalizadas; maneja valores undefined potenciales en columnas.

### Notas Importantes para Producción

1. **Seguridad**: En producción, considera:
   - Encriptar las contraseñas en `solicitudes_cuentas`
   - Implementar notificaciones por email
   - Agregar validación adicional de documentos
   - Implementar límite de solicitudes por IP/email

2. **Costos**: Google Maps tiene un modelo de precios por uso. Configura alertas de facturación en Google Cloud Console.

3. **Límites**: Las API tienen límites de solicitudes. Para producción, considera implementar caché de geocodificación.

4. **Seguridad de API Keys**: Nunca subas las API Keys al repositorio. Considera usar variables de entorno o archivos de configuración excluidos del control de versiones.

5. **Gestión de Usuarios**: Los usuarios eliminados todavía mostrándose requiere función Cloud para eliminación real de Auth (ver `docs/CLOUD_FUNCTION_DELETE_USERS.md`)

---

## Conclusión

Este documento proporciona una visión completa del proyecto BioWay México, incluyendo su arquitectura multi-tenant, sistemas de gestión de usuarios, optimizaciones de código realizadas, y guías de desarrollo. Para el desarrollador en turno, esta documentación debe servir como referencia completa para entender el contexto del proyecto y continuar el desarrollo de manera eficiente.

El proyecto está estructurado para máxima reutilización de código, separación clara de responsabilidades, y mantenibilidad a largo plazo. Las optimizaciones realizadas han reducido significativamente la duplicación de código y mejorado la consistencia en toda la aplicación.