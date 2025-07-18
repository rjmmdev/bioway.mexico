import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/utils/navigation_utils.dart';
import '../../../utils/colors.dart';
import 'transporte_entregar_screen.dart';
import 'transporte_ayuda_screen.dart';
import 'transporte_perfil_screen.dart';
import 'transporte_resumen_carga_screen.dart';

class TransporteInicioScreen extends StatefulWidget {
  const TransporteInicioScreen({super.key});

  @override
  State<TransporteInicioScreen> createState() => _TransporteInicioScreenState();
}

class _TransporteInicioScreenState extends State<TransporteInicioScreen> {
  final int _selectedIndex = 0;
  final TextEditingController _manualIdController = TextEditingController();
  late MobileScannerController _cameraController;
  bool _isFlashOn = false;
  bool _isProcessing = false;
  bool _isScanning = false;
  
  // Variables de usuario
  final String nombreOperador = 'Juan Pérez'; // TODO: Obtener del auth
  final String folioOperador = 'V0000001'; // TODO: Obtener del auth

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  void _startScanning() async {
    setState(() {
      _isScanning = true;
    });
    await _cameraController.start();
  }

  @override
  void dispose() {
    _manualIdController.dispose();
    if (_isScanning) {
      _cameraController.stop();
    }
    _cameraController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        // Ya estamos en inicio/recoger
        break;
      case 1:
        NavigationUtils.navigateWithFade(
          context,
          const TransporteEntregarScreen(),
          replacement: true,
        );
        break;
      case 2:
        NavigationUtils.navigateWithFade(
          context,
          const TransporteAyudaScreen(),
          replacement: true,
        );
        break;
      case 3:
        NavigationUtils.navigateWithFade(
          context,
          const TransportePerfilScreen(),
          replacement: true,
        );
        break;
    }
  }

  void _processQRCode(String code) {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    HapticFeedback.heavyImpact();
    
    // Procesar el código escaneado
    _procesarEscaneoExitoso(code);
  }

  void _procesarEscaneoExitoso(String loteId) {
    // Navegar a la pantalla de resumen de carga
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransporteResumenCargaScreen(
          loteInicial: {
            'id': loteId,
            'firebaseId': 'Firebase_ID_$loteId',
            'material': 'PET',
            'peso': 45.5,
            'presentacion': 'Pacas',
            'origen': 'Centro de Acopio Norte',
            'fecha': DateTime.now().toString(),
          },
        ),
      ),
    ).then((_) {
      setState(() {
        _isProcessing = false;
      });
    });
  }

  void _ingresarManualmente() {
    if (_manualIdController.text.isNotEmpty) {
      Navigator.pop(context);
      _procesarEscaneoExitoso(_manualIdController.text);
      _manualIdController.clear();
    }
  }

  void _showManualInputModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ingreso Manual de ID',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _manualIdController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Ej: FID_1234567',
                  prefixIcon: const Icon(Icons.qr_code),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (_) => _ingresarManualmente(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _ingresarManualmente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3AA45B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Colors.black54,
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black54,
              backgroundBlendMode: BlendMode.dstOut,
            ),
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: screenWidth * 0.7,
                height: screenWidth * 0.7,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          
          // Marco del visor QR
          Center(
            child: Container(
              width: screenWidth * 0.7,
              height: screenWidth * 0.7,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          
          // Esquinas decorativas
          Center(
            child: SizedBox(
              width: screenWidth * 0.7,
              height: screenWidth * 0.7,
              child: Stack(
                children: [
                  // Esquina superior izquierda
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: const Color(0xFF3AA45B),
                            width: 4,
                          ),
                          left: BorderSide(
                            color: const Color(0xFF3AA45B),
                            width: 4,
                          ),
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  // Esquina superior derecha
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: const Color(0xFF3AA45B),
                            width: 4,
                          ),
                          right: BorderSide(
                            color: const Color(0xFF3AA45B),
                            width: 4,
                          ),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  // Esquina inferior izquierda
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(0xFF3AA45B),
                            width: 4,
                          ),
                          left: BorderSide(
                            color: const Color(0xFF3AA45B),
                            width: 4,
                          ),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  // Esquina inferior derecha
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(0xFF3AA45B),
                            width: 4,
                          ),
                          right: BorderSide(
                            color: const Color(0xFF3AA45B),
                            width: 4,
                          ),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Instrucciones
          Positioned(
            bottom: screenHeight * 0.15,
            left: 0,
            right: 0,
            child: Text(
              'Centra el código QR en el visor',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.02,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3AA45B), Color(0xFF68C76A)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recoger Materiales',
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nombreOperador,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenHeight * 0.005,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Text(
                  folioOperador,
                  key: const Key('folio'),
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            if (_isScanning)
              MobileScanner(
                controller: _cameraController,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null && !_isProcessing) {
                      _processQRCode(barcode.rawValue!);
                    }
                  }
                },
              ),

            if (_isScanning) _buildScannerOverlay(),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(screenWidth, screenHeight),
            ),

            if (_isScanning)
              Positioned(
                top: screenHeight * 0.14,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () async {
                      setState(() {
                        _isFlashOn = !_isFlashOn;
                      });
                      await _cameraController.toggleTorch();
                    },
                  ),
                ),
              ),

            if (_isScanning)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: TextButton(
                    key: const Key('link_manual_entry'),
                    onPressed: _showManualInputModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Ingresa el ID manualmente',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            if (!_isScanning)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: screenWidth * 0.4,
                      color: const Color(0xFF3AA45B),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    SizedBox(
                      width: screenWidth * 0.6,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _startScanning,
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Iniciar Escaneo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3AA45B),
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
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        primaryColor: BioWayColors.deepBlue,
        items: EcoceNavigationConfigs.transporteItems,
      ),
    );
  }
}