# Configuración Manual del Usuario Maestro

Como Firebase CLI no tiene comandos directos para manipular Firestore, aquí están los pasos manuales:

## Opción 1: Usar Firebase Console (Recomendado)

1. **Acceder a Firebase Console**
   ```
   https://console.firebase.google.com/project/trazabilidad-ecoce/firestore
   ```

2. **Obtener el UID del usuario maestro**
   - Ve a Authentication > Users
   - Busca el email del usuario maestro
   - Copia el UID (User UID)

3. **Crear documento en colección `maestros`**
   - En Firestore, ve a la raíz
   - Si no existe, crea la colección `maestros`
   - Crea un documento con ID = UID del usuario maestro
   - Agrega estos campos:
   ```json
   {
     "activo": true,
     "nombre": "Maestro ECOCE",
     "email": "email@maestro.com",
     "fecha_creacion": [timestamp],
     "permisos": {
       "aprobar_solicitudes": true,
       "eliminar_usuarios": true,
       "gestionar_sistema": true
     }
   }
   ```

## Opción 2: Usar un Script Temporal en la App

Agrega este código temporalmente en cualquier pantalla después del login del maestro:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> configurarMaestro() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  
  await FirebaseFirestore.instance
    .collection('maestros')
    .doc(user.uid)
    .set({
      'activo': true,
      'nombre': user.displayName ?? 'Maestro ECOCE',
      'email': user.email,
      'fecha_creacion': FieldValue.serverTimestamp(),
      'permisos': {
        'aprobar_solicitudes': true,
        'eliminar_usuarios': true,
        'gestionar_sistema': true,
      }
    });
    
  print('✅ Maestro configurado');
}
```

## Opción 3: Usar Firebase Admin SDK (Node.js)

1. **Instalar dependencias**
   ```bash
   npm install firebase-admin
   ```

2. **Obtener Service Account Key**
   - Ve a Project Settings > Service Accounts
   - Generate new private key
   - Guarda el archivo como `serviceAccountKey.json`

3. **Ejecutar el script**
   ```bash
   node scripts/setup_maestro_user.js
   ```

## Verificación

Para verificar que funcionó:

1. En Firestore Console, verifica que existe:
   - Colección: `maestros`
   - Documento: [UID del usuario]
   - Campos correctos

2. Intenta eliminar un usuario desde la app - ahora debería funcionar.

## Troubleshooting

Si sigue sin funcionar:
1. Verifica que el UID en `maestros` coincide exactamente con el UID en Authentication
2. Verifica que las reglas de Firestore están actualizadas
3. Revisa la consola del navegador/app para ver errores específicos