import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase/firebase_manager.dart';

/// Modelo para representar un material configurable
class MaterialConfig {
  final String id;
  final String label;
  final bool activo;
  final int orden;
  final String? descripcion;
  final String? categoria;

  MaterialConfig({
    required this.id,
    required this.label,
    this.activo = true,
    required this.orden,
    this.descripcion,
    this.categoria,
  });

  factory MaterialConfig.fromMap(Map<String, dynamic> map) {
    return MaterialConfig(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      activo: map['activo'] ?? true,
      orden: map['orden'] ?? 999,
      descripcion: map['descripcion'],
      categoria: map['categoria'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'activo': activo,
      'orden': orden,
      if (descripcion != null) 'descripcion': descripcion,
      if (categoria != null) 'categoria': categoria,
    };
  }
}

/// Servicio para gestionar configuraciones dinámicas desde Firestore
class ConfigurationService {
  final FirebaseManager _firebaseManager = FirebaseManager();
  FirebaseFirestore? _firestore;
  
  // Cache de materiales con tiempo de expiración
  static final Map<String, List<MaterialConfig>> _materialesCache = {};
  static final Map<String, DateTime> _cacheExpiration = {};
  static const Duration _cacheDuration = Duration(hours: 1);

  FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instanceFor(
      app: _firebaseManager.currentApp!,
    );
    return _firestore!;
  }

  /// Obtiene los materiales configurados para un tipo de usuario específico
  Future<List<MaterialConfig>> getMaterialesPorTipo(String tipoUsuario) async {
    try {
      // Verificar cache
      if (_materialesCache.containsKey(tipoUsuario)) {
        final expiration = _cacheExpiration[tipoUsuario];
        if (expiration != null && DateTime.now().isBefore(expiration)) {
          debugPrint('📦 Materiales de $tipoUsuario obtenidos del cache');
          return _materialesCache[tipoUsuario]!;
        }
      }

      debugPrint('🔄 Obteniendo materiales de $tipoUsuario desde Firestore...');
      
      // Obtener de Firestore
      final docSnapshot = await firestore
          .collection('configuracion')
          .doc('materiales_por_tipo')
          .get();

      if (!docSnapshot.exists) {
        debugPrint('⚠️ No se encontró configuración de materiales');
        return _getMaterialesDefault(tipoUsuario);
      }

      final data = docSnapshot.data();
      final materialesData = data?[tipoUsuario] as List<dynamic>?;

      if (materialesData == null || materialesData.isEmpty) {
        debugPrint('⚠️ No hay materiales configurados para $tipoUsuario');
        return _getMaterialesDefault(tipoUsuario);
      }

      // Convertir a objetos MaterialConfig
      final materiales = materialesData
          .map((item) => MaterialConfig.fromMap(item as Map<String, dynamic>))
          .where((material) => material.activo) // Solo materiales activos
          .toList()
        ..sort((a, b) => a.orden.compareTo(b.orden)); // Ordenar por campo orden

      // Actualizar cache
      _materialesCache[tipoUsuario] = materiales;
      _cacheExpiration[tipoUsuario] = DateTime.now().add(_cacheDuration);

      debugPrint('✅ ${materiales.length} materiales obtenidos para $tipoUsuario');
      return materiales;

    } catch (e) {
      debugPrint('❌ Error obteniendo materiales: $e');
      return _getMaterialesDefault(tipoUsuario);
    }
  }

  /// Obtiene los materiales por subtipo de usuario (mapea a tipo principal)
  Future<List<MaterialConfig>> getMaterialesPorSubtipo(String subtipo) async {
    final tipoUsuario = _mapSubtipoToTipo(subtipo);
    return getMaterialesPorTipo(tipoUsuario);
  }

  /// Mapea el subtipo de usuario al tipo principal
  String _mapSubtipoToTipo(String subtipo) {
    switch (subtipo) {
      case 'A': // Acopiador
      case 'P': // Planta de Separación
        return 'origen';
      case 'R':
        return 'reciclador';
      case 'T':
        return 'transformador';
      case 'V':
        return 'transportista';
      case 'L':
        return 'laboratorio';
      default:
        return 'origen';
    }
  }

  /// Limpia el cache de materiales
  void clearCache() {
    _materialesCache.clear();
    _cacheExpiration.clear();
    debugPrint('🧹 Cache de materiales limpiado');
  }

  /// Recarga los materiales de un tipo específico
  Future<List<MaterialConfig>> reloadMateriales(String tipoUsuario) async {
    _materialesCache.remove(tipoUsuario);
    _cacheExpiration.remove(tipoUsuario);
    return getMaterialesPorTipo(tipoUsuario);
  }

  /// Retorna materiales por defecto en caso de error o falta de configuración
  List<MaterialConfig> _getMaterialesDefault(String tipoUsuario) {
    debugPrint('📋 Usando materiales por defecto para $tipoUsuario');
    
    switch (tipoUsuario) {
      case 'origen':
        return [
          MaterialConfig(id: 'epf_poli_pe', label: 'EPF - Poli (PE)', orden: 1),
          MaterialConfig(id: 'epf_pp', label: 'EPF - PP', orden: 2),
          MaterialConfig(id: 'epf_multi', label: 'EPF - Multi', orden: 3),
        ];
      case 'reciclador':
        return [
          MaterialConfig(id: 'epf_separados_tipo', label: 'EPF separados por tipo', orden: 1),
          MaterialConfig(id: 'epf_semiseparados_tipo', label: 'EPF semiseparados por tipo', orden: 2),
          MaterialConfig(id: 'epf_pacas', label: 'EPF en Pacas', orden: 3),
          MaterialConfig(id: 'epf_sacos_granel', label: 'EPF en sacos o granel', orden: 4),
          MaterialConfig(id: 'epf_limpios', label: 'EPF limpios', orden: 5),
          MaterialConfig(id: 'epf_contaminacion_leve', label: 'EPF con contaminación leve', orden: 6),
        ];
      case 'transformador':
        return [
          MaterialConfig(id: 'pellets_reciclados_poli', label: 'Pellets reciclados de Poli', orden: 1),
          MaterialConfig(id: 'pellets_reciclados_pp', label: 'Pellets reciclados de PP', orden: 2),
          MaterialConfig(id: 'hojuelas_recicladas_poli', label: 'Hojuelas recicladas de Poli', orden: 3),
          MaterialConfig(id: 'hojuelas_recicladas_pp', label: 'Hojuelas recicladas de PP', orden: 4),
        ];
      case 'transportista':
        // Transportista no maneja materiales
        return [];
      case 'laboratorio':
        return [
          MaterialConfig(id: 'muestras_hojuelas', label: 'Muestras en forma de hojuelas', orden: 1),
          MaterialConfig(id: 'muestras_pellets_reciclados', label: 'Muestras en forma de Pellets reciclados', orden: 2),
          MaterialConfig(id: 'muestras_productos_transformados', label: 'Muestras de productos transformados', orden: 3),
        ];
      default:
        return [];
    }
  }

  /// Inicializa los materiales en Firestore (solo para configuración inicial)
  Future<bool> initializeMateriales() async {
    try {
      debugPrint('🚀 Inicializando materiales en Firestore...');

      final materiales = {
        'origen': [
          {'id': 'epf_poli_pe', 'label': 'EPF - Poli (PE)', 'activo': true, 'orden': 1},
          {'id': 'epf_pp', 'label': 'EPF - PP', 'activo': true, 'orden': 2},
          {'id': 'epf_multi', 'label': 'EPF - Multi', 'activo': true, 'orden': 3},
        ],
        'reciclador': [
          {'id': 'epf_separados_tipo', 'label': 'EPF separados por tipo', 'activo': true, 'orden': 1},
          {'id': 'epf_semiseparados_tipo', 'label': 'EPF semiseparados por tipo', 'activo': true, 'orden': 2},
          {'id': 'epf_pacas', 'label': 'EPF en Pacas', 'activo': true, 'orden': 3},
          {'id': 'epf_sacos_granel', 'label': 'EPF en sacos o granel', 'activo': true, 'orden': 4},
          {'id': 'epf_limpios', 'label': 'EPF limpios', 'activo': true, 'orden': 5},
          {'id': 'epf_contaminacion_leve', 'label': 'EPF con contaminación leve', 'activo': true, 'orden': 6},
        ],
        'transformador': [
          {'id': 'pellets_reciclados_poli', 'label': 'Pellets reciclados de Poli', 'activo': true, 'orden': 1},
          {'id': 'pellets_reciclados_pp', 'label': 'Pellets reciclados de PP', 'activo': true, 'orden': 2},
          {'id': 'hojuelas_recicladas_poli', 'label': 'Hojuelas recicladas de Poli', 'activo': true, 'orden': 3},
          {'id': 'hojuelas_recicladas_pp', 'label': 'Hojuelas recicladas de PP', 'activo': true, 'orden': 4},
        ],
        // Transportista no tiene materiales
        'laboratorio': [
          {'id': 'muestras_hojuelas', 'label': 'Muestras en forma de hojuelas', 'activo': true, 'orden': 1},
          {'id': 'muestras_pellets_reciclados', 'label': 'Muestras en forma de Pellets reciclados', 'activo': true, 'orden': 2},
          {'id': 'muestras_productos_transformados', 'label': 'Muestras de productos transformados', 'activo': true, 'orden': 3},
        ],
      };

      await firestore
          .collection('configuracion')
          .doc('materiales_por_tipo')
          .set({
        ...materiales,
        'ultima_actualizacion': FieldValue.serverTimestamp(),
        'version': 1,
      });

      debugPrint('✅ Materiales inicializados correctamente en Firestore');
      return true;

    } catch (e) {
      debugPrint('❌ Error inicializando materiales: $e');
      return false;
    }
  }

  /// Actualiza los materiales de un tipo específico
  Future<bool> updateMateriales(String tipoUsuario, List<MaterialConfig> materiales) async {
    try {
      final materialesData = materiales.map((m) => m.toMap()).toList();

      await firestore
          .collection('configuracion')
          .doc('materiales_por_tipo')
          .update({
        tipoUsuario: materialesData,
        'ultima_actualizacion': FieldValue.serverTimestamp(),
      });

      // Limpiar cache para forzar recarga
      _materialesCache.remove(tipoUsuario);
      _cacheExpiration.remove(tipoUsuario);

      debugPrint('✅ Materiales de $tipoUsuario actualizados');
      return true;

    } catch (e) {
      debugPrint('❌ Error actualizando materiales: $e');
      return false;
    }
  }
}