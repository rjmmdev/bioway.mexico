import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../utils/colors.dart';

class SharedQRScannerScreen extends StatefulWidget {
  final bool isAddingMore;
  
  const SharedQRScannerScreen({
    super.key,
    this.isAddingMore = false,
  });

  @override
  State<SharedQRScannerScreen> createState() => _SharedQRScannerScreenState();
}

class _SharedQRScannerScreenState extends State<SharedQRScannerScreen> {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  
  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  
  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _hasScanned = true;
        });
        HapticFeedback.mediumImpact();
        Navigator.pop(context, barcode.rawValue);
        break;
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.isAddingMore ? 'Escanear otro lote' : 'Escanear código QR',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _controller?.torchEnabled ?? false 
                  ? Icons.flash_on 
                  : Icons.flash_off,
              color: _controller?.torchEnabled ?? false 
                  ? Colors.yellow 
                  : Colors.white,
            ),
            onPressed: () => _controller?.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          
          // Overlay con marco de escaneo
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.transparent),
            ),
            child: Stack(
              children: [
                // Oscurecer áreas fuera del recuadro
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.srcOut,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          backgroundBlendMode: BlendMode.dstOut,
                        ),
                      ),
                      Center(
                        child: Container(
                          height: 300,
                          width: 300,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Marco del escáner
                Center(
                  child: Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
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
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: BioWayColors.primaryGreen, width: 4),
                                left: BorderSide(color: BioWayColors.primaryGreen, width: 4),
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: BioWayColors.primaryGreen, width: 4),
                                right: BorderSide(color: BioWayColors.primaryGreen, width: 4),
                              ),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: BioWayColors.primaryGreen, width: 4),
                                left: BorderSide(color: BioWayColors.primaryGreen, width: 4),
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: BioWayColors.primaryGreen, width: 4),
                                right: BorderSide(color: BioWayColors.primaryGreen, width: 4),
                              ),
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Instrucciones
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 40,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Coloca el código QR dentro del recuadro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El escaneo es automático',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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
}