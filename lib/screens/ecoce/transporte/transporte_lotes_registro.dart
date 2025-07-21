import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
import '../shared/utils/material_utils.dart';
import 'transporte_forms_screen.dart';
import 'transporte_escaneo_qr.dart';

class TransporteLotesRegistro extends StatefulWidget {
  final String? initialScannedCode;
  
  const TransporteLotesRegistro({
    super.key,
    this.initialScannedCode,
  });

  @override
  State<TransporteLotesRegistro> createState() => _TransporteLotesRegistroState();
}

class _TransporteLotesRegistroState extends State<TransporteLotesRegistro> {
  final List<Map<String, dynamic>> _scannedLots = [];
  
  // Mock available lots for demo
  final List<Map<String, dynamic>> _availableLots = [
    {
      'id': 'LOTE-PEBD-001',
      'material': 'PEBD',
      'peso': 150.5,
      'origen': 'Centro Acopio Norte',
      'fecha': '15/07/2025',
      'presentacion': 'Pacas',
    },
    {
      'id': 'LOTE-PP-002',
      'material': 'PP',
      'peso': 200.0,
      'origen': 'Planta Separación Sur',
      'fecha': '15/07/2025',
      'presentacion': 'Sacos',
    },
    {
      'id': 'LOTE-MULTI-003',
      'material': 'Multilaminado',
      'peso': 175.0,
      'origen': 'Centro Acopio Este',
      'fecha': '14/07/2025',
      'presentacion': 'Pacas',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialScannedCode != null) {
      _addScannedLot(widget.initialScannedCode!);
    }
  }

  void _addScannedLot(String code) {
    // Check if already scanned
    if (_scannedLots.any((lot) => lot['id'] == code)) {
      _showErrorSnackBar('Este lote ya fue escaneado');
      return;
    }
    
    // Find lot in available lots (in production, would query Firestore)
    final lot = _availableLots.firstWhere(
      (l) => l['id'] == code,
      orElse: () => {
        'id': code,
        'material': _extractMaterial(code),
        'peso': 100.0 + (DateTime.now().millisecondsSinceEpoch % 200),
        'origen': 'Centro Acopio',
        'fecha': _formatDate(DateTime.now()),
        'presentacion': 'Pacas',
      },
    );
    
    setState(() {
      _scannedLots.add(Map.from(lot));
    });
  }

  String _extractMaterial(String code) {
    final parts = code.split('-');
    return parts.length >= 2 ? parts[1] : 'Unknown';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  double get _pesoTotal => _scannedLots.fold(0.0, (sum, lote) => sum + (lote['peso'] as double));

  void _removeLot(int index) {
    HapticFeedback.lightImpact();
    final removedLot = _scannedLots[index];
    
    setState(() {
      _scannedLots.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Lote eliminado'),
        backgroundColor: BioWayColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Deshacer',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _scannedLots.insert(index, removedLot);
            });
          },
        ),
      ),
    );
  }

  void _addMoreLots() {
    HapticFeedback.lightImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const TransporteEscaneoQR(isAddingMore: true),
      ),
    );
  }

  void _proceedToForm() {
    if (_scannedLots.isEmpty) {
      _showErrorSnackBar('Debes escanear al menos un lote');
      return;
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TransporteFormsScreen.pickup(
          lots: _scannedLots,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BioWayColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: BioWayColors.petBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const TransporteEscaneoQR(),
              ),
            );
          },
        ),
        title: const Text(
          'Lotes Escaneados',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_scannedLots.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _scannedLots.clear();
                });
              },
              child: const Text(
                'Limpiar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header con resumen
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: BioWayColors.petBlue,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Lotes',
                      _scannedLots.length.toString(),
                      Icons.inventory_2,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    _buildStatItem(
                      'Peso Total',
                      '${_pesoTotal.toStringAsFixed(1)} kg',
                      Icons.scale,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Botón para agregar más
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addMoreLots,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Agregar más lotes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de lotes
          Expanded(
            child: _scannedLots.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _scannedLots.length,
                    itemBuilder: (context, index) {
                      final lote = _scannedLots[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: Key(lote['id']),
                          direction: DismissDirection.endToStart,
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
                          onDismissed: (direction) {
                            _removeLot(index);
                          },
                          child: _buildLoteCard(lote),
                        ),
                      );
                    },
                  ),
          ),

          // Botón de continuar
          if (_scannedLots.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _proceedToForm,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    'Continuar con ${_scannedLots.length} lote${_scannedLots.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.petBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildLoteCard(Map<String, dynamic> lote) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Material icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: MaterialUtils.getMaterialColor(lote['material']).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    MaterialUtils.getMaterialIcon(lote['material']),
                    color: MaterialUtils.getMaterialColor(lote['material']),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Lot info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            lote['id'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.darkGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: MaterialUtils.getMaterialColor(lote['material']).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              lote['material'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: MaterialUtils.getMaterialColor(lote['material']),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lote['origen'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.scale,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${lote['peso']} kg',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.inventory_2,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lote['presentacion'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Delete button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: BioWayColors.error,
                  ),
                  onPressed: () => _removeLot(_scannedLots.indexOf(lote)),
                ),
              ],
            ),
          ),
        ),
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
              color: BioWayColors.petBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 60,
              color: BioWayColors.petBlue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay lotes escaneados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: BioWayColors.darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escanea el código QR de un lote\npara comenzar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addMoreLots,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear lote'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BioWayColors.petBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}