import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Enfoque alternativo para detectar lotes huérfanos
/// Usa consultas paginadas y evita obtener todos los lotes de una vez
class AlternativeOrphanLotsDetection {
  
  static Future<List<String>> detectOrphanLots(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final List<String> orphanLotIds = [];
    
    try {
      // Opción 1: Usar Stream en lugar de get()
      await for (var doc in firestore.collection('lotes').snapshots().first.asStream()) {
        for (var loteDoc in doc.docs) {
          // Verificar cada lote individualmente
          final datosGeneralesDoc = await loteDoc.reference
              .collection('datos_generales')
              .doc('info')
              .get();
          
          if (datosGeneralesDoc.exists) {
            final creadoPor = datosGeneralesDoc.data()?['creado_por'] as String?;
            if (creadoPor != null) {
              // Verificar si el usuario existe
              final userExists = await firestore
                  .collection('ecoce_profiles')
                  .doc(creadoPor)
                  .get()
                  .then((doc) => doc.exists);
              
              if (!userExists) {
                orphanLotIds.add(loteDoc.id);
              }
            }
          }
        }
      }
      
      return orphanLotIds;
      
    } catch (e) {
      debugPrint('Error en detección alternativa: $e');
      
      // Opción 2: Consulta paginada
      try {
        const int batchSize = 20;
        QuerySnapshot? lastSnapshot;
        bool hasMore = true;
        
        while (hasMore) {
          Query query = firestore.collection('lotes').limit(batchSize);
          
          if (lastSnapshot != null && lastSnapshot.docs.isNotEmpty) {
            query = query.startAfterDocument(lastSnapshot.docs.last);
          }
          
          final snapshot = await query.get();
          
          if (snapshot.docs.isEmpty) {
            hasMore = false;
            break;
          }
          
          for (var doc in snapshot.docs) {
            // Verificar cada lote
            final datosGeneralesDoc = await doc.reference
                .collection('datos_generales')
                .doc('info')
                .get();
            
            if (datosGeneralesDoc.exists) {
              final creadoPor = datosGeneralesDoc.data()?['creado_por'] as String?;
              if (creadoPor != null) {
                final userExists = await firestore
                    .collection('ecoce_profiles')
                    .doc(creadoPor)
                    .get()
                    .then((doc) => doc.exists);
                
                if (!userExists) {
                  orphanLotIds.add(doc.id);
                }
              }
            }
          }
          
          lastSnapshot = snapshot;
          hasMore = snapshot.docs.length == batchSize;
        }
        
        return orphanLotIds;
        
      } catch (e2) {
        debugPrint('Error en opción 2: $e2');
        
        // Opción 3: Consulta inversa - obtener usuarios primero
        try {
          // Obtener todos los usuarios existentes
          final usersSnapshot = await firestore
              .collection('ecoce_profiles')
              .get();
          
          final existingUserIds = usersSnapshot.docs.map((doc) => doc.id).toSet();
          
          // Ahora buscar lotes cuyos creadores no están en la lista
          final lotsQuery = firestore.collectionGroup('datos_generales')
              .where('__name__', isEqualTo: 'info');
          
          final lotsSnapshot = await lotsQuery.get();
          
          for (var doc in lotsSnapshot.docs) {
            final creadoPor = doc.data()['creado_por'] as String?;
            if (creadoPor != null && !existingUserIds.contains(creadoPor)) {
              // Extraer el ID del lote del path
              final pathSegments = doc.reference.path.split('/');
              if (pathSegments.length >= 2 && pathSegments[0] == 'lotes') {
                orphanLotIds.add(pathSegments[1]);
              }
            }
          }
          
          return orphanLotIds;
          
        } catch (e3) {
          debugPrint('Error en opción 3: $e3');
          rethrow;
        }
      }
    }
  }
}