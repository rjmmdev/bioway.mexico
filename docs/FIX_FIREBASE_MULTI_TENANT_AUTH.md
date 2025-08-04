# Fix: Firebase Multi-Tenant Authentication en Transformador

## Problema Identificado
El usuario aparecía como no autenticado porque el código estaba usando `FirebaseAuth.instance` (instancia por defecto) en lugar de la instancia multi-tenant de ECOCE.

```
Error: Usuario no autenticado. Por favor cierre sesión y vuelva a iniciar.
```

## Causa Raíz
El sistema usa Firebase multi-tenant con apps nombradas:
- ECOCE usa: `FirebaseAuth.instanceFor(app: ecoceApp)`
- El código incorrecto usaba: `FirebaseAuth.instance` (app por defecto)

Cuando el usuario se autentica en ECOCE, lo hace en la app nombrada "ecoce", NO en la app por defecto. Por eso `FirebaseAuth.instance.currentUser` retornaba `null`.

## Arquitectura Multi-Tenant

```
Firebase Manager
├── App "ecoce" → FirebaseAuth para ECOCE
├── App "bioway" → FirebaseAuth para BioWay (futuro)
└── App default → NO SE USA (siempre null)
```

## Solución Aplicada

### 1. Importar AuthService (línea 15)
```dart
import '../../../services/firebase/auth_service.dart';
```

### 2. Agregar AuthService a los servicios (línea 60)
```dart
final AuthService _authService = AuthService();
```

### 3. Cambiar todas las referencias de FirebaseAuth

#### ANTES (Incorrecto) ❌
```dart
final firebaseAuth = FirebaseAuth.instance;
final currentUser = firebaseAuth.currentUser; // Siempre null
```

#### DESPUÉS (Correcto) ✅
```dart
final currentUser = _authService.currentUser; // Usuario de la app ECOCE
```

### 4. Actualizar ambos métodos
- `_procesarSalida()` (líneas 493-500)
- `_prepareTransformacionData()` (líneas 332-339)

## Por Qué el Reciclador Funcionaba

El Reciclador usa `TransformacionService` que internamente ya usa:
```dart
// TransformacionService línea 52
var userData = _userSession.getUserData();
```

Y `getUserData()` obtiene los datos del usuario ya autenticado en la sesión, no directamente de Firebase Auth.

## Diferencias Clave

| Aspecto | Incorrecto | Correcto |
|---------|------------|----------|
| **Import** | Solo `firebase_auth` | También `auth_service` |
| **Obtención** | `FirebaseAuth.instance` | `_authService.currentUser` |
| **Resultado** | `null` (app default) | Usuario real (app ecoce) |

## Verificación en Logs

Ahora verás:
```
=== USUARIO FIREBASE AUTH (Multi-tenant) ===
Firebase Auth UID: [uid_real_del_usuario]
Usuario Folio: T0000001
```

## Estado
✅ **IMPLEMENTADO** - 2025-01-29

## Lecciones Aprendidas

1. **NUNCA usar `FirebaseAuth.instance` directamente** en un sistema multi-tenant
2. **SIEMPRE usar el `AuthService`** que maneja las instancias correctas
3. El sistema multi-tenant requiere usar `FirebaseAuth.instanceFor(app: app)`
4. Cada plataforma (ECOCE, BioWay) tiene su propia instancia de Firebase Auth

## Testing
El sistema ahora:
1. Obtiene el usuario correcto de la app ECOCE
2. El UID coincide con las reglas de Firestore
3. Puede crear megalotes sin errores de autenticación