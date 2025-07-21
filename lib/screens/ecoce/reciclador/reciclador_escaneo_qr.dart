import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
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

  void _handleCodeScanned(BuildContext context, String code) {
    // Navegar a la pantalla de registro de lotes con el código escaneado
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ScannedLotsScreen(
          initialScannedCode: code,
        ),
      ),
    );
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