# Desplegar Reglas de Firestore

## Actualización Requerida

Se ha actualizado el archivo `firestore.rules` para permitir la eliminación de documentos en la colección `entregas_transporte`.

### Cambio realizado:
```
// Antes:
allow delete: if false;

// Ahora:
allow delete: if isAuthenticated(); // Permitir eliminar entregas completadas
```

## Pasos para desplegar las reglas

### Opción 1: Usando Firebase CLI

1. Asegúrate de tener Firebase CLI instalado:
   ```bash
   npm install -g firebase-tools
   ```

2. Inicia sesión en Firebase:
   ```bash
   firebase login
   ```

3. Desde la raíz del proyecto, despliega las reglas:
   ```bash
   firebase deploy --only firestore:rules
   ```

### Opción 2: Desde la Consola de Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona el proyecto `trazabilidad-ecoce`
3. Ve a Firestore Database → Rules
4. Copia el contenido del archivo `firestore.rules`
5. Pega en el editor de reglas
6. Haz clic en "Publish"

## Verificación

Después de desplegar las reglas, verifica que:
1. Los usuarios autenticados pueden crear entregas
2. Los usuarios autenticados pueden actualizar entregas
3. Los usuarios autenticados pueden eliminar entregas completadas
4. La aplicación no muestra más el error de permisos al completar entregas

## Nota de Seguridad

Esta regla permite que cualquier usuario autenticado elimine entregas. En producción, considera agregar validaciones adicionales como:
- Verificar que el usuario sea el transportista o el receptor de la entrega
- Verificar que la entrega esté en estado "completada"
- Agregar un campo de auditoría en lugar de eliminar físicamente