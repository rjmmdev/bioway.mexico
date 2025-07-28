/// Utilidades para el manejo de códigos QR en el sistema unificado
class QRUtils {
  /// Extrae el ID del lote desde un código QR
  /// Formatos soportados:
  /// - LOTE-TIPOMATERIAL-ID (lotes normales)
  /// - SUBLOTE-ID (sublotes derivados)
  /// Ejemplos:
  /// - LOTE-PEBD-abc123def456 -> abc123def456
  /// - SUBLOTE-xyz789ghi012 -> xyz789ghi012
  static String extractLoteIdFromQR(String qrCode) {
    // Manejar sublotes
    if (qrCode.startsWith('SUBLOTE-')) {
      return qrCode.substring(8); // Remover 'SUBLOTE-' prefix
    }
    
    // Manejar lotes normales
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
  /// Acepta tanto lotes normales como sublotes
  static bool isValidLoteQR(String qrCode) {
    // Verificar formato de sublote
    if (qrCode.startsWith('SUBLOTE-') && qrCode.length > 8) {
      return true;
    }
    
    // Verificar formato de lote normal
    return qrCode.startsWith('LOTE-') && qrCode.split('-').length >= 3;
  }
  
  /// Extrae el tipo de material del código QR
  /// Ejemplo: LOTE-PEBD-abc123def456 -> PEBD
  /// Para sublotes devuelve null (el material debe obtenerse del lote en la base de datos)
  static String? extractMaterialFromQR(String qrCode) {
    // Los sublotes no tienen material en el QR
    if (qrCode.startsWith('SUBLOTE-')) {
      return null;
    }
    
    if (qrCode.startsWith('LOTE-')) {
      final parts = qrCode.split('-');
      if (parts.length >= 3) {
        return parts[1];
      }
    }
    return null;
  }
  
  /// Determina si un código QR corresponde a un sublote
  static bool isSubLoteQR(String qrCode) {
    return qrCode.startsWith('SUBLOTE-');
  }
  
  /// Genera un código QR para un sublote
  /// Formato: SUBLOTE-ID
  static String generateSubLoteQR(String subloteId) {
    return 'SUBLOTE-$subloteId';
  }
}