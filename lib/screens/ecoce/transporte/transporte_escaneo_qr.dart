import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../utils/colors.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import 'transporte_lotes_registro.dart';

class TransporteEscaneoQR extends StatefulWidget {
  final bool isAddingMore;
  
  const TransporteEscaneoQR({
    super.key, 
    this.isAddingMore = false,
  });

  @override
  State<TransporteEscaneoQR> createState() => _TransporteEscaneoQRState();
}

class _TransporteEscaneoQRState extends State<TransporteEscaneoQR> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualCodeController = TextEditingController();
  bool _isProcessing = false;
  bool _showManualInput = false;
  String? _lastScannedCode;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  void _handleCodeScanned(String code) {
    if (_isProcessing || code == _lastScannedCode) return;
    
    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
    });

    HapticFeedback.mediumImpact();
    
    // Navegar a la pantalla de registro de lotes
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TransporteLotesRegistro(
          initialScannedCode: code,
        ),
      ),
    );
  }

  void _processManualCode() {
    final code = _manualCodeController.text.trim();
    if (code.isEmpty) {
      _showErrorSnackBar('Por favor ingresa un código de lote');
      return;
    }
    
    _handleCodeScanned(code);
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

  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        // Ya estamos en recoger
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/transporte_entregar');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/ecoce_ayuda');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/ecoce_perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      resizeToAvoidBottomInset: true, // Para manejar el teclado
      appBar: AppBar(
        backgroundColor: BioWayColors.petBlue,
        elevation: 0,
        title: const Text(
          'Escanear Lote',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _showManualInput 
                      ? 'Ingresa el código manualmente'
                      : 'Escanea el código QR del lote',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isAddingMore 
                      ? 'Agregando más lotes al registro'
                      : 'Inicio de recolección',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Scanner area or manual input
          Expanded(
            child: _showManualInput ? _buildManualInput() : _buildScanner(),
          ),
          
          // Botón flotante para cambiar modo
          if (!_showManualInput)
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showManualInput = true;
                    });
                  },
                  icon: const Icon(Icons.keyboard),
                  label: const Text(
                    'Ingresar ID Manual',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: BioWayColors.petBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(
                        color: BioWayColors.petBlue,
                        width: 2,
                      ),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: 0,
        onItemTapped: _onBottomNavTapped,
        primaryColor: BioWayColors.petBlue,
        items: EcoceNavigationConfigs.transporteItems,
        fabConfig: null,
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        // Scanner reducido
        Container(
          margin: const EdgeInsets.only(top: 20, bottom: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _handleCodeScanned(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),
          ),
        ),
        
        // Overlay
        Container(
          margin: const EdgeInsets.only(top: 20, bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.transparent,
              width: 0,
            ),
          ),
          child: Stack(
            children: [
              // Center cutout with rounded corners
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              
              // Instructions
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'Alinea el código QR dentro del marco',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (_isProcessing) ...[
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Corner indicators
              Center(
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    children: [
                      // Top-left corner
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _buildCorner(true, true),
                      ),
                      // Top-right corner
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _buildCorner(true, false),
                      ),
                      // Bottom-left corner
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: _buildCorner(false, true),
                      ),
                      // Bottom-right corner
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _buildCorner(false, false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: BioWayColors.petBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.keyboard,
              size: 50,
              color: BioWayColors.petBlue,
            ),
          ),
          const SizedBox(height: 30),
          
          // Input field
          TextField(
            controller: _manualCodeController,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: 'Ej: LOTE-PEBD-001',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(
                Icons.tag,
                color: BioWayColors.petBlue,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: BioWayColors.petBlue,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            onSubmitted: (_) => _processManualCode(),
            textCapitalization: TextCapitalization.characters,
            autofocus: true,
          ),
          const SizedBox(height: 30),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _processManualCode,
              icon: const Icon(Icons.check_circle),
              label: const Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 18,
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
          
          const SizedBox(height: 20),
          
          // Botón para volver al scanner
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showManualInput = false;
                _manualCodeController.clear();
              });
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Volver al escáner'),
            style: TextButton.styleFrom(
              foregroundColor: BioWayColors.petBlue,
            ),
          ),
          
          const SizedBox(height: 20),
          Text(
            'Ingresa el código del lote tal como\naparece en la etiqueta',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}