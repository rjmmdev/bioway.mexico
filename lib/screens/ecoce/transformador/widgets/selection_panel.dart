import 'package:flutter/material.dart';
import '../../../../models/lotes/lote_unificado_model.dart';

/// Panel de selección múltiple específico del transformador
class SelectionPanel extends StatelessWidget {
  final Set<String> selectedLoteIds;
  final List<LoteUnificadoModel> allLotes;
  final VoidCallback onCancel;
  final VoidCallback onProcess;
  
  const SelectionPanel({
    super.key,
    required this.selectedLoteIds,
    required this.allLotes,
    required this.onCancel,
    required this.onProcess,
  });

  @override
  Widget build(BuildContext context) {
    final selectedLotes = allLotes.where((l) => selectedLoteIds.contains(l.id)).toList();
    final totalPeso = selectedLotes.fold(0.0, (total, lote) => total + lote.pesoActual);
    
    return Container(
      color: Colors.orange.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                '${selectedLoteIds.length} lotes seleccionados',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onCancel,
                child: const Text('Cancelar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Peso total: ${totalPeso.toStringAsFixed(2)} kg',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: selectedLoteIds.isNotEmpty ? onProcess : null,
                icon: const Icon(Icons.merge_type),
                label: const Text('Crear megalote'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}