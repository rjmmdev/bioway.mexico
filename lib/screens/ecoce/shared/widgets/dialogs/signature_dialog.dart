import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../utils/colors.dart';

class SignatureDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Color primaryColor;
  final Function(List<Offset>) onSignatureSaved;
  
  const SignatureDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.primaryColor,
    required this.onSignatureSaved,
  });

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  final List<Offset> _signaturePoints = [];
  bool _isDrawing = false;
  
  void _startDrawing(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
      _signaturePoints.add(details.localPosition);
    });
  }
  
  void _updateDrawing(DragUpdateDetails details) {
    if (_isDrawing) {
      setState(() {
        _signaturePoints.add(details.localPosition);
      });
    }
  }
  
  void _stopDrawing(DragEndDetails details) {
    setState(() {
      _isDrawing = false;
      _signaturePoints.add(Offset.infinite); // Marca el final de un trazo
    });
  }
  
  void _clearSignature() {
    HapticFeedback.lightImpact();
    setState(() {
      _signaturePoints.clear();
    });
  }
  
  void _saveSignature() {
    HapticFeedback.mediumImpact();
    if (_signaturePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, agregue su firma'),
          backgroundColor: BioWayColors.error,
        ),
      );
      return;
    }
    
    widget.onSignatureSaved(_signaturePoints);
    Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: Colors.grey[600],
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Canvas de firma
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: GestureDetector(
                  onPanStart: _startDrawing,
                  onPanUpdate: _updateDrawing,
                  onPanEnd: _stopDrawing,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: SignaturePainter(
                      points: _signaturePoints,
                      color: widget.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Botón limpiar
            TextButton.icon(
              onPressed: _clearSignature,
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveSignature,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Guardar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  
  SignaturePainter({
    required this.points,
    required this.color,
    this.strokeWidth = 2.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.infinite && points[i + 1] != Offset.infinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}