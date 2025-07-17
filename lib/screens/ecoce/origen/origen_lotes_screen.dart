import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import 'origen_inicio_screen.dart';
import 'origen_lote_detalle_screen.dart';
import 'origen_crear_lote_screen.dart';
import 'origen_ayuda.dart';
import 'origen_perfil.dart';
import 'widgets/lote_card.dart';
import 'widgets/origen_bottom_navigation.dart';

class OrigenLotesScreen extends StatefulWidget {
  const OrigenLotesScreen({super.key});

  @override
  State<OrigenLotesScreen> createState() => _OrigenLotesScreenState();
}

class _OrigenLotesScreenState extends State<OrigenLotesScreen> {
  // Índice para la navegación del bottom bar
  int _selectedIndex = 1; // Lotes está seleccionado

  // Filtros
  String _filtroMaterial = 'Todos';
  String _filtroPresentacion = 'Todas';
  
  // Búsqueda
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Lista de lotes (datos de ejemplo)
  final List<Map<String, dynamic>> _lotes = [
    {
      'firebaseId': 'FID_1x7h9k3',
      'material': 'PEBD',
      'peso': 125,
      'fecha': '15/07/2025',
      'presentacion': 'Pacas',
      'fuente': 'Programa Escolar Norte',
    },
    {
      'firebaseId': 'FID_2y8j0l4',
      'material': 'PP',
      'peso': 175,
      'fecha': '14/07/2025',
      'presentacion': 'Sacos',
      'fuente': 'Programa Escolar Norte',
    },
    {
      'firebaseId': 'FID_3z9k1m5',
      'material': 'Multi',
      'peso': 150,
      'fecha': '14/07/2025',
      'presentacion': 'Pacas',
      'fuente': 'Programa Escolar Centro',
    },
    {
      'firebaseId': 'FID_4a0b2n6',
      'material': 'PEBD',
      'peso': 200,
      'fecha': '13/07/2025',
      'presentacion': 'Sacos',
      'fuente': 'Recolección Municipal',
    },
    {
      'firebaseId': 'FID_5c1d3p7',
      'material': 'PP',
      'peso': 180,
      'fecha': '13/07/2025',
      'presentacion': 'Pacas',
      'fuente': 'Centro Comunitario Sur',
    },
  ];

  List<Map<String, dynamic>> get _lotesFiltrados {
    return _lotes.where((lote) {
      // Filtro por material
      if (_filtroMaterial != 'Todos' && lote['material'] != _filtroMaterial) {
        return false;
      }
      
      // Filtro por presentación
      if (_filtroPresentacion != 'Todas' && lote['presentacion'] != _filtroPresentacion) {
        return false;
      }
      
      // Filtro por búsqueda
      if (_searchController.text.isNotEmpty) {
        final searchLower = _searchController.text.toLowerCase();
        return lote['firebaseId'].toLowerCase().contains(searchLower) ||
               lote['fuente'].toLowerCase().contains(searchLower) ||
               lote['material'].toLowerCase().contains(searchLower);
      }
      
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _verCodigoQR(Map<String, dynamic> lote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrigenLoteDetalleScreen(
          firebaseId: lote['firebaseId'],
          material: lote['material'],
          peso: lote['peso'].toDouble(),
          presentacion: lote['presentacion'],
          fuente: lote['fuente'],
          fechaCreacion: DateTime.now(),
          mostrarMensajeExito: false,
        ),
      ),
    );
  }

  void _navigateToNewLot() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OrigenCrearLoteScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const OrigenInicioScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 1:
        // Ya estamos en lotes
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const OrigenAyudaScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const OrigenPerfilScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header minimalista
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Título y acciones
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Historial de Lotes',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: BioWayColors.darkGreen,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gestiona y consulta tus registros',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Botón de filtros
                        Container(
                          decoration: BoxDecoration(
                            color: BioWayColors.ecoceGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Stack(
                              children: [
                                Icon(
                                  Icons.filter_list,
                                  color: BioWayColors.ecoceGreen,
                                ),
                                if (_filtroMaterial != 'Todos' || _filtroPresentacion != 'Todas')
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onPressed: () {
                              _showFilterBottomSheet();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Barra de búsqueda moderna
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        decoration: InputDecoration(
                          hintText: 'Buscar por ID, material o fuente',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                            size: 22,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey[500],
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Indicador de filtros activos
            if (_filtroMaterial != 'Todos' || _filtroPresentacion != 'Todas')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.orange.shade50,
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Filtros activos: ${_getActiveFiltersText()}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filtroMaterial = 'Todos';
                          _filtroPresentacion = 'Todas';
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                      ),
                      child: Text(
                        'Limpiar',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Lista de lotes
            Expanded(
              child: _lotesFiltrados.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _lotesFiltrados.length,
                      itemBuilder: (context, index) {
                        final lote = _lotesFiltrados[index];
                        final isFirst = index == 0;
                        final isLast = index == _lotesFiltrados.length - 1;
                        
                        return Padding(
                          padding: EdgeInsets.only(
                            top: isFirst ? 0 : 6,
                            bottom: isLast ? 0 : 6,
                          ),
                          child: LoteCard(
                            lote: lote,
                            onQRTap: () => _verCodigoQR(lote),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar con FAB
      bottomNavigationBar: OrigenBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onBottomNavTapped,
        onFabPressed: _navigateToNewLot,
      ),

      // Floating Action Button
      floatingActionButton: OrigenFloatingActionButton(
        onPressed: _navigateToNewLot,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  String _getActiveFiltersText() {
    List<String> filters = [];
    if (_filtroMaterial != 'Todos') filters.add(_filtroMaterial);
    if (_filtroPresentacion != 'Todas') filters.add(_filtroPresentacion);
    return filters.join(', ');
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Título
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtrar lotes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filtroMaterial = 'Todos';
                        _filtroPresentacion = 'Todas';
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Restablecer'),
                  ),
                ],
              ),
            ),
            
            // Filtros por material
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Material',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Todos', 'PEBD', 'PP', 'Multi'].map((material) {
                      final isSelected = _filtroMaterial == material;
                      return ChoiceChip(
                        label: Text(material),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _filtroMaterial = material;
                          });
                        },
                        selectedColor: BioWayColors.ecoceGreen,
                        backgroundColor: Colors.grey[100],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? BioWayColors.ecoceGreen : Colors.transparent,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Filtros por presentación
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Presentación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Todas', 'Pacas', 'Sacos'].map((presentacion) {
                      final isSelected = _filtroPresentacion == presentacion;
                      return ChoiceChip(
                        label: Text(presentacion),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _filtroPresentacion = presentacion;
                          });
                        },
                        selectedColor: BioWayColors.ecoceGreen,
                        backgroundColor: Colors.grey[100],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? BioWayColors.ecoceGreen : Colors.transparent,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            // Botón aplicar
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.ecoceGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Aplicar filtros',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ilustración moderna
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: BioWayColors.ecoceGreen.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 60,
                    color: BioWayColors.ecoceGreen.withOpacity(0.3),
                  ),
                  Positioned(
                    right: 25,
                    bottom: 25,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.search_off,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay lotes que mostrar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No se encontraron resultados para tu búsqueda'
                  : 'Comienza creando tu primer lote',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_searchController.text.isNotEmpty)
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _filtroMaterial = 'Todos';
                    _filtroPresentacion = 'Todas';
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: BioWayColors.ecoceGreen),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Limpiar búsqueda',
                  style: TextStyle(
                    color: BioWayColors.ecoceGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _navigateToNewLot,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Crear nuevo lote'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BioWayColors.ecoceGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}