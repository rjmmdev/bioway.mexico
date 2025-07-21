import 'package:flutter/material.dart';
import 'reciclador_escaneo_qr.dart';
import 'reciclador_lotes_registro.dart';

/// Wrapper para compatibilidad con rutas existentes
/// Redirige a la pantalla de escaneo QR real
class QRScannerScreen extends StatelessWidget {
  final bool isAddingMore;
  
  const QRScannerScreen({
    super.key,
    this.isAddingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    // Redirigir a la pantalla de escaneo QR real
    return RecicladorEscaneoQR(
      isAddingMore: isAddingMore,
    );
  }
}

// Alias para mantener consistencia con el nombre usado en navegación
class RecicladorLotesRegistro extends StatelessWidget {
  final String? initialScannedCode;
  
  const RecicladorLotesRegistro({
    super.key,
    this.initialScannedCode,
  });

  @override
  Widget build(BuildContext context) {
    return ScannedLotsScreen(
      initialScannedCode: initialScannedCode,
    );
  }
}