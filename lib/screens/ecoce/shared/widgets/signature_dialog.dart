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
    return AlertDialog(
      title: Text(widget.title),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: BioWayColors.lightGrey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: GestureDetector(
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: CustomPaint(
            painter: SignaturePainter(List.of(_points)),
            size: Size.infinite,
            child: _points.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.draw, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Dibuja tu firma aquí',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _clear,
          child: Text('Limpiar', style: TextStyle(color: BioWayColors.error)),
        ),
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _points.isNotEmpty ? _save : null,
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

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter(this.points);

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
  bool shouldRepaint(covariant SignaturePainter oldDelegate) {
    return oldDelegate.points.length != points.length;
  }
}

