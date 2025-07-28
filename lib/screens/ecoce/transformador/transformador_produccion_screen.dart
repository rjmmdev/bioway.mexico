import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../models/lotes/lote_unificado_model.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/utils/user_type_helper.dart';
import '../shared/utils/dialog_utils.dart';
import '../shared/screens/receptor_recepcion_pasos_screen.dart';
import 'transformador_lote_detalle_screen.dart';
import 'transformador_formulario_salida.dart';
import 'transformador_documentacion_screen.dart';

class TransformadorProduccionScreen extends StatefulWidget {
  final int? initialTab;
  
  const TransformadorProduccionScreen({super.key, this.initialTab});

  @override
  State<TransformadorProduccionScreen> createState() => _TransformadorProduccionScreenState();
}

class _TransformadorProduccionScreenState extends State<TransformadorProduccionScreen> 
    with SingleTickerProviderStateMixin {
  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  final int _selectedIndex = 1; // Producción está en índice 1
  late TabController _tabController;
  int _selectedTabIndex = 0;
  
  // Filtros
  String _selectedPolimero = 'Todos';
  String _selectedTiempo = 'Este Mes';
  
  // Datos desde Firebase
  List<LoteUnificadoModel> _todosLotes = [];
  
  // Estados para selección múltiple
  bool _isSelectionMode = false;
  final Set<String> _selectedLoteIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3, 
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );
    _selectedTabIndex = widget.initialTab ?? 0;
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    
    // Load immediately
    _loadLotes();
    
    // Also load with a delay to catch any database propagation delays
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {}); // Force a rebuild to show updated data
      }
    });
  }
  
  void _loadLotes() {
    _loteUnificadoService.obtenerLotesPorProceso('transformador').listen((lotes) {
      if (mounted) {
        setState(() {
          _todosLotes = lotes;
        });
      }
    });
  }
  
  void _handleSearch(String value) {
    // Implementar búsqueda si es necesario
    setState(() {});
  }
  

  List<LoteUnificadoModel> get _lotesFiltrados {
    // Filtrar según la pestaña actual
    switch (_selectedTabIndex) {
      case 0: // Salida
        // Mostrar lotes pendientes y en proceso
        return _todosLotes.where((lote) {
          final estado = lote.transformador?.especificaciones?['estado'] ?? lote.datosGenerales.estadoActual;
          return estado == 'pendiente' || estado == 'procesando';
        }).where((lote) {
          // Aplicar filtros adicionales
          if (_selectedPolimero != 'Todos' && lote.datosGenerales.tipoMaterial != _selectedPolimero) return false;
          return _aplicarFiltroTiempo(lote);
        }).toList();
      case 1: // Documentación
        // Mostrar lotes que requieren documentación
        return _todosLotes.where((lote) {
          final estado = lote.transformador?.especificaciones?['estado'] ?? lote.datosGenerales.estadoActual;
          return estado == 'documentacion';
        }).where((lote) {
          // Aplicar filtros adicionales
          if (_selectedPolimero != 'Todos' && lote.datosGenerales.tipoMaterial != _selectedPolimero) return false;
          return _aplicarFiltroTiempo(lote);
        }).toList();
      case 2: // Completados
        // Para completados, mostrar solo lotes finalizados con toda la documentación
        return _todosLotes.where((lote) {
          final estado = lote.transformador?.especificaciones?['estado'] ?? lote.datosGenerales.estadoActual;
          return estado == 'completado' || estado == 'finalizado';
        }).where((lote) {
          // Aplicar filtros adicionales
          if (_selectedPolimero != 'Todos' && lote.datosGenerales.tipoMaterial != _selectedPolimero) return false;
          return _aplicarFiltroTiempo(lote);
        }).toList();
    }
    
    // Default case - should never reach here but needed for null safety
    return [];
  }
  
  bool _aplicarFiltroTiempo(LoteUnificadoModel lote) {
    final ahora = DateTime.now();
    final fecha = lote.datosGenerales.fechaCreacion;
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: BioWayColors.ecoceGreen,
          elevation: 0,
          title: const Text(
            'Gestión de Producción',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: () {
              // Por ahora, no implementar filtros avanzados
              HapticFeedback.lightImpact();
            },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: BioWayColors.ecoceGreen,
                unselectedLabelColor: Colors.grey,
                indicatorColor: BioWayColors.ecoceGreen,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Salida'),
                  Tab(text: 'Documentación'),
                  Tab(text: 'Completados'),
                ],
                onTap: (index) {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Barra de búsqueda y filtros
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        onChanged: _handleSearch,
                        decoration: InputDecoration(
                          hintText: 'Buscar por ID de lote...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Lista de lotes
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _loadLotes();
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent(),
                    _buildTabContent(),
                    _buildTabContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: EcoceBottomNavigation(
          selectedIndex: _selectedIndex,
          onItemTapped: _onBottomNavTapped,
          primaryColor: BioWayColors.ecoceGreen,
          items: EcoceNavigationConfigs.transformadorItems,
          fabConfig: UserTypeHelper.getFabConfig('T', context),
        ),
        floatingActionButton: EcoceFloatingActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            // Usar el flujo de recepción por pasos igual que el reciclador
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReceptorRecepcionPasosScreen(
                  userType: 'transformador',
                ),
              ),
            );
          },
          icon: Icons.add,
          backgroundColor: BioWayColors.ecoceGreen,
          tooltip: 'Recibir Lote',
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  // Obtener color según la pestaña
  Color _getTabColor() {
    switch (_selectedTabIndex) {
      case 0:
        return BioWayColors.error; // Rojo para Salida
      case 1:
        return BioWayColors.warning; // Naranja para Documentación
      case 2:
        return BioWayColors.success; // Verde para Completados
      default:
        return BioWayColors.ecoceGreen;
    }
  }
  
  // Calcular peso total
  double _calcularPesoTotal() {
    return _lotesFiltrados.fold(0.0, (sum, lote) => sum + (lote.transformador?.pesoEntrada ?? lote.pesoActual));
  }
  
  // Calcular material más producido
  Map<String, dynamic> _calcularMaterialMasProducido() {
    if (_lotesFiltrados.isEmpty) return {'producto': 'N/A', 'porcentaje': 0};
    
    final Map<String, int> conteo = {};
    for (final lote in _lotesFiltrados) {
      final producto = lote.transformador?.especificaciones?['producto_fabricado'] ?? 'Sin especificar';
      conteo[producto] = (conteo[producto] ?? 0) + 1;
    }
    
    String productoMasComun = '';
    int maxConteo = 0;
    conteo.forEach((producto, count) {
      if (count > maxConteo) {
        maxConteo = count;
        productoMasComun = producto;
      }
    });
    
    final porcentaje = (_lotesFiltrados.isEmpty) ? 0 : (maxConteo / _lotesFiltrados.length * 100).toInt();
    return {'producto': productoMasComun, 'porcentaje': porcentaje};
  }

  Widget _buildTabContent() {
    final tabColor = _getTabColor();
    final pesoTotal = _calcularPesoTotal();
    final materialInfo = _calcularMaterialMasProducido();
    
    return Column(
      children: [
        // Panel de selección múltiple (solo visible cuando hay selección)
        if (_isSelectionMode && _selectedTabIndex == 0) 
          _buildSelectionPanel(),
        
        // Filtros horizontales
        Container(
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
                        selectedColor: tabColor.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? tabColor : Colors.grey[700],
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
              // Filtros de tiempo y procesos
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownFilter(
                      label: 'Proceso',
                      value: 'Todos',
                      items: ['Todos', 'Pelletizado', 'Hojuelas', 'Otros'],
                      onChanged: (value) {
                        // Implementar filtro por proceso
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Tarjetas de estadísticas
        Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Número de lotes
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
                            child: Icon(Icons.factory, color: tabColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lotesFiltrados.length.toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Lotes',
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
                  // Peso total
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
                                  '${(pesoTotal / 1000).toStringAsFixed(2)} ton',
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
              const SizedBox(height: 12),
              // Material más producido
              Container(
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
                        color: BioWayColors.ppPurple.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_awesome, color: BioWayColors.ppPurple, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${materialInfo['producto']} (${materialInfo['porcentaje']}%)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Material más producido',
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
            ],
          ),
        ),
        
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
                        'No hay lotes en esta categoría',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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


  Widget _buildLoteCard(LoteUnificadoModel lote) {
    final String estado = lote.transformador?.especificaciones?['estado'] ?? lote.datosGenerales.estadoActual ?? 'pendiente';
    final Color estadoColor = _getEstadoColor(estado);
    final String estadoTexto = _getEstadoTexto(estado);
    final bool esSublote = lote.esSublote;
    final bool canBeSelected = _selectedTabIndex == 0 && estado == 'pendiente'; // Solo en tab Salida
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: esSublote 
          ? BorderSide(color: Colors.purple.withValues(alpha: 0.3), width: 1.5)
          : BorderSide.none,
      ),
      elevation: esSublote ? 3 : 1,
      child: InkWell(
        onTap: () {
          if (_selectedTabIndex == 0 && canBeSelected) {
            // En tab Salida, toggle selección
            if (!_isSelectionMode) {
              _startSelectionMode(lote.id);
            } else {
              _toggleLoteSelection(lote.id);
            }
          } else {
            // En otros tabs, mostrar detalles
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransformadorLoteDetalleScreen(
                  firebaseId: lote.id,
                  peso: lote.transformador?.pesoEntrada ?? lote.pesoActual,
                  tiposAnalisis: lote.transformador?.especificaciones?['tipos_analisis'] as List<String>? ?? [],
                  productoFabricado: lote.transformador?.especificaciones?['producto_fabricado'] as String? ?? 'En proceso',
                  composicionMaterial: lote.transformador?.especificaciones?['composicion_material'] as String? ?? 'Por definir',
                  fechaCreacion: lote.datosGenerales.fechaCreacion,
                  procesosAplicados: lote.transformador?.especificaciones?['procesos_aplicados'] as List<String>? ?? [],
                  comentarios: lote.transformador?.especificaciones?['comentarios'] as String?,
                  tipoPolimero: lote.datosGenerales.tipoMaterial,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Checkbox para selección múltiple (solo en tab Salida)
              if (canBeSelected) ...[
                Checkbox(
                  value: _selectedLoteIds.contains(lote.id),
                  onChanged: (_) {
                    if (!_isSelectionMode) {
                      _startSelectionMode(lote.id);
                    } else {
                      _toggleLoteSelection(lote.id);
                    }
                  },
                  activeColor: BioWayColors.ecoceGreen,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
              ],
              
              // Contenido principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primera línea: ID y estado
                    Row(
                      children: [
                        // Indicador de sublote
                        if (esSublote) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cut, size: 12, color: Colors.purple),
                                const SizedBox(width: 2),
                                Text(
                                  'SUBLOTE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        
                        // ID del lote
                        Expanded(
                          child: Text(
                            lote.id.length > 8 ? '${lote.id.substring(0, 8)}...' : lote.id,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Estado
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: estadoColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: estadoColor, width: 1),
                          ),
                          child: Text(
                            estadoTexto,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: estadoColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Segunda línea: Material, peso y producto
                    Row(
                      children: [
                        // Tipo de polímero
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPolimerColor(lote.datosGenerales.tipoMaterial ?? '').withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            lote.datosGenerales.tipoMaterial ?? 'N/A',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _getPolimerColor(lote.datosGenerales.tipoMaterial ?? ''),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Peso
                        Icon(Icons.scale, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(
                          '${(lote.transformador?.pesoEntrada ?? lote.pesoActual).toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Fecha
                        Expanded(
                          child: Text(
                            _formatDateTime(lote.datosGenerales.fechaCreacion),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
  
  // Métodos auxiliares para botones de acción
  void _openFormularioSalida(LoteUnificadoModel lote) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransformadorFormularioSalida(
          loteId: lote.id,
          peso: lote.transformador?.pesoEntrada ?? lote.pesoActual,
          tiposAnalisis: lote.transformador?.especificaciones?['tipos_analisis'] as List<String>? ?? [],
          productoFabricado: lote.transformador?.especificaciones?['producto_fabricado'] as String? ?? 'En proceso',
          composicionMaterial: lote.transformador?.especificaciones?['composicion_material'] as String? ?? 'Por definir',
          tipoPolimero: lote.datosGenerales.tipoMaterial,
        ),
      ),
    );
  }
  
  void _showQRCode(LoteUnificadoModel lote) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      '/transformador_qr_lote',
      arguments: {
        'loteId': lote.id,
        'material': lote.datosGenerales.tipoMaterial,
        'peso': lote.transformador?.pesoEntrada ?? lote.pesoActual,
      },
    );
  }
  
  void _uploadDocuments(LoteUnificadoModel lote) {
    HapticFeedback.lightImpact();
    
    if (_hasAllDocs(lote)) {
      // Si ya tiene toda la documentación, mostrar alerta
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Documentación Completa'),
          content: const Text('Este lote ya tiene toda su documentación cargada.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } else {
      // Navegar a pantalla de carga de documentos
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransformadorDocumentacionScreen(
            loteId: lote.id,
            material: lote.datosGenerales.tipoMaterial,
            peso: lote.transformador?.pesoEntrada ?? lote.pesoActual,
          ),
        ),
      );
    }
  }
  
  bool _hasAllDocs(LoteUnificadoModel lote) {
    // Check if the lot has all required documentation
    // The lot is considered to have all docs if its status is 'completado'
    final estado = lote.transformador?.especificaciones?['estado'] ?? lote.datosGenerales.estadoActual;
    return estado == 'completado' || estado == 'finalizado';
  }
  
  // Métodos para selección múltiple
  void _startSelectionMode(String loteId) {
    setState(() {
      _isSelectionMode = true;
      _selectedLoteIds.add(loteId);
    });
    HapticFeedback.lightImpact();
  }
  
  void _toggleLoteSelection(String loteId) {
    setState(() {
      if (_selectedLoteIds.contains(loteId)) {
        _selectedLoteIds.remove(loteId);
        if (_selectedLoteIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedLoteIds.add(loteId);
      }
    });
    HapticFeedback.selectionClick();
  }
  
  void _cancelSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedLoteIds.clear();
    });
  }
  
  void _processSelectedLotes() async {
    if (_selectedLoteIds.isEmpty) return;
    
    try {
      // Navegar al formulario con los lotes seleccionados
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransformadorFormularioSalida(
            lotesIds: _selectedLoteIds.toList(), // Pasamos múltiples IDs
          ),
        ),
      ).then((_) {
        _cancelSelectionMode();
        _loadLotes();
      });
    } catch (e) {
      if (mounted) {
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al procesar los lotes seleccionados',
        );
      }
    }
  }
  
  Widget _buildSelectionPanel() {
    // Obtener solo los lotes seleccionados
    final selectedLotes = _todosLotes.where((l) => _selectedLoteIds.contains(l.id)).toList();
    final totalPeso = selectedLotes.fold(0.0, (total, lote) => total + lote.pesoActual);
    
    return Container(
      color: BioWayColors.ecoceGreen.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: BioWayColors.ecoceGreen, size: 24),
              const SizedBox(width: 8),
              Text(
                '${_selectedLoteIds.length} lotes seleccionados',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _cancelSelectionMode,
                child: const Text('Cancelar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Peso total: ${totalPeso.toStringAsFixed(2)} kg',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _processSelectedLotes,
                icon: const Icon(Icons.merge_type),
                label: Text(_selectedLoteIds.length > 1 ? 'Procesar juntos' : 'Procesar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BioWayColors.ecoceGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'procesando':
        return Colors.blue;
      case 'documentacion':
        return BioWayColors.warning;
      case 'completado':
      case 'finalizado':
        return BioWayColors.success;
      default:
        return Colors.grey;
    }
  }
  
  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'PENDIENTE';
      case 'procesando':
        return 'EN PROCESO';
      case 'documentacion':
        return 'DOCUMENTACIÓN';
      case 'completado':
        return 'COMPLETADO';
      case 'finalizado':
        return 'FINALIZADO';
      default:
        return estado.toUpperCase();
    }
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