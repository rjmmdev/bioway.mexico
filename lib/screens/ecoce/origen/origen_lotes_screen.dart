import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../models/lotes/lote_unificado_model.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import '../../../services/lote_service.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/user_session_service.dart';
import 'origen_lote_detalle_screen.dart';
import 'origen_crear_lote_screen.dart';
import 'widgets/origen_lote_unificado_card.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import 'origen_config.dart';

class OrigenLotesScreen extends StatefulWidget {
  const OrigenLotesScreen({super.key});

  @override
  State<OrigenLotesScreen> createState() => _OrigenLotesScreenState();
}

class _OrigenLotesScreenState extends State<OrigenLotesScreen> {
  // Índice para la navegación del bottom bar
  final int _selectedIndex = 1; // Lotes está seleccionado

  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  final UserSessionService _sessionService = UserSessionService();
  
  // Datos del usuario
  EcoceProfileModel? _userProfile;
  
  // Color primario basado en el tipo de usuario
  Color get _primaryColor {
    if (_userProfile?.ecoceSubtipo == 'A') {
      return BioWayColors.darkGreen;
    } else if (_userProfile?.ecoceSubtipo == 'P') {
      return BioWayColors.ppPurple;
    }
    return BioWayColors.ecoceGreen;
  }

  // Filtros
  String _filtroMaterial = 'Todos';
  String _filtroPresentacion = 'Todas';
  
  // Búsqueda
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Lista de lotes desde Firestore
  List<LoteUnificadoModel> _lotes = [];
  bool _isLoading = true;

  List<LoteUnificadoModel> get _lotesFiltrados {
    return _lotes.where((lote) {
      // Solo mostrar lotes que están actualmente en origen
      if (lote.datosGenerales.procesoActual != 'origen') {
        return false;
      }
      
      // Obtener datos de origen
      final datosOrigen = lote.origen;
      if (datosOrigen == null) return false;
      
      // Filtro por material - Manejar prefijo "EPF-"
      if (_filtroMaterial != 'Todos') {
        String materialLote = datosOrigen.tipoPoli;
        String materialBuscado = _filtroMaterial;
        
        // Los materiales vienen con prefijo "EPF-" desde la creación
        // pero el filtro busca sin prefijo
        bool match = false;
        
        // Comparación directa
        if (materialLote == materialBuscado) {
          match = true;
        } 
        // Si el material tiene prefijo "EPF-", comparar sin él
        else if (materialLote.toUpperCase().startsWith('EPF-')) {
          String materialSinPrefijo = materialLote.substring(4);
          if (materialSinPrefijo.toUpperCase() == materialBuscado.toUpperCase()) {
            match = true;
          }
        }
        // Si el material no tiene prefijo, probar agregándolo
        else if ('EPF-$materialBuscado'.toUpperCase() == materialLote.toUpperCase()) {
          match = true;
        }
        
        if (!match) {
          return false;
        }
      }
      
      // Filtro por presentación
      if (_filtroPresentacion != 'Todas' && datosOrigen.presentacion != _filtroPresentacion) {
        return false;
      }
      
      // Filtro por búsqueda
      if (_searchController.text.isNotEmpty) {
        final searchLower = _searchController.text.toLowerCase();
        return lote.id.toLowerCase().contains(searchLower) ||
               datosOrigen.fuente.toLowerCase().contains(searchLower) ||
               datosOrigen.tipoPoli.toLowerCase().contains(searchLower);
      }
      
      return true;
    }).toList();
  }
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLotes();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    try {
      final profile = await _sessionService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      // En caso de error, continuar con el color por defecto
    }
  }
  
  void _loadLotes() {
    // Obtener lotes creados por el usuario actual que están en origen
    _loteUnificadoService.obtenerMisLotesCreados().listen((lotes) {
      if (mounted) {
        setState(() {
          _lotes = lotes;
          _isLoading = false;
        });
      }
    });
  }

  void _verCodigoQR(LoteUnificadoModel lote) {
    final datosOrigen = lote.origen!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrigenLoteDetalleScreen(
          firebaseId: lote.id,
          material: datosOrigen.tipoPoli,
          peso: datosOrigen.pesoNace,
          presentacion: datosOrigen.presentacion,
          fuente: datosOrigen.fuente,
          fechaCreacion: datosOrigen.fechaEntrada,
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
        Navigator.pushReplacementNamed(context, '/origen_inicio');
        break;
      case 1:
        // Ya estamos en lotes
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/origen_ayuda');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/origen_perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detectar si el teclado está visible usando MediaQuery
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Navegar a inicio en lugar de prevenir navegación
        Navigator.pushReplacementNamed(context, '/origen_inicio');
      },
      child: Scaffold(
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
                                  color: _primaryColor,
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
                            color: _primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Stack(
                              children: [
                                Icon(
                                  Icons.filter_list,
                                  color: _primaryColor,
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _lotesFiltrados.isEmpty
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
                              child: OrigenLoteUnificadoCard(
                                lote: lote,
                                onTap: () => _verCodigoQR(lote),
                                primaryColor: _primaryColor,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar con FAB
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onBottomNavTapped,
        primaryColor: _primaryColor,
        items: EcoceNavigationConfigs.origenItems,
        fabConfig: FabConfig(
          icon: Icons.add,
          onPressed: _navigateToNewLot,
          tooltip: 'Nuevo Lote',
        ),
      ),
      floatingActionButton: isKeyboardVisible 
        ? null 
        : EcoceFloatingActionButton(
            onPressed: _navigateToNewLot,
            icon: Icons.add,
            backgroundColor: _primaryColor,
            tooltip: 'Nuevo Lote',
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
                      setModalState(() {
                        _filtroMaterial = 'Todos';
                        _filtroPresentacion = 'Todas';
                      });
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
                    children: ['Todos', 'PEBD', 'PP', 'Multilaminado'].map((material) {
                      final isSelected = _filtroMaterial == material;
                      return ChoiceChip(
                        label: Text(material),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            _filtroMaterial = material;
                          });
                          setState(() {
                            _filtroMaterial = material;
                          });
                        },
                        selectedColor: _primaryColor,
                        backgroundColor: Colors.grey[100],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? _primaryColor : Colors.transparent,
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
                          setModalState(() {
                            _filtroPresentacion = presentacion;
                          });
                          setState(() {
                            _filtroPresentacion = presentacion;
                          });
                        },
                        selectedColor: _primaryColor,
                        backgroundColor: Colors.grey[100],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? _primaryColor : Colors.transparent,
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
                    backgroundColor: _primaryColor,
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
    ),
  );
}

  Widget _buildEmptyState() {
    // Detectar si el teclado está visible
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    
    // Si el teclado está visible, hacer el contenido scrollable
    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: isKeyboardVisible ? MainAxisSize.min : MainAxisSize.max,
      children: [
            // Ilustración moderna
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 60,
                    color: _primaryColor.withValues(alpha: 0.3),
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
                            color: Colors.orange.withValues(alpha: 0.3),
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
                  side: BorderSide(color: _primaryColor),
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
                    color: _primaryColor,
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
                  backgroundColor: _primaryColor,
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
    );
    
    // Si el teclado está visible, envolver en SingleChildScrollView
    if (isKeyboardVisible) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: content,
        ),
      );
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: content,
        ),
      );
    }
  }
}