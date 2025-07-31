import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../utils/qr_utils.dart';
import '../shared/widgets/qr_scanner_widget.dart';
import 'reciclador_lotes_registro.dart';

/// Pantalla de escaneo QR para el Usuario Reciclador
/// Utiliza el widget compartido QRScannerWidget y navega a la pantalla de registro de lotes
class RecicladorEscaneoQR extends StatelessWidget {
  final bool isAddingMore;
  
  const RecicladorEscaneoQR({
    super.key, 
    this.isAddingMore = false,
  });

  void _handleCodeScanned(BuildContext context, String qrCode) {
    // Extraer el ID del lote del código QR
    final loteId = QRUtils.extractLoteIdFromQR(qrCode);
    
    if (isAddingMore) {
      // Si estamos agregando más lotes, devolver el ID
      Navigator.pop(context, loteId);
    } else {
      // Si es el primer lote, navegar a la pantalla de registro
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScannedLotsScreen(
            initialScannedCode: loteId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharedQRScannerScreen(
      title: 'Escanear Lote',
      subtitle: 'Reciclador',
      onCodeScanned: (code) => _handleCodeScanned(context, code),
      userType: 'reciclador',
      showManualInput: true,
      manualInputHint: 'Ej: LOTE-PEBD-001',
      primaryColor: BioWayColors.ecoceGreen,
      scanPrompt: 'Apunta al código QR del lote',
      headerLabel: 'Usuario:',
      headerValue: 'Reciclador',
      isAddingMore: isAddingMore,
    );
  }
}