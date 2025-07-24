import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../services/user_session_service.dart';
import '../../../services/lote_service.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import '../../../models/lotes/lote_transformador_model.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/utils/user_type_helper.dart';
import 'transformador_lote_detalle_screen.dart';

class TransformadorProduccionScreen extends StatefulWidget {
  final int? initialTab;
  
  const TransformadorProduccionScreen({super.key, this.initialTab});

  @override
  State<TransformadorProduccionScreen> createState() => _TransformadorProduccionScreenState();
}

class _TransformadorProduccionScreenState extends State<TransformadorProduccionScreen> 
    with SingleTickerProviderStateMixin {
  final UserSessionService _sessionService = UserSessionService();
  final LoteService _loteService = LoteService();
  final int _selectedIndex = 1; // Producción está en índice 1
  late TabController _tabController;
  int _selectedTabIndex = 0;
  
  EcoceProfileModel? _userProfile;
  bool _isLoading = true;
  
  // Filtros
  String _selectedPolimero = 'Todos';
  String _selectedTiempo = 'Este Mes';
  List<String> _selectedProcesos = [];
  
  // Datos desde Firebase
  List<LoteTransformadorModel> _todosLotes = [];
  
  // Métricas calculadas
  double get _capacidadUtilizada {
    // Calcular capacidad basada en lotes en proceso
    final lotesEnProceso = _todosLotes.where((l) => l.estado == 'procesando').toList();
    if (lotesEnProceso.isEmpty) return 0;
    // Asumir capacidad máxima de 2000 kg
    final pesoEnProceso = lotesEnProceso.fold(0.0, (sum, lote) => sum + (lote.pesoIngreso ?? 0));
    return (pesoEnProceso / 2000) * 100;
  }
  
  double get _materialProcesado {
    // Material procesado en las últimas 24 horas
    final ahora = DateTime.now();
    final ayer = ahora.subtract(const Duration(hours: 24));
    final lotesRecientes = _todosLotes.where((lote) {
      final fecha = lote.fechaCreacion ?? DateTime.now();
      return fecha.isAfter(ayer) && lote.estado == 'completado';
    }).toList();
    return lotesRecientes.fold(0.0, (sum, lote) => sum + (lote.pesoIngreso ?? 0)) / 1000; // En toneladas
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );
    _selectedTabIndex = widget.initialTab ?? 0;
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadUserProfile();
    _loadLotes();
  }
  
  Future<void> _loadUserProfile() async {
    try {
      final profile = await _sessionService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _loadLotes() {
    _loteService.getLotesTransformador().listen((lotes) {
      if (mounted) {
        setState(() {
          _todosLotes = lotes;
          _isLoading = false;
        });
      }
    });
  }
  
  List<LoteTransformadorModel> get _lotesFiltrados {
    final estadoFiltro = _selectedTabIndex == 0 ? 'procesando' : 'completado';
    
    return _todosLotes.where((lote) {
      // Filtrar por estado
      if (lote.estado != estadoFiltro) return false;
      
      // Filtrar por polímero
      if (_selectedPolimero != 'Todos' && lote.tipoPolimero != _selectedPolimero) return false;
      
      // Filtrar por procesos aplicados
      if (_selectedProcesos.isNotEmpty) {
        final procesosLote = lote.procesosAplicados ?? [];
        if (!_selectedProcesos.every((p) => procesosLote.contains(p))) return false;
      }
      
      // Filtrar por tiempo
      final ahora = DateTime.now();
      final fecha = lote.fechaCreacion ?? DateTime.now();
      switch (_selectedTiempo) {
        case 'Esta Semana':
          final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
          return fecha.isAfter(inicioSemana);
        case 'Este Mes':
          return fecha.month == ahora.month && fecha.year == ahora.year;
        case 'Últimos tres meses':
          final haceTresMeses = ahora.subtract(const Duration(days: 90));
          return fecha.isAfter(haceTresMeses);
        case 'Este Año':
          return fecha.year == ahora.year;
      }
      
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/transformador_inicio');
        break;
      case 1:
        // Ya estamos en producción
        break;
      case 2:
        Navigator.pushNamed(context, '/transformador_ayuda');
        break;
      case 3:
        Navigator.pushNamed(context, '/transformador_perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevenir que el botón atrás cierre la sesión
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header moderno con gradiente (igual que la pantalla de inicio)
              SliverToBoxAdapter(
                child: Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        BioWayColors.ecoceGreen,
                        BioWayColors.ecoceGreen.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Patrón de fondo
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      // Contenido
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título y botón de actualizar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Producción',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _loadLotes();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Indicadores en tiempo real
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatusCard(
                                    icon: Icons.speed,
                                    label: 'Capacidad Utilizada',
                                    value: '${_capacidadUtilizada.toStringAsFixed(1)}%',
                                    color: _capacidadUtilizada > 80 ? BioWayColors.error : BioWayColors.success,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatusCard(
                                    icon: Icons.factory,
                                    label: 'Material Procesado (24h)',
                                    value: '${_materialProcesado.toStringAsFixed(2)} Ton',
                                    color: BioWayColors.info,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Tabs
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicatorColor: Colors.white,
                                indicatorWeight: 3,
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.white60,
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                tabs: [
                                  Tab(
                                    text: 'En Proceso (${_todosLotes.where((l) => l.estado == 'procesando').length})',
                                  ),
                                  Tab(
                                    text: 'Completados (${_todosLotes.where((l) => l.estado == 'completado').length})',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Contenido principal
              SliverFillRemaining(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: BioWayColors.ecoceGreen),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildProcesoContent(),
                            _buildCompletadosContent(),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: EcoceBottomNavigation(
          selectedIndex: _selectedIndex,
          onItemTapped: _onBottomNavTapped,
          primaryColor: BioWayColors.ecoceGreen,
          items: EcoceNavigationConfigs.transformadorItems,
          fabConfig: FabConfig(
            icon: Icons.add,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/transformador_recibir_lote');
            },
          ),
        ),
        floatingActionButton: EcoceFloatingActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, '/transformador_recibir_lote');
          },
          icon: Icons.add,
          backgroundColor: BioWayColors.ecoceGreen,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcesoContent() {
    return Column(
      children: [
        // Filtros
        _buildFilterSection(),
        
        // Lista de lotes
        Expanded(
          child: _lotesFiltrados.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.factory_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay lotes en proceso',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/transformador_escaneo');
                        },
                        child: const Text('Recibir nuevo lote'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lotesFiltrados.length,
                  itemBuilder: (context, index) {
                    final lote = _lotesFiltrados[index];
                    return _buildLoteCard(lote);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCompletadosContent() {
    return Column(
      children: [
        // Filtros
        _buildFilterSection(),
        
        // Lista de lotes
        Expanded(
          child: _lotesFiltrados.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay lotes completados',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lotesFiltrados.length,
                  itemBuilder: (context, index) {
                    final lote = _lotesFiltrados[index];
                    return _buildLoteCard(lote);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Filtro de polímeros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Todos', 'PEBD', 'PP', 'Multilaminado'].map((polimero) {
                final isSelected = _selectedPolimero == polimero;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(polimero),
                    selected: isSelected,
                    selectedColor: BioWayColors.ecoceGreen.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? BioWayColors.ecoceGreen : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedPolimero = polimero;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Filtro de tiempo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: BioWayColors.backgroundGrey,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTiempo,
                isDense: true,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: BioWayColors.darkGreen),
                items: ['Esta Semana', 'Este Mes', 'Últimos tres meses', 'Este Año'].map((tiempo) {
                  return DropdownMenuItem(
                    value: tiempo,
                    child: Text(tiempo, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTiempo = value!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoteCard(LoteTransformadorModel lote) {
    final bool esEnProceso = lote.estado == 'procesando';
    final Color estadoColor = esEnProceso ? Colors.blue : BioWayColors.success;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransformadorLoteDetalleScreen(
                firebaseId: lote.id!,
                peso: lote.pesoIngreso ?? 0.0,
                tiposAnalisis: lote.tiposAnalisis ?? [],
                productoFabricado: lote.productoFabricado ?? 'En proceso',
                composicionMaterial: lote.composicionMaterial ?? 'Por definir',
                fechaCreacion: lote.fechaCreacion,
                procesosAplicados: lote.procesosAplicados,
                comentarios: lote.comentarios,
                tipoPolimero: lote.tipoPolimero,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con ID y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lote.id ?? 'Sin ID',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: estadoColor, width: 1),
                    ),
                    child: Text(
                      esEnProceso ? 'EN PROCESO' : 'COMPLETADO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: estadoColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Información del producto
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lote.productoFabricado ?? 'En proceso',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Tipo de polímero y peso
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPolimerColor(lote.tipoPolimero ?? '').withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lote.tipoPolimero ?? 'N/A',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getPolimerColor(lote.tipoPolimero ?? ''),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${lote.pesoIngreso?.toStringAsFixed(1) ?? '0.0'} kg',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Procesos aplicados
              if ((lote.procesosAplicados ?? []).isNotEmpty) ...[
                Text(
                  'Procesos aplicados:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: (lote.procesosAplicados ?? []).map((proceso) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: BioWayColors.ecoceGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        proceso,
                        style: const TextStyle(
                          fontSize: 11,
                          color: BioWayColors.ecoceGreen,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
              
              // Fecha y botón
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateTime(lote.fechaCreacion ?? DateTime.now()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Ver detalles'),
                    style: TextButton.styleFrom(
                      foregroundColor: BioWayColors.ecoceGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPolimerColor(String polimero) {
    switch (polimero) {
      case 'PEBD':
        return BioWayColors.pebdPink;
      case 'PP':
        return BioWayColors.ppPurple;
      case 'Multilaminado':
        return BioWayColors.multilaminadoBrown;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}