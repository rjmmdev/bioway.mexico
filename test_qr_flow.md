# Flujo de Generación y Escaneo de Códigos QR - BioWay México

## 1. Generación del Código QR

### Código en `qr_code_display_widget.dart`:
```dart
String get _qrData {
  // El QR debe contener SOLO el ID del lote de Firebase
  // para que el escaneo pueda buscar la información en Firestore
  return widget.loteId;
}
```

**Ejemplo**: Si el ID del lote es `"LOT-FIREBASE-ABC123"`, el código QR contendrá exactamente: `LOT-FIREBASE-ABC123`

## 2. Proceso de Escaneo

### Transportista escanea el código:
```dart
void _handleScannerResult(String qrData) async {
  // qrData = "LOT-FIREBASE-ABC123" (string simple)
  
  // Buscar el lote en Firebase
  final lotesInfo = await _loteService.getLotesInfo([qrData]);
  
  // Si encuentra el lote, obtiene toda la información
  if (lotesInfo.isNotEmpty) {
    final loteInfo = lotesInfo.first;
    // Procesar información del lote...
  }
}
```

## 3. Búsqueda en Firebase

### En `lote_service.dart`:
```dart
Future<Map<String, dynamic>?> _buscarLoteEnColecciones(String loteId) async {
  final colecciones = [
    'lotes_origen',
    'lotes_transportista', 
    'lotes_reciclador',
    'lotes_laboratorio',
    'lotes_transformador',
  ];

  for (String coleccion in colecciones) {
    final doc = await _firestore.collection(coleccion).doc(loteId).get();
    if (doc.exists) {
      return doc.data();
    }
  }
  return null;
}
```

## 4. Flujo Completo Ejemplo

1. **Origen crea lote**:
   - Firebase genera ID: `"xY7kL9mNpQ2rS4tU"`
   - QR contiene: `"xY7kL9mNpQ2rS4tU"`

2. **Transportista escanea**:
   - Lee: `"xY7kL9mNpQ2rS4tU"`
   - Busca en Firebase → Encuentra en `lotes_origen`
   - Obtiene: material, peso, presentación, etc.

3. **Reciclador escanea lote de transporte**:
   - Lee: `"aB3cD4eF5gH6iJ7k"`
   - Busca en Firebase → Encuentra en `lotes_transportista`
   - Valida que puede recibirlo

## Verificación de Funcionamiento

✅ **QR contiene solo el ID** - No hay JSON ni mapas complejos
✅ **Escaneo usa el ID directamente** - No hay parseo de datos
✅ **Firebase retorna información completa** - Todos los datos vienen de la BD
✅ **Validación por tipo de usuario** - Cada usuario solo acepta lotes válidos

## Conclusión

El sistema está correctamente implementado. Los códigos QR son simples (solo ID), la búsqueda es eficiente (directa por ID), y la información completa se obtiene de Firebase, garantizando la integridad y trazabilidad de los datos.