import 'package:flutter/material.dart';
import '../../../../models/lotes/transformacion_model.dart';
import '../../../../utils/colors.dart';
import '../../shared/widgets/weight_input_widget.dart';

/// Diálogo para crear sublotes
class SubloteDialog extends StatefulWidget {
  final TransformacionModel transformacion;
  final Function(double peso) onCreateSublote;
  
  const SubloteDialog({
    super.key,
    required this.transformacion,
    required this.onCreateSublote,
  });

  @override
  State<SubloteDialog> createState() => _SubloteDialogState();
}

class _SubloteDialogState extends State<SubloteDialog> {
  final TextEditingController _pesoController = TextEditingController();
  
  @override
  void dispose() {
    _pesoController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        children: [
          Icon(
            Icons.cut,
            color: BioWayColors.ecoceGreen,
            size: 48,
          ),
          const SizedBox(height: 8),
          const Text(
            'Crear Sublote',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Peso disponible: ${widget.transformacion.pesoDisponible.toStringAsFixed(2)} kg',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            // Usar WeightInputWidget para entrada de peso
            WeightInputWidget(
              controller: _pesoController,
              label: 'Peso del sublote',
              primaryColor: BioWayColors.ecoceGreen,
              minValue: 0.01,
              maxValue: widget.transformacion.pesoDisponible,
              incrementValue: 0.5,
              quickAddValues: [10, 25, 50, 100],
              isRequired: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese un peso';
                }
                final peso = double.tryParse(value);
                if (peso == null || peso <= 0) {
                  return 'Ingrese un peso válido';
                }
                if (peso > widget.transformacion.pesoDisponible) {
                  return 'Excede el peso disponible';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _handleCreate,
          style: ElevatedButton.styleFrom(
            backgroundColor: BioWayColors.ecoceGreen,
          ),
          child: const Text('Crear'),
        ),
      ],
    );
  }
  
  void _handleCreate() {
    final pesoText = _pesoController.text.trim();
    if (pesoText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese un peso'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final peso = double.tryParse(pesoText);
    if (peso == null || peso <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese un peso válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (peso > widget.transformacion.pesoDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El peso excede el disponible (${widget.transformacion.pesoDisponible.toStringAsFixed(2)} kg)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    Navigator.of(context).pop();
    widget.onCreateSublote(peso);
  }
}