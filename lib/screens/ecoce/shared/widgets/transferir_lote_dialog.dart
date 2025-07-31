import 'package:flutter/material.dart';
import 'package:app/utils/colors.dart';
import 'package:app/services/lote_unificado_service.dart';
import 'package:app/models/lotes/lote_unificado_model.dart';
import 'package:app/screens/ecoce/shared/utils/dialog_utils.dart';

/// Dialog para transferir un lote a otro proceso
class TransferirLoteDialog extends StatefulWidget {
  final LoteUnificadoModel lote;
  final String procesoDestino;
  final String nombreProcesoDestino;
  final Color primaryColor;
  final Function(String)? onSuccess;

  const TransferirLoteDialog({
    super.key,
    required this.lote,
    required this.procesoDestino,
    required this.nombreProcesoDestino,
    this.primaryColor = BioWayColors.ecoceGreen,
    this.onSuccess,
  });

  @override
  State<TransferirLoteDialog> createState() => _TransferirLoteDialogState();
}

class _TransferirLoteDialogState extends State<TransferirLoteDialog> {
  final LoteUnificadoService _loteService = LoteUnificadoService();
  final TextEditingController _folioDestinoController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _folioDestinoController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }

  Future<void> _transferirLote() async {
    if (_folioDestinoController.text.trim().isEmpty) {
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Campo requerido',
        message: 'Debes ingresar el folio del destinatario',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Preparar datos iniciales según el proceso destino
      final datosIniciales = _getDatosInicialesPorProceso();
      
      await _loteService.transferirLote(
        loteId: widget.lote.id,
        procesoDestino: widget.procesoDestino,
        usuarioDestinoFolio: _folioDestinoController.text.trim(),
        datosIniciales: datosIniciales,
      );

      if (mounted) {
        Navigator.of(context).pop();
        DialogUtils.showSuccessDialog(
          context: context,
          title: 'Lote Transferido',
          message: 'El lote ha sido transferido exitosamente a ${widget.nombreProcesoDestino}',
        );
        
        if (widget.onSuccess != null) {
          widget.onSuccess!(widget.lote.id);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudo transferir el lote: ${e.toString()}',
        );
      }
    }
  }

  Map<String, dynamic> _getDatosInicialesPorProceso() {
    final datos = <String, dynamic>{
      'comentarios_transferencia': _comentariosController.text.trim(),
    };

    // Agregar datos específicos según el proceso destino
    switch (widget.procesoDestino) {
      case 'transporte':
        datos['origen_recogida'] = widget.lote.datosGenerales.procesoActual == 'origen' 
            ? widget.lote.origen?.usuarioFolio ?? ''
            : widget.lote.datosGenerales.procesoActual;
        datos['peso_recogido'] = widget.lote.pesoActual;
        datos['evidencias_foto'] = [];
        break;
        
      case 'reciclador':
        datos['peso_entrada'] = widget.lote.pesoActual;
        datos['evidencias_foto'] = [];
        break;
        
      case 'laboratorio':
        datos['peso_muestra'] = 0.0; // Se actualizará después
        datos['tipo_analisis'] = [];
        break;
        
      case 'transformador':
        datos['peso_entrada'] = widget.lote.pesoActual;
        datos['evidencias_foto'] = [];
        break;
    }

    return datos;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  color: widget.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transferir Lote',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: widget.primaryColor,
                        ),
                      ),
                      Text(
                        'A ${widget.nombreProcesoDestino}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Información del lote
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ID Lote:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        widget.lote.id.substring(0, 8).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Material:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        widget.lote.datosGenerales.tipoMaterial,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Peso actual:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${widget.lote.pesoActual.toStringAsFixed(2)} kg',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Campo de folio destinatario
            TextFormField(
              controller: _folioDestinoController,
              textCapitalization: TextCapitalization.characters,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Folio del ${widget.nombreProcesoDestino}',
                hintText: 'Ej: R0000001',
                prefixIcon: Icon(
                  Icons.badge,
                  color: widget.primaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Campo de comentarios
            TextFormField(
              controller: _comentariosController,
              maxLines: 3,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Comentarios (opcional)',
                hintText: 'Notas sobre la transferencia...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _transferirLote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Transferir',
                          style: TextStyle(color: Colors.white),
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