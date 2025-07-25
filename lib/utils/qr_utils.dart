/// Utilidades para el manejo de códigos QR en el sistema unificado
class QRUtils {
  /// Extrae el ID del lote desde un código QR
  /// Formato esperado: LOTE-TIPOMATERIAL-ID
  /// Ejemplo: LOTE-PEBD-abc123def456 -> abc123def456
  static String extractLoteIdFromQR(String qrCode) {
    if (qrCode.startsWith('LOTE-')) {
      final parts = qrCode.split('-');
      if (parts.length >= 3) {
        // El ID es todo después del segundo guión
        return parts.sublist(2).join('-');
      }
    }
    // Si no tiene el formato esperado, asumir que es el ID directo
    return qrCode;
  }
  
  /// Genera un código QR para un lote
  /// Formato: LOTE-TIPOMATERIAL-ID
  static String generateLoteQR(String tipoPoli, String loteId) {
    return 'LOTE-$tipoPoli-$loteId';
  }
  
  /// Verifica si un código QR tiene el formato de lote válido
  static bool isValidLoteQR(String qrCode) {
    return qrCode.startsWith('LOTE-') && qrCode.split('-').length >= 3;
  }
  
  /// Extrae el tipo de material del código QR
  /// Ejemplo: LOTE-PEBD-abc123def456 -> PEBD
  static String? extractMaterialFromQR(String qrCode) {
    if (qrCode.startsWith('LOTE-')) {
      final parts = qrCode.split('-');
      if (parts.length >= 3) {
        return parts[1];
      }
    }
    return null;
  }
}