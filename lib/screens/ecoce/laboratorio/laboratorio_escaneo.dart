import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'laboratorio_registro_muestras.dart';
import '../shared/widgets/shared_qr_scanner_screen.dart';
import '../../../utils/qr_utils.dart';

class LaboratorioEscaneoScreen extends StatefulWidget {
  final bool isAddingMore;

  const LaboratorioEscaneoScreen({
    super.key,
    this.isAddingMore = false,
  });

  @override
  State<LaboratorioEscaneoScreen> createState() => _LaboratorioEscaneoScreenState();
}

class _LaboratorioEscaneoScreenState extends State<LaboratorioEscaneoScreen> {
  void _navigateToScannedMuestras(String qrCode) async {
    // Dar tiempo para que el escáner libere los recursos de la cámara
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    // Verificar si es un código QR de muestra de megalote
    if (qrCode.startsWith('MUESTRA-MEGALOTE-')) {
      // Es una muestra de megalote, procesarla directamente
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LaboratorioRegistroMuestrasScreen(
            initialMuestraId: qrCode, // Pasar el QR completo
            isMegaloteSample: true,
          ),
        ),
      );
    } else {
      // Es un lote normal, extraer el ID
      final loteId = QRUtils.extractLoteIdFromQR(qrCode);
      
      // Si estamos agregando más muestras, devolver el ID
      if (widget.isAddingMore) {
        Navigator.pop(context, loteId);
      } else {
        // Si es la primera vez, navegar a la pantalla de muestras escaneadas
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LaboratorioRegistroMuestrasScreen(
              initialMuestraId: loteId,
              isMegaloteSample: false,
            ),
          ),
        );
      }
    }
  }
  
  Future<void> _scanQR() async {
    HapticFeedback.lightImpact();
    
    final qrCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => SharedQRScannerScreen(
          isAddingMore: widget.isAddingMore,
        ),
      ),
    );
    
    if (qrCode != null && mounted) {
      _navigateToScannedMuestras(qrCode);
    }
  }

  @override
  void initState() {
    super.initState();
    // Iniciar el escaneo automáticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanQR();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla temporal mientras se abre el scanner
    return Scaffold(
      backgroundColor: Colors.black,
      body: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF9333EA), // Morado para laboratorio
        ),
      ),
    );
  }
}