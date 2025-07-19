# 🔧 Configuración Firebase para Registro ECOCE

## ❌ Error Actual
```
[firebase_auth/operation-not-allowed] This operation is not allowed. 
This may be because the given sign-in provider is disabled for this Firebase project.
```

## ✅ Solución: Habilitar Email/Password Authentication

### **Paso 1: Ir a Firebase Console**
1. Abrir: https://console.firebase.google.com
2. Seleccionar proyecto: **"trazabilidad-ecoce"**

### **Paso 2: Configurar Authentication**
1. Ir a **Authentication** (menú lateral)
2. Ir a **Sign-in method** (segunda pestaña)
3. Buscar **"Email/Password"** en la lista de proveedores
4. Hacer clic en **"Email/Password"**
5. **Habilitar** el primer toggle (✅ Enable)
6. **Guardar** cambios

### **Paso 3: Configuración Completa**
```
Proveedor: Email/Password
Estado: ✅ Habilitado
Email verification: ❌ No requerida (opcional)
```

### **Paso 4: Verificar configuración**
- Proyecto ID: `trazabilidad-ecoce`
- Package name: `com.biowaymexico.app`
- API Key: `AIzaSyDgKMZL6trJuXIt-gkKTn5RDzfrg_1aEyU`

## 🚨 **Errores Adicionales (Opcionales de resolver)**

### **App Check Warning**
```
W/LocalRequestInterceptor: Error getting App Check token
```
**Solución:** Configurar App Check en Firebase Console (opcional para desarrollo)

### **reCAPTCHA Warning**  
```
I/FirebaseAuth: Creating user with empty reCAPTCHA token
```
**Solución:** Se resuelve habilitando Email/Password authentication

## ✅ **Después de la Configuración**

Una vez habilitado Email/Password en Firebase Console:
1. **Reiniciar la app** en el dispositivo
2. **Probar el registro** nuevamente
3. **Verificar** que se cree el usuario en Firebase Auth
4. **Confirmar** que se guarde el perfil en Firestore

## 📱 **Flujo Esperado Post-Configuración**

1. Usuario completa registro → ✅
2. Firebase crea cuenta de autenticación → ✅  
3. Se genera folio único (A0000001/P0000001) → ✅
4. Se guarda perfil en `ecoce_profiles` → ✅
5. Aparece diálogo de éxito → ✅

¡El registro funcionará correctamente después de habilitar Email/Password en Firebase Console!