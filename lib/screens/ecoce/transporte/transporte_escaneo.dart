import 'package:flutter/material.dart';
import '../shared/widgets/qr_scanner_widget.dart';
import '../../../utils/colors.dart';
import 'transporte_resumen_carga_screen.dart';

class TransporteEscaneoScreen extends StatelessWidget {
  final bool isAddingMore;
  final String nombreOperador;
  final String folioOperador;

  const TransporteEscaneoScreen({
    super.key,
    this.isAddingMore = false,
    this.nombreOperador = 'Juan Pérez',
    this.folioOperador = 'V0000001',
  });

  void _navigateToResumenCarga(BuildContext context, String lotId) {
    // Si estamos agregando más lotes, devolver el ID
    if (isAddingMore) {
      Navigator.pop(context, lotId);
    } else {
      // Si es la primera vez, navegar a la pantalla de resumen de carga
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TransporteResumenCargaScreen(
            loteInicial: {
              'id': lotId,
              'firebaseId': 'Firebase_ID_$lotId',
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
  }

  @override
  Widget build(BuildContext context) {
    return SharedQRScannerScreen(
      title: 'Recoger Lotes',
      subtitle: 'Escanea el código del lote a recoger',
      onCodeScanned: (code) => _navigateToResumenCarga(context, code),
      primaryColor: BioWayColors.deepBlue,
      headerLabel: 'Transportista',
      headerValue: folioOperador,
      userType: 'transportista',
      isAddingMore: isAddingMore,
      scanPrompt: 'Apunta el escáner al código QR del lote',
      manualInputHint: 'Ej: FID_1234567',
    );
  }
}