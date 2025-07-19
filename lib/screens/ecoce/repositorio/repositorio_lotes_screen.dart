import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../shared/utils/navigation_utils.dart';
import '../shared/utils/material_utils.dart';
import 'widgets/lote_card.dart';
import 'widgets/dashboard_stats.dart';
import 'widgets/filters_sheet.dart';
import 'lote_detalle_screen.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../origen/origen_inicio_screen.dart';
import '../origen/origen_lotes_screen.dart';
import '../origen/origen_ayuda.dart';
import '../origen/origen_perfil.dart';
import '../origen/origen_crear_lote_screen.dart';
import '../reciclador/reciclador_inicio.dart';
import '../reciclador/reciclador_administracion_lotes.dart';
import '../reciclador/reciclador_ayuda.dart';
import '../reciclador/reciclador_perfil.dart';
import '../reciclador/reciclador_escaneo.dart';
import '../transporte/transporte_escaneo.dart';
import '../transporte/transporte_entregar_screen.dart';
import '../transporte/transporte_ayuda_screen.dart';
import '../transporte/transporte_perfil_screen.dart';

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
  bool _showFilters = false;

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
    final materials = ['PET', 'HDPE', 'LDPE', 'PP', 'PS', 'PVC', 'Otros'];
    final ubicaciones = [
      'Acopiador Norte',
      'Planta de Separación Sur',
      'Reciclador Este',
      'Transformador Oeste',
      'En Tránsito',
      'Laboratorio Central'
    ];
    
    return List.generate(50, (index) {
      final randomMaterial = materials[index % materials.length];
      final randomUbicacion = ubicaciones[index % ubicaciones.length];
      final randomPeso = 50.0 + (index * 7.5 % 200);
      
      return {
        'id': 'LOT${(1000 + index).toString()}',
        'firebaseId': 'FID_${index}x7h9k3',
        'material': randomMaterial,
        'peso': randomPeso,
        'ubicacionActual': randomUbicacion,
        'fechaCreacion': DateTime.now().subtract(Duration(days: index * 2)),
        'estado': index % 3 == 0 ? 'En Proceso' : 'Completado',
        'origen': 'Centro de Acopio ${["Norte", "Sur", "Este", "Oeste"][index % 4]}',
      };
    });
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
          return LoteCard(
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
                  return LoteCard(
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
              const QRScannerScreen(),
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
              const QRScannerScreen(),
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
          const OrigenAyudaScreen(),
          replacement: true,
        );
        break;
      case 4:
        NavigationUtils.navigateWithFade(
          context,
          const OrigenPerfilScreen(),
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
          const RecicladorHomeScreen(),
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
          const RecicladorAyudaScreen(),
          replacement: true,
        );
        break;
      case 4:
        NavigationUtils.navigateWithFade(
          context,
          const RecicladorPerfilScreen(),
          replacement: true,
        );
        break;
    }
  }
  
  void _navigateTransporte(int index) {
    switch (index) {
      case 0:
        NavigationUtils.navigateWithFade(
          context,
          const TransporteEscaneoScreen(),
          replacement: true,
        );
        break;
      case 1:
        NavigationUtils.navigateWithFade(
          context,
          const TransporteEntregarScreen(),
          replacement: true,
        );
        break;
      case 3:
        NavigationUtils.navigateWithFade(
          context,
          const TransporteAyudaScreen(),
          replacement: true,
        );
        break;
      case 4:
        NavigationUtils.navigateWithFade(
          context,
          const TransportePerfilScreen(),
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