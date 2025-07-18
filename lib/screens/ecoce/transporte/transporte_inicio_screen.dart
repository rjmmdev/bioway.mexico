import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/transporte_bottom_navigation.dart';
import 'transporte_entregar_screen.dart';
import 'transporte_ayuda_screen.dart';
import 'transporte_perfil_screen.dart';
import 'transporte_resumen_carga_screen.dart';
import '../shared/widgets/qr_scanner_widget.dart';

class TransporteInicioScreen extends StatefulWidget {
  const TransporteInicioScreen({super.key});

  @override
  State<TransporteInicioScreen> createState() => _TransporteInicioScreenState();
}

class _TransporteInicioScreenState extends State<TransporteInicioScreen> {
  final int _selectedIndex = 0;
  final TextEditingController _manualIdController = TextEditingController();
  
  // Variables de usuario
  final String nombreOperador = 'Juan Pérez'; // TODO: Obtener del auth
  final String folioOperador = 'V0000001'; // TODO: Obtener del auth

  @override
  void dispose() {
    _manualIdController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        // Ya estamos en inicio/recoger
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const TransporteEntregarScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const TransporteAyudaScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const TransportePerfilScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
    }
  }

  void _iniciarEscaneo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SharedQRScannerScreen(
          title: 'Escanear Lote',
          subtitle: 'Escanea el código QR del lote',
          onCodeScanned: (code) {
            Navigator.pop(context);
            _procesarEscaneoExitoso(code);
          },
          primaryColor: const Color(0xFF3AA45B),
          headerLabel: 'Transportista',
          headerValue: folioOperador,
        ),
      ),
    );
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
    );
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

  List<Widget> _buildCornerGuides(double size) {
    final cornerLength = size * 0.15;
    final cornerWidth = 3.0;
    final cornerColor = Colors.white;
    
    return [
      // Top-left corner
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: cornerLength,
          height: cornerWidth,
          color: cornerColor,
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: cornerWidth,
          height: cornerLength,
          color: cornerColor,
        ),
      ),
      // Top-right corner
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: cornerLength,
          height: cornerWidth,
          color: cornerColor,
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: cornerWidth,
          height: cornerLength,
          color: cornerColor,
        ),
      ),
      // Bottom-left corner
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: cornerLength,
          height: cornerWidth,
          color: cornerColor,
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: cornerWidth,
          height: cornerLength,
          color: cornerColor,
        ),
      ),
      // Bottom-right corner
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: cornerLength,
          height: cornerWidth,
          color: cornerColor,
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: cornerWidth,
          height: cornerLength,
          color: cornerColor,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header con gradiente verde
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3AA45B),
                    Color(0xFF68C76A),
                  ],
                ),
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
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          key: const Key('folio'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Contenido principal - Vista de escáner
            Expanded(
              child: _buildScannerView(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: TransporteBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildScannerView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scannerSize = screenWidth * 0.8;
    
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          SizedBox(height: screenHeight * 0.05),
          
          // Visor cuadrado negro con esquinas guía
          Container(
            width: scannerSize,
            height: scannerSize,
            child: Stack(
              children: [
                // Fondo del visor
                Container(
                  color: Colors.black,
                ),
                
                // Esquinas guía
                ..._buildCornerGuides(scannerSize),
                
                // Icono de cámara central
                Center(
                  child: Icon(
                    Icons.camera_alt,
                    size: screenWidth * 0.15,
                    color: Colors.grey,
                  ),
                ),
                
                // Texto "Escanear Código QR"
                Positioned(
                  bottom: screenHeight * 0.05,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        'Escanear Código QR',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Apunta al código del lote',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: screenHeight * 0.05),

          // Botón primario "Iniciar Escaneo"
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: Container(
              key: const Key('btn_scan_start'),
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3AA45B),
                    Color(0xFF68C76A),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _iniciarEscaneo,
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: Text(
                      'Iniciar Escaneo',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.02),
          
          // Enlace "Ingresa el ID manualmente"
          TextButton(
            key: const Key('link_manual_entry'),
            onPressed: _showManualInputModal,
            child: Text(
              'Ingresa el ID manualmente',
              style: TextStyle(
                color: const Color(0xFF2E7D32),
                fontSize: screenWidth * 0.035,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}