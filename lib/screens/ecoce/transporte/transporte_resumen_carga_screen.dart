import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../utils/colors.dart';
import '../../../services/lote_service.dart';
import '../shared/utils/dialog_utils.dart';
import '../shared/widgets/qr_scanner_widget.dart';
import '../shared/widgets/lote_card_unified.dart';
import 'transporte_formulario_carga_screen.dart';

class TransporteResumenCargaScreen extends StatefulWidget {
  final List<Map<String, dynamic>> lotesIniciales;
  
  const TransporteResumenCargaScreen({
    super.key,
    required this.lotesIniciales,
  });

  @override
  State<TransporteResumenCargaScreen> createState() => _TransporteResumenCargaScreenState();
}

class _TransporteResumenCargaScreenState extends State<TransporteResumenCargaScreen> {
  List<Map<String, dynamic>> _scannedLots = [];
  final LoteService _loteService = LoteService();
  bool _showSuccessBanner = true;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    // Agregar todos los lotes iniciales
    _scannedLots.addAll(widget.lotesIniciales);
    
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
      ),
    );
  }

  void _scanAnotherLot() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => SharedQRScannerScreen(
          title: 'Escanear Otro Lote',
          subtitle: 'Apunta al código del lote',
          onCodeScanned: (code) {
            // No hacer nada aquí porque isAddingMore maneja el retorno
          },
          primaryColor: const Color(0xFF3AA45B),
          scanPrompt: 'Apunta al código del lote',
          showManualInput: true,
          manualInputHint: 'Ej: Firebase_ID_1x7h9k3',
          isAddingMore: true,
        ),
      ),
    );
    
    // Si se escaneó un código, procesarlo
    if (code != null) {
      _processScannedCode(code, fromScanner: true);
    }
  }

  void _processScannedCode(String qrData, {bool fromScanner = false}) async {
    // Solo cerrar el scanner si no viene de _scanAnotherLot
    if (!fromScanner) {
      Navigator.pop(context); // Cerrar el scanner
    }
    
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Buscar el lote en Firebase
      final lotesInfo = await _loteService.getLotesInfo([qrData]);
      
      Navigator.pop(context); // Cerrar loading

      if (lotesInfo.isEmpty) {
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Lote no encontrado',
          message: 'El código QR escaneado no corresponde a un lote válido',
        );
        return;
      }

      final loteInfo = lotesInfo.first;
      
      // Verificar que no sea un lote ya escaneado
      if (_scannedLots.any((lot) => lot['id'] == qrData)) {
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Lote duplicado',
          message: 'Este lote ya ha sido escaneado',
        );
        return;
      }
      
      // Convertir la información del lote al formato esperado
      Map<String, dynamic> lot = {};
      
      if (loteInfo['tipo_lote'] == 'lotes_origen') {
        lot = {
          'id': loteInfo['id'],
          'material': loteInfo['ecoce_origen_tipo_poli'] ?? 'Desconocido',
          'peso': (loteInfo['ecoce_origen_peso_nace'] ?? 0).toDouble(),
          'presentacion': loteInfo['ecoce_origen_presentacion'] ?? 'N/A',
          'origen': loteInfo['ecoce_origen_fuente'] ?? 'Origen desconocido',
          'centro_acopio': loteInfo['ecoce_origen_direccion'] ?? 'Sin dirección',
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else if (loteInfo['tipo_lote'] == 'lotes_reciclador') {
        lot = {
          'id': loteInfo['id'],
          'material': _getTipoPredominante(loteInfo['ecoce_reciclador_tipo_poli']),
          'peso': (loteInfo['ecoce_reciclador_peso_resultante'] ?? 0).toDouble(),
          'presentacion': 'Procesado',
          'origen': 'Reciclador',
          'centro_acopio': 'Planta de Reciclaje',
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Tipo de lote no válido',
          message: 'Este código QR no corresponde a un lote que pueda ser transportado',
        );
        return;
      }
      
      // Agregar el lote a la lista
      setState(() {
        _scannedLots.add(lot);
        _showSuccessBanner = true;
      });

      // Reiniciar el timer del banner
      _bannerTimer?.cancel();
      _bannerTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showSuccessBanner = false;
          });
        }
      });
    } catch (e) {
      Navigator.pop(context); // Cerrar loading
      
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Error',
        message: 'No se pudo obtener la información del lote: ${e.toString()}',
      );
    }
  }

  String _getTipoPredominante(Map<String, dynamic>? tipoPoli) {
    if (tipoPoli == null || tipoPoli.isEmpty) return 'N/A';
    
    String tipoPredominante = '';
    double maxPorcentaje = 0;
    
    tipoPoli.forEach((tipo, porcentaje) {
      final pct = (porcentaje as num).toDouble();
      if (pct > maxPorcentaje) {
        maxPorcentaje = pct;
        tipoPredominante = tipo;
      }
    });
    
    return tipoPredominante.isEmpty ? 'N/A' : tipoPredominante;
  }

  void _continueToForm() {
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransporteFormularioCargaScreen(
          lotes: _scannedLots,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/transporte_inicio',
              (route) => route.isFirst,
            );
          },
          icon: Icon(
            Icons.home,
            color: BioWayColors.petBlue,
          ),
          tooltip: 'Ir a inicio',
        ),
        title: const Text(
          'Resumen de Carga',
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
                color: Color(0xFFE8F5E9),
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Tarjeta de resumen
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Resumen de Carga',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            // Columna Lotes
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    _scannedLots.length.toString(),
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: BioWayColors.primaryGreen,
                                    ),
                                  ),
                                  const Text(
                                    'Lotes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF606060),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Divisor vertical
                            Container(
                              height: 60,
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                            // Columna Kg Total
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    _pesoTotal.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: BioWayColors.primaryGreen,
                                    ),
                                  ),
                                  const Text(
                                    'Kg Total',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF606060),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Sección de lotes escaneados
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lotes Escaneados',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Lista de lotes
                        if (_scannedLots.isEmpty)
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 60,
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
                                ],
                              ),
                            ),
                          )
                        else
                          ...List.generate(_scannedLots.length, (index) {
                            final lote = _scannedLots[index];
                            return _buildLoteCard(lote, index);
                          }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botón escanear otro lote
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: OutlinedButton.icon(
                      onPressed: _scanAnotherLot,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Escanear Otro Lote'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BioWayColors.primaryGreen,
                        side: BorderSide(color: BioWayColors.primaryGreen, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      key: const Key('btn_scan_another'),
                    ),
                  ),

                  const SizedBox(height: 100), // Espacio para el botón fijo
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Botón continuar fijo
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _scannedLots.isNotEmpty ? _continueToForm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: BioWayColors.primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: _scannedLots.isNotEmpty ? 2 : 0,
              ),
              child: Text(
                _scannedLots.isEmpty
                    ? 'Escanea al menos un lote'
                    : 'Continuar al Formulario',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              key: const Key('btn_continue_form'),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildLoteCard(Map<String, dynamic> lote, int index) {
    return LoteCard(
      lote: lote,
      onTap: () {
        // Opcional: mostrar detalles del lote
        HapticFeedback.lightImpact();
      },
      trailing: IconButton(
        onPressed: () => _removeLot(index),
        icon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: BioWayColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.close,
            color: BioWayColors.error,
            size: 16,
          ),
        ),
        key: Key('btn_remove_lote_$index'),
      ),
      showActions: false,
      showQRButton: false,
      showLocation: true,
    );
  }

}