import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

/// Dialogo reutilizable para capturar firmas dibujando sobre el lienzo.
class SignatureDialog extends StatefulWidget {
  final String title;
  final List<Offset?> initialSignature;
  final ValueChanged<List<Offset?>> onSignatureSaved;
  final Color primaryColor;

  const SignatureDialog({
    super.key,
    this.title = 'Firma del Responsable',
    required this.initialSignature,
    required this.onSignatureSaved,
    this.primaryColor = const Color(0xFF2E3A59),
  });

  /// Muestra el diálogo de firma.
  static Future<void> show({
    required BuildContext context,
    String title = 'Firma del Responsable',
    required List<Offset?> initialSignature,
    required ValueChanged<List<Offset?>> onSignatureSaved,
    Color? primaryColor,
  }) {
    return showDialog(
      context: context,
      builder: (_) => SignatureDialog(
        title: title,
        initialSignature: initialSignature,
        onSignatureSaved: onSignatureSaved,
        primaryColor: primaryColor ?? const Color(0xFF2E3A59),
      ),
    );
  }

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  late List<Offset?> _points;

  @override
  void initState() {
    super.initState();
    _points = List.of(widget.initialSignature);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _points.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _points.add(null);
    });
  }

  void _clear() {
    setState(() {
      _points.clear();
    });
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  void _save() {
    widget.onSignatureSaved(List.of(_points));
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Firma guardada correctamente'),
        backgroundColor: BioWayColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    
    // Ajustar tamaños según el dispositivo
    final dialogWidth = isTablet 
        ? screenWidth * 0.7  // 70% en tablets
        : screenWidth * 0.9; // 90% en móviles
    
    final dialogHeight = screenHeight * 0.5; // 50% de la altura de pantalla
    
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05, // 5% de margen horizontal
        vertical: screenHeight * 0.1,   // 10% de margen vertical
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Container(
        width: dialogWidth,
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Text(
              widget.title,
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            // Área de firma
            Container(
              width: double.infinity,
              height: dialogHeight,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: BioWayColors.lightGrey),
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                child: GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    painter: SignaturePainter(
                      List.of(_points),
                      strokeWidth: screenWidth * 0.008, // Grosor responsivo
                    ),
                    size: Size.infinite,
                    child: _points.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.draw, 
                                  size: screenWidth * 0.12, 
                                  color: Colors.grey[400]
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                Text(
                                  'Dibuja tu firma aquí',
                                  style: TextStyle(
                                    color: Colors.grey[600], 
                                    fontSize: screenWidth * 0.04
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _clear,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.015,
                    ),
                  ),
                  child: Text(
                    'Limpiar', 
                    style: TextStyle(
                      color: BioWayColors.error,
                      fontSize: screenWidth * 0.035,
                    )
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                TextButton(
                  onPressed: _cancel,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.015,
                    ),
                  ),
                  child: Text(
                    'Cancelar', 
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: screenWidth * 0.035,
                    )
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                ElevatedButton(
                  onPressed: _points.isNotEmpty ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: screenHeight * 0.015,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                  ),
                  child: Text(
                    'Guardar',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final double strokeWidth;

  SignaturePainter(this.points, {this.strokeWidth = 2.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) {
    return oldDelegate.points.length != points.length;
  }
}
