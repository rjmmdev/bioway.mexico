import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../shared/utils/material_utils.dart';
import 'transformador_escaneo_screen.dart';
import 'transformador_recibir_lote_screen.dart';

// Modelo temporal para representar un lote
class ScannedLot {
  final String id;
  final String material;
  final double weight;
  final String origen;
  final DateTime dateScanned;

  ScannedLot({
    required this.id,
    required this.material,
    required this.weight,
    required this.origen,
    required this.dateScanned,
  });
}

class TransformadorLotesRegistroScreen extends StatefulWidget {
  final String? initialLotId;

  const TransformadorLotesRegistroScreen({
    super.key,
    this.initialLotId,
  });

  @override
  State<TransformadorLotesRegistroScreen> createState() => _TransformadorLotesRegistroScreenState();
}

class _TransformadorLotesRegistroScreenState extends State<TransformadorLotesRegistroScreen> {
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
      origen: _getOrigenForDemo(),
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

  String _getOrigenForDemo() {
    final origenes = ['RECICLADOR PLASTICOS DEL NORTE', 'PLANTA DE RECICLAJE INDUSTRIAL', 'CENTRO DE ACOPIO SUSTENTABLE'];
    return origenes[DateTime.now().millisecondsSinceEpoch % origenes.length];
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
      ),
    );
  }

  void _addMoreLots() async {
    HapticFeedback.lightImpact();

    // Navegar al escáner indicando que estamos agregando más lotes
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const TransformadorEscaneoScreen(isAddingMore: true),
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
          content: const Text('Debe escanear o ingresar al menos un lote'),
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

    // Navegar al formulario con los lotes escaneados
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransformadorRecibirLoteScreen(
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
          'Lotes para Recibir',
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
          if (_scannedLots.isNotEmpty)
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
                      'Lote agregado correctamente',
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
                  BioWayColors.ecoceGreen.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: BioWayColors.ecoceGreen.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Resumen de Recepción',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          _scannedLots.length.toString(),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Lotes',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 50,
                      width: 1,
                      color: Colors.white24,
                    ),
                    Column(
                      children: [
                        Text(
                          '${_scannedLots.fold<double>(0, (sum, lot) => sum + lot.weight).toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Peso Total',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                  'Lotes Registrados',
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
                    backgroundColor: BioWayColors.ecoceGreen.withValues(alpha: 0.1),
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
                    Icons.qr_code_scanner_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay lotes registrados',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _addMoreLots,
                    child: Text(
                      'Escanear o ingresar primer lote',
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
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _scannedLots.length,
              itemBuilder: (context, index) {
                final lot = _scannedLots[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  child: Dismissible(
                    key: Key(lot.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) => _removeLot(index),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: BioWayColors.error,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Indicador de material
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: MaterialUtils.getMaterialColor(lot.material).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                lot.material.substring(0, 2).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getMaterialColor(lot.material),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Información del lote
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ID: ${lot.id}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: BioWayColors.darkGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${lot.weight.toStringAsFixed(1)} kg • ${lot.material}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lot.origen,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Ícono de eliminar
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                            onPressed: () => _removeLot(index),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Botón flotante
      floatingActionButton: _scannedLots.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _continueWithLots,
        backgroundColor: BioWayColors.ecoceGreen,
        elevation: 4,
        icon: const Icon(Icons.arrow_forward, color: Colors.white),
        label: const Text(
          'Continuar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}