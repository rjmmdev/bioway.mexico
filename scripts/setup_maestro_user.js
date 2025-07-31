const admin = require('firebase-admin');
const readline = require('readline');

// Inicializar Firebase Admin
const serviceAccount = require('../serviceAccountKey.json'); // Necesitarás el archivo de cuenta de servicio

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: `https://trazabilidad-ecoce.firebaseio.com`
});

const db = admin.firestore();
const auth = admin.auth();

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function setupMaestroUser() {
  try {
    console.log('\n🔧 Configuración de Usuario Maestro ECOCE\n');
    
    // Solicitar email del maestro
    const email = await question('Ingrese el email del usuario maestro: ');
    
    // Buscar usuario por email
    console.log('\n🔍 Buscando usuario...');
    let userRecord;
    try {
      userRecord = await auth.getUserByEmail(email);
      console.log(`✅ Usuario encontrado: ${userRecord.displayName || 'Sin nombre'} (${userRecord.uid})`);
    } catch (error) {
      console.error('❌ Usuario no encontrado en Firebase Auth');
      process.exit(1);
    }
    
    // Verificar si ya existe en colección maestros
    console.log('\n🔍 Verificando colección maestros...');
    const maestroDoc = await db.collection('maestros').doc(userRecord.uid).get();
    
    if (maestroDoc.exists) {
      console.log('✅ El usuario ya está configurado como maestro');
      const data = maestroDoc.data();
      console.log(`   - Nombre: ${data.nombre}`);
      console.log(`   - Email: ${data.email}`);
      console.log(`   - Activo: ${data.activo}`);
      
      const update = await question('\n¿Desea actualizar la configuración? (s/n): ');
      if (update.toLowerCase() !== 's') {
        console.log('👍 No se realizaron cambios');
        process.exit(0);
      }
    }
    
    // Crear o actualizar documento maestro
    console.log('\n📝 Configurando usuario maestro...');
    await db.collection('maestros').doc(userRecord.uid).set({
      activo: true,
      nombre: userRecord.displayName || 'Maestro ECOCE',
      email: userRecord.email,
      fecha_creacion: admin.firestore.FieldValue.serverTimestamp(),
      permisos: {
        aprobar_solicitudes: true,
        eliminar_usuarios: true,
        gestionar_sistema: true,
        ver_estadisticas: true,
        gestionar_maestros: true
      }
    }, { merge: true });
    
    console.log('✅ Usuario maestro configurado exitosamente');
    
    // Verificar si el usuario tiene perfil en ecoce_profiles
    console.log('\n🔍 Verificando perfiles ECOCE...');
    const profilePaths = [
      `ecoce_profiles/origen/centro_acopio/${userRecord.uid}`,
      `ecoce_profiles/origen/planta_separacion/${userRecord.uid}`,
      `ecoce_profiles/reciclador/usuarios/${userRecord.uid}`,
      `ecoce_profiles/transformador/usuarios/${userRecord.uid}`,
      `ecoce_profiles/transporte/usuarios/${userRecord.uid}`,
      `ecoce_profiles/laboratorio/usuarios/${userRecord.uid}`,
      `ecoce_profiles/maestro/usuarios/${userRecord.uid}`
    ];
    
    let foundProfile = false;
    for (const path of profilePaths) {
      const doc = await db.doc(path).get();
      if (doc.exists) {
        console.log(`⚠️  Encontrado perfil en: ${path}`);
        foundProfile = true;
      }
    }
    
    if (!foundProfile) {
      // Crear perfil maestro si no existe
      const createProfile = await question('\n¿Desea crear perfil maestro en ecoce_profiles? (s/n): ');
      if (createProfile.toLowerCase() === 's') {
        await db.doc(`ecoce_profiles/maestro/usuarios/${userRecord.uid}`).set({
          ecoce_tipo_actor: 'M',
          ecoce_subtipo: 'M',
          ecoce_nombre: userRecord.displayName || 'Maestro ECOCE',
          ecoce_folio: 'M0000001',
          ecoce_correo_contacto: userRecord.email,
          ecoce_aprobado: true,
          fecha_creacion: admin.firestore.FieldValue.serverTimestamp()
        });
        
        // Crear índice en ecoce_profiles
        await db.collection('ecoce_profiles').doc(userRecord.uid).set({
          path: `ecoce_profiles/maestro/usuarios/${userRecord.uid}`,
          folio: 'M0000001',
          aprobado: true,
          tipo: 'maestro'
        });
        
        console.log('✅ Perfil maestro creado en ecoce_profiles');
      }
    }
    
    console.log('\n✨ Configuración completada exitosamente');
    console.log(`\nEl usuario ${email} ahora puede:`);
    console.log('  ✓ Aprobar/rechazar solicitudes de cuenta');
    console.log('  ✓ Eliminar usuarios del sistema');
    console.log('  ✓ Gestionar el sistema completo');
    
  } catch (error) {
    console.error('\n❌ Error:', error.message);
  } finally {
    rl.close();
    process.exit(0);
  }
}

// Ejecutar configuración
setupMaestroUser();