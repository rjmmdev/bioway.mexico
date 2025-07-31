import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../shared/utils/navigation_utils.dart';
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
import '../../../services/lote_service.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../models/lotes/lote_unificado_model.dart';

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
  String? _selectedTipoActor;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  
  // Servicios
  final LoteService _loteService = LoteService();
  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  Stream<List<LoteUnificadoModel>>? _lotesStream;

  @override
  void initState() {
    super.initState();
    _setupLotesStream();
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

  void _setupLotesStream() {
    setState(() {
      _isLoading = true;
    });
    
    _lotesStream = _loteUnificadoService.obtenerTodosLotesRepositorio(
      searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
      tipoMaterial: _selectedMaterial,
      procesoActual: _selectedTipoActor,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
    );
    
    _lotesStream!.listen((lotes) {
      setState(() {
        _allLotes = lotes.map((lote) => {
          'id': lote.id,
          'firebaseId': lote.id,
          'material': lote.datosGenerales.tipoMaterial ?? 'Sin especificar',
          'peso': lote.pesoActual,
          'origen': _getOrigenFromProceso(lote.datosGenerales.procesoActual),
          'fechaCreacion': lote.datosGenerales.fechaCreacion,
          'estado': lote.datosGenerales.estadoActual ?? 'activo',
          'ubicacionActual': lote.datosGenerales.procesoActual ?? 'En proceso',
          'data': lote,
          'tipo_coleccion': 'lotes', // Sistema unificado
        }).toList();
        _filteredLotes = List.from(_allLotes);
        _isLoading = false;
      });
      _calculateItemsPerPage();
    });
  }
  
  String _getOrigenFromProceso(String? proceso) {
    switch (proceso) {
      case 'origen':
        return 'Centro de Acopio';
      case 'transporte':
        return 'Transportista';
      case 'reciclador':
        return 'Reciclador';
      case 'laboratorio':
        return 'Laboratorio';
      case 'transformador':
        return 'Transformador';
      default:
        return 'Desconocido';
    }
  }

  void _handleSearch(String query) {
    _setupLotesStream();
  }

  void _showQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerWidget(
          title: 'Escanear Código QR',
          subtitle: 'Escanea el código QR del lote para ver su trazabilidad',
          onCodeScanned: (code) {
            Navigator.pop(context); // Cerrar el scanner
            _handleScanResult(code);
          },
          primaryColor: widget.primaryColor,
        ),
      ),
    );
  }

  void _handleScanResult(String loteId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: widget.primaryColor,
        ),
      ),
    );
    
    try {
      // Obtener el historial de trazabilidad
      final historial = await _loteService.obtenerHistorialTrazabilidad(loteId);
      
      // Close loading
      Navigator.pop(context);
      
      if (historial.isNotEmpty) {
        final loteData = historial.first;
        
        // Extraer material y otros datos de manera segura
        String material = 'Sin especificar';
        if (loteData['detalles'] != null && loteData['detalles'] is Map) {
          final detalles = loteData['detalles'] as Map<String, dynamic>;
          // Buscar material en diferentes campos según el tipo
          material = detalles['material'] ?? 
                    detalles['tipo_material'] ?? 
                    detalles['tipo_polimero'] ?? 
                    'Sin especificar';
        }
        
        final lote = {
          'id': loteId,
          'firebaseId': loteId,
          'material': material,
          'peso': loteData['peso'] ?? 0.0,
          'origen': loteData['actor'] ?? 'Desconocido',
          'fechaCreacion': loteData['fecha'] ?? DateTime.now(),
          'estado': 'activo',
          'ubicacionActual': loteData['tipo'] ?? 'En proceso',
          'historialTrazabilidad': historial,
        };
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoteDetalleScreen(
              lote: lote,
              primaryColor: widget.primaryColor,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lote $loteId no encontrado'),
            backgroundColor: BioWayColors.error,
          ),
        );
      }
    } catch (e) {
      // Close loading if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al buscar el lote: $e'),
          backgroundColor: BioWayColors.error,
        ),
      );
    }
  }

  void _applyFilters(Map<String, dynamic> filters) {
    setState(() {
      _selectedMaterial = filters['material'];
      _selectedTipoActor = filters['tipoActor'];
      _fechaInicio = filters['fechaInicio'];
      _fechaFin = filters['fechaFin'];
    });
    _setupLotesStream();
  }


  void _filterLotes(String query) {
    // Filtering is now done through the stream in _setupLotesStream
    // This method is kept for compatibility but delegates to _handleSearch
    _handleSearch(query);
  }

  void _showFiltersSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FiltersSheet(
        selectedMaterial: _selectedMaterial,
        selectedTipoActor: _selectedTipoActor,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        onApplyFilters: _applyFilters,
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> lote) async {
    HapticFeedback.lightImpact();
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: widget.primaryColor,
        ),
      ),
    );
    
    try {
      // Get complete traceability history
      final historial = await _loteService.obtenerHistorialTrazabilidad(lote['firebaseId'] ?? lote['id']);
      
      // Add history to lot data
      lote['historialTrazabilidad'] = historial;
      
      // Close loading
      Navigator.pop(context);
      
      // Navigate to detail
      NavigationUtils.navigateWithFade(
        context,
        LoteDetalleScreen(
          lote: lote,
          primaryColor: widget.primaryColor,
        ),
      );
    } catch (e) {
      // Close loading
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar historial: $e'),
          backgroundColor: BioWayColors.error,
        ),
      );
    }
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
                if (_selectedMaterial != null || _selectedTipoActor != null || _fechaInicio != null || _fechaFin != null)
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
            if (_selectedMaterial != null || _selectedTipoActor != null || _fechaInicio != null || _fechaFin != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedMaterial = null;
                    _selectedTipoActor = null;
                    _fechaInicio = null;
                    _fechaFin = null;
                  });
                  _setupLotesStream();
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
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showQRScanner();
                    },
                    icon: Icon(
                      Icons.qr_code_scanner,
                      color: widget.primaryColor,
                    ),
                    tooltip: 'Escanear QR',
                  ),
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