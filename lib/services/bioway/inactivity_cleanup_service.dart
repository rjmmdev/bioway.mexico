import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InactivityCleanupService {
  static const int INACTIVITY_DAYS_THRESHOLD = 90; // 3 meses

  static Future<void> checkAndCleanupInactiveUsers() async {
    try {
      final now = DateTime.now();
      final thresholdDate = now.subtract(const Duration(days: INACTIVITY_DAYS_THRESHOLD));
      
      // Verificar brindadores inactivos
      await _cleanupUserType(
        'bioway_brindadores',
        thresholdDate,
      );
      
      // Verificar recolectores inactivos
      await _cleanupUserType(
        'bioway_recolectores',
        thresholdDate,
      );
      
      // Verificar centros de acopio inactivos
      await _cleanupUserType(
        'bioway_centros_acopio',
        thresholdDate,
      );
    } catch (e) {
      print('Error en limpieza de usuarios inactivos: $e');
    }
  }

  static Future<void> _cleanupUserType(
    String collection,
    DateTime thresholdDate,
  ) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(collection)
          .where('ultimaActividad', isLessThan: thresholdDate)
          .get();

      for (final doc in querySnapshot.docs) {
        final userData = doc.data();
        final userId = userData['userId'] ?? doc.id;
        
        // Marcar para eliminación en Firebase Auth
        await FirebaseFirestore.instance
            .collection('users_pending_deletion')
            .doc(userId)
            .set({
          'userId': userId,
          'userType': collection,
          'markedForDeletion': DateTime.now(),
          'status': 'pending',
          'reason': 'inactivity_3_months',
        });
        
        // Eliminar datos del usuario
        await doc.reference.delete();
        
        // Eliminar solicitudes relacionadas
        await _deleteUserRequests(userId);
        
        // Eliminar materiales brindados/recolectados
        await _deleteUserMaterials(userId);
      }
    } catch (e) {
      print('Error limpiando usuarios de $collection: $e');
    }
  }

  static Future<void> _deleteUserRequests(String userId) async {
    try {
      // Eliminar solicitudes del brindador
      final brindadorRequests = await FirebaseFirestore.instance
          .collection('bioway_solicitudes')
          .where('brindadorId', isEqualTo: userId)
          .get();
          
      for (final doc in brindadorRequests.docs) {
        await doc.reference.delete();
      }
      
      // Eliminar solicitudes del recolector
      final recolectorRequests = await FirebaseFirestore.instance
          .collection('bioway_solicitudes')
          .where('recolectorId', isEqualTo: userId)
          .get();
          
      for (final doc in recolectorRequests.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error eliminando solicitudes del usuario: $e');
    }
  }

  static Future<void> _deleteUserMaterials(String userId) async {
    try {
      // Eliminar materiales brindados
      final materials = await FirebaseFirestore.instance
          .collection('bioway_materiales_disponibles')
          .where('brindadorId', isEqualTo: userId)
          .get();
          
      for (final doc in materials.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error eliminando materiales del usuario: $e');
    }
  }

  static Future<void> updateUserActivity(String userId, String userType) async {
    try {
      await FirebaseFirestore.instance
          .collection(userType)
          .doc(userId)
          .update({
        'ultimaActividad': DateTime.now(),
      });
    } catch (e) {
      print('Error actualizando actividad del usuario: $e');
    }
  }
}