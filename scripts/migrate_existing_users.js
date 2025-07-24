// Script para migrar usuarios existentes de Firebase Auth a la estructura correcta
// Este script debe ejecutarse en un entorno Node.js con el Admin SDK de Firebase

const admin = require('firebase-admin');

// Inicializar Firebase Admin SDK
// Necesitas descargar el archivo de credenciales de servicio desde Firebase Console
admin.initializeApp({
  credential: admin.credential.cert('./path-to-service-account-key.json'),
  databaseURL: 'https://trazabilidad-ecoce.firebaseio.com'
});

const auth = admin.auth();
const firestore = admin.firestore();

async function migrateExistingUsers() {
  try {
    // Obtener todos los usuarios de Firebase Auth
    let allUsers = [];
    let nextPageToken;
    
    do {
      const listUsersResult = await auth.listUsers(1000, nextPageToken);
      allUsers = allUsers.concat(listUsersResult.users);
      nextPageToken = listUsersResult.pageToken;
    } while (nextPageToken);
    
    console.log(`Encontrados ${allUsers.length} usuarios en Firebase Auth`);
    
    // Para cada usuario, verificar si existe en ecoce_profiles
    for (const user of allUsers) {
      console.log(`\nProcesando usuario: ${user.email}`);
      
      // Buscar si ya existe un perfil
      const profileExists = await checkIfProfileExists(user.uid);
      
      if (!profileExists) {
        console.log(`  → Usuario ${user.email} no tiene perfil, creando...`);
        
        // Determinar el tipo de usuario basándose en el email
        const userType = determineUserType(user.email);
        
        // Crear el perfil en la subcolección correcta
        await createUserProfile(user, userType);
        
        console.log(`  ✓ Perfil creado para ${user.email}`);
      } else {
        console.log(`  ✓ Usuario ${user.email} ya tiene perfil`);
      }
    }
    
    console.log('\n✅ Migración completada');
    
  } catch (error) {
    console.error('Error durante la migración:', error);
  }
}

async function checkIfProfileExists(userId) {
  const subcollections = [
    'origen/centro_acopio',
    'origen/planta_separacion',
    'reciclador/usuarios',
    'transformador/usuarios',
    'transporte/usuarios',
    'laboratorio/usuarios',
    'maestro/usuarios',
  ];
  
  for (const subcollection of subcollections) {
    const [parent, child] = subcollection.split('/');
    const doc = await firestore
      .collection('ecoce_profiles')
      .doc(parent)
      .collection(child)
      .doc(userId)
      .get();
    
    if (doc.exists) {
      return true;
    }
  }
  
  return false;
}

function determineUserType(email) {
  // Lógica para determinar el tipo de usuario basándose en el email
  // Ajusta esto según tu lógica de negocio
  
  if (email.includes('maestro') || email.includes('admin')) {
    return { tipo: 'M', subtipo: 'M', collection: 'maestro/usuarios' };
  } else if (email.includes('acopio')) {
    return { tipo: 'O', subtipo: 'A', collection: 'origen/centro_acopio' };
  } else if (email.includes('planta')) {
    return { tipo: 'O', subtipo: 'P', collection: 'origen/planta_separacion' };
  } else if (email.includes('reciclador')) {
    return { tipo: 'R', subtipo: 'R', collection: 'reciclador/usuarios' };
  } else if (email.includes('transporte')) {
    return { tipo: 'V', subtipo: 'V', collection: 'transporte/usuarios' };
  } else if (email.includes('laboratorio')) {
    return { tipo: 'L', subtipo: 'L', collection: 'laboratorio/usuarios' };
  } else if (email.includes('transformador')) {
    return { tipo: 'T', subtipo: 'T', collection: 'transformador/usuarios' };
  } else {
    // Por defecto, crear como acopiador
    return { tipo: 'O', subtipo: 'A', collection: 'origen/centro_acopio' };
  }
}

async function createUserProfile(user, userType) {
  const [parent, child] = userType.collection.split('/');
  
  // Generar folio
  const folio = await generateFolio(userType.subtipo);
  
  const profileData = {
    id: user.uid,
    ecoce_tipo_actor: userType.tipo,
    ecoce_subtipo: userType.subtipo,
    ecoce_folio: folio,
    ecoce_nombre: user.displayName || 'Usuario Sin Nombre',
    ecoce_correo_contacto: user.email,
    ecoce_nombre_contacto: user.displayName || 'Sin nombre',
    ecoce_tel_contacto: user.phoneNumber || '0000000000',
    ecoce_estatus_aprobacion: 1, // Aprobar automáticamente usuarios existentes
    ecoce_fecha_reg: admin.firestore.Timestamp.now(),
    ecoce_fecha_aprobacion: admin.firestore.Timestamp.now(),
    ecoce_aprobado_por: 'MIGRATION_SCRIPT',
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    
    // Campos adicionales con valores por defecto
    ecoce_rfc: 'XAXX010101000',
    ecoce_calle: 'Sin dirección',
    ecoce_num_ext: 'S/N',
    ecoce_cp: '00000',
    ecoce_estado: 'Por definir',
    ecoce_municipio: 'Por definir',
    ecoce_colonia: 'Por definir',
  };
  
  await firestore
    .collection('ecoce_profiles')
    .doc(parent)
    .collection(child)
    .doc(user.uid)
    .set(profileData);
}

async function generateFolio(subtipo) {
  // Esta es una versión simplificada
  // En producción, deberías usar una transacción para garantizar folios únicos
  const prefix = subtipo === 'A' ? 'A' : 
                 subtipo === 'P' ? 'P' :
                 subtipo === 'R' ? 'R' :
                 subtipo === 'T' ? 'T' :
                 subtipo === 'V' ? 'V' :
                 subtipo === 'L' ? 'L' :
                 subtipo === 'M' ? 'M' : 'X';
  
  const timestamp = Date.now().toString().slice(-6);
  return `${prefix}${timestamp.padStart(7, '0')}`;
}

// Ejecutar la migración
migrateExistingUsers()
  .then(() => {
    console.log('Proceso completado');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Error en el proceso:', error);
    process.exit(1);
  });