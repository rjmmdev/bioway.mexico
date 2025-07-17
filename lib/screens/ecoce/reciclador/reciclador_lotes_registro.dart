import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import 'reciclador_escaneo.dart';
import 'reciclador_formulario_entrada.dart';
import 'widgets/reciclador_lote_card.dart';

// Modelo temporal para representar un lote
class ScannedLot {
  final String id;
  final String material;
  final double weight;
  final String format; // 'Pacas' o 'Sacos'
  final DateTime dateScanned;

  ScannedLot({
    required this.id,
    required this.material,
    required this.weight,
    required this.format,
    required this.dateScanned,
  });
}

class ScannedLotsScreen extends StatefulWidget {
  final String? initialLotId;

  const ScannedLotsScreen({
    super.key,
    this.initialLotId,
  });

  @override
  State<ScannedLotsScreen> createState() => _ScannedLotsScreenState();
}

class _ScannedLotsScreenState extends State<ScannedLotsScreen> {
  // Lista de lotes escaneados
  List<ScannedLot> _scannedLots = [];

  @override
  void initState() {
    super.initState();
    // Si viene con un ID inicial, agregarlo a la lista
    if (widget.initialLotId != null) {
      _addLotFromId(widget.initialLotId!);
    }
  }

  void _addLotFromId(String lotId) {
    // TODO: Aquí se consultaría la base de datos con el ID
    // Por ahora simulamos datos
    final newLot = ScannedLot(
      id: lotId,
      material: _getMaterialForDemo(lotId),
      weight: _getWeightForDemo(),
      format: _getFormatForDemo(),
      dateScanned: DateTime.now(),
    );

    setState(() {
      _scannedLots.add(newLot);
    });
  }

  // Métodos temporales para simular datos
  String _getMaterialForDemo(String id) {
    final materials = ['PEBD', 'PP', 'Multilaminado'];
    return materials[id.length % materials.length];
  }

  double _getWeightForDemo() {
    return 100 + (DateTime.now().millisecondsSinceEpoch % 200);
  }

  String _getFormatForDemo() {
    return DateTime.now().millisecondsSinceEpoch % 2 == 0 ? 'Pacas' : 'Sacos';
  }

  void _removeLot(int index) {
    HapticFeedback.lightImpact();

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
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Deshacer',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Implementar deshacer eliminación
          },
        ),
      ),
    );
  }

  void _addMoreLots() async {
    HapticFeedback.lightImpact();

    // Navegar al escáner indicando que estamos agregando más lotes
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(isAddingMore: true),
      ),
    );

    // Si regresa con un ID, agregarlo
    if (result != null && result.isNotEmpty) {
      _addLotFromId(result);
    }
  }

  void _continueWithLots() {
    if (_scannedLots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debe escanear al menos un lote'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    // Navegar a la tercera pantalla (formulario)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecicladorFormularioEntrada(
          lotIds: _scannedLots.map((lot) => lot.id).toList(),
          totalLotes: _scannedLots.length,
        ),
      ),
    );
  }

  Color _getMaterialColor(String material) {
    switch (material) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: BioWayColors.darkGreen),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Lotes Escaneados',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: Column(
        children: [
          // Mensaje de confirmación
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: BioWayColors.success,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Código QR escaneado correctamente',
                    style: TextStyle(
                      fontSize: 14,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Resumen de carga
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BioWayColors.ecoceGreen,
                  BioWayColors.ecoceGreen.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: BioWayColors.ecoceGreen.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Resumen de Carga',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _scannedLots.length.toString(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Lotes',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Header de la lista
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lotes Escaneados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addMoreLots,
                  icon: Icon(
                    Icons.add,
                    color: BioWayColors.ecoceGreen,
                    size: 20,
                  ),
                  label: Text(
                    'Agregar',
                    style: TextStyle(
                      color: BioWayColors.ecoceGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: BioWayColors.ecoceGreen.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de lotes
          Expanded(
            child: _scannedLots.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay lotes escaneados',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _addMoreLots,
                    child: Text(
                      'Escanear primer lote',
                      style: TextStyle(
                        color: BioWayColors.ecoceGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _scannedLots.length,
              itemBuilder: (context, index) {
                final lot = _scannedLots[index];
                final loteMap = {
                  'id': lot.id,
                  'material': lot.material,
                  'peso': lot.weight,
                  'presentacion': lot.format,
                  'origen': 'Entrada Pendiente',
                  'fecha': _formatDate(lot.dateScanned),
                };
                
                return RecicladorLoteCard(
                  lote: loteMap,
                  onTap: () {
                    // No hacemos nada en el tap principal
                  },
                  trailing: IconButton(
                    onPressed: () => _removeLot(index),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BioWayColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.close,
                        color: BioWayColors.error,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Botón continuar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _scannedLots.isNotEmpty ? _continueWithLots : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.ecoceGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: _scannedLots.isNotEmpty ? 3 : 0,
                  ),
                  child: Text(
                    _scannedLots.isEmpty
                        ? 'Escanea al menos un lote'
                        : 'Continuar con ${_scannedLots.length} lote${_scannedLots.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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

  // Método legacy mantenido por compatibilidad
  Widget _buildLotCard(ScannedLot lot, int index) {
    final materialColor = _getMaterialColor(lot.material);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del lote
            Row(
              children: [
                // Ícono del material
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: materialColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: materialColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),

                // ID del lote
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lote Identificado',
                        style: TextStyle(
                          fontSize: 12,
                          color: BioWayColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lot.id,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botón eliminar
                IconButton(
                  onPressed: () => _removeLot(index),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BioWayColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close,
                      color: BioWayColors.error,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 16),

            // Detalles del lote
            Row(
              children: [
                // Material
                Expanded(
                  child: _buildLotDetail(
                    icon: Icons.recycling,
                    label: lot.material,
                    sublabel: 'MATERIAL',
                    color: materialColor,
                  ),
                ),

                // Peso
                Expanded(
                  child: _buildLotDetail(
                    icon: Icons.scale,
                    label: '${lot.weight.toStringAsFixed(0)} kg',
                    sublabel: 'PESO',
                    color: BioWayColors.warning,
                  ),
                ),

                // Formato
                Expanded(
                  child: _buildLotDetail(
                    icon: lot.format == 'Pacas' ? Icons.inventory : Icons.shopping_bag,
                    label: lot.format,
                    sublabel: 'PRESENTACIÓN',
                    color: BioWayColors.info,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLotDetail({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: 10,
            color: BioWayColors.textGrey,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}