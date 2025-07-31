const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'trazabilidad-ecoce'
});

const db = admin.firestore();

async function verificarMaestros() {
  try {
    console.log('Verificando usuarios maestros...\n');
    
    const maestrosSnapshot = await db.collection('maestros').get();
    
    if (maestrosSnapshot.empty) {
      console.log('❌ No hay usuarios maestros configurados');
      console.log('\nPara configurar un maestro, el usuario debe:');
      console.log('1. Iniciar sesión en la app como maestro');
      console.log('2. El sistema creará automáticamente el documento en maestros/');
      return;
    }
    
    console.log(`✅ Encontrados ${maestrosSnapshot.size} usuarios maestros:\n`);
    
    maestrosSnapshot.forEach(doc => {
      const data = doc.data();
      console.log(`ID: ${doc.id}`);
      console.log(`Nombre: ${data.nombre || 'Sin nombre'}`);
      console.log(`Email: ${data.email || 'Sin email'}`);
      console.log(`Activo: ${data.activo ? 'Sí' : 'No'}`);
      console.log(`Permisos:`);
      if (data.permisos) {
        Object.entries(data.permisos).forEach(([permiso, valor]) => {
          console.log(`  - ${permiso}: ${valor ? '✓' : '✗'}`);
        });
      }
      console.log('---');
    });
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    process.exit(0);
  }
}

verificarMaestros();