import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../firebase/firebase_manager.dart';

class BioWayRecyclingService {
  final FirebaseManager _firebaseManager = FirebaseManager();
  
  FirebaseFirestore get _firestore {
    final app = _firebaseManager.currentApp;
    if (app == null) throw Exception('Firebase no inicializado para BioWay');
    return FirebaseFirestore.instanceFor(app: app);
  }

  FirebaseAuth get _auth {
    final app = _firebaseManager.currentApp;
    if (app == null) throw Exception('Firebase no inicializado para BioWay');
    return FirebaseAuth.instanceFor(app: app);
  }

  /// Registra una nueva actividad de reciclaje
  Future<String> registerRecyclingActivity({
    required Map<String, double> materials,
    required DateTime scheduledTime,
    required String locationId,
    double? bioCoinsEarned,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final activityData = {
        'userId': user.uid,
        'userEmail': user.email,
        'materials': materials,
        'scheduledTime': Timestamp.fromDate(scheduledTime),
        'registeredAt': FieldValue.serverTimestamp(),
        'locationId': locationId,
        'status': 'registered', // registered, collected, completed
        'bioCoinsEarned': bioCoinsEarned ?? _calculateBioCoins(materials),
        'totalWeight': materials.values.fold(0.0, (sum, weight) => sum + weight),
      };

      // Registrar la actividad
      final docRef = await _firestore
          .collection('recycling_activities')
          .add(activityData);

      // Actualizar estadísticas del usuario
      await _updateUserStats(user.uid, materials, bioCoinsEarned ?? _calculateBioCoins(materials));

      debugPrint('✅ Actividad de reciclaje registrada: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error al registrar actividad de reciclaje: $e');
      rethrow;
    }
  }

  /// Actualiza las estadísticas del usuario
  Future<void> _updateUserStats(String userId, Map<String, double> materials, double bioCoinsEarned) async {
    final userStatsRef = _firestore.collection('user_stats').doc(userId);
    
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userStatsRef);
        
        if (!snapshot.exists) {
          // Crear nuevo documento de estadísticas
          transaction.set(userStatsRef, {
            'userId': userId,
            'totalBioCoins': bioCoinsEarned,
            'totalActivities': 1,
            'totalWeight': materials.values.fold(0.0, (sum, weight) => sum + weight),
            'materialsByType': materials,
            'lastActivityDate': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Actualizar estadísticas existentes
          final data = snapshot.data() as Map<String, dynamic>;
          final currentBioCoins = (data['totalBioCoins'] ?? 0.0) as num;
          final currentActivities = (data['totalActivities'] ?? 0) as int;
          final currentWeight = (data['totalWeight'] ?? 0.0) as num;
          final currentMaterials = Map<String, double>.from(data['materialsByType'] ?? {});
          
          // Sumar nuevos materiales
          materials.forEach((type, weight) {
            currentMaterials[type] = (currentMaterials[type] ?? 0.0) + weight;
          });
          
          transaction.update(userStatsRef, {
            'totalBioCoins': currentBioCoins + bioCoinsEarned,
            'totalActivities': currentActivities + 1,
            'totalWeight': currentWeight + materials.values.fold(0.0, (sum, weight) => sum + weight),
            'materialsByType': currentMaterials,
            'lastActivityDate': FieldValue.serverTimestamp(),
          });
        }
      });
      
      debugPrint('✅ Estadísticas de usuario actualizadas');
    } catch (e) {
      debugPrint('❌ Error al actualizar estadísticas: $e');
      throw Exception('Error al actualizar estadísticas del usuario');
    }
  }

  /// Calcula los BioCoins basándose en el peso de los materiales
  double _calculateBioCoins(Map<String, double> materials) {
    // Fórmula simple: 2 BioCoins por kg
    final totalWeight = materials.values.fold(0.0, (sum, weight) => sum + weight);
    return totalWeight * 2;
  }

  /// Obtiene las estadísticas del usuario actual
  Future<Map<String, dynamic>?> getUserStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('user_stats')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      
      // Si no existen estadísticas, retornar valores por defecto
      return {
        'totalBioCoins': 0.0,
        'totalActivities': 0,
        'totalWeight': 0.0,
        'materialsByType': {},
      };
    } catch (e) {
      debugPrint('❌ Error al obtener estadísticas: $e');
      return null;
    }
  }

  /// Obtiene el historial de actividades del usuario
  Future<List<Map<String, dynamic>>> getUserActivityHistory({int limit = 10}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('recycling_activities')
          .where('userId', isEqualTo: user.uid)
          .orderBy('registeredAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('❌ Error al obtener historial: $e');
      return [];
    }
  }

  /// Obtiene el balance actual de BioCoins del usuario
  Future<double> getCurrentBioCoinsBalance() async {
    try {
      final stats = await getUserStats();
      return (stats?['totalBioCoins'] ?? 0.0) as double;
    } catch (e) {
      debugPrint('❌ Error al obtener balance de BioCoins: $e');
      return 0.0;
    }
  }

  /// Marca una actividad como recolectada
  Future<void> markActivityAsCollected(String activityId) async {
    try {
      await _firestore
          .collection('recycling_activities')
          .doc(activityId)
          .update({
        'status': 'collected',
        'collectedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Actividad marcada como recolectada');
    } catch (e) {
      debugPrint('❌ Error al marcar actividad como recolectada: $e');
      rethrow;
    }
  }

  /// Completa una actividad de reciclaje
  Future<void> completeActivity(String activityId) async {
    try {
      await _firestore
          .collection('recycling_activities')
          .doc(activityId)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Actividad completada');
    } catch (e) {
      debugPrint('❌ Error al completar actividad: $e');
      rethrow;
    }
  }
}