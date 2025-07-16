import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import 'reciclador_inicio.dart';
import 'reciclador_escaneo.dart';
import 'reciclador_formulario_salida.dart';
import 'widgets/reciclador_bottom_navigation.dart';

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
  const RecicladorAdministracionLotes({super.key});

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
      material: 'PET',
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
      material: 'PET',
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
      material: 'Multi',
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
      material: 'PET',
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
    _tabController = TabController(length: 3, vsync: this);
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
        // TODO: Implementar pantalla de ayuda
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pantalla de Ayuda en desarrollo'),
            backgroundColor: BioWayColors.info,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
        break;
      case 3:
        // TODO: Implementar pantalla de perfil
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pantalla de Perfil en desarrollo'),
            backgroundColor: BioWayColors.info,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 1),
          ),
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
        elevation: 0,
        title: const Text(
          'Administración de Lotes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white.withOpacity(0.1),
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
                  children: ['Todos', 'PET', 'PP', 'Multi'].map((material) {
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
        ),
        
        // Tarjeta de estadísticas
        Container(
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
        ),
        
        // Lista de lotes
        Expanded(
          child: _lotesFiltrados.isEmpty
              ? Center(
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
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _lotesFiltrados.length,
                  itemBuilder: (context, index) {
                    return _buildLoteCard(_lotesFiltrados[index], tabColor);
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

  Widget _buildLoteCard(Lote lote, Color tabColor) {
    String buttonText = '';
    IconData? buttonIcon;
    
    switch (lote.estado) {
      case 'salida':
        buttonText = 'Formulario de Salida';
        break;
      case 'documentacion':
        buttonText = 'Ingresar Documentación';
        break;
      case 'finalizado':
        buttonText = 'Ver Código QR';
        buttonIcon = Icons.qr_code;
        break;
    }
    
    // Color del material
    Color materialColor = BioWayColors.ecoceGreen;
    switch (lote.material) {
      case 'PET':
        materialColor = BioWayColors.petBlue;
        break;
      case 'PP':
        materialColor = BioWayColors.ppOrange;
        break;
      case 'Multi':
        materialColor = BioWayColors.otherPurple;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Indicador de material
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: materialColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      lote.material,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: materialColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Información del lote
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lote ${lote.id}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.darkGreen,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${lote.peso} kg',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: materialColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  lote.presentacion,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Origen: ${lote.origen}',
                        style: TextStyle(
                          fontSize: 13,
                          color: BioWayColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Creado: ${_formatDate(lote.fechaCreacion)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: BioWayColors.textGrey.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Botón de acción
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              
              switch (lote.estado) {
                case 'salida':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecicladorFormularioSalida(
                        loteId: lote.id,
                        pesoOriginal: lote.peso,
                      ),
                    ),
                  );
                  break;
                case 'documentacion':
                  // TODO: Navegar a pantalla de documentación
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Pantalla de documentación en desarrollo'),
                      backgroundColor: BioWayColors.info,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  break;
                case 'finalizado':
                  // TODO: Navegar a pantalla de código QR
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Pantalla de código QR en desarrollo'),
                      backgroundColor: BioWayColors.info,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  break;
              }
            },
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: tabColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (buttonIcon != null) ...[
                    Icon(
                      buttonIcon,
                      color: tabColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: tabColor,
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


  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}