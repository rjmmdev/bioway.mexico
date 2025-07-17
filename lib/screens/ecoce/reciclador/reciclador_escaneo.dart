import 'package:flutter/material.dart';
import 'reciclador_lotes_registro.dart';
import '../shared/widgets/qr_scanner_widget.dart';
import '../../../utils/colors.dart';

class QRScannerScreen extends StatelessWidget {
  final bool isAddingMore;

  const QRScannerScreen({
    super.key,
    this.isAddingMore = false,
  });

  void _navigateToScannedLots(BuildContext context, String lotId) {
    // Si estamos agregando más lotes, devolver el ID
    if (isAddingMore) {
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

  @override
  Widget build(BuildContext context) {
    return SharedQRScannerScreen(
      title: 'Crear Nuevo Lote',
      subtitle: 'Paso 1: Escanear lote',
      onCodeScanned: (code) => _navigateToScannedLots(context, code),
      primaryColor: BioWayColors.ecoceGreen,
      headerLabel: 'Recicladora',
      headerValue: 'R0000001',
      userType: 'reciclador',
      isAddingMore: isAddingMore,
    );
  }
}