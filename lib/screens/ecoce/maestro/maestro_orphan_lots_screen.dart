import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../utils/colors.dart';
import '../../../utils/ui_constants.dart';
import '../../../utils/format_utils.dart';
import '../../../services/firebase/firebase_manager.dart';
import '../../../services/user_session_service.dart';
import '../shared/widgets/dialog_utils.dart';
import '../shared/widgets/lote_filter_section.dart';

class MaestroOrphanLotsScreen extends StatefulWidget {
  const MaestroOrphanLotsScreen({super.key});

  @override
  State<MaestroOrphanLotsScreen> createState() => _MaestroOrphanLotsScreenState();
}

class _MaestroOrphanLotsScreenState extends State<MaestroOrphanLotsScreen> {
  final FirebaseManager _firebaseManager = FirebaseManager();
  final UserSessionService _sessionService = UserSessionService();
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  
  // Estados
  Stream<List<OrphanLotInfo>>? _orphanLotsStream;
  List<OrphanLotInfo>? _cachedOrphanLots;
  Set<String> _selectedLots = {};
  bool _isDeleting = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  
  // Paginación
  static const int _batchSize = 100; // Procesar en lotes de 100
  DocumentSnapshot? _lastProcessedDoc;
  
  // Filtros
  String _selectedMaterial = 'Todos';
  String _selectedTime = 'Todos';
  
  @override
  void initState() {
    super.initState();
    // Obtener las instancias correctas de Firebase para ECOCE
    _initializeFirebase();
    
    // Verificar estado de autenticación inmediatamente
    _checkAuthState();
    
    // Cargar lotes huérfanos después de que se construya el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrphanLots();
    });
  }
  
  void _initializeFirebase() {
    final app = _firebaseManager.currentApp;
    if (app != null) {
      _firestore = FirebaseFirestore.instanceFor(app: app);
      _auth = FirebaseAuth.instanceFor(app: app);
      debugPrint('✅ Firebase inicializado con app: ${app.name}');
    } else {
      // Fallback a instancia por defecto
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      debugPrint('⚠️ Usando instancia Firebase por defecto');
    }
  }
  
  void _checkAuthState() async {
    debugPrint('=== VERIFICANDO ESTADO DE AUTENTICACIÓN EN INIT ===');
    
    // Primero verificar con UserSessionService
    if (_sessionService.isLoggedIn) {
      final userData = _sessionService.getUserData();
      if (userData != null) {
        debugPrint('✅ Usuario encontrado en UserSessionService');
        debugPrint('   ID: ${userData['uid']}');
        debugPrint('   Nombre: ${userData['nombre']}');
        debugPrint('   Tipo: ${userData['tipoActor']}');
        return;
      }
    }
    
    // Si no hay sesión en UserSessionService, verificar Firebase Auth
    final user = _auth.currentUser;
    if (user != null) {
      debugPrint('✅ Usuario encontrado en Firebase Auth: ${user.uid}');
      debugPrint('   Email: ${user.email}');
      // Cargar el perfil en UserSessionService
      await _sessionService.getCurrentUserProfile(forceRefresh: true);
    } else {
      debugPrint('❌ No hay usuario autenticado');
    }
  }
  
  
  void _loadOrphanLots() {
    setState(() {
      _orphanLotsStream = _createOrphanLotsStream();
    });
  }
  
  // Crear stream de lotes huérfanos con paginación
  Stream<List<OrphanLotInfo>> _createOrphanLotsStream() {
    // Para la carga inicial, usar el método optimizado con paginación
    return _detectOrphanLotsWithPagination();
  }
  
  // Stream que emite lotes huérfanos por bloques
  Stream<List<OrphanLotInfo>> _detectOrphanLotsWithPagination() async* {
    try {
      debugPrint('\n=== INICIANDO DETECCIÓN CON PAGINACIÓN ===');
      
      // Primero obtener todos los usuarios (esto sí lo hacemos completo)
      final usuariosExistentes = await _obtenerUsuariosExistentes();
      
      // Resetear estado de paginación
      _lastProcessedDoc = null;
      _hasMoreData = true;
      final allOrphanLots = <OrphanLotInfo>[];
      
      // Procesar lotes en bloques
      await for (final batch in _procesarLotesEnBloques(usuariosExistentes)) {
        allOrphanLots.addAll(batch);
        yield List<OrphanLotInfo>.from(allOrphanLots); // Emitir acumulado
      }
      
      // Procesar transformaciones (estas son menos, no necesitan paginación)
      final transformacionesHuerfanas = await _procesarTransformaciones(usuariosExistentes);
      allOrphanLots.addAll(transformacionesHuerfanas);
      yield List<OrphanLotInfo>.from(allOrphanLots);
      
      // Procesar muestras de laboratorio (también en bloques si son muchas)
      final muestrasHuerfanas = await _procesarMuestrasLaboratorio(usuariosExistentes);
      allOrphanLots.addAll(muestrasHuerfanas);
      yield List<OrphanLotInfo>.from(allOrphanLots);
      
      // Procesar entregas y cargas de transporte
      final transporteHuerfanos = await _procesarEntregasYCargasTransporte(usuariosExistentes);
      allOrphanLots.addAll(transporteHuerfanos);
      yield List<OrphanLotInfo>.from(allOrphanLots);
      
      debugPrint('✅ Detección completa. Total elementos huérfanos: ${allOrphanLots.length}');
      
    } catch (e) {
      debugPrint('Error en detección con paginación: $e');
      yield [];
    }
  }
  
  // Obtener todos los usuarios existentes (esto no se pagina)
  Future<Set<String>> _obtenerUsuariosExistentes() async {
    final stopwatch = Stopwatch()..start();
    final Set<String> usuarios = {};
    
    debugPrint('🔍 Buscando usuarios en todas las subcarpetas...');
    
    // Lista de todas las subcarpetas donde pueden estar los usuarios
    // IMPORTANTE: Los usuarios de origen están directamente en centro_acopio y planta_separacion
    final subcarpetas = [
      'origen/centro_acopio',      // Sin /usuarios al final
      'origen/planta_separacion',  // Sin /usuarios al final
      'reciclador/usuarios',
      'transformador/usuarios',
      'transporte/usuarios',
      'laboratorio/usuarios',
    ];
    
    // Obtener usuarios de cada subcarpeta
    for (final subcarpeta in subcarpetas) {
      try {
        final parts = subcarpeta.split('/');
        CollectionReference collectionRef = _firestore.collection('ecoce_profiles');
        
        // Navegar a la subcarpeta correcta
        if (parts.length == 2) {
          if (parts[0] == 'origen') {
            // Para origen, los usuarios están directamente en centro_acopio o planta_separacion
            collectionRef = _firestore
                .collection('ecoce_profiles')
                .doc(parts[0])
                .collection(parts[1]);
          } else {
            // Para otros tipos, están en la subcarpeta usuarios
            collectionRef = _firestore
                .collection('ecoce_profiles')
                .doc(parts[0])
                .collection(parts[1]);
          }
        }
        
        final snapshot = await collectionRef.get();
        
        for (var doc in snapshot.docs) {
          usuarios.add(doc.id);
        }
        
        debugPrint('  ✓ ${snapshot.docs.length} usuarios en $subcarpeta');
      } catch (e) {
        debugPrint('  ⚠️ Error leyendo $subcarpeta: $e');
      }
    }
    
    // También buscar usuarios maestros
    try {
      final maestrosSnapshot = await _firestore.collection('maestros').get();
      for (var doc in maestrosSnapshot.docs) {
        usuarios.add(doc.id);
      }
      debugPrint('  ✓ ${maestrosSnapshot.docs.length} usuarios maestros');
    } catch (e) {
      debugPrint('  ⚠️ Error leyendo maestros: $e');
    }
    
    // También buscar en la raíz de ecoce_profiles
    // IMPORTANTE: Aquí están los índices de usuarios con su path real
    try {
      final rootSnapshot = await _firestore.collection('ecoce_profiles').get();
      int usuariosEnRaiz = 0;
      
      for (var doc in rootSnapshot.docs) {
        // Los documentos en la raíz son índices de usuarios que apuntan a su ubicación real
        // No verificamos campos específicos, simplemente agregamos todos los IDs
        usuarios.add(doc.id);
        usuariosEnRaiz++;
      }
      
      debugPrint('  ✓ ${usuariosEnRaiz} usuarios índice en raíz de ecoce_profiles');
    } catch (e) {
      debugPrint('  ⚠️ Error leyendo raíz de ecoce_profiles: $e');
    }
    
    // SEGURIDAD ADICIONAL: Buscar en todas las subcollecciones posibles que no hayamos cubierto
    try {
      // Buscar en maestro/usuarios (por si existe)
      final maestroUsuariosSnapshot = await _firestore
          .collection('ecoce_profiles')
          .doc('maestro')
          .collection('usuarios')
          .get();
          
      for (var doc in maestroUsuariosSnapshot.docs) {
        usuarios.add(doc.id);
      }
      
      if (maestroUsuariosSnapshot.docs.isNotEmpty) {
        debugPrint('  ✓ ${maestroUsuariosSnapshot.docs.length} usuarios en maestro/usuarios');
      }
    } catch (e) {
      // Ignorar si no existe
    }
    
    debugPrint('✅ ${usuarios.length} usuarios totales obtenidos en ${stopwatch.elapsedMilliseconds}ms');
    
    // Si no hay usuarios, todos los lotes serían huérfanos
    if (usuarios.isEmpty) {
      debugPrint('⚠️ ADVERTENCIA: No se encontraron usuarios en ninguna subcarpeta');
      debugPrint('   Esto significaría que TODOS los lotes son huérfanos');
    } else {
      // Mostrar algunos IDs de muestra para verificación
      debugPrint('📋 Muestra de IDs de usuarios encontrados:');
      usuarios.take(10).forEach((id) {
        debugPrint('   - $id');
      });
      if (usuarios.length > 10) {
        debugPrint('   ... y ${usuarios.length - 10} más');
      }
    }
    
    return usuarios;
  }
  
  // Procesar lotes en bloques usando paginación
  Stream<List<OrphanLotInfo>> _procesarLotesEnBloques(Set<String> usuariosExistentes) async* {
    debugPrint('\n📦 PROCESANDO LOTES EN BLOQUES DE $_batchSize');
    
    DocumentSnapshot? lastDoc;
    int totalProcesados = 0;
    int bloque = 0;
    
    while (_hasMoreData) {
      bloque++;
      debugPrint('\n  Bloque #$bloque:');
      
      // Construir query con paginación
      // No podemos filtrar por documentId en collectionGroup, así que obtenemos todos
      // y filtramos en memoria
      Query query = _firestore
          .collectionGroup('datos_generales')
          .limit(_batchSize * 2); // Aumentamos el límite porque filtraremos después
      
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        _hasMoreData = false;
        debugPrint('  ✓ No hay más documentos');
        break;
      }
      
      lastDoc = snapshot.docs.last;
      
      // Procesar este bloque
      final orphanLotsEnBloque = <OrphanLotInfo>[];
      int huerfanosEnBloque = 0;
      int docsInfo = 0;
      
      for (var doc in snapshot.docs) {
        // Filtrar solo documentos 'info'
        if (doc.id != 'info') continue;
        
        docsInfo++;
        
        try {
          final data = doc.data() as Map<String, dynamic>;
          final creadoPor = data['creado_por'] as String?;
          
          if (creadoPor != null && creadoPor.isNotEmpty && !usuariosExistentes.contains(creadoPor)) {
            // Verificación adicional: intentar buscar el usuario directamente
            bool confirmarHuerfano = true;
            try {
              // Verificar en ecoce_profiles por si acaso
              final profileDoc = await _firestore
                  .collection('ecoce_profiles')
                  .doc(creadoPor)
                  .get();
              
              if (profileDoc.exists) {
                debugPrint('    ⚠️ Usuario $creadoPor encontrado en verificación directa, NO es huérfano');
                confirmarHuerfano = false;
                // Agregar a la lista de usuarios para futuras verificaciones
                usuariosExistentes.add(creadoPor);
              }
            } catch (e) {
              // Si hay error, asumimos que es huérfano
            }
            
            if (!confirmarHuerfano) continue;
            
            huerfanosEnBloque++;
            final loteId = doc.reference.parent.parent!.id;
            
            // Obtener información adicional si es necesario
            String folio = 'Sin folio';
            try {
              final origenDoc = await doc.reference.parent.parent!
                  .collection('origen')
                  .doc('data')
                  .get();
              
              if (origenDoc.exists) {
                folio = origenDoc.data()?['usuario_folio'] ?? 'Sin folio';
              }
            } catch (_) {}
            
            orphanLotsEnBloque.add(OrphanLotInfo(
              loteId: loteId,
              userId: creadoPor,
              fechaCreacion: (data['fecha_creacion'] as Timestamp?)?.toDate(),
              tipoMaterial: data['tipo_material'] ?? 'Desconocido',
              peso: (data['peso'] ?? 0).toDouble(),
              procesoActual: data['proceso_actual'] ?? 'desconocido',
              folio: folio,
            ));
          }
        } catch (e) {
          debugPrint('    Error procesando documento: $e');
        }
      }
      
      totalProcesados += docsInfo;
      debugPrint('  ✓ Procesados: $docsInfo docs info (de ${snapshot.docs.length} totales)');
      debugPrint('  ✓ Huérfanos encontrados en bloque: $huerfanosEnBloque');
      debugPrint('  ✓ Total acumulado: $totalProcesados documentos info');
      
      if (orphanLotsEnBloque.isNotEmpty) {
        yield orphanLotsEnBloque;
      }
      
      // Si procesamos menos documentos que el batch size, no hay más
      if (snapshot.docs.length < _batchSize) {
        _hasMoreData = false;
      }
    }
  }
  
  // Procesar transformaciones (no necesita paginación por ser menos elementos)
  Future<List<OrphanLotInfo>> _procesarTransformaciones(Set<String> usuariosExistentes) async {
    debugPrint('\n🔄 PROCESANDO TRANSFORMACIONES');
    final orphanTransformaciones = <OrphanLotInfo>[];
    
    try {
      // Obtener TODAS las transformaciones directamente de la colección principal
      // (igual que hace TransformacionService pero sin filtro por usuario)
      final snapshot = await _firestore
          .collection('transformaciones')
          .get();
          
      debugPrint('  Total transformaciones encontradas: ${snapshot.docs.length}');
      
      int transformacionesProcesadas = 0;
      int huerfanas = 0;
      
      for (var doc in snapshot.docs) {
        transformacionesProcesadas++;
        
        try {
          // Ahora estamos accediendo directamente a los documentos de transformaciones
          final data = doc.data();
          final usuarioId = data['usuario_id'] as String?;
          
          if (usuarioId != null && !usuariosExistentes.contains(usuarioId)) {
            huerfanas++;
            
            orphanTransformaciones.add(OrphanLotInfo(
              loteId: doc.id,
              userId: usuarioId,
              fechaCreacion: (data['fecha_inicio'] as Timestamp?)?.toDate(),
              tipoMaterial: data['tipo'] == 'agrupacion_reciclador' 
                  ? 'Megalote Reciclador' 
                  : 'Megalote Transformador',
              peso: (data['peso_total_entrada'] ?? 0).toDouble(),
              procesoActual: 'transformacion',
              folio: data['usuario_folio'] ?? 'Sin folio',
              isTransformacion: true,
            ));
            
            debugPrint('  ❌ Transformación huérfana: ${doc.id} (usuario: $usuarioId)');
          }
        } catch (e) {
          debugPrint('    Error procesando transformación ${doc.id}: $e');
        }
      }
      
      debugPrint('  ✓ Transformaciones procesadas: $transformacionesProcesadas');
      debugPrint('  ✓ Transformaciones huérfanas encontradas: $huerfanas');
    } catch (e) {
      debugPrint('  ❌ Error procesando transformaciones: $e');
    }
    
    return orphanTransformaciones;
  }
  
  // Procesar muestras de laboratorio con paginación si son muchas
  Future<List<OrphanLotInfo>> _procesarMuestrasLaboratorio(Set<String> usuariosExistentes) async {
    debugPrint('\n🧪 PROCESANDO MUESTRAS DE LABORATORIO');
    final orphanMuestras = <OrphanLotInfo>[];
    final lotesConMuestrasHuerfanas = <String>{};
    
    try {
      // Si hay muchas muestras, podríamos paginar aquí también
      final snapshot = await _firestore
          .collectionGroup('analisis_laboratorio')
          .limit(500) // Limitar para no sobrecargar
          .get();
          
      debugPrint('  Total muestras procesadas: ${snapshot.docs.length}');
      
      int muestrasHuerfanas = 0;
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          // El campo correcto es 'usuario_id', no 'usuario_laboratorio'
          final usuarioLab = data['usuario_id'] as String?;
          
          if (usuarioLab != null && !usuariosExistentes.contains(usuarioLab)) {
            muestrasHuerfanas++;
            
            final loteId = doc.reference.parent.parent!.id;
            if (lotesConMuestrasHuerfanas.contains(loteId)) continue;
            
            lotesConMuestrasHuerfanas.add(loteId);
            
            // Obtener info del lote
            String tipoMaterial = 'Desconocido';
            try {
              final loteInfoDoc = await doc.reference.parent.parent!
                  .collection('datos_generales')
                  .doc('info')
                  .get();
              
              if (loteInfoDoc.exists) {
                tipoMaterial = loteInfoDoc.data()?['tipo_material'] ?? 'Desconocido';
              }
            } catch (_) {}
            
            orphanMuestras.add(OrphanLotInfo(
              loteId: loteId,
              userId: usuarioLab,
              fechaCreacion: (data['fecha_analisis'] as Timestamp?)?.toDate(),
              tipoMaterial: 'Muestra Lab - $tipoMaterial',
              peso: (data['peso_muestra'] ?? 0).toDouble(),
              procesoActual: 'laboratorio',
              folio: 'LAB-${loteId.substring(0, 6)}',
              isTransformacion: false,
            ));
          }
        } catch (e) {
          debugPrint('    Error procesando muestra: $e');
        }
      }
      
      debugPrint('  ✓ Muestras huérfanas encontradas: $muestrasHuerfanas');
    } catch (e) {
      debugPrint('  ❌ Error procesando muestras: $e');
    }
    
    return orphanMuestras;
  }
  
  // Procesar entregas y cargas de transporte huérfanas
  Future<List<OrphanLotInfo>> _procesarEntregasYCargasTransporte(Set<String> usuariosExistentes) async {
    debugPrint('\n🚛 PROCESANDO ENTREGAS Y CARGAS DE TRANSPORTE');
    final orphanTransporte = <OrphanLotInfo>[];
    
    try {
      // 1. Procesar cargas de transporte
      final cargasSnapshot = await _firestore
          .collection('cargas_transporte')
          .get();
          
      debugPrint('  Cargas de transporte encontradas: ${cargasSnapshot.docs.length}');
      
      int cargasHuerfanas = 0;
      for (var doc in cargasSnapshot.docs) {
        try {
          final data = doc.data();
          final transportistaId = data['transportista_id'] as String?;
          final origenUsuarioId = data['origen_usuario_id'] as String?;
          
          // Verificar si alguno de los usuarios involucrados ya no existe
          bool esHuerfana = false;
          String usuarioFaltante = '';
          
          if (transportistaId != null && !usuariosExistentes.contains(transportistaId)) {
            esHuerfana = true;
            usuarioFaltante = transportistaId;
          } else if (origenUsuarioId != null && !usuariosExistentes.contains(origenUsuarioId)) {
            esHuerfana = true;
            usuarioFaltante = origenUsuarioId;
          }
          
          if (esHuerfana) {
            cargasHuerfanas++;
            orphanTransporte.add(OrphanLotInfo(
              loteId: doc.id,
              userId: usuarioFaltante,
              fechaCreacion: (data['fecha_creacion'] as Timestamp?)?.toDate(),
              tipoMaterial: 'Carga Transporte',
              peso: 0.0, // Las cargas no tienen peso directo
              procesoActual: 'transporte',
              folio: data['qr_carga'] ?? 'Sin QR',
              isTransformacion: false,
            ));
          }
        } catch (e) {
          debugPrint('    Error procesando carga ${doc.id}: $e');
        }
      }
      
      // 2. Procesar entregas de transporte
      final entregasSnapshot = await _firestore
          .collection('entregas_transporte')
          .get();
          
      debugPrint('  Entregas de transporte encontradas: ${entregasSnapshot.docs.length}');
      
      int entregasHuerfanas = 0;
      for (var doc in entregasSnapshot.docs) {
        try {
          final data = doc.data();
          final transportistaId = data['transportista_id'] as String?;
          final receptorId = data['receptor_id'] as String?;
          
          // Verificar si alguno de los usuarios involucrados ya no existe
          bool esHuerfana = false;
          String usuarioFaltante = '';
          
          if (transportistaId != null && !usuariosExistentes.contains(transportistaId)) {
            esHuerfana = true;
            usuarioFaltante = transportistaId;
          } else if (receptorId != null && !usuariosExistentes.contains(receptorId)) {
            esHuerfana = true;
            usuarioFaltante = receptorId;
          }
          
          if (esHuerfana) {
            entregasHuerfanas++;
            orphanTransporte.add(OrphanLotInfo(
              loteId: doc.id,
              userId: usuarioFaltante,
              fechaCreacion: (data['fecha_entrega'] as Timestamp?)?.toDate(),
              tipoMaterial: 'Entrega Transporte',
              peso: 0.0,
              procesoActual: 'entrega',
              folio: data['qr_entrega'] ?? 'Sin QR',
              isTransformacion: false,
            ));
          }
        } catch (e) {
          debugPrint('    Error procesando entrega ${doc.id}: $e');
        }
      }
      
      debugPrint('  ✓ Cargas huérfanas encontradas: $cargasHuerfanas');
      debugPrint('  ✓ Entregas huérfanas encontradas: $entregasHuerfanas');
    } catch (e) {
      debugPrint('  ❌ Error procesando transporte: $e');
    }
    
    return orphanTransporte;
  }
  
  Future<List<OrphanLotInfo>> _detectOrphanLots() async {
    try {
      debugPrint('=== INICIANDO VERIFICACIÓN DE ACCESO Y DETECCIÓN DE LOTES HUÉRFANOS ===');
      
      
      // 1. VERIFICAR CONFIGURACIÓN DE FIREBASE Y AUTENTICACIÓN
      debugPrint('\n1. VERIFICANDO CONFIGURACIÓN:');
      debugPrint('----------------------------------------');
      
      // Verificar usuario autenticado
      String? userId;
      
      // Primero intentar con UserSessionService
      if (_sessionService.isLoggedIn) {
        final userData = _sessionService.getUserData();
        userId = userData?['uid'];
        
        if (userId != null) {
          debugPrint('✅ Usuario autenticado desde UserSessionService: $userId');
          debugPrint('   Tipo: ${userData?['tipoActor']}');
        }
      }
      
      // Si no hay usuario en UserSessionService, verificar Firebase Auth
      if (userId == null) {
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          debugPrint('❌ ERROR: No hay usuario autenticado');
          
          // Intentar cargar el perfil una vez más
          await _sessionService.getCurrentUserProfile(forceRefresh: true);
          final userData = _sessionService.getUserData();
          userId = userData?['uid'];
          
          if (userId == null) {
            debugPrint('❌ No se pudo obtener usuario después de recargar perfil');
            return [];
          }
        } else {
          userId = currentUser.uid;
          debugPrint('✅ Usuario autenticado desde Firebase Auth: $userId');
        }
      }
      
      // Verificar que es maestro
      try {
        // Primero verificar con UserSessionService
        final tipoActor = _sessionService.getUserData()?['tipoActor'];
        if (tipoActor == 'M') {
          debugPrint('✅ Usuario confirmado como MAESTRO por UserSessionService');
        } else {
          // Si no, verificar en Firestore
          final maestroDoc = await _firestore
              .collection('maestros')
              .doc(userId)
              .get();
          
          if (maestroDoc.exists) {
            debugPrint('✅ Usuario confirmado como MAESTRO por Firestore');
          } else {
            debugPrint('❌ Usuario NO es maestro');
            return [];
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error verificando maestro: $e');
      }
      
      // Verificar instancia de Firebase
      try {
        final apps = Firebase.apps;
        debugPrint('Apps Firebase disponibles: ${apps.map((app) => app.name).join(', ')}');
      } catch (e) {
        debugPrint('Error listando apps: $e');
      }
      
      // Continuar con la detección normal
      return await _performOrphanLotsDetection();
      
    } catch (e, stackTrace) {
      debugPrint('Error detectando lotes huérfanos: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }
  
  // Método que realiza la detección real de lotes huérfanos
  Future<List<OrphanLotInfo>> _performOrphanLotsDetection() async {
    try {
      debugPrint('\n=== INICIANDO DETECCIÓN PARALELA DE LOTES HUÉRFANOS ===');
      final stopwatch = Stopwatch()..start();
      
      // 1. EJECUTAR TODAS LAS CONSULTAS EN PARALELO
      debugPrint('\n1. EJECUTANDO CONSULTAS EN PARALELO:');
      debugPrint('----------------------------------------');
      
      final results = await Future.wait([
        // Query 1: Obtener usuarios existentes
        _firestore.collection('ecoce_profiles').get(),
        // Query 2: Obtener todos los datos_generales
        _firestore.collectionGroup('datos_generales').get(),
        // Query 3: Obtener todas las transformaciones
        _firestore.collection('transformaciones').get(),
        // Query 4: Obtener todas las muestras de laboratorio
        _firestore.collectionGroup('analisis_laboratorio').get(),
        // Query 5: Obtener todos los sublotes
        _firestore.collection('sublotes').get(),
      ]);
      
      final profilesSnapshot = results[0];
      final lotesSnapshot = results[1];
      final transformacionesSnapshot = results[2];
      final muestrasSnapshot = results[3];
      final sublotesSnapshot = results[4];
      
      debugPrint('✅ Todas las consultas completadas en ${stopwatch.elapsedMilliseconds}ms');
      
      // 2. CONSTRUIR SET DE USUARIOS EXISTENTES
      final Set<String> usuariosExistentes = {};
      for (var doc in profilesSnapshot.docs) {
        usuariosExistentes.add(doc.id);
      }
      
      debugPrint('✅ Usuarios existentes encontrados: ${usuariosExistentes.length}');
      if (usuariosExistentes.isNotEmpty) {
        debugPrint('   Primeros 5 IDs: ${usuariosExistentes.take(5).join(', ')}...');
      }
      
      // 3. PROCESAR DATOS EN PARALELO
      debugPrint('\n2. PROCESANDO DATOS EN PARALELO:');
      debugPrint('----------------------------------------');
      
      final List<OrphanLotInfo> orphanLots = [];
      
      debugPrint('✅ Documentos datos_generales encontrados: ${lotesSnapshot.docs.length}');
      
      int lotesConInfo = 0;
      int lotesSinCreador = 0;
      int lotesHuerfanosEncontrados = 0;
      
      // 3. PROCESAR CADA LOTE Y FILTRAR HUÉRFANOS
      debugPrint('\n3. PROCESANDO LOTES Y DETECTANDO HUÉRFANOS:');
      debugPrint('----------------------------------------');
      
      for (var doc in lotesSnapshot.docs) {
        try {
          // Verificar que es un documento 'info'
          if (doc.id != 'info') continue;
          
          lotesConInfo++;
          
          final data = doc.data();
          final creadoPor = data['creado_por'] as String?;
          
          if (creadoPor == null || creadoPor.isEmpty) {
            lotesSinCreador++;
            continue;
          }
          
          // Verificar si el usuario NO existe en nuestro Set
          if (!usuariosExistentes.contains(creadoPor)) {
            lotesHuerfanosEncontrados++;
            
            // Obtener el ID del lote desde la referencia del documento
            // doc.reference.parent es 'datos_generales', parent.parent es el lote
            final loteId = doc.reference.parent.parent!.id;
            
            // Obtener información adicional del origen si existe
            String folio = 'Sin folio';
            try {
              final origenDoc = await doc.reference.parent.parent!
                  .collection('origen')
                  .doc('data')
                  .get();
              
              if (origenDoc.exists) {
                folio = origenDoc.data()?['usuario_folio'] ?? 'Sin folio';
              }
            } catch (e) {
              // Ignorar error si no hay datos de origen
            }
            
            // Agregar a la lista de lotes huérfanos
            orphanLots.add(OrphanLotInfo(
              loteId: loteId,
              userId: creadoPor,
              fechaCreacion: (data['fecha_creacion'] as Timestamp?)?.toDate(),
              tipoMaterial: data['tipo_material'] ?? 'Desconocido',
              peso: (data['peso'] ?? 0).toDouble(),
              procesoActual: data['proceso_actual'] ?? 'desconocido',
              folio: folio,
            ));
            
            debugPrint('❌ Lote huérfano encontrado: $loteId (creado por: $creadoPor)');
          }
        } catch (e) {
          debugPrint('Error procesando documento: $e');
        }
      }
      
      // 4. VERIFICAR TRANSFORMACIONES HUÉRFANAS (YA TENEMOS LOS DATOS)
      debugPrint('\n4. PROCESANDO TRANSFORMACIONES:');
      debugPrint('----------------------------------------');
      
      debugPrint('✅ Transformaciones encontradas: ${transformacionesSnapshot.docs.length}');
      
      int transformacionesConInfo = 0;
      int transformacionesHuerfanas = 0;
      
      for (var doc in transformacionesSnapshot.docs) {
        try {
          // Obtener datos_generales/info de cada transformación
          final infoDoc = await doc.reference
              .collection('datos_generales')
              .doc('info')
              .get();
          
          if (!infoDoc.exists) continue;
          
          transformacionesConInfo++;
          
          final data = infoDoc.data()!;
          final usuarioId = data['usuario_id'] as String?;
          
          if (usuarioId != null && !usuariosExistentes.contains(usuarioId)) {
            transformacionesHuerfanas++;
            
            orphanLots.add(OrphanLotInfo(
              loteId: doc.id,
              userId: usuarioId,
              fechaCreacion: (data['fecha_creacion'] as Timestamp?)?.toDate(),
              tipoMaterial: data['tipo'] == 'agrupacion_reciclador' ? 'Megalote Reciclador' : 'Megalote Transformador',
              peso: (data['peso_total_entrada'] ?? 0).toDouble(),
              procesoActual: 'transformacion',
              folio: data['folio'] ?? 'Sin folio',
              isTransformacion: true,
            ));
            
            debugPrint('❌ Transformación huérfana: ${doc.id} (usuario: $usuarioId)');
          }
        } catch (e) {
          debugPrint('Error procesando transformación ${doc.id}: $e');
        }
      }
      
      // 5. VERIFICAR MUESTRAS DE LABORATORIO HUÉRFANAS (YA TENEMOS LOS DATOS)
      debugPrint('\n5. PROCESANDO MUESTRAS DE LABORATORIO:');
      debugPrint('----------------------------------------');
      
      debugPrint('✅ Muestras de laboratorio encontradas: ${muestrasSnapshot.docs.length}');
      
      int muestrasHuerfanas = 0;
      final Set<String> lotesConMuestrasHuerfanas = {}; // Para evitar duplicados
      
      for (var doc in muestrasSnapshot.docs) {
        try {
          final data = doc.data();
          final usuarioLab = data['usuario_laboratorio'] as String?;
          
          if (usuarioLab != null && !usuariosExistentes.contains(usuarioLab)) {
            muestrasHuerfanas++;
            
            // Obtener el ID del lote padre
            final loteId = doc.reference.parent.parent!.id;
            
            // Si ya procesamos este lote, saltarlo
            if (lotesConMuestrasHuerfanas.contains(loteId)) continue;
            
            lotesConMuestrasHuerfanas.add(loteId);
            
            // Obtener información del lote para mostrar más detalles
            final loteInfoDoc = await doc.reference.parent.parent!
                .collection('datos_generales')
                .doc('info')
                .get();
            
            String tipoMaterial = 'Desconocido';
            double peso = 0;
            
            if (loteInfoDoc.exists) {
              final loteData = loteInfoDoc.data()!;
              tipoMaterial = loteData['tipo_material'] ?? 'Desconocido';
              peso = (loteData['peso'] ?? 0).toDouble();
            }
            
            orphanLots.add(OrphanLotInfo(
              loteId: loteId,
              userId: usuarioLab,
              fechaCreacion: (data['fecha_analisis'] as Timestamp?)?.toDate(),
              tipoMaterial: 'Muestra Lab - $tipoMaterial',
              peso: (data['peso_muestra'] ?? 0).toDouble(),
              procesoActual: 'laboratorio',
              folio: 'LAB-${loteId.substring(0, 6)}',
              isTransformacion: false,
            ));
            
            debugPrint('❌ Muestra de laboratorio huérfana en lote: $loteId (usuario lab: $usuarioLab)');
          }
        } catch (e) {
          debugPrint('Error procesando muestra de laboratorio: $e');
        }
      }
      
      // 6. PROCESAR SUBLOTES HUÉRFANOS
      debugPrint('\n6. PROCESANDO SUBLOTES:');
      debugPrint('----------------------------------------');
      
      debugPrint('✅ Sublotes encontrados: ${sublotesSnapshot.docs.length}');
      
      int sublotesHuerfanos = 0;
      
      for (var doc in sublotesSnapshot.docs) {
        try {
          final data = doc.data();
          final creadoPor = data['creado_por'] as String?;
          
          if (creadoPor != null && !usuariosExistentes.contains(creadoPor)) {
            sublotesHuerfanos++;
            
            // Obtener información de la transformación origen
            String tipoTransformacion = 'Sublote';
            double pesoTotal = (data['peso'] ?? 0).toDouble();
            
            // Intentar obtener info de la transformación origen
            if (data['transformacion_origen'] != null) {
              try {
                final transformacionDoc = await _firestore
                    .collection('transformaciones')
                    .doc(data['transformacion_origen'])
                    .get();
                    
                if (transformacionDoc.exists) {
                  final transData = transformacionDoc.data()!;
                  tipoTransformacion = transData['tipo'] == 'agrupacion_reciclador' 
                      ? 'Sublote de Reciclador' 
                      : 'Sublote de Transformador';
                }
              } catch (_) {
                // Si no se puede obtener la transformación, usar tipo genérico
              }
            }
            
            orphanLots.add(OrphanLotInfo(
              loteId: doc.id,
              userId: creadoPor,
              fechaCreacion: (data['fecha_creacion'] as Timestamp?)?.toDate(),
              tipoMaterial: tipoTransformacion,
              peso: pesoTotal,
              procesoActual: data['proceso_actual'] ?? 'reciclador',
              folio: data['qr_code'] ?? 'SUBLOTE-${doc.id.substring(0, 6)}',
              isTransformacion: false,
              isSublote: true,
            ));
            
            debugPrint('❌ Sublote huérfano: ${doc.id} (creado por: $creadoPor)');
          }
        } catch (e) {
          debugPrint('Error procesando sublote ${doc.id}: $e');
        }
      }
      
      // 7. RESUMEN FINAL
      stopwatch.stop();
      debugPrint('\n=== RESUMEN DE DETECCIÓN ===');
      debugPrint('Usuarios existentes: ${usuariosExistentes.length}');
      debugPrint('Lotes con info procesados: $lotesConInfo');
      debugPrint('Lotes sin campo creado_por: $lotesSinCreador');
      debugPrint('Lotes huérfanos encontrados: $lotesHuerfanosEncontrados');
      debugPrint('Transformaciones procesadas: $transformacionesConInfo');
      debugPrint('Transformaciones huérfanas: $transformacionesHuerfanas');
      debugPrint('Muestras de laboratorio huérfanas: $muestrasHuerfanas');
      debugPrint('Sublotes huérfanos: $sublotesHuerfanos');
      debugPrint('TOTAL DE ELEMENTOS HUÉRFANOS: ${orphanLots.length}');
      debugPrint('⏱️ TIEMPO TOTAL: ${stopwatch.elapsedMilliseconds}ms');
      
      return orphanLots;
      
    } catch (e) {
      debugPrint('Error en _performOrphanLotsDetection: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return [];
    }
  }
  
  // Filtrar lotes según criterios seleccionados
  List<OrphanLotInfo> _filterLots(List<OrphanLotInfo> lotes) {
    return lotes.where((lote) {
      // Filtro por material
      if (_selectedMaterial != 'Todos') {
        String materialLote = lote.tipoMaterial;
        String materialBuscado = _selectedMaterial;
        
        // Manejar prefijo "EPF-"
        if (materialLote.toUpperCase().startsWith('EPF-')) {
          materialLote = materialLote.substring(4);
        }
        
        if (materialLote.toUpperCase() != materialBuscado.toUpperCase()) {
          return false;
        }
      }
      
      // Filtro por tiempo
      if (_selectedTime != 'Todos' && lote.fechaCreacion != null) {
        final now = DateTime.now();
        final fecha = lote.fechaCreacion!;
        
        switch (_selectedTime) {
          case 'Hoy':
            return fecha.day == now.day && 
                   fecha.month == now.month && 
                   fecha.year == now.year;
          case 'Esta semana':
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            return fecha.isAfter(startOfWeek);
          case 'Este mes':
            return fecha.month == now.month && fecha.year == now.year;
        }
      }
      
      return true;
    }).toList();
  }
  
  Future<void> _deleteSelectedLots() async {
    if (_selectedLots.isEmpty) {
      if (mounted) {
        DialogUtils.showInfoDialog(
          context,
          title: 'Selección vacía',
          message: 'Por favor selecciona al menos un lote para eliminar.',
        );
      }
      return;
    }
    
    // Confirmación doble
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          'Se eliminarán ${_selectedLots.length} lote(s) huérfano(s).\n\n'
          'Esta acción es PERMANENTE y no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BioWayColors.error,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    
    if (confirm1 != true || !mounted) return;
    
    // Segunda confirmación con detalles
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ ÚLTIMA CONFIRMACIÓN', 
          style: TextStyle(color: BioWayColors.error),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás ABSOLUTAMENTE SEGURO de eliminar estos elementos?\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Se eliminarán permanentemente:\n'
              '• ${_selectedLots.length} elemento(s) huérfano(s)\n'
              '• Sus usuarios ya NO existen en el sistema\n'
              '• Esta acción NO se puede deshacer',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Se ha verificado que los usuarios asociados\nYA NO EXISTEN en ninguna parte del sistema',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO, cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BioWayColors.error,
            ),
            child: const Text('SÍ, eliminar permanentemente'),
          ),
        ],
      ),
    );
    
    if (confirm2 != true || !mounted) return;
    
    setState(() {
      _isDeleting = true;
    });
    
    int deletedCount = 0;
    int errorCount = 0;
    
    // Usar la lista cacheada de lotes
    final currentLots = _cachedOrphanLots ?? [];
    
    for (String loteId in _selectedLots) {
      try {
        final lotInfo = currentLots.firstWhere((lot) => lot.loteId == loteId);
        
        if (lotInfo.isTransformacion) {
          // Eliminar transformación
          await _deleteTransformacion(loteId);
        } else if (lotInfo.isSublote) {
          // Eliminar sublote
          await _deleteSublote(loteId);
        } else if (lotInfo.tipoMaterial == 'Carga Transporte') {
          // Eliminar carga de transporte
          await _deleteCargaTransporte(loteId);
        } else if (lotInfo.tipoMaterial == 'Entrega Transporte') {
          // Eliminar entrega de transporte
          await _deleteEntregaTransporte(loteId);
        } else {
          // Eliminar lote regular
          await _deleteLote(loteId);
        }
        
        // Registrar en audit_logs
        await _firestore.collection('audit_logs').add({
          'action': 'orphan_lot_deleted',
          'loteId': loteId,
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedBy': 'maestro_utility',
          'reason': 'Lote huérfano - usuario no existe',
          'originalUserId': lotInfo.userId,
        });
        
        deletedCount++;
      } catch (e) {
        debugPrint('Error eliminando lote $loteId: $e');
        errorCount++;
      }
    }
    
    setState(() {
      _isDeleting = false;
      _selectedLots.clear();
    });
    
    // Mostrar resultado
    if (mounted) {
      DialogUtils.showSuccessDialog(
        context,
        title: 'Eliminación completada',
        message: 'Se eliminaron $deletedCount lote(s) exitosamente.'
                 '${errorCount > 0 ? '\n$errorCount lote(s) con errores.' : ''}',
        onAccept: () {
          // Recargar la lista
          _loadOrphanLots();
        },
      );
    }
  }
  
  Future<void> _deleteLote(String loteId) async {
    // Verificar si es una muestra de laboratorio huérfana
    final lotInfo = _cachedOrphanLots?.firstWhere(
      (lot) => lot.loteId == loteId,
      orElse: () => OrphanLotInfo(
        loteId: loteId,
        userId: '',
        tipoMaterial: '',
        peso: 0,
        procesoActual: '',
        folio: '',
      ),
    );
    
    if (lotInfo?.procesoActual == 'laboratorio') {
      // Es una muestra de laboratorio huérfana
      // Solo eliminar los documentos de análisis del usuario huérfano
      final analisisSnapshot = await _firestore
          .collection('lotes')
          .doc(loteId)
          .collection('analisis_laboratorio')
          .where('usuario_laboratorio', isEqualTo: lotInfo!.userId)
          .get();
      
      for (var doc in analisisSnapshot.docs) {
        await doc.reference.delete();
      }
      
      debugPrint('Eliminadas muestras de laboratorio huérfanas del lote $loteId');
    } else {
      // Es un lote completo huérfano
      // Eliminar todas las subcollecciones primero
      final subcollections = [
        'datos_generales',
        'origen',
        'transporte',
        'reciclador',
        'transformador',
        'analisis_laboratorio',
      ];
      
      for (String subcollection in subcollections) {
        final docs = await _firestore
            .collection('lotes')
            .doc(loteId)
            .collection(subcollection)
            .get();
        
        for (var doc in docs.docs) {
          await doc.reference.delete();
        }
      }
      
      // Eliminar el documento principal
      await _firestore.collection('lotes').doc(loteId).delete();
      
      debugPrint('Eliminado lote completo: $loteId');
    }
  }
  
  Future<void> _deleteTransformacion(String transformacionId) async {
    // Eliminar subcollecciones
    final subcollections = [
      'datos_generales',
      'sublotes',
      'documentacion',
    ];
    
    for (String subcollection in subcollections) {
      final docs = await _firestore
          .collection('transformaciones')
          .doc(transformacionId)
          .collection(subcollection)
          .get();
      
      for (var doc in docs.docs) {
        await doc.reference.delete();
      }
    }
    
    // Eliminar el documento principal
    await _firestore.collection('transformaciones').doc(transformacionId).delete();
  }
  
  Future<void> _deleteCargaTransporte(String cargaId) async {
    debugPrint('Eliminando carga de transporte: $cargaId');
    await _firestore.collection('cargas_transporte').doc(cargaId).delete();
  }
  
  Future<void> _deleteEntregaTransporte(String entregaId) async {
    debugPrint('Eliminando entrega de transporte: $entregaId');
    await _firestore.collection('entregas_transporte').doc(entregaId).delete();
  }
  
  Future<void> _deleteSublote(String subloteId) async {
    debugPrint('Eliminando sublote: $subloteId');
    
    // Los sublotes generalmente no tienen subcollecciones, pero por si acaso
    // verificamos si existe alguna estructura adicional
    try {
      // Primero intentar obtener el documento para verificar que existe
      final subloteDoc = await _firestore.collection('sublotes').doc(subloteId).get();
      
      if (subloteDoc.exists) {
        // Eliminar el documento principal
        await _firestore.collection('sublotes').doc(subloteId).delete();
        debugPrint('Sublote eliminado exitosamente: $subloteId');
      } else {
        debugPrint('Sublote no encontrado: $subloteId');
      }
    } catch (e) {
      debugPrint('Error al eliminar sublote: $e');
      throw e;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        title: const Text('Lotes Huérfanos'),
        backgroundColor: BioWayColors.ecoceGreen,
        elevation: UIConstants.elevationNone,
        actions: [
          if (_cachedOrphanLots != null && _cachedOrphanLots!.isNotEmpty)
            TextButton.icon(
              onPressed: _isDeleting ? null : () {
                setState(() {
                  final filteredLots = _filterLots(_cachedOrphanLots!);
                  if (_selectedLots.length == filteredLots.length) {
                    _selectedLots.clear();
                  } else {
                    _selectedLots = filteredLots.map((lot) => lot.loteId).toSet();
                  }
                });
              },
              icon: Icon(
                _selectedLots.length == _filterLots(_cachedOrphanLots!).length 
                  ? Icons.deselect 
                  : Icons.select_all,
                color: Colors.white,
              ),
              label: Text(
                _selectedLots.length == _filterLots(_cachedOrphanLots!).length 
                  ? 'Quitar todos' 
                  : 'Seleccionar todos',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _orphanLotsStream == null 
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<OrphanLotInfo>>(
              stream: _orphanLotsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: BioWayColors.error,
                        ),
                        SizedBox(height: UIConstants.spacing16),
                        Text(
                          'Error al detectar lotes huérfanos',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeBody,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: UIConstants.spacing8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeSmall,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: UIConstants.spacing16),
                        ElevatedButton(
                          onPressed: _loadOrphanLots,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                
                final allOrphanLots = snapshot.data ?? [];
                // Cache the data when it arrives
                if (_cachedOrphanLots == null || _cachedOrphanLots!.length != allOrphanLots.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _cachedOrphanLots = allOrphanLots;
                    });
                  });
                }
                final filteredLots = _filterLots(allOrphanLots);
                
                if (allOrphanLots.isEmpty && snapshot.connectionState == ConnectionState.done) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: BioWayColors.success,
                        ),
                        SizedBox(height: UIConstants.spacing16),
                        const Text(
                          'No se encontraron lotes huérfanos',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeBody,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Filtros
                    LoteFilterSection(
                      selectedMaterial: _selectedMaterial,
                      selectedTime: _selectedTime,
                      onMaterialChanged: (value) {
                        setState(() {
                          _selectedMaterial = value;
                        });
                      },
                      onTimeChanged: (value) {
                        setState(() {
                          _selectedTime = value;
                        });
                      },
                      tabColor: BioWayColors.warning,
                    ),
                    
                    // Estadísticas
                    Padding(
                      padding: EdgeInsetsConstants.paddingHorizontal16,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total encontrados',
                              allOrphanLots.length.toString(),
                              BioWayColors.info,
                            ),
                          ),
                          SizedBox(width: UIConstants.spacing12),
                          Expanded(
                            child: _buildStatCard(
                              'Filtrados',
                              filteredLots.length.toString(),
                              BioWayColors.warning,
                            ),
                          ),
                          SizedBox(width: UIConstants.spacing12),
                          Expanded(
                            child: _buildStatCard(
                              'Seleccionados',
                              _selectedLots.length.toString(),
                              BioWayColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Botón de eliminar
                    if (_selectedLots.isNotEmpty)
                      Padding(
                        padding: EdgeInsetsConstants.paddingAll20,
                        child: ElevatedButton.icon(
                          onPressed: _isDeleting ? null : _deleteSelectedLots,
                          icon: _isDeleting 
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.delete_forever),
                          label: Text(
                            _isDeleting 
                              ? 'Eliminando...' 
                              : 'Eliminar ${_selectedLots.length} lote(s)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BioWayColors.error,
                            padding: EdgeInsets.symmetric(
                              vertical: UIConstants.spacing16,
                            ),
                          ),
                        ),
                      ),
                    
                    // Lista de lotes
                    ...filteredLots.map((lot) => Padding(
                      padding: EdgeInsetsConstants.paddingHorizontal16,
                      child: _buildLoteCard(lot),
                    )),
                    
                    // Indicador de carga mientras se procesan más bloques
                    if (snapshot.connectionState == ConnectionState.active)
                      Padding(
                        padding: EdgeInsetsConstants.paddingAll20,
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                color: BioWayColors.ecoceGreen,
                              ),
                              SizedBox(height: UIConstants.spacing12),
                              Text(
                                'Buscando más elementos huérfanos...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: UIConstants.fontSizeSmall,
                                ),
                              ),
                              if (allOrphanLots.isNotEmpty)
                                Text(
                                  '${allOrphanLots.length} encontrados hasta ahora',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: UIConstants.fontSizeSmall - 2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    
                    SizedBox(height: UIConstants.spacing40 * 2),
                  ],
                );
              },
            ),
    );
  }
  
  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsetsConstants.paddingAll16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusConstants.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: UIConstants.opacityLow),
            blurRadius: UIConstants.blurRadiusMedium,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: UIConstants.fontSizeLarge + 4,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: UIConstants.spacing4),
          Text(
            label,
            style: TextStyle(
              fontSize: UIConstants.fontSizeSmall,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoteCard(OrphanLotInfo lot) {
    final isSelected = _selectedLots.contains(lot.loteId);
    
    return Card(
      elevation: UIConstants.elevationSmall,
      margin: EdgeInsets.only(bottom: UIConstants.spacing12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusConstants.borderRadiusMedium,
        side: isSelected 
          ? BorderSide(color: BioWayColors.warning, width: 2)
          : BorderSide.none,
      ),
      child: InkWell(
        onTap: _isDeleting ? null : () {
          setState(() {
            if (_selectedLots.contains(lot.loteId)) {
              _selectedLots.remove(lot.loteId);
            } else {
              _selectedLots.add(lot.loteId);
            }
          });
        },
        borderRadius: BorderRadiusConstants.borderRadiusMedium,
        child: Padding(
          padding: EdgeInsetsConstants.paddingAll16,
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: _isDeleting ? null : (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedLots.add(lot.loteId);
                    } else {
                      _selectedLots.remove(lot.loteId);
                    }
                  });
                },
                activeColor: BioWayColors.warning,
              ),
              
              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado
                    Row(
                      children: [
                        Icon(
                          lot.procesoActual == 'laboratorio' 
                            ? Icons.science
                            : lot.isTransformacion 
                              ? Icons.transform 
                              : Icons.inventory_2,
                          color: lot.procesoActual == 'laboratorio'
                            ? BioWayColors.info
                            : lot.isTransformacion 
                              ? BioWayColors.primaryGreen 
                              : BioWayColors.ecoceGreen,
                          size: 20,
                        ),
                        SizedBox(width: UIConstants.spacing8),
                        Expanded(
                          child: Text(
                            '${lot.folio} - ${lot.tipoMaterial}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: UIConstants.fontSizeBody,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: UIConstants.spacing8),
                    
                    // Detalles
                    _buildInfoRow(
                      Icons.fingerprint, 
                      'ID: ${lot.loteId.substring(0, 8)}...',
                    ),
                    _buildInfoRow(
                      Icons.person_off, 
                      'Usuario: ${lot.userId.substring(0, 8)}...',
                    ),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Creado: ${FormatUtils.formatDate(lot.fechaCreacion)}',
                    ),
                    _buildInfoRow(
                      Icons.scale,
                      'Peso: ${lot.peso.toStringAsFixed(2)} kg',
                    ),
                    _buildInfoRow(
                      Icons.sync,
                      'Proceso: ${lot.procesoActual}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: UIConstants.spacing4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          SizedBox(width: UIConstants.spacing8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: UIConstants.fontSizeSmall,
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class OrphanLotInfo {
  final String loteId;
  final String userId;
  final DateTime? fechaCreacion;
  final String tipoMaterial;
  final double peso;
  final String procesoActual;
  final String folio;
  final bool isTransformacion;
  final bool isSublote;
  
  OrphanLotInfo({
    required this.loteId,
    required this.userId,
    this.fechaCreacion,
    required this.tipoMaterial,
    required this.peso,
    required this.procesoActual,
    required this.folio,
    this.isTransformacion = false,
    this.isSublote = false,
  });
}