import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import 'reciclador_inicio.dart';
import 'reciclador_escaneo.dart';
import 'reciclador_formulario_salida.dart';
import 'reciclador_documentacion.dart';
import 'reciclador_lote_qr_screen.dart';
import 'reciclador_ayuda.dart';
import 'reciclador_perfil.dart';
import '../shared/utils/material_utils.dart';
import '../shared/widgets/material_filter_bar.dart';
import 'widgets/reciclador_bottom_navigation.dart';
import 'widgets/reciclador_lote_card.dart';

// Modelo para los lotes
class Lote {
  final String id;
  final String material;
  final double peso;
  final String presentacion; // Pacas o Sacos
  final DateTime fechaCreacion;
  final DateTime? fechaSalida;
  final bool tieneDocumentacion;
  final String estado; // salida, documentacion, finalizado
  final String origen;

  Lote({
    required this.id,
    required this.material,
    required this.peso,
    required this.presentacion,
    required this.fechaCreacion,
    this.fechaSalida,
    required this.tieneDocumentacion,
    required this.estado,
    required this.origen,
  });
}

class RecicladorAdministracionLotes extends StatefulWidget {
  final int initialTab;
  
  const RecicladorAdministracionLotes({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<RecicladorAdministracionLotes> createState() => _RecicladorAdministracionLotesState();
}

class _RecicladorAdministracionLotesState extends State<RecicladorAdministracionLotes> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Filtros
  String _selectedMaterial = 'Todos';
  String _selectedTiempo = 'Este Mes';
  String _selectedPresentacion = 'Todos';
  
  // Bottom navigation
  final int _selectedIndex = 1; // Lotes está seleccionado
  
  // Datos de ejemplo
  final List<Lote> _todosLotes = [
    // Lotes pendientes de salida
    Lote(
      id: 'L001',
      material: 'PEBD',
      peso: 125.5,
      presentacion: 'Pacas',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 2)),
      tieneDocumentacion: false,
      estado: 'salida',
      origen: 'Acopiador Norte',
    ),
    Lote(
      id: 'L002',
      material: 'PP',
      peso: 89.3,
      presentacion: 'Sacos',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 1)),
      tieneDocumentacion: false,
      estado: 'salida',
      origen: 'Planta Sur',
    ),
    // Lotes pendientes de documentación
    Lote(
      id: 'L003',
      material: 'PEBD',
      peso: 200.8,
      presentacion: 'Pacas',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 5)),
      fechaSalida: DateTime.now().subtract(const Duration(days: 3)),
      tieneDocumentacion: false,
      estado: 'documentacion',
      origen: 'Acopiador Centro',
    ),
    Lote(
      id: 'L004',
      material: 'Multilaminado',
      peso: 156.2,
      presentacion: 'Sacos',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 4)),
      fechaSalida: DateTime.now().subtract(const Duration(days: 2)),
      tieneDocumentacion: false,
      estado: 'documentacion',
      origen: 'Planta Este',
    ),
    // Lotes finalizados
    Lote(
      id: 'L005',
      material: 'PEBD',
      peso: 180.5,
      presentacion: 'Pacas',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 10)),
      fechaSalida: DateTime.now().subtract(const Duration(days: 8)),
      tieneDocumentacion: true,
      estado: 'finalizado',
      origen: 'Acopiador Norte',
    ),
    Lote(
      id: 'L006',
      material: 'PP',
      peso: 95.0,
      presentacion: 'Sacos',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 7)),
      fechaSalida: DateTime.now().subtract(const Duration(days: 5)),
      tieneDocumentacion: true,
      estado: 'finalizado',
      origen: 'Planta Sur',
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

  List<Lote> get _lotesFiltrados {
    // Obtener lotes según la pestaña actual
    String estadoActual = '';
    switch (_tabController.index) {
      case 0:
        estadoActual = 'salida';
        break;
      case 1:
        estadoActual = 'documentacion';
        break;
      case 2:
        estadoActual = 'finalizado';
        break;
    }
    
    return _todosLotes.where((lote) {
      // Filtrar por estado
      if (lote.estado != estadoActual) return false;
      
      // Filtrar por material
      if (_selectedMaterial != 'Todos' && lote.material != _selectedMaterial) return false;
      
      // Filtrar por presentación
      if (_selectedPresentacion != 'Todos' && lote.presentacion != _selectedPresentacion) return false;
      
      // Filtrar por tiempo
      final now = DateTime.now();
      switch (_selectedTiempo) {
        case 'Esta Semana':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return lote.fechaCreacion.isAfter(weekStart);
        case 'Este Mes':
          return lote.fechaCreacion.month == now.month &&
                 lote.fechaCreacion.year == now.year;
        case 'Últimos tres meses':
          final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
          return lote.fechaCreacion.isAfter(threeMonthsAgo);
        case 'Este Año':
          return lote.fechaCreacion.year == now.year;
      }
      
      return true;
    }).toList();
  }

  Color _getTabColor() {
    switch (_tabController.index) {
      case 0:
        return BioWayColors.error; // Rojo para Salida
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
      case 'salida':
        return 'Formulario de Salida';
      case 'documentacion':
        return 'Ingresar Documentación';
      case 'finalizado':
        return 'Ver Código QR';
      default:
        return '';
    }
  }

  // Obtener color del botón según el estado
  Color _getActionButtonColor(String estado) {
    switch (estado) {
      case 'salida':
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
    if (_lotesFiltrados.isEmpty) return 'N/A';
    
    Map<String, int> conteo = {};
    for (var lote in _lotesFiltrados) {
      conteo[lote.material] = (conteo[lote.material] ?? 0) + 1;
    }
    
    var entrada = conteo.entries.reduce((a, b) => a.value > b.value ? a : b);
    double porcentaje = (entrada.value / _lotesFiltrados.length) * 100;
    
    return '${entrada.key} (${porcentaje.toStringAsFixed(0)}%)';
  }

  void _onBottomNavTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        NavigationHelper.navigateWithReplacement(
          context: context,
          destination: const RecicladorHomeScreen(),
        );
        break;
      case 1:
        // Ya estamos en lotes
        break;
      case 2:
        NavigationHelper.navigateWithReplacement(
          context: context,
          destination: const RecicladorAyudaScreen(),
        );
        break;
      case 3:
        NavigationHelper.navigateWithReplacement(
          context: context,
          destination: const RecicladorPerfilScreen(),
        );
        break;
    }
  }

  void _navigateToNewLot() {
    HapticFeedback.lightImpact();
    NavigationHelper.navigateWithSlideTransition(
      context: context,
      destination: const QRScannerScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: BioWayColors.ecoceGreen,
        title: const Text(
          'Administración de Lotes',
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
                Tab(text: 'Salida'),
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
      bottomNavigationBar: RecicladorBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onBottomNavTapped,
        onFabPressed: _navigateToNewLot,
      ),
      floatingActionButton: RecicladorFloatingActionButton(
        onPressed: _navigateToNewLot,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildTabContent() {
    final tabColor = _getTabColor();
    
    if (_lotesFiltrados.isEmpty) {
      // Mostrar estado vacío con filtros scrollables
      return SingleChildScrollView(
        child: Column(
          children: [
            // Filtros
            _buildFilterSection(tabColor),
            // Tarjeta de estadísticas
            _buildStatisticsCard(tabColor),
            // Estado vacío
            Container(
              height: 300,
              child: Center(
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
                      'No hay lotes en esta sección',
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
      itemCount: _lotesFiltrados.length + 2, // +2 para filtros y estadísticas
      itemBuilder: (context, index) {
        // Primer item: Filtros
        if (index == 0) {
          return _buildFilterSection(tabColor);
        }
        
        // Segundo item: Estadísticas
        if (index == 1) {
          return _buildStatisticsCard(tabColor);
        }
        
        // Resto: Lotes
        final loteIndex = index - 2;
        final lote = _lotesFiltrados[loteIndex];
        final loteMap = {
          'id': lote.id,
          'material': lote.material,
          'peso': lote.peso,
          'presentacion': lote.presentacion,
          'origen': lote.origen,
          'fecha': MaterialUtils.formatDate(lote.fechaCreacion),
          'fechaSalida': lote.fechaSalida != null ? MaterialUtils.formatDate(lote.fechaSalida!) : null,
          'estado': lote.estado,
          'tieneDocumentacion': lote.tieneDocumentacion,
        };
        
        // Padding para el primer y último lote
        Widget card;
        
        // Para lotes finalizados, usar el estilo original con botón QR lateral
        if (lote.estado == 'finalizado') {
          card = RecicladorLoteCard(
            lote: loteMap,
            onTap: () => _onLoteTap(lote),
            showActionButton: false,
            showActions: false,
            trailing: _buildQRButton(lote),
          );
        } else {
          // Para lotes en salida y documentación, mostrar botón debajo
          card = RecicladorLoteCard(
            lote: loteMap,
            onTap: () => _onLoteTap(lote),
            showActionButton: true,
            actionButtonText: _getActionButtonText(lote.estado),
            actionButtonColor: _getActionButtonColor(lote.estado),
            onActionPressed: () => _onLoteTap(lote),
            showActions: true, // Mostrar flecha lateral
          );
        }
        
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: loteIndex == _lotesFiltrados.length - 1 ? 100 : 0, // Espacio para FAB
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
                    selectedColor: tabColor.withOpacity(0.2),
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
                  items: ['Todos', 'Pacas', 'Sacos'],
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
            tabColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: tabColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.inventory_2,
            value: _lotesFiltrados.length.toString(),
            label: 'Lotes',
          ),
          _buildStatItem(
            icon: Icons.scale,
            value: '${_lotesFiltrados.fold(0.0, (sum, lote) => sum + lote.peso).toStringAsFixed(1)} kg',
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



  void _onLoteTap(Lote lote) {
    HapticFeedback.lightImpact();
    
    switch (lote.estado) {
      case 'salida':
        NavigationHelper.navigateWithSlideTransition(
          context: context,
          destination: RecicladorFormularioSalida(
            loteId: lote.id,
            pesoOriginal: lote.peso,
          ),
        );
        break;
      case 'documentacion':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorDocumentacion(
              lotId: lote.id,
            ),
          ),
        );
        break;
      case 'finalizado':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorLoteQRScreen(
              loteId: lote.id,
              material: lote.material,
              pesoOriginal: lote.peso,
              pesoFinal: lote.peso, // En producción vendría de la base de datos
              presentacion: lote.presentacion,
              origen: lote.origen,
              fechaEntrada: lote.fechaCreacion,
              fechaSalida: lote.fechaSalida,
              documentosCargados: ['Ficha Técnica', 'Reporte de Reciclaje'], // En producción vendría de la BD
            ),
          ),
        );
        break;
    }
  }

  Widget _buildQRButton(Lote lote) {
    return Container(
      decoration: BoxDecoration(
        color: BioWayColors.ecoceGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          _onLoteTap(lote);
        },
        icon: Icon(
          Icons.qr_code_2,
          color: BioWayColors.ecoceGreen,
          size: 22,
        ),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        tooltip: 'Ver QR',
      ),
    );
  }


}