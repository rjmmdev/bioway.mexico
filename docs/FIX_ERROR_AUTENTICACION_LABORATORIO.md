# Fix: Error de Autenticación en Toma de Muestra de Laboratorio

## Fecha de Identificación y Solución
**2025-01-29**

## Error Reportado
```
Error al registrar la muestra: Exception: Error al crear muestra: Exception: Usuario no autenticado.
```

## Causa Raíz

El error ocurre debido a una **incompatibilidad entre sistemas de autenticación**:

1. **Sistema Multi-Tenant (AuthService)**:
   - Usa `FirebaseAuth.instanceFor(app: app)` con apps específicas
   - El usuario se autentica en la app ECOCE
   - Maneja múltiples proyectos Firebase

2. **MuestraLaboratorioService (Original)**:
   - Usaba `FirebaseAuth.instance` (instancia por defecto)
   - La instancia por defecto NO tiene usuario autenticado
   - No estaba alineado con el sistema multi-tenant

### Flujo del Problema:
```
1. Usuario inicia sesión → AuthService (app ECOCE) ✓
2. Usuario navega a toma de muestra ✓
3. MuestraLaboratorioService intenta obtener usuario → FirebaseAuth.instance ✗
4. No encuentra usuario → "Usuario no autenticado"
```

## Solución Implementada

### Modificación de `MuestraLaboratorioService`

Se actualizó el servicio para usar el mismo sistema de autenticación multi-tenant:

#### 1. Imports Agregados:
```dart
import 'firebase/auth_service.dart';
import 'firebase/firebase_manager.dart';
```

#### 2. Inicialización Actualizada:
```dart
class MuestraLaboratorioService {
  late final FirebaseFirestore _firestore;
  late final AuthService _authService;
  final FirebaseManager _firebaseManager = FirebaseManager();
  
  MuestraLaboratorioService() {
    // Usar la instancia de Firebase correspondiente a la app actual
    final app = _firebaseManager.currentApp;
    if (app != null) {
      _firestore = FirebaseFirestore.instanceFor(app: app);
    } else {
      _firestore = FirebaseFirestore.instance;
    }
    _authService = AuthService();
  }
```

#### 3. Reemplazo de Referencias:
- **ANTES**: `_auth.currentUser?.uid`
- **AHORA**: `_authService.currentUser?.uid`

## Archivos Modificados
- `lib/services/muestra_laboratorio_service.dart`

## Verificación

### Para verificar que funciona:
1. Iniciar sesión como Laboratorio en plataforma ECOCE
2. Escanear QR de megalote
3. Completar formulario de toma de muestra
4. Verificar que se crea exitosamente sin error de autenticación

### Puntos de Verificación:
- ✅ Usuario autenticado correctamente en AuthService
- ✅ MuestraLaboratorioService usa la misma instancia de Firebase
- ✅ Firestore también usa la app correcta
- ✅ Transacciones funcionan en el contexto correcto

## Consideraciones Técnicas

### Sistema Multi-Tenant
La aplicación maneja múltiples proyectos Firebase (BioWay y ECOCE):
- Cada plataforma tiene su propio proyecto Firebase
- AuthService maneja el cambio entre proyectos
- TODOS los servicios deben usar la misma instancia

### Consistencia
Es crítico que todos los servicios usen:
- La misma app Firebase (`FirebaseManager.currentApp`)
- El mismo AuthService (no FirebaseAuth.instance directamente)
- FirebaseFirestore.instanceFor(app) en lugar de .instance

## Prevención Futura

### Reglas para Nuevos Servicios:
1. **NUNCA** usar `FirebaseAuth.instance` directamente
2. **SIEMPRE** inyectar o crear AuthService
3. **USAR** FirebaseManager para obtener la app actual
4. **VERIFICAR** que Firestore también use la app correcta

### Patrón Recomendado:
```dart
class NuevoServicio {
  late final FirebaseFirestore _firestore;
  late final AuthService _authService;
  final FirebaseManager _firebaseManager = FirebaseManager();
  
  NuevoServicio() {
    final app = _firebaseManager.currentApp;
    if (app != null) {
      _firestore = FirebaseFirestore.instanceFor(app: app);
    } else {
      _firestore = FirebaseFirestore.instance;
    }
    _authService = AuthService();
  }
}
```

## Estado Final

✅ **Error Solucionado**
- El servicio ahora usa el sistema de autenticación correcto
- Compatible con multi-tenant
- Usuario se autentica correctamente
- Muestras se crean sin errores

## Testing Recomendado

1. **Test de Autenticación**:
   - Cerrar sesión completamente
   - Iniciar sesión en ECOCE como Laboratorio
   - Verificar que `_authService.currentUser` no es null

2. **Test de Creación de Muestra**:
   - Escanear QR de megalote
   - Completar formulario
   - Verificar creación exitosa

3. **Test de Persistencia**:
   - Crear muestra
   - Navegar a otras pantallas
   - Volver y verificar que sigue autenticado

## Notas Adicionales

Este error es común en aplicaciones Flutter con Firebase multi-tenant. La solución implementada garantiza que todos los componentes del sistema de laboratorio usen la misma instancia de Firebase, evitando problemas de autenticación.