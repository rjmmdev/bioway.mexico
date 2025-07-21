import 'package:flutter/material.dart';
import 'transformador_lotes_registro_screen.dart';
import '../shared/widgets/qr_scanner_widget.dart';
import '../../../utils/colors.dart';

class TransformadorEscaneoScreen extends StatelessWidget {
  final bool isAddingMore;

  const TransformadorEscaneoScreen({
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
          builder: (context) => TransformadorLotesRegistroScreen(initialLotId: lotId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharedQRScannerScreen(
      title: 'Recibir Lotes',
      subtitle: 'Paso 1: Escanear o ingresar ID',
      onCodeScanned: (code) => _navigateToScannedLots(context, code),
      primaryColor: BioWayColors.ecoceGreen,
      headerLabel: 'Transformador',
      headerValue: 'V0000001',
      userType: 'transformador',
      isAddingMore: isAddingMore,
    );
  }
}