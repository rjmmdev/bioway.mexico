import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../services/lote_service.dart';
import '../../../models/lotes/lote_laboratorio_model.dart';
import 'laboratorio_inicio.dart';
import 'laboratorio_escaneo.dart';
import 'laboratorio_formulario.dart';
import 'laboratorio_documentacion.dart';
import '../shared/ecoce_ayuda_screen.dart';
import '../shared/ecoce_perfil_screen.dart';
import '../shared/utils/material_utils.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import 'widgets/laboratorio_muestra_card.dart';
import '../shared/utils/navigation_utils.dart';

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
  
  // Servicio y datos
  final LoteService _loteService = LoteService();
  List<LoteLaboratorioModel> _todasMuestras = [];
  bool _isLoading = true;

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
    _loadMuestras();
  }

  void _loadMuestras() {
    _loteService.getLotesLaboratorio().listen((muestras) {
      if (mounted) {
        setState(() {
          _todasMuestras = muestras;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<LoteLaboratorioModel> get _muestrasFiltradas {
    // Obtener muestras según la pestaña actual
    String estadoActual = '';
    switch (_tabController.index) {
      case 0:
        estadoActual = 'pendiente';      // Muestras pendientes de análisis
        break;
      case 1:
        estadoActual = 'analizado';     // Muestras analizadas pendientes de documentación
        break;
      case 2:
        estadoActual = 'finalizado';    // Muestras con análisis completo
        break;
    }
    
    return _todasMuestras.where((muestra) {
      // Filtrar por estado
      if (muestra.estado != estadoActual) return false;
      
      // Filtrar por material
      if (_selectedMaterial != 'Todos' && muestra.tipoMaterial != _selectedMaterial) return false;
      
      // Filtrar por tiempo
      final now = DateTime.now();
      final fechaAnalisis = muestra.fechaAnalisis ?? DateTime.now();
      switch (_selectedTiempo) {
        case 'Esta Semana':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return fechaAnalisis.isAfter(weekStart);
        case 'Este Mes':
          return fechaAnalisis.month == now.month &&
                 fechaAnalisis.year == now.year;
        case 'Últimos tres meses':
          final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
          return fechaAnalisis.isAfter(threeMonthsAgo);
        case 'Este Año':
          return fechaAnalisis.year == now.year;
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

  // Obtener texto del botón según el estado
  String _getActionButtonText(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Análisis';
      case 'analizado':
        return 'Añadir Documentación';
      case 'finalizado':
        return 'Ver Resultados';
      default:
        return '';
    }
  }

  // Obtener color del botón según el estado
  Color _getActionButtonColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFF9333EA); // Morado para análisis
      case 'analizado':
        return BioWayColors.warning; // Naranja para documentación
      case 'finalizado':
        return BioWayColors.success; // Verde para finalizados
      default:
        return const Color(0xFF9333EA);
    }
  }

  String _getMaterialMasPredominante() {
    if (_muestrasFiltradas.isEmpty) return 'N/A';
    
    Map<String, int> conteo = {};
    for (var muestra in _muestrasFiltradas) {
      final material = muestra.tipoMaterial ?? 'Desconocido';
      conteo[material] = (conteo[material] ?? 0) + 1;
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
        Navigator.pushReplacementNamed(context, '/laboratorio_inicio');
        break;
      case 1:
        // Ya estamos en muestras
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/ecoce_ayuda');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/ecoce_perfil');
        break;
    }
  }

  void _navigateToNewMuestra() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LaboratorioEscaneoScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevenir que el botón atrás cierre la sesión
        return false;
      },
      child: Scaffold(
        backgroundColor: BioWayColors.backgroundGrey,
        appBar: AppBar(
        backgroundColor: const Color(0xFF9333EA), // Morado para laboratorio
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Gestión de Muestras',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white.withValues(alpha: 0.1),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Análisis'),
                Tab(text: 'Documentación'),
                Tab(text: 'Finalizadas'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent(),
          _buildTabContent(),
          _buildTabContent(),
        ],
      ),
      bottomNavigationBar: _isLoading ? null : EcoceBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onBottomNavTapped,
        items: EcoceNavigationConfigs.laboratorioItems,
        primaryColor: const Color(0xFF9333EA),
      ),
      floatingActionButton: _isLoading ? null : FloatingActionButton(
        onPressed: _navigateToNewMuestra,
        backgroundColor: const Color(0xFF9333EA),
        elevation: 8,
        child: const Icon(
          Icons.add,
          size: 28,
          color: Colors.white,
        ),
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
    
    return Column(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownFilter(
                      label: 'Presentación',
                      value: _selectedPresentacion,
                      items: ['Todos', 'Muestra'],
                      onChanged: (value) {
                        setState(() {
                          _selectedPresentacion = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Tarjeta de estadísticas
        Container(
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
                value: '${_muestrasFiltradas.fold(0.0, (sum, muestra) => sum + (muestra.pesoMuestra ?? 0.0)).toStringAsFixed(1)} kg',
                label: 'Peso Total',
              ),
              _buildStatItem(
                icon: Icons.category,
                value: _getMaterialMasPredominante(),
                label: 'Predominante',
              ),
            ],
          ),
        ),
        
        // Lista de muestras
        Expanded(
          child: _muestrasFiltradas.isEmpty
              ? Center(
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
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _muestrasFiltradas.length,
                  itemBuilder: (context, index) {
                    final muestra = _muestrasFiltradas[index];
                    final muestraMap = {
                      'id': muestra.id,
                      'material': muestra.tipoMaterial ?? 'Sin especificar',
                      'peso': muestra.pesoMuestra ?? 0.0,
                      'presentacion': 'Muestra',
                      'origen': muestra.proveedor ?? 'Desconocido',
                      'fecha': _formatDate(muestra.fechaAnalisis ?? DateTime.now()),
                      'fechaAnalisis': muestra.fechaAnalisis != null ? _formatDate(muestra.fechaAnalisis!) : null,
                      'estado': muestra.estado ?? 'pendiente',
                      'tieneDocumentacion': muestra.informe != null && muestra.informe!.isNotEmpty,
                    };
                    
                    return LaboratorioMuestraCard(
                      muestra: muestraMap,
                      onTap: () => _onMuestraTap(muestra),
                      showActionButton: true,
                      actionButtonText: _getActionButtonText(muestra.estado ?? 'pendiente'),
                      actionButtonColor: _getActionButtonColor(muestra.estado ?? 'pendiente'),
                      onActionPressed: () => _onMuestraTap(muestra),
                    );
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

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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

  void _onMuestraTap(LoteLaboratorioModel muestra) {
    HapticFeedback.lightImpact();
    
    switch (muestra.estado ?? 'pendiente') {
      case 'pendiente':
        // Navegar a formulario de análisis
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaboratorioFormulario(
              muestraId: muestra.id!,
              peso: muestra.pesoMuestra ?? 0.0,
            ),
          ),
        );
        break;
      case 'analizado':
        // Navegar a documentación
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaboratorioDocumentacion(
              muestraId: muestra.id!,
            ),
          ),
        );
        break;
      case 'finalizado':
        // Ver resultados de análisis
        _showResultadosDialog(muestra);
        break;
    }
  }

  void _showResultadosDialog(LoteLaboratorioModel muestra) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Resultados de Análisis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${muestra.id}'),
            Text('Material: ${muestra.tipoMaterial}'),
            Text('Peso: ${muestra.pesoMuestra} kg'),
            if (muestra.humedad != null || muestra.contOrg != null || muestra.contInorg != null) ...[
              const SizedBox(height: 8),
              if (muestra.humedad != null) Text('Humedad: ${muestra.humedad}'),
              if (muestra.contOrg != null) Text('Contaminación Orgánica: ${muestra.contOrg}'),
              if (muestra.contInorg != null) Text('Contaminación Inorgánica: ${muestra.contInorg}'),
              if (muestra.ftir != null) Text('Tipo de Polímero (FTIR): ${muestra.ftir}'),
              if (muestra.requisitos != null) Text('Cumple requisitos: ${muestra.requisitos! ? 'Sí' : 'No'}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}