import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import 'laboratorio_inicio.dart';
import 'laboratorio_escaneo.dart';
import 'laboratorio_formulario.dart';
import 'laboratorio_documentacion.dart';
import 'laboratorio_ayuda.dart';
import 'laboratorio_perfil.dart';
import '../shared/utils/material_utils.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import 'widgets/laboratorio_muestra_card.dart';
import '../shared/utils/navigation_utils.dart';

// Modelo para las muestras
class Muestra {
  final String id;
  final String material;
  final double peso;
  final String presentacion; // Siempre 'Muestra'
  final DateTime fechaCreacion;
  final DateTime? fechaAnalisis;
  final bool tieneDocumentacion;
  final String estado; // formulario, documentacion, finalizado
  final String origen;

  Muestra({
    required this.id,
    required this.material,
    required this.peso,
    required this.presentacion,
    required this.fechaCreacion,
    this.fechaAnalisis,
    required this.tieneDocumentacion,
    required this.estado,
    required this.origen,
  });
}

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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Filtros
  String _selectedMaterial = 'Todos';
  String _selectedTiempo = 'Este Mes';
  String _selectedPresentacion = 'Todos';
  
  // Bottom navigation
  final int _selectedIndex = 1; // Muestras está seleccionado
  
  // Datos de ejemplo
  final List<Muestra> _todasMuestras = [
    // Muestras pendientes de formulario
    Muestra(
      id: 'M001',
      material: 'PEBD',
      peso: 2.5,
      presentacion: 'Muestra',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 2)),
      tieneDocumentacion: false,
      estado: 'formulario',
      origen: 'Reciclador Norte',
    ),
    Muestra(
      id: 'M002',
      material: 'PP',
      peso: 1.8,
      presentacion: 'Muestra',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 1)),
      tieneDocumentacion: false,
      estado: 'formulario',
      origen: 'Reciclador Sur',
    ),
    // Muestras pendientes de documentación
    Muestra(
      id: 'M003',
      material: 'PEBD',
      peso: 3.2,
      presentacion: 'Muestra',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 5)),
      fechaAnalisis: DateTime.now().subtract(const Duration(days: 3)),
      tieneDocumentacion: false,
      estado: 'documentacion',
      origen: 'Reciclador Centro',
    ),
    Muestra(
      id: 'M004',
      material: 'Multilaminado',
      peso: 2.0,
      presentacion: 'Muestra',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 4)),
      fechaAnalisis: DateTime.now().subtract(const Duration(days: 2)),
      tieneDocumentacion: false,
      estado: 'documentacion',
      origen: 'Reciclador Este',
    ),
    // Muestras finalizadas
    Muestra(
      id: 'M005',
      material: 'PEBD',
      peso: 1.5,
      presentacion: 'Muestra',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 10)),
      fechaAnalisis: DateTime.now().subtract(const Duration(days: 8)),
      tieneDocumentacion: true,
      estado: 'finalizado',
      origen: 'Reciclador Norte',
    ),
    Muestra(
      id: 'M006',
      material: 'PP',
      peso: 2.2,
      presentacion: 'Muestra',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 7)),
      fechaAnalisis: DateTime.now().subtract(const Duration(days: 5)),
      tieneDocumentacion: true,
      estado: 'finalizado',
      origen: 'Reciclador Sur',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3, 
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != _tabController.previousIndex) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Muestra> get _muestrasFiltradas {
    // Obtener muestras según la pestaña actual
    String estadoActual = '';
    switch (_tabController.index) {
      case 0:
        estadoActual = 'formulario';
        break;
      case 1:
        estadoActual = 'documentacion';
        break;
      case 2:
        estadoActual = 'finalizado';
        break;
    }
    
    return _todasMuestras.where((muestra) {
      // Filtrar por estado
      if (muestra.estado != estadoActual) return false;
      
      // Filtrar por material
      if (_selectedMaterial != 'Todos' && muestra.material != _selectedMaterial) return false;
      
      // Filtrar por presentación (aunque siempre será 'Muestra')
      if (_selectedPresentacion != 'Todos' && muestra.presentacion != _selectedPresentacion) return false;
      
      // Filtrar por tiempo
      final now = DateTime.now();
      switch (_selectedTiempo) {
        case 'Esta Semana':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return muestra.fechaCreacion.isAfter(weekStart);
        case 'Este Mes':
          return muestra.fechaCreacion.month == now.month &&
                 muestra.fechaCreacion.year == now.year;
        case 'Últimos tres meses':
          final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
          return muestra.fechaCreacion.isAfter(threeMonthsAgo);
        case 'Este Año':
          return muestra.fechaCreacion.year == now.year;
      }
      
      return true;
    }).toList();
  }

  Color _getTabColor() {
    switch (_tabController.index) {
      case 0:
        return BioWayColors.error; // Rojo para Formulario
      case 1:
        return Colors.orange; // Naranja para Documentación
      case 2:
        return BioWayColors.ecoceGreen; // Verde para Finalizados
      default:
        return BioWayColors.ecoceGreen;
    }
  }

  // Obtener texto del botón según el estado
  String _getActionButtonText(String estado) {
    switch (estado) {
      case 'formulario':
        return 'Formulario';
      case 'documentacion':
        return 'Ingresar Documentación';
      case 'finalizado':
        return '';
      default:
        return '';
    }
  }

  // Obtener color del botón según el estado
  Color _getActionButtonColor(String estado) {
    switch (estado) {
      case 'formulario':
        return BioWayColors.error; // Rojo
      case 'documentacion':
        return BioWayColors.warning; // Naranja
      case 'finalizado':
        return BioWayColors.success; // Verde
      default:
        return BioWayColors.ecoceGreen;
    }
  }

  String _getMaterialMasPredominante() {
    if (_muestrasFiltradas.isEmpty) return 'N/A';
    
    Map<String, int> conteo = {};
    for (var muestra in _muestrasFiltradas) {
      conteo[muestra.material] = (conteo[muestra.material] ?? 0) + 1;
    }
    
    var entrada = conteo.entries.reduce((a, b) => a.value > b.value ? a : b);
    double porcentaje = (entrada.value / _muestrasFiltradas.length) * 100;
    
    return '${entrada.key} (${porcentaje.toStringAsFixed(0)}%)';
  }

  void _onBottomNavTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        NavigationUtils.navigateWithFade(
          context,
          const LaboratorioInicioScreen(),
          replacement: true,
        );
        break;
      case 1:
        // Ya estamos en muestras
        break;
      case 2:
        NavigationUtils.navigateWithFade(
          context,
          const LaboratorioAyudaScreen(),
          replacement: true,
        );
        break;
      case 3:
        NavigationUtils.navigateWithFade(
          context,
          const LaboratorioPerfilScreen(),
          replacement: true,
        );
        break;
    }
  }

  void _navigateToNewMuestra() {
    HapticFeedback.lightImpact();
    NavigationUtils.navigateWithSlide(
      context,
      const LaboratorioEscaneoScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: BioWayColors.ecoceGreen,
        title: const Text(
          'Gestión de Muestras',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // TabBar
          Container(
            color: BioWayColors.ecoceGreen,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Formulario'),
                Tab(text: 'Documentación'),
                Tab(text: 'Finalizados'),
              ],
            ),
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(),
                _buildTabContent(),
                _buildTabContent(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onBottomNavTapped,
        primaryColor: const Color(0xFF9333EA), // Purple color for laboratorio
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
        backgroundColor: const Color(0xFF9333EA), // Purple color for laboratorio
        tooltip: 'Nueva muestra',
        heroTag: 'laboratorio_fab',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildTabContent() {
    final tabColor = _getTabColor();
    
    if (_muestrasFiltradas.isEmpty) {
      // Mostrar estado vacío con filtros scrollables
      return SingleChildScrollView(
        child: Column(
          children: [
            // Filtros
            _buildFilterSection(tabColor),
            // Tarjeta de estadísticas
            _buildStatisticsCard(tabColor),
            // Estado vacío
            SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.science_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay muestras en esta sección',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Lista con filtros y estadísticas scrollables
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _muestrasFiltradas.length + 2, // +2 para filtros y estadísticas
      itemBuilder: (context, index) {
        // Primer item: Filtros
        if (index == 0) {
          return _buildFilterSection(tabColor);
        }
        
        // Segundo item: Estadísticas
        if (index == 1) {
          return _buildStatisticsCard(tabColor);
        }
        
        // Resto: Muestras
        final muestraIndex = index - 2;
        final muestra = _muestrasFiltradas[muestraIndex];
        final muestraMap = {
          'id': muestra.id,
          'material': muestra.material,
          'peso': muestra.peso,
          'presentacion': muestra.presentacion,
          'origen': muestra.origen,
          'fecha': MaterialUtils.formatDate(muestra.fechaCreacion),
          'fechaAnalisis': muestra.fechaAnalisis != null ? MaterialUtils.formatDate(muestra.fechaAnalisis!) : null,
          'estado': muestra.estado,
          'tieneDocumentacion': muestra.tieneDocumentacion,
        };
        
        // Padding para el primer y último elemento
        Widget card;
        
        // Para muestras finalizadas, no mostrar botón de acción
        if (muestra.estado == 'finalizado') {
          card = LaboratorioMuestraCard(
            muestra: muestraMap,
            onTap: null,
            showActionButton: false,
            showActions: false,
          );
        } else {
          // Para muestras en formulario y documentación, mostrar botón debajo
          card = LaboratorioMuestraCard(
            muestra: muestraMap,
            onTap: () => _onMuestraTap(muestra),
            showActionButton: true,
            actionButtonText: _getActionButtonText(muestra.estado),
            actionButtonColor: _getActionButtonColor(muestra.estado),
            onActionPressed: () => _onMuestraTap(muestra),
            showActions: true, // Mostrar flecha lateral
          );
        }
        
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: muestraIndex == _muestrasFiltradas.length - 1 ? 100 : 0, // Espacio para FAB
          ),
          child: card,
        );
      },
    );
  }
  
  Widget _buildFilterSection(Color tabColor) {
    return Container(
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
          // Filtro de tiempo solamente
          _buildDropdownFilter(
            label: 'Tiempo',
            value: _selectedTiempo,
            items: ['Esta Semana', 'Este Mes', 'Últimos tres meses', 'Este Año'],
            onChanged: (value) {
              setState(() {
                _selectedTiempo = value!;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatisticsCard(Color tabColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tabColor,
            tabColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: tabColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.science,
            value: _muestrasFiltradas.length.toString(),
            label: 'Muestras',
          ),
          _buildStatItem(
            icon: Icons.scale,
            value: '${_muestrasFiltradas.fold(0.0, (sum, muestra) => sum + muestra.peso).toStringAsFixed(1)} kg',
            label: 'Peso Total',
          ),
          _buildStatItem(
            icon: Icons.category,
            value: _getMaterialMasPredominante(),
            label: 'Predominante',
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: BioWayColors.backgroundGrey,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey[300]!,
            ),
          ),
          child: DropdownButton<String>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
            iconSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  void _onMuestraTap(Muestra muestra) {
    HapticFeedback.lightImpact();
    
    switch (muestra.estado) {
      case 'formulario':
        NavigationUtils.navigateWithSlide(
          context,
          LaboratorioFormulario(
            muestraId: muestra.id,
            peso: muestra.peso,
          ),
        );
        break;
      case 'documentacion':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaboratorioDocumentacion(
              muestraId: muestra.id,
            ),
          ),
        );
        break;
      case 'finalizado':
        // No hacer nada para muestras finalizadas
        break;
    }
  }
}