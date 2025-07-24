const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Inicializar admin si no está inicializado
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Cloud Function para eliminar usuarios de Firebase Auth
 * Se activa cuando se crea un documento en users_pending_deletion
 */
exports.deleteAuthUser = functions.firestore
  .document('users_pending_deletion/{userId}')
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const data = snap.data();
    
    console.log(`Procesando eliminación de usuario: ${userId}`);
    
    try {
      // Eliminar el usuario de Firebase Auth
      await admin.auth().deleteUser(userId);
      
      console.log(`Usuario ${userId} eliminado exitosamente de Firebase Auth`);
      
      // Registrar en audit log
      await admin.firestore().collection('audit_logs').add({
        action: 'auth_user_deleted',
        userId: userId,
        userEmail: data.userEmail || 'unknown',
        userFolio: data.userFolio || 'SIN FOLIO',
        userName: data.userName || 'Sin nombre',
        deletedBy: data.requestedBy || 'system',
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        success: true
      });
      
      // Eliminar el documento de la cola
      await snap.ref.delete();
      
      return {
        success: true,
        message: `Usuario ${userId} eliminado de Auth`
      };
      
    } catch (error) {
      console.error(`Error eliminando usuario ${userId}:`, error);
      
      // Actualizar el documento con el error
      await snap.ref.update({
        status: 'error',
        error: error.message,
        errorAt: admin.firestore.FieldValue.serverTimestamp(),
        retryCount: admin.firestore.FieldValue.increment(1)
      });
      
      // Registrar el error en audit log
      await admin.firestore().collection('audit_logs').add({
        action: 'auth_user_deletion_failed',
        userId: userId,
        userEmail: data.userEmail || 'unknown',
        error: error.message,
        deletedBy: data.requestedBy || 'system',
        attemptedAt: admin.firestore.FieldValue.serverTimestamp(),
        success: false
      });
      
      // Si ha fallado más de 3 veces, marcar como error permanente
      const retryCount = data.retryCount || 0;
      if (retryCount >= 3) {
        await snap.ref.update({
          status: 'permanent_error',
          finalError: `Fallo después de ${retryCount + 1} intentos: ${error.message}`
        });
      }
      
      throw error;
    }
  });

/**
 * Cloud Function programada para reintentar eliminaciones fallidas
 * Se ejecuta cada hora
 */
exports.retryFailedDeletions = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    console.log('Iniciando reintento de eliminaciones fallidas...');
    
    const failedDeletions = await admin.firestore()
      .collection('users_pending_deletion')
      .where('status', '==', 'error')
      .where('retryCount', '<', 3)
      .limit(10)
      .get();
    
    console.log(`Encontradas ${failedDeletions.size} eliminaciones para reintentar`);
    
    const promises = [];
    
    failedDeletions.forEach(doc => {
      const userId = doc.id;
      const data = doc.data();
      
      const promise = admin.auth().deleteUser(userId)
        .then(async () => {
          console.log(`Usuario ${userId} eliminado exitosamente en reintento`);
          
          // Registrar éxito
          await admin.firestore().collection('audit_logs').add({
            action: 'auth_user_deleted_on_retry',
            userId: userId,
            userEmail: data.userEmail || 'unknown',
            retryCount: data.retryCount || 0,
            deletedAt: admin.firestore.FieldValue.serverTimestamp(),
            success: true
          });
          
          // Eliminar de la cola
          await doc.ref.delete();
        })
        .catch(async (error) => {
          console.error(`Error en reintento para usuario ${userId}:`, error);
          
          // Actualizar contador de reintentos
          await doc.ref.update({
            retryCount: admin.firestore.FieldValue.increment(1),
            lastRetryAt: admin.firestore.FieldValue.serverTimestamp(),
            lastError: error.message
          });
        });
      
      promises.push(promise);
    });
    
    await Promise.all(promises);
    
    console.log('Reintento de eliminaciones completado');
    return null;
  });

/**
 * Cloud Function para limpiar registros antiguos
 * Se ejecuta una vez al día
 */
exports.cleanupOldDeletionRecords = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    console.log('Iniciando limpieza de registros antiguos...');
    
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    // Limpiar registros con error permanente después de 30 días
    const oldRecords = await admin.firestore()
      .collection('users_pending_deletion')
      .where('status', '==', 'permanent_error')
      .where('requestedAt', '<', thirtyDaysAgo)
      .get();
    
    console.log(`Encontrados ${oldRecords.size} registros antiguos para eliminar`);
    
    const batch = admin.firestore().batch();
    oldRecords.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    if (oldRecords.size > 0) {
      await batch.commit();
      console.log(`Eliminados ${oldRecords.size} registros antiguos`);
    }
    
    return null;
  });