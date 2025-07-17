import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

/// A reusable signature dialog widget that allows users to draw their signature
class SignatureDialog extends StatefulWidget {
  final String title;
  final List<Offset?> initialSignature;
  final Function(List<Offset?>) onSignatureSaved;
  final Color primaryColor;

  const SignatureDialog({
    super.key,
    this.title = 'Firma del Responsable',
    required this.initialSignature,
    required this.onSignatureSaved,
    this.primaryColor = const Color(0xFF2E3A59), // BioWayColors.deepBlue
  });

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();

  /// Static method to show the signature dialog
  static Future<void> show({
    required BuildContext context,
    String title = 'Firma del Responsable',
    required List<Offset?> initialSignature,
    required Function(List<Offset?>) onSignatureSaved,
    Color? primaryColor,
  }) {
    return showDialog(
      context: context,
      builder: (context) => SignatureDialog(
        title: title,
        initialSignature: initialSignature,
        onSignatureSaved: onSignatureSaved,
        primaryColor: primaryColor ?? const Color(0xFF2E3A59),
      ),
    );
  }
}

class _SignatureDialogState extends State<SignatureDialog> {
  late List<Offset?> _tempSignaturePoints;

  @override
  void initState() {
    super.initState();
    _tempSignaturePoints = List.from(widget.initialSignature);
  }

  void _clearSignature() {
    setState(() {
      _tempSignaturePoints.clear();
    });
  }

  void _saveSignature() {
    widget.onSignatureSaved(_tempSignaturePoints);
    Navigator.of(context).pop();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Firma guardada correctamente'),
        backgroundColor: BioWayColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: 400,
        decoration: BoxDecoration(
          border: Border.all(color: BioWayColors.lightGrey),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Stack(
          children: [
            // Signature drawing area
            GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _tempSignaturePoints.add(details.localPosition);
                });
              },
              onPanEnd: (details) {
                _tempSignaturePoints.add(null); // Add null to separate stroke paths
              },
              child: CustomPaint(
                painter: SignaturePainter(_tempSignaturePoints),
                size: Size.infinite,
              ),
            ),
            // Placeholder when no signature
            if (_tempSignaturePoints.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.draw,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dibuja tu firma aquí',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        // Clear button
        TextButton(
          onPressed: _clearSignature,
          child: Text(
            'Limpiar',
            style: TextStyle(color: BioWayColors.error),
          ),
        ),
        // Cancel button
        TextButton(
          onPressed: _cancel,
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        // Save button
        ElevatedButton(
          onPressed: _tempSignaturePoints.isNotEmpty ? _saveSignature : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Custom painter for drawing the signature
class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  const SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}