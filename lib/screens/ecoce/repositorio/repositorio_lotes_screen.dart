import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../shared/utils/navigation_utils.dart';
import '../shared/utils/material_utils.dart';
import '../shared/widgets/lote_card_unified.dart';
import 'widgets/dashboard_stats.dart';
import 'widgets/filters_sheet.dart';
import 'lote_detalle_screen.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../origen/origen_inicio_screen.dart';
import '../origen/origen_lotes_screen.dart';
import '../shared/ecoce_ayuda_screen.dart';
import '../shared/ecoce_perfil_screen.dart';
import '../origen/origen_crear_lote_screen.dart';
import '../reciclador/reciclador_inicio.dart';
import '../reciclador/reciclador_administracion_lotes.dart';
// import '../transporte/transporte_lot_management_screen.dart';
// import '../transporte/transporte_delivery_screen.dart';
import '../shared/widgets/qr_scanner_widget.dart';

class RepositorioLotesScreen extends StatefulWidget {
  final Color primaryColor;
  final String tipoUsuario;
  
  const RepositorioLotesScreen({
    super.key,
    required this.primaryColor,
    required this.tipoUsuario,
  });

  @override
  State<RepositorioLotesScreen> createState() => _RepositorioLotesScreenState();
}

class _RepositorioLotesScreenState extends State<RepositorioLotesScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Estados
  List<Map<String, dynamic>> _allLotes = [];
  List<Map<String, dynamic>> _filteredLotes = [];
  bool _isLoading = true;
  int _itemsPerPage = 10;
  int _currentTabIndex = 0;
  
  // Filtros
  String? _selectedMaterial;
  String? _selectedUbicacion;
  // final bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadLotes();
    _calculateItemsPerPage();
  }

  void _calculateItemsPerPage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenHeight = MediaQuery.of(context).size.height;
      final availableHeight = screenHeight - 400; // Header, tabs, etc.
      final itemHeight = 120.0; // Altura aproximada de cada tarjeta
      _itemsPerPage = (availableHeight / itemHeight).floor().clamp(5, 15);
      
      final pageCount = (_filteredLotes.length / _itemsPerPage).ceil();
      _tabController = TabController(length: pageCount.clamp(1, 10), vsync: this);
      _tabController.addListener(() {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      });
      
      setState(() {});
    });
  }

  void _loadLotes() {
    // Simular carga de datos
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _allLotes = _generateMockLotes();
        _filteredLotes = List.from(_allLotes);
        _isLoading = false;
      });
      _calculateItemsPerPage();
    });
  }

  List<Map<String, dynamic>> _generateMockLotes() {
    // Simulaciones de trazabilidad completa
    final simulaciones = <Map<String, dynamic>>[];
    
    // SIMULACIÓN 1: Lote completo desde Acopiador hasta Transformador
    simulaciones.add({
      'id': 'LOT-A0001-2025',
      'firebaseId': 'FID_acopiador_001',
      'material': 'PET',
      'peso': 450.5,
      'ubicacionActual': 'Transformador PlastiTech',
      'fechaCreacion': DateTime.now().subtract(const Duration(days: 15)),
      'estado': 'Completado',
      'origen': 'Centro de Acopio EcoNorte',
      'historialTrazabilidad': [
        {
          'etapa': 'Origen',
          'actor': 'Centro de Acopio EcoNorte',
          'tipo': 'Acopiador',
          'fecha': DateTime.now().subtract(const Duration(days: 15)),
          'accion': 'Creación de lote',
          'peso': 450.5,
          'detalles': 'Recolección de botellas PET transparentes'
        },
        {
          'etapa': 'Transporte',
          'actor': 'Transportes Verdes S.A.',
          'tipo': 'Transportista',
          'fecha': DateTime.now().subtract(const Duration(days: 14)),
          'accion': 'Recolección y transporte',
          'peso': 450.5,
          'detalles': 'Ruta: EcoNorte → ReciclaPlus'
        },
        {
          'etapa': 'Reciclaje',
          'actor': 'ReciclaPlus',
          'tipo': 'Reciclador',
          'fecha': DateTime.now().subtract(const Duration(days: 12)),
          'accion': 'Procesamiento de material',
          'peso': 420.0,
          'detalles': 'Trituración y lavado, pérdida del 6.7% por contaminantes'
        },
        {
          'etapa': 'Transporte',
          'actor': 'LogisTrans México',
          'tipo': 'Transportista',
          'fecha': DateTime.now().subtract(const Duration(days: 8)),
          'accion': 'Transporte a transformador',
          'peso': 420.0,
          'detalles': 'Ruta: ReciclaPlus → PlastiTech'
        },
        {
          'etapa': 'Transformación',
          'actor': 'Transformador PlastiTech',
          'tipo': 'Transformador',
          'fecha': DateTime.now().subtract(const Duration(days: 5)),
          'accion': 'Producción de pellets',
          'peso': 400.0,
          'detalles': 'Conversión a pellets de PET grado alimenticio'
        },
      ],
    });

    // SIMULACIÓN 2: Lote desde Planta de Separación hasta Laboratorio
    simulaciones.add({
      'id': 'LOT-P0002-2025',
      'firebaseId': 'FID_planta_002',
      'material': 'HDPE',
      'peso': 320.0,
      'ubicacionActual': 'Laboratorio QualityTest',
      'fechaCreacion': DateTime.now().subtract(const Duration(days: 10)),
      'estado': 'En Análisis',
      'origen': 'Planta de Separación MetroWaste',
      'historialTrazabilidad': [
        {
          'etapa': 'Origen',
          'actor': 'Planta de Separación MetroWaste',
          'tipo': 'Planta de Separación',
          'fecha': DateTime.now().subtract(const Duration(days: 10)),
          'accion': 'Separación y clasificación',
          'peso': 320.0,
          'detalles': 'HDPE natural de envases de leche'
        },
        {
          'etapa': 'Transporte',
          'actor': 'EcoLogística',
          'tipo': 'Transportista',
          'fecha': DateTime.now().subtract(const Duration(days: 9)),
          'accion': 'Transporte directo',
          'peso': 320.0,
          'detalles': 'Ruta: MetroWaste → RecycleMax'
        },
        {
          'etapa': 'Reciclaje',
          'actor': 'RecycleMax',
          'tipo': 'Reciclador',
          'fecha': DateTime.now().subtract(const Duration(days: 7)),
          'accion': 'Procesamiento inicial',
          'peso': 310.0,
          'detalles': 'Limpieza y preparación para análisis'
        },
        {
          'etapa': 'Transporte',
          'actor': 'TransLab Express',
          'tipo': 'Transportista',
          'fecha': DateTime.now().subtract(const Duration(days: 4)),
          'accion': 'Transporte a laboratorio',
          'peso': 310.0,
          'detalles': 'Ruta: RecycleMax → QualityTest'
        },
        {
          'etapa': 'Análisis',
          'actor': 'Laboratorio QualityTest',
          'tipo': 'Laboratorio',
          'fecha': DateTime.now().subtract(const Duration(days: 2)),
          'accion': 'Análisis de calidad',
          'peso': 310.0,
          'detalles': 'Pruebas de pureza y contaminantes en proceso'
        },
      ],
    });

    // SIMULACIÓN 3: Lote con ruta completa (Transformador + Laboratorio)
    simulaciones.add({
      'id': 'LOT-A0003-2025',
      'firebaseId': 'FID_completo_003',
      'material': 'PP',
      'peso': 680.0,
      'ubicacionActual': 'Completado - Múltiples destinos',
      'fechaCreacion': DateTime.now().subtract(const Duration(days: 20)),
      'estado': 'Completado',
      'origen': 'Centro de Acopio SurVerde',
      'historialTrazabilidad': [
        {
          'etapa': 'Origen',
          'actor': 'Centro de Acopio SurVerde',
          'tipo': 'Acopiador',
          'fecha': DateTime.now().subtract(const Duration(days: 20)),
          'accion': 'Recolección inicial',
          'peso': 680.0,
          'detalles': 'Tapas y envases de PP multicolor'
        },
        {
          'etapa': 'Transporte',
          'actor': 'Rutas Ecológicas',
          'tipo': 'Transportista',
          'fecha': DateTime.now().subtract(const Duration(days: 19)),
          'accion': 'Primer transporte',
          'peso': 680.0,
          'detalles': 'Ruta: SurVerde → MegaRecicla'
        },
        {
          'etapa': 'Reciclaje',
          'actor': 'MegaRecicla Industrial',
          'tipo': 'Reciclador',
          'fecha': DateTime.now().subtract(const Duration(days: 17)),
          'accion': 'Procesamiento y separación',
          'peso': 650.0,
          'detalles': 'Separación por colores, trituración y lavado'
        },
        {
          'etapa': 'División',
          'actor': 'MegaRecicla Industrial',
          'tipo': 'Reciclador',
          'fecha': DateTime.now().subtract(const Duration(days: 15)),
          'accion': 'División del lote',
          'peso': 650.0,
          'detalles': 'Lote dividido: 500kg a Transformador, 150kg a Laboratorio'
        },
        {
          'etapa': 'Transporte',
          'actor': 'MultiTrans Logistics',
          'tipo': 'Transportista',
          'fecha': DateTime.now().subtract(const Duration(days: 14)),
          'accion': 'Transporte múltiple',
          'peso': 500.0,
          'detalles': 'Ruta 1: MegaRecicla → PolyTransform'
        },
        {
          'etapa': 'Transformación',
          'actor': 'PolyTransform Industries',
          'tipo': 'Transformador',
          'fecha': DateTime.now().subtract(const Duration(days: 10)),
          'accion': 'Producción de pellets',
          'peso': 480.0,
          'detalles': 'Pellets de PP para inyección automotriz'
        },
        {
          'etapa': 'Transporte',
          'actor': 'LabExpress',
          'tipo': 'Transportista',
          'fecha': DateTime.now().subtract(const Duration(days: 14)),
          'accion': 'Transporte a laboratorio',
          'peso': 150.0,
          'detalles': 'Ruta 2: MegaRecicla → TestLab Pro'
        },
        {
          'etapa': 'Análisis',
          'actor': 'TestLab Pro',
          'tipo': 'Laboratorio',
          'fecha': DateTime.now().subtract(const Duration(days: 8)),
          'accion': 'Análisis completo',
          'peso': 150.0,
          'detalles': 'Certificación de calidad completada'
        },
      ],
    });

    // SIMULACIÓN 4: Lote en tránsito
    simulaciones.add({
      'id': 'LOT-P0004-2025',
      'firebaseId': 'FID_transito_004',
      'material': 'LDPE',
      'peso': 280.0,
      'ubicacionActual': 'En Tránsito - Transportes Verdes',
      'fechaCreacion': DateTime.now().subtract(const Duration(days: 5)),
      'estado': 'En Proceso',
      'origen': 'Planta de Separación EcoSort',
      'historialTrazabilidad': [
        {
          'etapa': 'Origen',
          'actor': 'Planta de Separación EcoSort',
          'tipo': 'Planta de Separación',
          'fecha': DateTime.now().subtract(const Duration(days: 5)),
          'accion': 'Separación de LDPE',
          'peso': 280.0,
          'detalles': 'Film plástico transparente'
        },
        {
          'etapa': 'Transporte',
          'actor': 'Transportes Verdes S.A.',
          'tipo': 'Transportista',
          'fecha': DateTime.now().subtract(const Duration(days: 4)),
          'accion': 'Recolección',
          'peso': 280.0,
          'detalles': 'En ruta hacia GreenRecycle'
        },
      ],
    });

    // SIMULACIÓN 5: Lote con múltiples transformaciones
    simulaciones.add({
      'id': 'LOT-A0005-2025',
      'firebaseId': 'FID_multi_005',
      'material': 'PVC',
      'peso': 150.0,
      'ubicacionActual': 'Transformador SecondLife',
      'fechaCreacion': DateTime.now().subtract(const Duration(days: 25)),
      'estado': 'Completado',
      'origen': 'Centro de Acopio Industrial Norte',
      'historialTrazabilidad': [
        {
          'etapa': 'Origen',
          'actor': 'Centro de Acopio Industrial Norte',
          'tipo': 'Acopiador',
          'fecha': DateTime.now().subtract(const Duration(days: 25)),
          'accion': 'Recolección industrial',
          'peso': 150.0,
          'detalles': 'Tubería y perfiles de PVC'
        },
        {
          'etapa': 'Transporte',
          'actor': 'CargaTech',
          'tipo': 'Transportista',
          'fecha': DateTime.now().subtract(const Duration(days: 24)),
          'accion': 'Transporte especializado',
          'peso': 150.0,
          'detalles': 'Manejo especial por material PVC'
        },
        {
          'etapa': 'Reciclaje',
          'actor': 'PVC Recycling Experts',
          'tipo': 'Reciclador',
          'fecha': DateTime.now().subtract(const Duration(days: 22)),
          'accion': 'Procesamiento especializado',
          'peso': 140.0,
          'detalles': 'Separación de aditivos y estabilizadores'
        },
        {
          'etapa': 'Transporte',
          'actor': 'SecureLogistics',
          'tipo': 'Transportista',
          'fecha': DateTime.now().subtract(const Duration(days: 18)),
          'accion': 'Transporte seguro',
          'peso': 140.0,
          'detalles': 'Ruta: PVC Experts → SecondLife'
        },
        {
          'etapa': 'Transformación',
          'actor': 'Transformador SecondLife',
          'tipo': 'Transformador',
          'fecha': DateTime.now().subtract(const Duration(days: 15)),
          'accion': 'Producción de nuevos perfiles',
          'peso': 135.0,
          'detalles': 'Perfiles de PVC para construcción'
        },
      ],
    });

    // Agregar más lotes variados para completar la lista
    for (int i = 6; i <= 30; i++) {
      final materials = ['PET', 'HDPE', 'LDPE', 'PP', 'PS', 'PVC', 'Otros'];
      final estados = ['En Proceso', 'Completado', 'En Análisis', 'En Tránsito'];
      final origenes = [
        'Centro de Acopio EcoNorte',
        'Planta de Separación MetroWaste',
        'Centro de Acopio SurVerde',
        'Planta de Separación EcoSort',
        'Centro de Acopio Industrial Norte'
      ];
      
      simulaciones.add({
        'id': 'LOT-${i.toString().padLeft(4, '0')}-2025',
        'firebaseId': 'FID_auto_$i',
        'material': materials[i % materials.length],
        'peso': 100.0 + (i * 15.5 % 500),
        'ubicacionActual': _getRandomUbicacion(i),
        'fechaCreacion': DateTime.now().subtract(Duration(days: i)),
        'estado': estados[i % estados.length],
        'origen': origenes[i % origenes.length],
        'historialTrazabilidad': _generateSimpleHistory(i),
      });
    }
    
    return simulaciones;
  }
  
  String _getRandomUbicacion(int index) {
    final ubicaciones = [
      'Transformador PlastiTech',
      'Laboratorio QualityTest',
      'ReciclaPlus',
      'En Tránsito - Transportes Verdes',
      'MegaRecicla Industrial',
      'TestLab Pro',
      'PolyTransform Industries'
    ];
    return ubicaciones[index % ubicaciones.length];
  }
  
  List<Map<String, dynamic>> _generateSimpleHistory(int index) {
    // Generar un historial simple para lotes adicionales
    final history = <Map<String, dynamic>>[];
    final stages = index % 4 + 2; // Entre 2 y 5 etapas
    
    for (int i = 0; i < stages; i++) {
      history.add({
        'etapa': _getEtapaNombre(i),
        'actor': 'Actor Simulado $index-$i',
        'tipo': _getTipoActor(i),
        'fecha': DateTime.now().subtract(Duration(days: index - i * 2)),
        'accion': _getAccion(i),
        'peso': 100.0 + (index * 15.5 % 500) - (i * 5),
        'detalles': 'Proceso simulado etapa ${i + 1}'
      });
    }
    
    return history;
  }
  
  String _getEtapaNombre(int index) {
    final etapas = ['Origen', 'Transporte', 'Reciclaje', 'Transporte', 'Transformación', 'Análisis'];
    return etapas[index % etapas.length];
  }
  
  String _getTipoActor(int index) {
    final tipos = ['Acopiador', 'Transportista', 'Reciclador', 'Transportista', 'Transformador', 'Laboratorio'];
    return tipos[index % tipos.length];
  }
  
  String _getAccion(int index) {
    final acciones = ['Creación de lote', 'Transporte', 'Procesamiento', 'Transporte', 'Transformación', 'Análisis'];
    return acciones[index % acciones.length];
  }

  void _filterLotes(String query) {
    setState(() {
      _filteredLotes = _allLotes.where((lote) {
        final matchesSearch = query.isEmpty || 
            lote['id'].toString().toLowerCase().contains(query.toLowerCase());
        final matchesMaterial = _selectedMaterial == null || 
            lote['material'] == _selectedMaterial;
        final matchesUbicacion = _selectedUbicacion == null || 
            lote['ubicacionActual'] == _selectedUbicacion;
            
        return matchesSearch && matchesMaterial && matchesUbicacion;
      }).toList();
    });
    _calculateItemsPerPage();
  }

  void _showFiltersSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FiltersSheet(
        selectedMaterial: _selectedMaterial,
        selectedUbicacion: _selectedUbicacion,
        onApplyFilters: (material, ubicacion) {
          setState(() {
            _selectedMaterial = material;
            _selectedUbicacion = ubicacion;
          });
          _filterLotes(_searchController.text);
        },
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> lote) {
    HapticFeedback.lightImpact();
    NavigationUtils.navigateWithFade(
      context,
      LoteDetalleScreen(
        lote: lote,
        primaryColor: widget.primaryColor,
      ),
    );
  }

  Widget _buildSearchBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      margin: EdgeInsets.all(screenWidth * 0.04),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterLotes,
                decoration: InputDecoration(
                  hintText: 'Buscar por ID de lote...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: screenWidth * 0.035,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _filterLotes('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Container(
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                IconButton(
                  onPressed: _showFiltersSheet,
                  icon: Icon(
                    Icons.filter_list,
                    color: widget.primaryColor,
                  ),
                  tooltip: 'Filtros',
                ),
                if (_selectedMaterial != null || _selectedUbicacion != null)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLotesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredLotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron lotes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (_selectedMaterial != null || _selectedUbicacion != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedMaterial = null;
                    _selectedUbicacion = null;
                  });
                  _filterLotes(_searchController.text);
                },
                child: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      );
    }

    final pageCount = (_filteredLotes.length / _itemsPerPage).ceil();
    
    if (pageCount <= 1) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filteredLotes.length,
        itemBuilder: (context, index) {
          return LoteCard.repositorio(
            lote: _filteredLotes[index],
            onTap: () => _navigateToDetail(_filteredLotes[index]),
          );
        },
      );
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: widget.primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: widget.primaryColor,
            tabs: List.generate(
              pageCount,
              (index) => Tab(text: 'Página ${index + 1}'),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(pageCount, (pageIndex) {
              final startIndex = pageIndex * _itemsPerPage;
              final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredLotes.length);
              final pageLotes = _filteredLotes.sublist(startIndex, endIndex);
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: pageLotes.length,
                itemBuilder: (context, index) {
                  return LoteCard.repositorio(
                    lote: pageLotes[index],
                    onTap: () => _navigateToDetail(pageLotes[index]),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: widget.primaryColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Repositorio de Lotes',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance para centrar el título
                ],
              ),
            ),
            
            // Dashboard Stats
            DashboardStats(
              totalLotes: _filteredLotes.length,
              totalPeso: _filteredLotes.fold(
                0.0,
                (sum, lote) => sum + (lote['peso'] as double),
              ),
              primaryColor: widget.primaryColor,
            ),
            
            // Search and Filters
            _buildSearchBar(),
            
            // Lotes List with Tabs
            Expanded(
              child: _buildLotesList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget? _buildBottomNavigation() {
    // Determinar índice según el tipo de usuario
    int selectedIndex = 2; // Por defecto, repositorio es el tercero
    
    List<NavigationItem> items;
    FabConfig? fabConfig;
    
    switch (widget.tipoUsuario.toLowerCase()) {
      case 'acopiador':
      case 'origen':
        items = EcoceNavigationConfigs.origenItems;
        fabConfig = FabConfig(
          icon: Icons.add,
          onPressed: () {
            NavigationUtils.navigateWithFade(
              context,
              const OrigenCrearLoteScreen(),
            );
          },
        );
        break;
      case 'reciclador':
        items = EcoceNavigationConfigs.recicladorItems;
        fabConfig = FabConfig(
          icon: Icons.add,
          onPressed: () {
            NavigationUtils.navigateWithFade(
              context,
              QRScannerWidget(
                title: 'Escanear Lote',
                subtitle: 'Escanea el código QR del lote',
                onCodeScanned: (code) {
                  Navigator.pop(context);
                  // Handle scan result
                },
                primaryColor: widget.primaryColor,
              ),
            );
          },
        );
        break;
      case 'transportista':
      case 'transporte':
        items = EcoceNavigationConfigs.transporteItems;
        fabConfig = null;
        break;
      default:
        return null;
    }
    
    return EcoceBottomNavigation(
      selectedIndex: selectedIndex,
      onItemTapped: (index) {
        if (index == selectedIndex) return; // Ya estamos en repositorio
        
        _navigateBasedOnUserType(index);
      },
      primaryColor: widget.primaryColor,
      items: items,
      fabConfig: fabConfig,
    );
  }
  
  Widget? _buildFloatingActionButton() {
    switch (widget.tipoUsuario.toLowerCase()) {
      case 'acopiador':
      case 'origen':
        return EcoceFloatingActionButton(
          onPressed: () {
            NavigationUtils.navigateWithFade(
              context,
              const OrigenCrearLoteScreen(),
            );
          },
          icon: Icons.add,
          backgroundColor: widget.primaryColor,
        );
      case 'reciclador':
        return EcoceFloatingActionButton(
          onPressed: () {
            NavigationUtils.navigateWithFade(
              context,
              QRScannerWidget(
                title: 'Escanear Lote',
                subtitle: 'Escanea el código QR del lote',
                onCodeScanned: (code) {
                  Navigator.pop(context);
                  // Handle scan result
                },
                primaryColor: widget.primaryColor,
              ),
            );
          },
          icon: Icons.add,
          backgroundColor: widget.primaryColor,
        );
      default:
        return null;
    }
  }
  
  void _navigateBasedOnUserType(int index) {
    switch (widget.tipoUsuario.toLowerCase()) {
      case 'acopiador':
      case 'origen':
        _navigateOrigen(index);
        break;
      case 'reciclador':
        _navigateReciclador(index);
        break;
      case 'transportista':
      case 'transporte':
        _navigateTransporte(index);
        break;
    }
  }
  
  void _navigateOrigen(int index) {
    switch (index) {
      case 0:
        NavigationUtils.navigateWithFade(
          context,
          const OrigenInicioScreen(),
          replacement: true,
        );
        break;
      case 1:
        NavigationUtils.navigateWithFade(
          context,
          const OrigenLotesScreen(),
          replacement: true,
        );
        break;
      case 3:
        NavigationUtils.navigateWithFade(
          context,
          const EcoceAyudaScreen(),
          replacement: true,
        );
        break;
      case 4:
        NavigationUtils.navigateWithFade(
          context,
          const EcocePerfilScreen(),
          replacement: true,
        );
        break;
    }
  }
  
  void _navigateReciclador(int index) {
    switch (index) {
      case 0:
        NavigationUtils.navigateWithFade(
          context,
          const RecicladorInicio(),
          replacement: true,
        );
        break;
      case 1:
        NavigationUtils.navigateWithFade(
          context,
          const RecicladorAdministracionLotes(),
          replacement: true,
        );
        break;
      case 3:
        NavigationUtils.navigateWithFade(
          context,
          const EcoceAyudaScreen(),
          replacement: true,
        );
        break;
      case 4:
        NavigationUtils.navigateWithFade(
          context,
          const EcocePerfilScreen(),
          replacement: true,
        );
        break;
    }
  }
  
  void _navigateTransporte(int index) {
    switch (index) {
      case 0:
        // NavigationUtils.navigateWithFade(
        //   context,
        //   const TransporteLotManagementScreen(),
        //   replacement: true,
        // );
        Navigator.pushReplacementNamed(context, '/transporte_inicio');
        break;
      case 1:
        // NavigationUtils.navigateWithFade(
        //   context,
        //   const TransporteDeliveryScreen(),
        //   replacement: true,
        // );
        Navigator.pushReplacementNamed(context, '/transporte_entregar');
        break;
      case 3:
        NavigationUtils.navigateWithFade(
          context,
          const EcoceAyudaScreen(),
          replacement: true,
        );
        break;
      case 4:
        NavigationUtils.navigateWithFade(
          context,
          const EcocePerfilScreen(),
          replacement: true,
        );
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}