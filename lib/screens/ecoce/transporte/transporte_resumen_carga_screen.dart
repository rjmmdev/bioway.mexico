import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../utils/colors.dart';
import '../shared/utils/material_utils.dart';
import '../reciclador/widgets/reciclador_lote_card.dart';
import 'transporte_escaneo.dart';
import 'transporte_recoger_screen.dart';

class TransporteResumenCargaScreen extends StatefulWidget {
  final Map<String, dynamic> loteInicial;
  
  const TransporteResumenCargaScreen({
    super.key,
    required this.loteInicial,
  });

  @override
  State<TransporteResumenCargaScreen> createState() => _TransporteResumenCargaScreenState();
}

class _TransporteResumenCargaScreenState extends State<TransporteResumenCargaScreen> {
  List<Map<String, dynamic>> _scannedLots = [];
  bool _showSuccessBanner = true;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    // Agregar el lote inicial
    _scannedLots.add(widget.loteInicial);
    
    // Configurar el timer para ocultar el banner después de 3 segundos
    _bannerTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSuccessBanner = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  double get _pesoTotal => _scannedLots.fold(0.0, (sum, lote) => sum + (lote['peso'] as double));

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
        builder: (context) => const TransporteEscaneoScreen(isAddingMore: true),
      ),
    );

    // Si regresa con un ID, agregarlo
    if (result != null && result.isNotEmpty) {
      setState(() {
        _scannedLots.add({
          'id': result,
          'firebaseId': 'Firebase_ID_$result',
          'material': _getMaterialForDemo(result),
          'peso': _getWeightForDemo(),
          'presentacion': _getFormatForDemo(),
          'origen': 'Centro de Acopio ${["Norte", "Sur", "Este", "Oeste"][DateTime.now().millisecondsSinceEpoch % 4]}',
          'fecha': MaterialUtils.formatDate(DateTime.now()),
        });
      });
    }
  }

  // Métodos temporales para simular datos
  String _getMaterialForDemo(String id) {
    final materials = ['PET', 'HDPE', 'LDPE', 'PP', 'PS', 'PVC', 'Otros'];
    return materials[id.length % materials.length];
  }

  double _getWeightForDemo() {
    return 30 + (DateTime.now().millisecondsSinceEpoch % 70);
  }

  String _getFormatForDemo() {
    return DateTime.now().millisecondsSinceEpoch % 2 == 0 ? 'Pacas' : 'Sacos';
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

    // Navegar al formulario de carga
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransporteRecogerScreen(
          lotesSeleccionados: _scannedLots,
        ),
      ),
    );
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
          'Lotes para Transportar',
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
          // Banner de confirmación animado
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showSuccessBanner ? null : 0,
            child: AnimatedOpacity(
              opacity: _showSuccessBanner ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
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
                        'Lote escaneado correctamente',
                        style: TextStyle(
                          fontSize: 14,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Resumen de carga con gradiente azul transportista
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BioWayColors.deepBlue,
                  BioWayColors.deepBlue.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: BioWayColors.deepBlue.withOpacity(0.3),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
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
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 60,
                      width: 1,
                      color: Colors.white24,
                    ),
                    Column(
                      children: [
                        Text(
                          _pesoTotal.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Kg Total',
                          style: TextStyle(
                            fontSize: 16,
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
                    color: BioWayColors.deepBlue,
                    size: 20,
                  ),
                  label: Text(
                    'Agregar',
                    style: TextStyle(
                      color: BioWayColors.deepBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: BioWayColors.deepBlue.withOpacity(0.1),
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
                              color: BioWayColors.deepBlue,
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
                      
                      return RecicladorLoteCard(
                        lote: lot,
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
                    backgroundColor: BioWayColors.deepBlue,
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
}