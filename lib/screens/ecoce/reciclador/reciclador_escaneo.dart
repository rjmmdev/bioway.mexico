import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import 'reciclador_lotes_registro.dart';
// TODO: Importar paquete qr_code_scanner cuando se agregue al pubspec.yaml
// import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  final bool isAddingMore; // Indica si está agregando más lotes

  const QRScannerScreen({
    super.key,
    this.isAddingMore = false,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  // TODO: Descomentar cuando se agregue el paquete qr_code_scanner
  // QRViewController? controller;
  // final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  final TextEditingController _manualIdController = TextEditingController();
  bool _isScanning = false;
  bool _showManualInput = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    // TODO: Descomentar cuando se agregue el paquete qr_code_scanner
    // controller?.dispose();
    _manualIdController.dispose();
    super.dispose();
  }

  void _onQRViewCreated(dynamic controller) {
    // TODO: Implementar cuando se agregue el paquete qr_code_scanner
    // this.controller = controller;
    // controller.scannedDataStream.listen((scanData) {
    //   if (_isScanning && scanData.code != null) {
    //     _handleScannedCode(scanData.code!);
    //   }
    // });
  }

  void _handleScannedCode(String code) {
    setState(() {
      _isScanning = false;
      _isProcessing = true;
    });

    // Vibración de éxito
    HapticFeedback.mediumImpact();

    // TODO: Aquí se consultaría la base de datos con el ID escaneado
    // Por ahora simulamos el proceso
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _navigateToScannedLots(code);
      }
    });
  }

  void _handleManualId() {
    final id = _manualIdController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor ingrese un ID válido'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Ocultar teclado
    FocusScope.of(context).unfocus();

    setState(() {
      _isProcessing = true;
    });

    // TODO: Aquí se consultaría la base de datos con el ID manual
    // Por ahora simulamos el proceso
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _navigateToScannedLots(id);
      }
    });
  }

  void _navigateToScannedLots(String lotId) {
    // Si estamos agregando más lotes, devolver el ID
    if (widget.isAddingMore) {
      Navigator.pop(context, lotId);
    } else {
      // Si es la primera vez, navegar a la pantalla de lotes escaneados
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScannedLotsScreen(initialLotId: lotId),
        ),
      );
    }
  }

  void _toggleManualInput() {
    setState(() {
      _showManualInput = !_showManualInput;
      if (!_showManualInput) {
        _manualIdController.clear();
      }
    });
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
    });

    // TODO: Descomentar cuando se agregue el paquete qr_code_scanner
    // controller?.resumeCamera();

    // Simulación temporal
    Future.delayed(const Duration(seconds: 3), () {
      if (_isScanning && mounted) {
        _handleScannedCode('Firebase_ID_1x7h9k3');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: BioWayColors.ecoceGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crear Nuevo Lote',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Paso 1: Escanear lote',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header verde
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: BioWayColors.ecoceGreen,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Recicladora',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'R0000001',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.ecoceGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Área del escáner
                  Container(
                    height: 350,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: BioWayColors.ecoceGreen.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // TODO: Reemplazar con QRView cuando se agregue el paquete
                          // QRView(
                          //   key: qrKey,
                          //   onQRViewCreated: _onQRViewCreated,
                          // ),

                          // Simulación temporal del escáner
                          Container(
                            color: Colors.black87,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner,
                                    size: 80,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 20),
                                  if (_isScanning)
                                    Column(
                                      children: [
                                        SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: CircularProgressIndicator(
                                            color: BioWayColors.ecoceGreen,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Escaneando...',
                                          style: TextStyle(
                                            color: BioWayColors.ecoceGreen,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // Marco del escáner
                          if (!_isProcessing)
                            Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _isScanning
                                      ? BioWayColors.ecoceGreen
                                      : Colors.white.withOpacity(0.5),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Stack(
                                children: [
                                  // Esquinas decorativas
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    child: _buildCorner(true, true),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: _buildCorner(true, false),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    child: _buildCorner(false, true),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: _buildCorner(false, false),
                                  ),
                                ],
                              ),
                            ),

                          // Texto indicativo
                          if (!_isScanning && !_isProcessing)
                            Positioned(
                              bottom: 60,
                              child: Text(
                                'Apunta al código del lote',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ),

                          // Indicador de procesamiento
                          if (_isProcessing)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: BioWayColors.success,
                                    size: 60,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Código escaneado',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: BioWayColors.ecoceGreen,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Botón de iniciar escaneo
                  if (!_isScanning && !_isProcessing)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _startScanning,
                        icon: const Icon(Icons.camera_alt, size: 24),
                        label: const Text(
                          'Iniciar Escaneo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BioWayColors.ecoceGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Opción de ingreso manual
                  if (!_isProcessing)
                    Column(
                      children: [
                        Text(
                          '¿No puedes escanear?',
                          style: TextStyle(
                            fontSize: 14,
                            color: BioWayColors.textGrey,
                          ),
                        ),
                        TextButton(
                          onPressed: _toggleManualInput,
                          child: Text(
                            _showManualInput
                                ? 'Cancelar ingreso manual'
                                : 'Ingresa el ID manualmente',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: BioWayColors.ecoceGreen,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Campo de ingreso manual
                  if (_showManualInput && !_isProcessing)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ingreso Manual de ID',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.darkGreen,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _manualIdController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'Ej: Firebase_ID_1x7h9k3',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                              ),
                              prefixIcon: Icon(
                                Icons.keyboard,
                                color: BioWayColors.ecoceGreen,
                              ),
                              filled: true,
                              fillColor: BioWayColors.backgroundGrey,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: BioWayColors.ecoceGreen.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: BioWayColors.ecoceGreen,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _handleManualId,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BioWayColors.ecoceGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Enviar ID',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? BorderSide(
            color: _isScanning
                ? BioWayColors.ecoceGreen
                : Colors.white,
            width: 3,
          )
              : BorderSide.none,
          bottom: !isTop
              ? BorderSide(
            color: _isScanning
                ? BioWayColors.ecoceGreen
                : Colors.white,
            width: 3,
          )
              : BorderSide.none,
          left: isLeft
              ? BorderSide(
            color: _isScanning
                ? BioWayColors.ecoceGreen
                : Colors.white,
            width: 3,
          )
              : BorderSide.none,
          right: !isLeft
              ? BorderSide(
            color: _isScanning
                ? BioWayColors.ecoceGreen
                : Colors.white,
            width: 3,
          )
              : BorderSide.none,
        ),
      ),
    );
  }
}