const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

// Inicializar Admin SDK
admin.initializeApp();

// Obtener referencias
const db = admin.firestore();
const auth = admin.auth();

/**
 * Cloud Function que se activa cuando se crea un documento en users_pending_deletion
 * Elimina el usuario de Firebase Auth
 */
exports.deleteAuthUser = onDocumentCreated(
  'users_pending_deletion/{userId}',
  async (event) => {
    const snap = event.data;
    const context = event.params;
    const userId = context.params.userId;
    const data = snap.data();
    
    console.log(`🗑️ Procesando eliminación de usuario: ${userId}`);
    console.log(`📧 Email: ${data.userEmail || 'No especificado'}`);
    console.log(`📋 Razón: ${data.reason || 'No especificada'}`);
    
    try {
      // Verificar que el usuario existe en Auth
      let userRecord;
      try {
        userRecord = await auth.getUser(userId);
        console.log(`✅ Usuario encontrado en Auth: ${userRecord.email}`);
      } catch (error) {
        if (error.code === 'auth/user-not-found') {
          console.log('⚠️ Usuario no encontrado en Auth, marcando como completado');
          // Actualizar estado aunque no exista
          await snap.ref.update({
            status: 'completed',
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
            error: 'Usuario no encontrado en Auth'
          });
          return null;
        }
        throw error;
      }
      
      // Eliminar el usuario de Auth
      await auth.deleteUser(userId);
      console.log(`✅ Usuario ${userId} eliminado de Firebase Auth`);
      
      // Actualizar el estado del documento
      await snap.ref.update({
        status: 'completed',
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        deletedEmail: userRecord.email
      });
      
      // Crear registro en audit_logs
      await db.collection('audit_logs').add({
        action: 'user_deleted_from_auth',
        userId: userId,
        userEmail: userRecord.email,
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        deletedBy: data.requestedBy || 'system',
        reason: data.reason || 'No especificada',
        rejectionReason: data.rejectionReason || null
      });
      
      console.log('✅ Proceso completado exitosamente');
      
    } catch (error) {
      console.error('❌ Error eliminando usuario:', error);
      
      // Actualizar el documento con el error
      await snap.ref.update({
        status: 'error',
        errorAt: admin.firestore.FieldValue.serverTimestamp(),
        error: error.message || 'Error desconocido',
        errorCode: error.code || 'unknown'
      });
      
      // Re-lanzar el error para que se registre en los logs de Functions
      throw error;
    }
  });

/**
 * Cloud Function programada para limpiar registros antiguos de users_pending_deletion
 * Se ejecuta diariamente a las 2 AM
 */
exports.cleanupOldDeletionRecords = onSchedule({
  schedule: '0 2 * * *',
  timeZone: 'America/Mexico_City',
}, async (event) => {
    console.log('🧹 Iniciando limpieza de registros antiguos');
    
    try {
      // Obtener registros con más de 30 días
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      const oldRecords = await db.collection('users_pending_deletion')
        .where('requestedAt', '<', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
        .get();
      
      if (oldRecords.empty) {
        console.log('✅ No hay registros antiguos para limpiar');
        return null;
      }
      
      console.log(`📊 Encontrados ${oldRecords.size} registros para eliminar`);
      
      // Eliminar en lotes
      let batch = db.batch();
      let count = 0;
      
      oldRecords.forEach((doc) => {
        batch.delete(doc.ref);
        count++;
        
        // Firestore tiene un límite de 500 operaciones por batch
        if (count === 500) {
          batch.commit();
          batch = db.batch();
          count = 0;
        }
      });
      
      // Commit del último batch si tiene operaciones
      if (count > 0) {
        await batch.commit();
      }
      
      console.log(`✅ Eliminados ${oldRecords.size} registros antiguos`);
      
      // Crear registro en audit_logs
      await db.collection('audit_logs').add({
        action: 'cleanup_deletion_records',
        deletedCount: oldRecords.size,
        executedAt: admin.firestore.FieldValue.serverTimestamp(),
        executedBy: 'scheduled_function'
      });
      
    } catch (error) {
      console.error('❌ Error en limpieza:', error);
      throw error;
    }
  });

/**
 * Cloud Function HTTP para eliminar manualmente un usuario
 * Útil para casos especiales o pruebas
 */
exports.manualDeleteUser = onCall(async (request) => {
  const data = request.data;
  const context = request.auth;
  // Verificar que el usuario está autenticado
  if (!context) {
    throw new HttpsError(
      'unauthenticated',
      'Usuario no autenticado'
    );
  }
  
  const requestingUserId = context.uid;
  
  // Verificar que es un maestro
  const maestroDoc = await db.collection('maestros').doc(requestingUserId).get();
  if (!maestroDoc.exists) {
    throw new HttpsError(
      'permission-denied',
      'Solo los usuarios maestros pueden eliminar usuarios'
    );
  }
  
  const { userId, reason } = data;
  
  if (!userId) {
    throw new HttpsError(
      'invalid-argument',
      'Se requiere el ID del usuario a eliminar'
    );
  }
  
  console.log(`🔧 Eliminación manual solicitada por ${requestingUserId} para usuario ${userId}`);
  
  try {
    // Crear documento en users_pending_deletion
    // Esto activará la función deleteAuthUser automáticamente
    await db.collection('users_pending_deletion').doc(userId).set({
      userId: userId,
      requestedBy: requestingUserId,
      requestedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
      reason: reason || 'Eliminación manual solicitada',
      source: 'manual_function'
    });
    
    return {
      success: true,
      message: 'Usuario marcado para eliminación',
      userId: userId
    };
    
  } catch (error) {
    console.error('Error en eliminación manual:', error);
    throw new HttpsError(
      'internal',
      'Error al procesar la eliminación',
      error.message
    );
  }
});

/**
 * Cloud Function para verificar el estado de salud del sistema
 */
exports.healthCheck = onRequest(async (req, res) => {
  try {
    // Verificar conexión a Firestore
    const testDoc = await db.collection('_health').doc('check').get();
    
    // Verificar Admin Auth
    const users = await auth.listUsers(1);
    
    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        firestore: 'connected',
        auth: 'connected',
        functions: 'running'
      }
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});