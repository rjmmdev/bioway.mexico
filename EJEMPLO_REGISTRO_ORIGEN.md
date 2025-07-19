# 📋 Ejemplo de Registro de Usuario Origen

## ✅ Sistema Implementado

### **Estructura de Base de Datos**

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

### **Folios Generados**

- **Acopiador**: A0000001, A0000002, A0000003...
- **Planta de Separación**: P0000001, P0000002, P0000003...

### **Identificación de Usuarios**

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

## 🎯 Flujo de Registro

### **1. Selección de Tipo**
Usuario selecciona:
- **Acopiador** → subtipo = 'A'
- **Planta de Separación** → subtipo = 'P'

### **2. Registro Completo (5 pasos)**
- ✅ Información básica
- ✅ Ubicación con mapa
- ✅ Materiales EPF (Poli, PP, Multi)
- ✅ Documentos fiscales
- ✅ Credenciales

### **3. Guardado en Firebase**
```dart
await _profileService.createOrigenProfile(
  subtipo: 'A', // o 'P'
  // ... resto de datos
);
```

### **4. Resultado**
- ✅ `ecoce_tipo_actor` = 'O' (Usuario Origen)
- ✅ `ecoce_subtipo` = 'A' o 'P' 
- ✅ `ecoce_folio` = A0000001 o P0000001
- ✅ Acceso a pantallas de origen
- ✅ Distinción por subtipo cuando sea necesario

## 🔍 Verificación

El usuario queda registrado como **Usuario Origen** y puede:
1. **Acceder** a todas las pantallas de origen
2. **Ser identificado** como Acopiador o Planta según su subtipo
3. **Mantener** su folio específico (A o P)
4. **Compartir** la misma funcionalidad base de origen

✅ **Sistema completamente funcional y listo para uso**