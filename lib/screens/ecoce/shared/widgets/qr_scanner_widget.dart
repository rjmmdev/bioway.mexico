import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../utils/colors.dart';

/// Widget compartido para escaneo de códigos QR
/// Puede ser utilizado por cualquier usuario del sistema ECOCE
class QRScannerWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? userType;
  final String? userId;
  final Function(String) onCodeScanned;
  final bool showManualInput;
  final String manualInputHint;
  final Color primaryColor;
  final String scanPrompt;
  final String? headerLabel;
  final String? headerValue;

  const QRScannerWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onCodeScanned,
    this.userType,
    this.userId,
    this.showManualInput = true,
    this.manualInputHint = 'Ej: Firebase_ID_1x7h9k3',
    this.primaryColor = const Color(0xFF4CAF50), // Verde ECOCE por defecto
    this.scanPrompt = 'Apunta al código del lote',
    this.headerLabel,
    this.headerValue,
  });

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  MobileScannerController controller = MobileScannerController();
  final TextEditingController _manualIdController = TextEditingController();
  bool _isScanning = false;
  bool _showManualInput = false;
  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  void dispose() {
    controller.dispose();
    _manualIdController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (_isScanning && barcodes.isNotEmpty && !_isProcessing) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code != _lastScannedCode) {
        _handleScannedCode(code);
      }
    }
  }

  void _handleScannedCode(String code) {
    setState(() {
      _isScanning = false;
      _isProcessing = true;
      _lastScannedCode = code;
    });

    // Vibración de éxito
    HapticFeedback.mediumImpact();

    // Detener el escáner
    controller.stop();

    // Esperar un momento para mostrar la animación
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        widget.onCodeScanned(code);
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

    // Esperar un momento para mostrar la animación
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        widget.onCodeScanned(id);
      }
    });
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
      _lastScannedCode = null;
    });

    controller.start();
  }

  void _resetScanner() {
    setState(() {
      _isScanning = false;
      _isProcessing = false;
      _lastScannedCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: widget.primaryColor,
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
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header con información del usuario (opcional)
          if (widget.headerLabel != null && widget.headerValue != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: widget.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.headerLabel!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
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
                      widget.headerValue!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.primaryColor,
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
                        color: widget.primaryColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Escáner QR
                          if (!_isProcessing)
                            MobileScanner(
                              controller: controller,
                              onDetect: _onDetect,
                            ),

                          // Marco del escáner
                          if (!_isProcessing)
                            Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _isScanning
                                      ? widget.primaryColor
                                      : Colors.white.withValues(alpha: 0.5),
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
                                widget.scanPrompt,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
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
                                  const Text(
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
                                      color: widget.primaryColor,
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
                          backgroundColor: widget.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),

                  // Botón de reintentar cuando hay error
                  if (_isProcessing)
                    TextButton(
                      onPressed: _resetScanner,
                      child: Text(
                        'Reintentar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: widget.primaryColor,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Opción de ingreso manual
                  if (!_isProcessing && widget.showManualInput)
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
                              color: widget.primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Campo de ingreso manual
                  if (_showManualInput && !_isProcessing && widget.showManualInput)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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
                            textCapitalization: TextCapitalization.none,
                            decoration: InputDecoration(
                              hintText: widget.manualInputHint,
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                              ),
                              prefixIcon: Icon(
                                Icons.keyboard,
                                color: widget.primaryColor,
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
                                  color: widget.primaryColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: widget.primaryColor,
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
                                backgroundColor: widget.primaryColor,
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
                  color: _isScanning ? widget.primaryColor : Colors.white,
                  width: 3,
                )
              : BorderSide.none,
          bottom: !isTop
              ? BorderSide(
                  color: _isScanning ? widget.primaryColor : Colors.white,
                  width: 3,
                )
              : BorderSide.none,
          left: isLeft
              ? BorderSide(
                  color: _isScanning ? widget.primaryColor : Colors.white,
                  width: 3,
                )
              : BorderSide.none,
          right: !isLeft
              ? BorderSide(
                  color: _isScanning ? widget.primaryColor : Colors.white,
                  width: 3,
                )
              : BorderSide.none,
        ),
      ),
    );
  }
}

/// Página simple de escaneo QR que utiliza el widget compartido
class SharedQRScannerScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final Function(String) onCodeScanned;
  final String? userType;
  final String? userId;
  final bool showManualInput;
  final String manualInputHint;
  final Color primaryColor;
  final String scanPrompt;
  final String? headerLabel;
  final String? headerValue;
  final bool isAddingMore;

  const SharedQRScannerScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onCodeScanned,
    this.userType,
    this.userId,
    this.showManualInput = true,
    this.manualInputHint = 'Ej: Firebase_ID_1x7h9k3',
    this.primaryColor = const Color(0xFF4CAF50),
    this.scanPrompt = 'Apunta al código del lote',
    this.headerLabel,
    this.headerValue,
    this.isAddingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return QRScannerWidget(
      title: title,
      subtitle: subtitle,
      onCodeScanned: (code) {
        // Si estamos agregando más lotes, devolver el ID
        if (isAddingMore) {
          Navigator.pop(context, code);
        } else {
          // Si no, ejecutar la función callback
          onCodeScanned(code);
        }
      },
      userType: userType,
      userId: userId,
      showManualInput: showManualInput,
      manualInputHint: manualInputHint,
      primaryColor: primaryColor,
      scanPrompt: scanPrompt,
      headerLabel: headerLabel,
      headerValue: headerValue,
    );
  }
}