import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_manager.dart';

/// Servicio de Firestore que trabaja con múltiples proyectos Firebase
class FirestoreService {
  static FirestoreService? _instance;
  static FirestoreService get instance => _instance ??= FirestoreService._();
  
  FirestoreService._();
  
  final FirebaseManager _firebaseManager = FirebaseManager.instance;
  
  /// Obtener instancia de Firestore actual
  FirebaseFirestore? get _firestore => _firebaseManager.firestore;
  
  /// Verificar si Firestore está disponible
  bool get isAvailable => _firestore != null;
  
  /// Obtener una colección
  CollectionReference<Map<String, dynamic>> collection(String path) {
    if (!isAvailable) {
      throw Exception('Firestore no está inicializado');
    }
    return _firestore!.collection(path);
  }
  
  /// Obtener un documento
  DocumentReference<Map<String, dynamic>> doc(String path) {
    if (!isAvailable) {
      throw Exception('Firestore no está inicializado');
    }
    return _firestore!.doc(path);
  }
  
  /// Crear o actualizar un documento
  Future<void> setDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    try {
      await this.collection(collection).doc(docId).set(
        data,
        SetOptions(merge: merge),
      );
    } catch (e) {
      throw Exception('Error al guardar documento: $e');
    }
  }
  
  /// Agregar un documento con ID automático
  Future<DocumentReference<Map<String, dynamic>>> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      return await this.collection(collection).add(data);
    } catch (e) {
      throw Exception('Error al agregar documento: $e');
    }
  }
  
  /// Obtener un documento
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      return await this.collection(collection).doc(docId).get();
    } catch (e) {
      throw Exception('Error al obtener documento: $e');
    }
  }
  
  /// Actualizar campos específicos de un documento
  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await this.collection(collection).doc(docId).update(data);
    } catch (e) {
      throw Exception('Error al actualizar documento: $e');
    }
  }
  
  /// Eliminar un documento
  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      await this.collection(collection).doc(docId).delete();
    } catch (e) {
      throw Exception('Error al eliminar documento: $e');
    }
  }
  
  /// Obtener stream de un documento
  Stream<DocumentSnapshot<Map<String, dynamic>>> documentStream({
    required String collection,
    required String docId,
  }) {
    if (!isAvailable) {
      return Stream.error('Firestore no está inicializado');
    }
    return this.collection(collection).doc(docId).snapshots();
  }
  
  /// Obtener stream de una colección
  Stream<QuerySnapshot<Map<String, dynamic>>> collectionStream({
    required String collection,
    Query<Map<String, dynamic>>? Function(Query<Map<String, dynamic>>)? queryBuilder,
  }) {
    if (!isAvailable) {
      return Stream.error('Firestore no está inicializado');
    }
    
    Query<Map<String, dynamic>> query = this.collection(collection);
    
    if (queryBuilder != null) {
      final modifiedQuery = queryBuilder(query);
      if (modifiedQuery != null) {
        query = modifiedQuery;
      }
    }
    
    return query.snapshots();
  }
  
  /// Realizar una consulta
  Future<QuerySnapshot<Map<String, dynamic>>> query({
    required String collection,
    Query<Map<String, dynamic>>? Function(Query<Map<String, dynamic>>)? queryBuilder,
  }) async {
    try {
      Query<Map<String, dynamic>> query = this.collection(collection);
      
      if (queryBuilder != null) {
        final modifiedQuery = queryBuilder(query);
        if (modifiedQuery != null) {
          query = modifiedQuery;
        }
      }
      
      return await query.get();
    } catch (e) {
      throw Exception('Error al realizar consulta: $e');
    }
  }
  
  /// Batch write
  Future<void> batchWrite(
    Future<void> Function(WriteBatch batch) operations,
  ) async {
    if (!isAvailable) {
      throw Exception('Firestore no está inicializado');
    }
    
    try {
      final batch = _firestore!.batch();
      await operations(batch);
      await batch.commit();
    } catch (e) {
      throw Exception('Error en batch write: $e');
    }
  }
  
  /// Transacción
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) transactionHandler,
  ) async {
    if (!isAvailable) {
      throw Exception('Firestore no está inicializado');
    }
    
    try {
      return await _firestore!.runTransaction(transactionHandler);
    } catch (e) {
      throw Exception('Error en transacción: $e');
    }
  }
  
  /// Obtener timestamp del servidor
  FieldValue get serverTimestamp => FieldValue.serverTimestamp();
  
  /// Incrementar un campo numérico
  FieldValue increment(num value) => FieldValue.increment(value);
  
  /// Agregar elementos a un array
  FieldValue arrayUnion(List<dynamic> elements) => FieldValue.arrayUnion(elements);
  
  /// Remover elementos de un array
  FieldValue arrayRemove(List<dynamic> elements) => FieldValue.arrayRemove(elements);
}