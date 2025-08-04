import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../utils/qr_utils.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../services/firebase/firebase_manager.dart'; // NUEVO: Para obtener la instancia correcta
import '../../../services/muestra_laboratorio_service.dart'; // NUEVO: Servicio independiente
import '../../../services/transformacion_service.dart';
import '../../../models/laboratorio/muestra_laboratorio_model.dart'; // NUEVO: Modelo de muestra
import '../../../models/lotes/transformacion_model.dart';
import 'laboratorio_registro_muestras.dart';
import 'laboratorio_toma_muestra_megalote_screen.dart';
import 'laboratorio_formulario.dart';
import 'laboratorio_documentacion.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/shared_qr_scanner_screen.dart';

class LaboratorioGestionMuestras extends StatefulWidget {
  final int initialTab;
  
  const LaboratorioGestionMuestras({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<LaboratorioGestionMuestras> createState() => _LaboratorioGestionMuestrasState();
}

class _LaboratorioGestionMuestrasState extends State<LaboratorioGestionMuestras> 
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  
  // Filtros
  String _selectedMaterial = 'Todos';
  String _selectedTiempo = 'Este Mes';
  
  // Bottom navigation
  final int _selectedIndex = 1; // Muestras está seleccionado
  
  // Servicios
  final AuthService _authService = AuthService();
  late final FirebaseFirestore _firestore; // CAMBIADO: Se inicializa en initState con la instancia correcta
  final MuestraLaboratorioService _muestraService = MuestraLaboratorioService(); // NUEVO: Servicio independiente
  final FirebaseManager _firebaseManager = FirebaseManager(); // NUEVO: Para obtener la app correcta
  final TransformacionService _transformacionService = TransformacionService();
  
  // Datos - NUEVO: Usando modelo tipado
  bool _isLoading = false;
  List<MuestraLaboratorioModel> _muestrasAnalisis = [];
  List<MuestraLaboratorioModel> _muestrasDocumentacion = [];
  List<MuestraLaboratorioModel> _muestrasFinalizadas = [];
  
  // Cache para transformaciones
  Map<String, TransformacionModel?> _transformacionesCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // CRÍTICO: Usar la misma instancia de Firebase que el servicio
    // Esto asegura que leemos del proyecto ECOCE donde se crean las muestras
    final app = _firebaseManager.currentApp;
    if (app != null) {
      _firestore = FirebaseFirestore.instanceFor(app: app);
      debugPrint('[LABORATORIO] Usando Firebase app: ${app.name} - Project: ${app.options.projectId}');
    } else {
      _firestore = FirebaseFirestore.instance;
      debugPrint('[LABORATORIO] ADVERTENCIA: Usando instancia default de Firebase');
    }
    
    _tabController = TabController(
      length: 3, 
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != _tabController.previousIndex) {
        setState(() {});
        // Recargar datos cuando se cambia de pestaña manualmente
        if (!_tabController.indexIsChanging) {
          debugPrint('[LABORATORIO] Cambio de pestaña detectado - índice: ${_tabController.index}');
          _loadMuestras();
        }
      }
    });
    
    // Si estamos navegando directamente a la pestaña de documentación (tab 1),
    // dar un poco más de tiempo para que Firebase propague los cambios
    if (widget.initialTab == 1) {
      debugPrint('[LABORATORIO] Navegando a pestaña de documentación - esperando propagación de datos...');
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _loadMuestras();
        }
      });
    } else {
      _loadMuestras();
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recargar cuando la app vuelve a primer plano
      debugPrint('[LABORATORIO] App resumed - recargando muestras...');
      _loadMuestras();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar cada vez que se navega a esta pantalla
    debugPrint('[LABORATORIO] didChangeDependencies - recargando muestras...');
    _loadMuestras();
  }

  void _loadMuestras() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        debugPrint('[LABORATORIO] No hay usuario autenticado');
        return;
      }
      
      debugPrint('[LABORATORIO] NUEVO SISTEMA - Cargando muestras independientes para usuario: $userId');
      debugPrint('[LABORATORIO] Usando Firestore del proyecto: ${_firebaseManager.currentApp?.options.projectId}');
      
      // IMPORTANTE: Forzar obtención desde el servidor (no caché)
      // Esto asegura que obtenemos los datos más recientes
      final muestrasSnapshot = await _firestore
          .collection('muestras_laboratorio')
          .where('laboratorio_id', isEqualTo: userId)
          .get(const GetOptions(source: Source.server)); // ← Forzar desde servidor
      
      debugPrint('[LABORATORIO] Muestras independientes encontradas: ${muestrasSnapshot.docs.length}');
      
      // Ordenar manualmente por fecha (más recientes primero)
      final docs = muestrasSnapshot.docs.toList();
      
      // Siempre ordenar para consistencia
      debugPrint('[LABORATORIO] Ordenando muestras por fecha');
      docs.sort((a, b) {
        try {
          final fechaA = a.data()['fecha_toma'];
          final fechaB = b.data()['fecha_toma'];
          
          DateTime dateA;
          DateTime dateB;
          
          if (fechaA is Timestamp) {
            dateA = fechaA.toDate();
          } else if (fechaA is String) {
            dateA = DateTime.parse(fechaA);
          } else {
            dateA = DateTime.now();
          }
          
          if (fechaB is Timestamp) {
            dateB = fechaB.toDate();
          } else if (fechaB is String) {
            dateB = DateTime.parse(fechaB);
          } else {
            dateB = DateTime.now();
          }
          
          return dateB.compareTo(dateA); // Orden descendente
        } catch (e) {
          debugPrint('[LABORATORIO] Error ordenando: $e');
          return 0;
        }
      });
      
      // Convertir documentos a modelos tipados
      List<MuestraLaboratorioModel> todasLasMuestras = [];
      Set<String> transformacionIds = {}; // IDs de transformaciones a cargar
      
      for (var doc in docs) {
        try {
          final muestra = MuestraLaboratorioModel.fromMap(doc.data(), doc.id);
          todasLasMuestras.add(muestra);
          
          // Si es de una transformación, agregar a la lista para cargar
          if (muestra.origenTipo == 'transformacion') {
            transformacionIds.add(muestra.origenId);
          }
          
          debugPrint('[LABORATORIO] Muestra cargada:');
          debugPrint('  - ID: ${muestra.id}');
          debugPrint('  - Origen: ${muestra.origenTipo} - ${muestra.origenId}');
          debugPrint('  - Estado: ${muestra.estado}');
          debugPrint('  - Peso: ${muestra.pesoMuestra} kg');
          debugPrint('  - Fecha: ${muestra.fechaToma}');
        } catch (e) {
          debugPrint('[ERROR] Error al parsear muestra ${doc.id}: $e');
        }
      }
      
      // Cargar transformaciones en cache para filtrado por material
      if (transformacionIds.isNotEmpty) {
        debugPrint('[LABORATORIO] Cargando ${transformacionIds.length} transformaciones para filtrado');
        for (String transformacionId in transformacionIds) {
          try {
            final transformacion = await _transformacionService.obtenerTransformacion(transformacionId);
            _transformacionesCache[transformacionId] = transformacion;
          } catch (e) {
            debugPrint('[ERROR] Error al cargar transformación $transformacionId: $e');
            _transformacionesCache[transformacionId] = null;
          }
        }
      }
      
      debugPrint('[LABORATORIO] ========================================');
      debugPrint('[LABORATORIO] Total de muestras del usuario: ${todasLasMuestras.length}');
      
      // Imprimir todos los estados para debugging
      debugPrint('[LABORATORIO] Estados encontrados:');
      final estadosUnicos = todasLasMuestras.map((m) => m.estado).toSet();
      for (var estado in estadosUnicos) {
        final cantidad = todasLasMuestras.where((m) => m.estado == estado).length;
        debugPrint('[LABORATORIO]   - "$estado": $cantidad muestras');
      }
      
      // Clasificar las muestras por estado
      _muestrasAnalisis = todasLasMuestras.where((m) => 
        m.estado == 'pendiente_analisis'
      ).toList();
      
      // IMPORTANTE: La pestaña de documentación muestra muestras con análisis completado
      _muestrasDocumentacion = todasLasMuestras.where((m) => 
        m.estado == 'analisis_completado' // Estado exacto después del análisis
      ).toList();
      
      _muestrasFinalizadas = todasLasMuestras.where((m) => 
        m.estado == 'documentacion_completada' // Muestras completamente finalizadas
      ).toList();
      
      debugPrint('[LABORATORIO] RESULTADO DEL FILTRADO:');
      debugPrint('[LABORATORIO]   - Pendientes de Análisis: ${_muestrasAnalisis.length}');
      debugPrint('[LABORATORIO]   - Pendientes de Documentación: ${_muestrasDocumentacion.length}');
      debugPrint('[LABORATORIO]   - Finalizadas: ${_muestrasFinalizadas.length}');
      
      // Si hay muestras con análisis completado, mostrar sus IDs
      if (_muestrasDocumentacion.isNotEmpty) {
        debugPrint('[LABORATORIO] Muestras en pestaña Documentación:');
        for (var muestra in _muestrasDocumentacion) {
          debugPrint('[LABORATORIO]   - ${muestra.id.substring(0, 8)}: estado="${muestra.estado}"');
        }
      } else {
        debugPrint('[LABORATORIO] ⚠️ NO HAY muestras con estado "analisis_completado"');
        debugPrint('[LABORATORIO] Verificar en Firebase si el estado se está actualizando correctamente');
      }
      
      debugPrint('[LABORATORIO] ========================================');
      
    } catch (e) {
      debugPrint('[ERROR] Error cargando muestras independientes: $e');
      debugPrint('[ERROR] Tipo de error: ${e.runtimeType}');
      debugPrint('[ERROR] Stack trace: ${StackTrace.current}');
      
      // Verificar si es un error de permisos específicamente
      if (e.toString().contains('permission-denied')) {
        debugPrint('[ERROR] Es un error de permisos - verificando configuración...');
        debugPrint('[ERROR] Usuario ID usado en consulta: ${_authService.currentUser?.uid}');
        
        // Intentar una consulta más simple para debug
        try {
          debugPrint('[DEBUG] Intentando consulta simple sin filtros...');
          final testQuery = await _firestore
              .collection('muestras_laboratorio')
              .limit(1)
              .get();
          debugPrint('[DEBUG] Consulta simple exitosa, documentos: ${testQuery.docs.length}');
        } catch (testError) {
          debugPrint('[DEBUG] Consulta simple también falló: $testError');
        }
      }
      
      // Mostrar error al usuario con más detalles
      if (mounted) {
        String errorMessage = 'Error al cargar muestras';
        
        if (e.toString().contains('permission-denied')) {
          errorMessage = 'Error de permisos. El índice se está creando, intente en unos minutos.';
        } else if (e.toString().contains('index')) {
          errorMessage = 'Creando índice de base de datos. Intente nuevamente en 2-3 minutos.';
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filtro por material
            DropdownButtonFormField<String>(
              value: _selectedMaterial,
              decoration: const InputDecoration(
                labelText: 'Tipo de Material',
                border: OutlineInputBorder(),
              ),
              items: ['Todos', 'PEBD', 'PP', 'Multilaminado']
                  .map((material) => DropdownMenuItem(
                        value: material,
                        child: Text(material),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMaterial = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            // Filtro por tiempo
            DropdownButtonFormField<String>(
              value: _selectedTiempo,
              decoration: const InputDecoration(
                labelText: 'Periodo',
                border: OutlineInputBorder(),
              ),
              items: ['Esta Semana', 'Este Mes', 'Últimos tres meses', 'Este Año']
                  .map((time) => DropdownMenuItem(
                        value: time,
                        child: Text(time),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTiempo = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  // Método helper para verificar si un megalote contiene >50% del material seleccionado
  bool _megaloteContieneMaterial(TransformacionModel megalote, String material) {
    if (material == 'Todos') return true;
    
    // Calcular porcentaje del material en el megalote
    final lotesDelMaterial = megalote.lotesEntrada.where((lote) {
      final materialLote = lote.tipoMaterial.trim();
      final materialBuscado = material.trim();
      
      // Comparación directa
      if (materialLote == materialBuscado) {
        return true;
      }
      
      // Comparación case-insensitive
      if (materialLote.toUpperCase() == materialBuscado.toUpperCase()) {
        return true;
      }
      
      // Manejar el caso donde el material tiene prefijo "EPF-"
      String materialLoteSinPrefijo = materialLote;
      if (materialLote.toUpperCase().startsWith('EPF-')) {
        materialLoteSinPrefijo = materialLote.substring(4); // Remover "EPF-"
      }
      
      // Comparar sin prefijo
      if (materialLoteSinPrefijo.toUpperCase() == materialBuscado.toUpperCase()) {
        return true;
      }
      
      // También probar agregando el prefijo al material buscado
      final materialBuscadoConPrefijo = 'EPF-$materialBuscado';
      if (materialLote.toUpperCase() == materialBuscadoConPrefijo.toUpperCase()) {
        return true;
      }
      
      return false;
    }).toList();
    
    if (lotesDelMaterial.isEmpty) {
      return false;
    }
    
    final pesoMaterial = lotesDelMaterial.fold<double>(
      0, (sum, lote) => sum + lote.peso
    );
    
    final porcentaje = (pesoMaterial / megalote.pesoTotalEntrada) * 100;
    
    return porcentaje > 50; // Más del 50% del material
  }
  
  List<MuestraLaboratorioModel> get _muestrasFiltradas {
    List<MuestraLaboratorioModel> muestras;
    
    // Seleccionar muestras según la pestaña activa
    switch (_tabController.index) {
      case 0:
        muestras = _muestrasAnalisis;
        break;
      case 1:
        muestras = _muestrasDocumentacion;
        break;
      case 2:
        muestras = _muestrasFinalizadas;
        break;
      default:
        muestras = [];
    }
    
    // Aplicar filtros
    return muestras.where((muestra) {
      // Filtro por tiempo
      if (_selectedTiempo != 'Todos') {
        final ahora = DateTime.now();
        final fechaMuestra = muestra.fechaToma;
        
        switch (_selectedTiempo) {
          case 'Esta Semana':
            final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
            if (fechaMuestra.isBefore(inicioSemana)) return false;
            break;
          case 'Este Mes':
            if (fechaMuestra.month != ahora.month || fechaMuestra.year != ahora.year) return false;
            break;
          case 'Últimos tres meses':
            final tresMesesAtras = ahora.subtract(const Duration(days: 90));
            if (fechaMuestra.isBefore(tresMesesAtras)) return false;
            break;
          case 'Este Año':
            if (fechaMuestra.year != ahora.year) return false;
            break;
        }
      }
      
      // Filtro por material
      if (_selectedMaterial != 'Todos') {
        // Si la muestra viene de un megalote, verificar composición >50%
        if (muestra.origenTipo == 'transformacion') {
          // Buscar en cache primero
          final transformacion = _transformacionesCache[muestra.origenId];
          if (transformacion != null) {
            return _megaloteContieneMaterial(transformacion, _selectedMaterial);
          }
          // Si no está en cache, no podemos filtrar correctamente
          // Se cargará de forma asíncrona
          return true;
        }
      }
      
      return true;
    }).toList();
  }

  Color _getTabColor() {
    switch (_tabController.index) {
      case 0:
        return const Color(0xFF9333EA); // Morado para análisis
      case 1:
        return BioWayColors.warning; // Naranja para documentación  
      case 2:
        return BioWayColors.success; // Verde para finalizados
      default:
        return const Color(0xFF9333EA);
    }
  }
  
  double _calcularPesoTotal() {
    double pesoTotal = 0.0;
    
    // NUEVO SISTEMA: Sumar el peso usando el modelo tipado
    for (var muestra in _muestrasFiltradas) {
      pesoTotal += muestra.pesoMuestra;
    }
    
    return pesoTotal;
  }

  void _onBottomNavTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/laboratorio_inicio');
        break;
      case 1:
        // Ya estamos en muestras
        break;
      case 2:
        Navigator.pushNamed(context, '/laboratorio_ayuda');
        break;
      case 3:
        Navigator.pushNamed(context, '/laboratorio_perfil');
        break;
    }
  }

  void _navigateToNewMuestra() async {
    HapticFeedback.lightImpact();
    
    // Navegar directamente al escáner QR (como Reciclador y Transformador)
    final qrCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const SharedQRScannerScreen(),
      ),
    );
    
    if (qrCode != null && mounted) {
      // Verificar si es un código QR de muestra de megalote
      if (qrCode.startsWith('MUESTRA-MEGALOTE-')) {
        // Es una muestra de megalote, ir directamente al formulario
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaboratorioTomaMuestraMegaloteScreen(
              qrCode: qrCode,
            ),
          ),
        );
      } else {
        // Es un lote normal, extraer el ID y procesar
        final loteId = QRUtils.extractLoteIdFromQR(qrCode);
        
        // Navegar a la pantalla de registro de muestras
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaboratorioRegistroMuestrasScreen(
              initialMuestraId: loteId,
              isMegaloteSample: false,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF9333EA), // Morado laboratorio
          elevation: 0,
          title: const Text(
            'Gestión de Muestras',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: _showFilterDialog,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF9333EA), // Morado laboratorio
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF9333EA), // Morado laboratorio
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Análisis'),
                  Tab(text: 'Documentación'),
                  Tab(text: 'Finalizadas'),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Lista de muestras
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      debugPrint('[LABORATORIO] Actualizando pestaña Análisis...');
                      _loadMuestras();
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    color: const Color(0xFF9333EA),
                    child: _buildTabContent(),
                  ),
                  RefreshIndicator(
                    onRefresh: () async {
                      debugPrint('[LABORATORIO] Actualizando pestaña Documentación...');
                      _loadMuestras();
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    color: BioWayColors.warning,
                    child: _buildTabContent(),
                  ),
                  RefreshIndicator(
                    onRefresh: () async {
                      debugPrint('[LABORATORIO] Actualizando pestaña Finalizadas...');
                      _loadMuestras();
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    color: BioWayColors.success,
                    child: _buildTabContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: EcoceBottomNavigation(
          selectedIndex: _selectedIndex,
          onItemTapped: _onBottomNavTapped,
          primaryColor: const Color(0xFF9333EA),
          items: const [
            NavigationItem(
              icon: Icons.home,
              label: 'Inicio',
              testKey: 'laboratorio_nav_inicio',
            ),
            NavigationItem(
              icon: Icons.science,
              label: 'Muestras',
              testKey: 'laboratorio_nav_muestras',
            ),
            NavigationItem(
              icon: Icons.help_outline,
              label: 'Ayuda',
              testKey: 'laboratorio_nav_ayuda',
            ),
            NavigationItem(
              icon: Icons.person,
              label: 'Perfil',
              testKey: 'laboratorio_nav_perfil',
            ),
          ],
          fabConfig: FabConfig(
            icon: Icons.add,
            onPressed: _navigateToNewMuestra,
            tooltip: 'Nueva muestra',
          ),
        ),
        floatingActionButton: EcoceFloatingActionButton(
          onPressed: _navigateToNewMuestra,
          icon: Icons.add,
          backgroundColor: const Color(0xFF9333EA),
          tooltip: 'Nueva muestra',
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF9333EA)),
      );
    }
    
    final tabColor = _getTabColor();
    
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100), // Espacio para el FAB
      children: [
        // Filtros
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Filtro de materiales
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Todos', 'PEBD', 'PP', 'Multilaminado'].map((material) {
                    final isSelected = _selectedMaterial == material;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(material),
                        selected: isSelected,
                        selectedColor: tabColor.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? tabColor : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedMaterial = material;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              // Filtros de tiempo y presentación
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownFilter(
                      label: 'Tiempo',
                      value: _selectedTiempo,
                      items: ['Esta Semana', 'Este Mes', 'Últimos tres meses', 'Este Año'],
                      onChanged: (value) {
                        setState(() {
                          _selectedTiempo = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Tarjeta de estadísticas con diseño moderno
        Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: tabColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.science, color: tabColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _muestrasFiltradas.length.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Muestras',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.scale, color: Colors.orange, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_calcularPesoTotal().toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Peso Total',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Lista de muestras o mensaje de vacío
        if (_muestrasFiltradas.isEmpty) ...[
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _tabController.index == 0 ? Icons.analytics : 
                  _tabController.index == 1 ? Icons.upload_file : Icons.check_circle,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  _tabController.index == 0 ? 'No hay muestras pendientes de análisis' :
                  _tabController.index == 1 ? 'No hay muestras pendientes de documentación' :
                  'No hay muestras finalizadas',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Desliza hacia abajo para actualizar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
                if (_tabController.index == 0)
                  ElevatedButton.icon(
                    onPressed: _navigateToNewMuestra,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Escanear Nueva Muestra'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9333EA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ] else ...[
          // Lista de todas las muestras
          ..._muestrasFiltradas.map((muestra) => _buildMuestraCard(muestra)),
        ],
        
        // Espacio adicional al final
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: BioWayColors.backgroundGrey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: BioWayColors.darkGreen),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  color: BioWayColors.darkGreen,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
  
  Widget _buildMuestraCard(MuestraLaboratorioModel muestra) {
    final tabColor = _getTabColor();
    final muestraId = muestra.id;
    final tipoDisplay = muestra.tipo == 'megalote' ? 'Megalote' : 'Lote';
    final origenDisplay = muestra.origenId.length > 8 ? muestra.origenId.substring(0, 8).toUpperCase() : muestra.origenId.toUpperCase();
    final peso = muestra.pesoMuestra;
    final fecha = muestra.fechaToma;
    
    // Determinar estado y color
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (_tabController.index) {
      case 0: // Análisis
        statusColor = const Color(0xFF9333EA);
        statusText = 'Pendiente de análisis';
        statusIcon = Icons.analytics;
        break;
      case 1: // Documentación
        statusColor = BioWayColors.warning;
        statusText = 'Pendiente de documentación';
        statusIcon = Icons.upload_file;
        break;
      case 2: // Finalizadas
        statusColor = BioWayColors.success;
        statusText = 'Completada';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Estado desconocido';
        statusIcon = Icons.help_outline;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _tabController.index == 2 ? null : () => _navigateToMuestraDetail(muestra),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estilo consistente
              Row(
                children: [
                  // Icono de estado
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      muestra.tipo == 'megalote' ? Icons.science : Icons.biotech,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Información principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'MUESTRA: ${_formatMuestraId(muestraId)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9333EA).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF9333EA).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    muestra.tipo == 'megalote' ? Icons.layers : Icons.inventory_2,
                                    size: 12,
                                    color: const Color(0xFF9333EA),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    tipoDisplay,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF9333EA),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Botón de acción
                  if (_tabController.index != 2)
                    IconButton(
                      icon: Icon(
                        _tabController.index == 0 ? Icons.analytics : Icons.upload_file,
                        color: statusColor,
                      ),
                      onPressed: () => _navigateToMuestraDetail(muestra),
                      tooltip: _tabController.index == 0 ? 'Realizar análisis' : 'Subir documentos',
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Información principal
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.qr_code_2,
                      label: 'Origen',
                      value: origenDisplay,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.scale,
                      label: 'Peso',
                      value: '${peso.toStringAsFixed(2)} kg',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.calendar_today,
                      label: 'Fecha',
                      value: '${fecha.day}/${fecha.month}/${fecha.year}',
                    ),
                  ),
                ],
              ),
              
              // Información adicional
              if (muestra.laboratorioFolio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Folio Lab: ${muestra.laboratorioFolio}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Color _getMaterialColor(String material) {
    switch (material.toUpperCase()) {
      case 'PEBD':
        return BioWayColors.pebdPink;
      case 'PP':
        return BioWayColors.ppPurple;
      case 'MULTILAMINADO':
        return BioWayColors.multilaminadoBrown;
      default:
        return Colors.grey;
    }
  }
  
  String _formatMuestraId(String id) {
    if (id.isEmpty) return 'SIN-ID';
    if (id.length >= 8) {
      return id.substring(0, 8).toUpperCase();
    }
    return id.toUpperCase();
  }
  
  void _navigateToMuestraDetail(MuestraLaboratorioModel muestra) {
    HapticFeedback.lightImpact();
    
    // NUEVO SISTEMA: Navegar con el modelo tipado
    if (_tabController.index == 0) {
      // Navegar al formulario de análisis
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LaboratorioFormulario(
            muestraId: muestra.id,
            transformacionId: muestra.origenId, // El origen es la transformación
            datosMuestra: muestra.toMap(), // Convertir a Map para compatibilidad temporal
          ),
        ),
      ).then((_) => _loadMuestras()); // Recargar al volver
    } else if (_tabController.index == 1) {
      // Navegar a la carga de documentación
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LaboratorioDocumentacion(
            muestraId: muestra.id,
            transformacionId: muestra.origenId, // El origen es la transformación
          ),
        ),
      ).then((_) => _loadMuestras()); // Recargar al volver
    }
  }
}