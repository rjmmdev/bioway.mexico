import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/qr_scanner_widget.dart';
import '../shared/widgets/unified_stat_card.dart';
import '../shared/utils/dialog_utils.dart';
import 'transporte_services.dart';
import 'transporte_forms_screen.dart';
import 'transporte_resumen_carga_screen.dart';

/// Unified lot management screen for transport pickup flow
class TransporteLotManagementScreen extends StatefulWidget {
  const TransporteLotManagementScreen({super.key});

  @override
  State<TransporteLotManagementScreen> createState() => _TransporteLotManagementScreenState();
}

class _TransporteLotManagementScreenState extends State<TransporteLotManagementScreen> {
  final List<Map<String, dynamic>> _scannedLots = [];
  bool _isScanning = false;
  
  // Mock available lots for demo
  final List<Map<String, dynamic>> _availableLots = [
    {
      'id': 'LOTE-PEBD-001',
      'material': 'PEBD',
      'peso': 150.5,
      'origen': 'Centro Acopio Norte',
      'fecha': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': 'LOTE-PP-002',
      'material': 'PP',
      'peso': 200.0,
      'origen': 'Planta Separación Sur',
      'fecha': DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      'id': 'LOTE-MULTI-003',
      'material': 'Multi',
      'peso': 175.0,
      'origen': 'Centro Acopio Este',
      'fecha': DateTime.now().subtract(const Duration(days: 1)),
    },
  ];

  void _showScanner() {
    setState(() => _isScanning = true);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerWidget(
          title: 'Escanear Lotes',
          subtitle: 'Escanea los códigos QR de los lotes a recoger',
          onCodeScanned: (barcode) {
            _processScanResults([barcode]);
            Navigator.pop(context);
          },
          userType: 'transporte',
          primaryColor: BioWayColors.ecoceGreen,
          scanPrompt: 'Escanea uno o más códigos QR',
        ),
      ),
    ).then((_) => setState(() => _isScanning = false));
  }

  void _processScanResults(List<String> barcodes) {
    setState(() {
      for (final code in barcodes) {
        // Check if already scanned
        if (_scannedLots.any((lot) => lot['id'] == code)) {
          continue;
        }
        
        // Find lot in available lots (in production, would query Firestore)
        final lot = _availableLots.firstWhere(
          (l) => l['id'] == code,
          orElse: () => {
            'id': code,
            'material': _extractMaterial(code),
            'peso': 100.0 + (DateTime.now().millisecondsSinceEpoch % 200),
            'origen': 'Centro Acopio',
            'fecha': DateTime.now(),
          },
        );
        
        _scannedLots.add(Map.from(lot));
      }
    });
    
    if (_scannedLots.isNotEmpty && !_isScanning) {
      _showLotSummary();
    }
  }

  String _extractMaterial(String code) {
    // Extract material from QR code format: LOTE-MATERIAL-ID
    final parts = code.split('-');
    return parts.length >= 2 ? parts[1] : 'Unknown';
  }

  void _showLotSummary() {
    if (_scannedLots.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransporteResumenCargaScreen(
            loteInicial: _scannedLots.first,
          ),
        ),
      ).then((_) {
        // Handle return from summary screen
        _proceedToForm();
      });
    }
  }

  void _proceedToForm() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TransporteFormsScreen.pickup(
          lots: _scannedLots,
        ),
      ),
    );
  }

  void _removeLot(int index) {
    setState(() {
      _scannedLots.removeAt(index);
    });
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar lista'),
        content: const Text('¿Deseas eliminar todos los lotes escaneados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _scannedLots.clear());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BioWayColors.error,
            ),
            child: const Text(
              'Limpiar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        // Already on recoger
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/transporte_entregar');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/transporte_ayuda');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/transporte_perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalWeight = TransporteServices.calculateTotalWeight(_scannedLots);
    final groupedLots = TransporteServices.groupLotsByOrigin(_scannedLots);
    
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
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () => Navigator.pop(context),
                        color: BioWayColors.darkGreen,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recoger Lotes',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.darkGreen,
                              ),
                            ),
                            Text(
                              'Escanea los lotes a transportar',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_scannedLots.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_all),
                          onPressed: _clearAll,
                          color: BioWayColors.error,
                          tooltip: 'Limpiar todo',
                        ),
                    ],
                  ),
                  if (_scannedLots.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: 'Lotes Escaneados',
                            value: _scannedLots.length.toString(),
                            icon: Icons.inventory_2,
                            iconColor: BioWayColors.ecoceGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            label: 'Peso Total',
                            value: '${totalWeight.toStringAsFixed(1)} kg',
                            icon: Icons.scale,
                            iconColor: BioWayColors.info,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _scannedLots.isEmpty
                  ? _buildEmptyState()
                  : _buildLotsList(groupedLots),
            ),
            
            // Action buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_scannedLots.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showScanner,
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
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _scannedLots.isEmpty ? _showScanner : _showLotSummary,
                      icon: Icon(_scannedLots.isEmpty ? Icons.qr_code_scanner : Icons.arrow_forward),
                      label: Text(_scannedLots.isEmpty ? 'Escanear Lotes' : 'Continuar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BioWayColors.ecoceGreen,
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
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: 0,
        onItemTapped: _onBottomNavTapped,
        primaryColor: BioWayColors.petBlue,
        items: TransporteServices.navigationItems,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: BioWayColors.ecoceGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner,
              size: 60,
              color: BioWayColors.ecoceGreen,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sin lotes escaneados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: BioWayColors.darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escanea los códigos QR de los lotes\nque deseas transportar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLotsList(Map<String, List<Map<String, dynamic>>> groupedLots) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: groupedLots.length,
      itemBuilder: (context, groupIndex) {
        final origin = groupedLots.keys.elementAt(groupIndex);
        final lots = groupedLots[origin]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (groupIndex > 0) const SizedBox(height: 20),
            // Origin header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: BioWayColors.ecoceGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18,
                    color: BioWayColors.ecoceGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      origin,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BioWayColors.darkGreen,
                      ),
                    ),
                  ),
                  Text(
                    '${lots.length} ${lots.length == 1 ? 'lote' : 'lotes'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Lots for this origin
            ...lots.map((lot) {
              final index = _scannedLots.indexOf(lot);
              return _buildLotCard(lot, index);
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildLotCard(Map<String, dynamic> lot, int index) {
    final material = lot['material'] as String;
    final materialColor = TransporteServices.getMaterialColor(material);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(lot['id']),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _removeLot(index),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: BioWayColors.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 28,
          ),
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: materialColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    TransporteServices.getMaterialIcon(material),
                    color: materialColor,
                    size: 24,
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
                        '$material • ${TransporteServices.formatWeight(lot['peso'])}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey[400],
                  ),
                  onPressed: () => _removeLot(index),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}