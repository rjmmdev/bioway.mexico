import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/material_filter_bar.dart';
import '../shared/widgets/unified_stat_card.dart';
import '../shared/widgets/qr_scanner_widget.dart';
import 'reciclador_services.dart';
import 'reciclador_forms_screen.dart';
import 'reciclador_lote_qr_screen.dart';

/// Unified lot management screen for reciclador
class RecicladorLotManagementScreen extends StatefulWidget {
  final int initialTab;
  
  const RecicladorLotManagementScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<RecicladorLotManagementScreen> createState() => _RecicladorLotManagementScreenState();
}

class _RecicladorLotManagementScreenState extends State<RecicladorLotManagementScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Filter states
  final List<String> _selectedMaterials = [];
  String _selectedTimeFilter = 'all';
  String _selectedPresentationFilter = 'all';
  
  // Scanned lots for registro
  final List<Map<String, dynamic>> _scannedLots = [];
  
  // Mock data for different states
  final List<Map<String, dynamic>> _lotesData = [
    // Salida
    {
      'id': 'LOTE-2024-001',
      'material': 'PP',
      'peso': 150.5,
      'formato': 'Pacas',
      'fecha': DateTime.now().subtract(const Duration(hours: 2)),
      'estado': LotState.salida,
      'origen': 'Centro Acopio Norte',
    },
    {
      'id': 'LOTE-2024-002',
      'material': 'PEBD',
      'peso': 200.0,
      'formato': 'Granel',
      'fecha': DateTime.now().subtract(const Duration(days: 1)),
      'estado': LotState.salida,
      'origen': 'Planta Separación Sur',
    },
    // Documentación
    {
      'id': 'LOTE-2024-003',
      'material': 'Multi',
      'peso': 175.0,
      'formato': 'Sacos',
      'fecha': DateTime.now().subtract(const Duration(days: 2)),
      'estado': LotState.documentacion,
      'origen': 'Centro Acopio Este',
      'pesoSalida': 170.0,
      'merma': 2.9,
    },
    // Finalizados
    {
      'id': 'LOTE-2024-004',
      'material': 'PP',
      'peso': 300.0,
      'formato': 'Pacas',
      'fecha': DateTime.now().subtract(const Duration(days: 5)),
      'estado': LotState.finalizado,
      'origen': 'Centro Acopio Norte',
      'pesoSalida': 290.0,
      'merma': 3.3,
      'destino': 'Transformador XYZ',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredLotes {
    return _lotesData.where((lote) {
      // Filter by tab
      final tabState = [LotState.salida, LotState.documentacion, LotState.finalizado][_tabController.index];
      if (lote['estado'] != tabState) return false;
      
      // Filter by material
      if (_selectedMaterials.isNotEmpty && !_selectedMaterials.contains(lote['material'])) {
        return false;
      }
      
      // Filter by time
      if (_selectedTimeFilter != 'all') {
        final fecha = lote['fecha'] as DateTime;
        final now = DateTime.now();
        switch (_selectedTimeFilter) {
          case 'today':
            if (fecha.day != now.day || fecha.month != now.month || fecha.year != now.year) {
              return false;
            }
            break;
          case 'week':
            if (now.difference(fecha).inDays > 7) return false;
            break;
          case 'month':
            if (now.difference(fecha).inDays > 30) return false;
            break;
        }
      }
      
      // Filter by presentation
      if (_selectedPresentationFilter != 'all' && lote['formato'] != _selectedPresentationFilter) {
        return false;
      }
      
      return true;
    }).toList();
  }

  void _showScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerWidget(
          title: 'Escanear Lotes',
          subtitle: 'Escanea los códigos QR de los lotes',
          onCodeScanned: (barcode) {
            _processScanResults([barcode]);
            Navigator.pop(context);
          },
          userType: 'reciclador',
          primaryColor: BioWayColors.recycleOrange,
          scanPrompt: 'Escanea uno o más códigos QR',
        ),
      ),
    );
  }

  void _processScanResults(List<String> barcodes) {
    setState(() {
      for (final code in barcodes) {
        // Parse QR code (format: LOTE-MATERIAL-ID)
        final parts = code.split('-');
        if (parts.length >= 3) {
          _scannedLots.add({
            'id': code,
            'material': parts[1],
            'peso': 0.0, // Will be set in form
            'formato': 'Por definir',
            'fecha': DateTime.now(),
          });
        }
      }
    });
    
    if (_scannedLots.isNotEmpty) {
      _showScannedLotsDialog();
    }
  }

  void _showScannedLotsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lotes Escaneados',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _scannedLots.clear()),
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _scannedLots.length,
                itemBuilder: (context, index) {
                  final lot = _scannedLots[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        RecicladorServices.getMaterialIcon(lot['material']),
                        color: RecicladorServices.getMaterialColor(lot['material']),
                      ),
                      title: Text(lot['id']),
                      subtitle: Text('Material: ${lot['material']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() => _scannedLots.removeAt(index));
                          if (_scannedLots.isEmpty) Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showScanner();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar más'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _scannedLots.isNotEmpty ? _continueToForm : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continuar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BioWayColors.recycleOrange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continueToForm() {
    final lotIds = _scannedLots.map((lot) => lot['id'] as String).toList();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RecicladorFormsScreen.entrada(
          lotIds: lotIds,
          totalLotes: _scannedLots.length,
        ),
      ),
    );
  }

  void _handleLotAction(Map<String, dynamic> lot) {
    switch (lot['estado'] as LotState) {
      case LotState.salida:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorFormsScreen.salida(
              lotData: lot,
            ),
          ),
        );
        break;
      case LotState.documentacion:
        Navigator.pushNamed(
          context,
          '/reciclador_documentacion',
          arguments: lot,
        );
        break;
      case LotState.finalizado:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorLoteQRScreen(
              loteId: lot['id'] ?? '',
              material: lot['material'] ?? '',
              pesoOriginal: (lot['peso'] ?? 0.0).toDouble(),
              pesoFinal: (lot['pesoSalida'] ?? lot['peso'] ?? 0.0).toDouble(),
              presentacion: lot['presentacion'] ?? lot['formato'] ?? 'Pacas',
              origen: lot['origen'] ?? '',
              fechaEntrada: lot['fecha'] as DateTime?,
              fechaSalida: lot['fechaSalida'] as DateTime? ?? DateTime.now(),
              mostrarMensajeExito: false,
            ),
          ),
        );
        break;
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == 1) return; // Already on lots screen
    
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/reciclador_inicio');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/reciclador_ayuda');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/reciclador_perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Administración de Lotes',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.darkGreen,
                              ),
                            ),
                            Text(
                              'Gestiona tus lotes en proceso',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              BioWayColors.recycleOrange,
                              BioWayColors.recycleOrange.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _showScanner,
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.qr_code_scanner,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: BioWayColors.recycleOrange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorPadding: const EdgeInsets.all(2),
                      tabs: const [
                        Tab(text: 'Salida'),
                        Tab(text: 'Documentación'),
                        Tab(text: 'Finalizados'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Filters
            MaterialFilterBar(
              selectedMaterial: _selectedMaterials.isEmpty ? 'Todos' : _selectedMaterials.first,
              selectedTime: _selectedTimeFilter,
              onMaterialChanged: (material) {
                setState(() {
                  _selectedMaterials.clear();
                  if (material != 'Todos') {
                    _selectedMaterials.add(material);
                  }
                });
              },
              onTimeChanged: (filter) {
                setState(() => _selectedTimeFilter = filter);
              },
              materials: const ['Todos', 'PEBD', 'PP', 'Multilaminado'],
              timeOptions: const ['Hoy', 'Semana', 'Mes', 'Todos'],
            ),
            
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabContent(LotState.salida),
                  _buildTabContent(LotState.documentacion),
                  _buildTabContent(LotState.finalizado),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: 1,
        onItemTapped: _onBottomNavTapped,
        primaryColor: BioWayColors.recycleOrange,
        items: EcoceNavigationConfigs.recicladorItems,
      ),
      floatingActionButton: EcoceFloatingActionButton(
        onPressed: _showScanner,
        icon: Icons.add,
        backgroundColor: BioWayColors.recycleOrange,
        tooltip: 'Escanear Lotes',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildTabContent(LotState state) {
    final tabLotes = _filteredLotes;
    
    if (tabLotes.isEmpty) {
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
              'No hay lotes en ${state.label.toLowerCase()}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            if (state == LotState.salida) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Escanear Lotes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BioWayColors.recycleOrange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Statistics card
        Container(
          margin: const EdgeInsets.all(20),
          child: StatCard(
            label: _getStatTitle(state),
            value: tabLotes.length.toString(),
            icon: _getStatIcon(state),
            iconColor: state.color,
          ),
        ),
        // Lots list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
            itemCount: tabLotes.length,
            itemBuilder: (context, index) {
              final lot = tabLotes[index];
              return _buildLotCard(lot);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLotCard(Map<String, dynamic> lot) {
    final state = lot['estado'] as LotState;
    final material = lot['material'] as String;
    final materialColor = RecicladorServices.getMaterialColor(material);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: () => _handleLotAction(lot),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: materialColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        RecicladorServices.getMaterialIcon(material),
                        color: materialColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lot['id'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.darkGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${lot['material']} • ${RecicladorServices.formatWeight(lot['peso'])} • ${lot['formato']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (lot['origen'] != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    lot['origen'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: state.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            state.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: state.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          RecicladorServices.getTimeAgo(lot['fecha']),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (state != LotState.salida && lot['merma'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMetric(
                          'Peso Salida',
                          RecicladorServices.formatWeight(lot['pesoSalida']),
                          Icons.scale,
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[300],
                        ),
                        _buildMetric(
                          'Merma',
                          '${lot['merma']}%',
                          Icons.trending_down,
                        ),
                        if (lot['destino'] != null) ...[
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey[300],
                          ),
                          _buildMetric(
                            'Destino',
                            lot['destino'],
                            Icons.location_on,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: BioWayColors.darkGreen,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatTitle(LotState state) {
    switch (state) {
      case LotState.salida:
        return 'Pendientes de Salida';
      case LotState.documentacion:
        return 'En Documentación';
      case LotState.finalizado:
        return 'Lotes Finalizados';
    }
  }

  IconData _getStatIcon(LotState state) {
    switch (state) {
      case LotState.salida:
        return Icons.output;
      case LotState.documentacion:
        return Icons.description;
      case LotState.finalizado:
        return Icons.check_circle;
    }
  }
}