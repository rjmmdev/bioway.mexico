import 'package:flutter/material.dart';
import 'laboratorio_registro_muestras.dart';
import '../shared/widgets/qr_scanner_widget.dart';
import '../../../utils/colors.dart';

class LaboratorioEscaneoScreen extends StatelessWidget {
  final bool isAddingMore;

  const LaboratorioEscaneoScreen({
    super.key,
    this.isAddingMore = false,
  });

  void _navigateToScannedMuestras(BuildContext context, String muestraId) {
    // Si estamos agregando más muestras, devolver el ID
    if (isAddingMore) {
      Navigator.pop(context, muestraId);
    } else {
      // Si es la primera vez, navegar a la pantalla de muestras escaneadas
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LaboratorioRegistroMuestrasScreen(initialMuestraId: muestraId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharedQRScannerScreen(
      title: 'Registrar Nueva Muestra',
      subtitle: 'Paso 1: Escanear muestra',
      onCodeScanned: (code) => _navigateToScannedMuestras(context, code),
      primaryColor: BioWayColors.ecoceGreen,
      headerLabel: 'Laboratorio',
      headerValue: 'L0000001',
      userType: 'laboratorio',
      isAddingMore: isAddingMore,
    );
  }
}