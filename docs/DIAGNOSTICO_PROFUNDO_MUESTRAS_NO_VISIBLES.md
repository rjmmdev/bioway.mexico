# Diagnóstico Profundo: Muestras Existen en Firestore pero NO se Muestran en la App

## Fecha: 2025-01-29

## CONFIRMACIÓN DEL PROBLEMA
- ✅ Las muestras SE CREAN correctamente en Firestore
- ✅ Son visibles en Firebase Console
- ❌ NO aparecen en la aplicación
- ❌ Error persistente: "permission-denied" al intentar leerlas

---

## 1. ANÁLISIS DE CAUSAS PROBABLES

### 🔴 CAUSA #1: Multi-Tenant Firebase (MÁS PROBABLE)

#### El Problema
La aplicación usa **múltiples proyectos de Firebase** (BioWay y ECOCE). El servicio `MuestraLaboratorioService` podría estar:
1. Escribiendo en una instancia de Firebase (ECOCE)
2. Intentando leer de otra instancia (default o incorrecta)

#### Evidencia en el Código
```dart
// muestra_laboratorio_service.dart - línea 14-23
MuestraLaboratorioService() {
  final app = _firebaseManager.currentApp;
  if (app != null) {
    _firestore = FirebaseFirestore.instanceFor(app: app);
  } else {
    _firestore = FirebaseFirestore.instance;  // ← PODRÍA SER INSTANCIA INCORRECTA
  }
}
```

```dart
// laboratorio_gestion_muestras.dart - línea 42
final FirebaseFirestore _firestore = FirebaseFirestore.instance; // ← INSTANCIA DEFAULT
```

#### Diagnóstico
**Las muestras se crean con `FirebaseFirestore.instanceFor(app: app)` pero se intentan leer con `FirebaseFirestore.instance`**

Si estas son instancias diferentes:
- Crear → Proyecto ECOCE ✅
- Leer → Proyecto default (¿BioWay?) ❌

---

### 🟡 CAUSA #2: Desincronización de Usuario/Autenticación

#### El Problema
El `laboratorio_id` guardado podría no coincidir con el UID actual del usuario.

#### Posibles Escenarios
1. El UID cambia entre sesiones
2. Se usa un UID diferente para crear vs leer
3. El campo se guarda con formato incorrecto

#### Verificación Necesaria
- Comparar el `laboratorio_id` en Firestore con el UID del usuario actual
- Verificar que `_authService.currentUser?.uid` devuelve el valor esperado

---

### 🟠 CAUSA #3: Problema con el Índice Compuesto

#### El Problema
Aunque el índice esté "Habilitado", podría estar mal configurado.

#### Posibles Errores de Configuración
1. **Nombre del campo incorrecto**:
   - Índice creado para: `laboratorioId` o `laboratorio_Id`
   - Campo real: `laboratorio_id` (con guión bajo)

2. **Tipo de índice incorrecto**:
   - Collection vs Collection Group
   - Orden de campos invertido

3. **Proyecto incorrecto**:
   - Índice creado en proyecto BioWay
   - Datos en proyecto ECOCE

---

### 🔵 CAUSA #4: Caché Local de Firestore

#### El Problema
Firestore mantiene caché local que podría estar corrupto o desactualizado.

#### Síntomas
- Los datos nuevos no aparecen
- Errores persisten después de corregir reglas
- Comportamiento inconsistente

---

## 2. SOLUCIONES ESPECÍFICAS POR CAUSA

### SOLUCIÓN PARA CAUSA #1: Multi-Tenant Firebase

#### Diagnóstico Rápido
```dart
// Agregar logs para verificar instancias
print('CREAR - Firebase App: ${_firebaseManager.currentApp?.name}');
print('CREAR - Project ID: ${_firebaseManager.currentApp?.options.projectId}');

// En laboratorio_gestion_muestras.dart
print('LEER - Project ID: ${FirebaseFirestore.instance.app.options.projectId}');
```

#### Solución A: Usar la Misma Instancia
```dart
// En laboratorio_gestion_muestras.dart
class _LaboratorioGestionMuestrasState {
  late final FirebaseFirestore _firestore;
  
  @override
  void initState() {
    super.initState();
    // Usar la MISMA lógica que MuestraLaboratorioService
    final app = FirebaseManager().currentApp;
    _firestore = app != null 
        ? FirebaseFirestore.instanceFor(app: app)
        : FirebaseFirestore.instance;
  }
}
```

#### Solución B: Centralizar en el Servicio
```dart
// NO usar _firestore directamente, usar el servicio
await _muestraService.obtenerMuestrasDirectamente(userId);
```

---

### SOLUCIÓN PARA CAUSA #2: Verificación de Usuario

#### Diagnóstico
```dart
// Agregar en _loadMuestras()
final userId = _authService.currentUser?.uid;
print('Usuario intentando leer: $userId');

// Verificar en Firebase Console que laboratorio_id == este userId
```

#### Solución
```dart
// Verificar múltiples fuentes de usuario
final authUserId = _authService.currentUser?.uid;
final sessionUserId = _userSession.getUserData()?['uid'];
final firebaseAuthUserId = FirebaseAuth.instance.currentUser?.uid;

print('AuthService UID: $authUserId');
print('UserSession UID: $sessionUserId');
print('Firebase Direct UID: $firebaseAuthUserId');

// Usar el correcto consistentemente
```

---

### SOLUCIÓN PARA CAUSA #3: Bypass del Índice

#### Solución Temporal A: Sin orderBy
```dart
// Eliminar orderBy completamente
final muestrasSnapshot = await _firestore
    .collection('muestras_laboratorio')
    .where('laboratorio_id', isEqualTo: userId)
    .get();

// Ordenar manualmente después
```

#### Solución Temporal B: Sin where
```dart
// Obtener todas y filtrar en memoria (como Reciclador)
final muestrasSnapshot = await _firestore
    .collection('muestras_laboratorio')
    .get();

final misMuestras = muestrasSnapshot.docs
    .where((doc) => doc.data()['laboratorio_id'] == userId)
    .toList();
```

#### Solución Temporal C: Consulta por ID directo
```dart
// Si conoces los IDs de las muestras
final muestraDoc = await _firestore
    .collection('muestras_laboratorio')
    .doc(muestraId)
    .get();
```

---

### SOLUCIÓN PARA CAUSA #4: Limpiar Caché

#### En el Código
```dart
// Forzar lectura desde servidor
final muestrasSnapshot = await _firestore
    .collection('muestras_laboratorio')
    .where('laboratorio_id', isEqualTo: userId)
    .get(const GetOptions(source: Source.server)); // ← FORZAR SERVIDOR
```

#### En el Dispositivo
1. Cerrar completamente la app
2. Limpiar datos de la app en configuración
3. Reiniciar dispositivo
4. Volver a iniciar sesión

---

## 3. MATRIZ DE DIAGNÓSTICO

| Prueba | Qué Verificar | Resultado Esperado | Indica |
|--------|---------------|-------------------|---------|
| Log Firebase App | `print(app?.options.projectId)` al crear y leer | Mismo proyecto | Multi-tenant |
| Log Usuario | `print(userId)` al crear y leer | Mismo UID | Auth problem |
| Consulta sin orderBy | `.where()` sin `.orderBy()` | Funciona | Índice problema |
| Consulta sin where | Solo `.get()` | Ve todas las muestras | Reglas problema |
| GetOptions.server | Forzar servidor | Funciona | Caché problema |
| Firebase Console | Ver laboratorio_id en docs | Coincide con UID | Data problema |

---

## 4. SOLUCIÓN DEFINITIVA RECOMENDADA

### IMPLEMENTACIÓN INMEDIATA (Hacer funcionar HOY)

```dart
// En laboratorio_gestion_muestras.dart
void _loadMuestras() async {
  try {
    // 1. Asegurar misma instancia Firebase
    final app = FirebaseManager().currentApp;
    final firestore = app != null 
        ? FirebaseFirestore.instanceFor(app: app)
        : FirebaseFirestore.instance;
    
    // 2. Verificar usuario
    final userId = _authService.currentUser?.uid;
    print('[DEBUG] Loading muestras for user: $userId');
    print('[DEBUG] Firebase project: ${app?.options.projectId}');
    
    // 3. Consulta SIN orderBy (temporal)
    final muestrasSnapshot = await firestore
        .collection('muestras_laboratorio')
        .where('laboratorio_id', isEqualTo: userId)
        .get(const GetOptions(source: Source.server)); // Forzar servidor
    
    print('[DEBUG] Muestras encontradas: ${muestrasSnapshot.docs.length}');
    
    // 4. Ordenar manualmente
    final docs = muestrasSnapshot.docs;
    docs.sort((a, b) {
      final fechaA = (a.data()['fecha_toma'] as Timestamp).toDate();
      final fechaB = (b.data()['fecha_toma'] as Timestamp).toDate();
      return fechaB.compareTo(fechaA);
    });
    
    // Procesar...
  } catch (e) {
    print('[ERROR] Detalles completos: $e');
  }
}
```

---

## 5. CHECKLIST DE VERIFICACIÓN

### Verificar en Firebase Console:
- [ ] ¿En qué proyecto están las muestras? (trazabilidad-ecoce)
- [ ] ¿El campo se llama exactamente `laboratorio_id`?
- [ ] ¿El valor de `laboratorio_id` coincide con el UID del usuario?
- [ ] ¿El índice está en el proyecto correcto?
- [ ] ¿El índice tiene los campos correctos?

### Verificar en la App:
- [ ] ¿Se está usando la misma instancia de Firebase para crear y leer?
- [ ] ¿El UID es consistente entre crear y leer?
- [ ] ¿Las reglas están publicadas en el proyecto correcto?
- [ ] ¿El índice está habilitado en el proyecto correcto?

---

## 6. CONCLUSIÓN

El problema **NO es de permisos reales**, sino muy probablemente de:
1. **Instancias diferentes de Firebase** (90% probabilidad)
2. **Índice mal configurado** (5% probabilidad)
3. **Caché corrupto** (5% probabilidad)

### La Razón Principal
Como las muestras SE CREAN pero NO SE LEEN, y la app es multi-tenant, es casi seguro que:
- **Escribes en**: Proyecto ECOCE (con FirebaseFirestore.instanceFor)
- **Lees de**: Proyecto default/incorrecto (con FirebaseFirestore.instance)

### Acción Inmediata
1. Verificar qué proyecto se usa al crear vs leer
2. Asegurar que ambos usen la misma instancia
3. Si eso no funciona, usar consulta sin orderBy temporalmente