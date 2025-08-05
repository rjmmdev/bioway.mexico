import 'package:flutter/material.dart';
import '../../../../models/lotes/transformacion_model.dart';
import '../../../../utils/colors.dart';
import '../../shared/utils/material_utils.dart';

/// Tarjeta de transformación (megalote) específica del transformador
class TransformacionCardTransformador extends StatelessWidget {
  final TransformacionModel transformacion;
  final VoidCallback onTap;
  final VoidCallback? onUploadDocuments;
  
  const TransformacionCardTransformador({
    super.key,
    required this.transformacion,
    required this.onTap,
    this.onUploadDocuments,
  });

  @override
  Widget build(BuildContext context) {
    final bool isComplete = transformacion.estado == 'completado';
    final bool needsDocumentation = transformacion.estado == 'documentacion';
    
    // Obtener datos específicos del transformador
    final datosAdicionales = transformacion.datos;
    final pesoSalida = datosAdicionales['peso_salida'] ?? transformacion.pesoTotalEntrada;
    final cantidadProducto = datosAdicionales['cantidad_producto'] ?? 0;
    final productoFabricado = datosAdicionales['producto_fabricado'] ?? '';
    final merma = transformacion.mermaProceso;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.merge_type,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MEGALOTE ${transformacion.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isComplete)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BioWayColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: BioWayColors.success,
                        size: 20,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Información de peso - Adaptativa con Wrap
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.scale,
                    label: 'Entrada',
                    value: '${transformacion.pesoTotalEntrada.toStringAsFixed(2)} kg',
                    color: Colors.blue,
                  ),
                  _buildInfoChip(
                    icon: Icons.output,
                    label: 'Salida',
                    value: '${pesoSalida.toStringAsFixed(2)} kg',
                    color: Colors.orange,
                  ),
                  if (merma > 0)
                    _buildInfoChip(
                      icon: Icons.trending_down,
                      label: 'Merma',
                      value: '${merma.toStringAsFixed(2)} kg',
                      color: Colors.red,
                    ),
                ],
              ),
              
              // Producto fabricado y cantidad - Adaptativo con Wrap
              if (productoFabricado.isNotEmpty || cantidadProducto > 0) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (productoFabricado.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.factory, size: 16, color: Colors.deepOrange),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                productoFabricado,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.deepOrange,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (cantidadProducto > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2, size: 16, color: Colors.green),
                            const SizedBox(width: 6),
                            Text(
                              '${cantidadProducto.toStringAsFixed(0)} unidades',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Composición de materiales con porcentajes
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Composición de materiales:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildMaterialComposition(),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Lotes de entrada
              Text(
                '${transformacion.lotesEntrada.length} lotes procesados',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              
              // Botón de documentación si es necesario
              if (needsDocumentation && onUploadDocuments != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onUploadDocuments,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Cargar Documentación'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
              
              // Indicador de completado
              if (isComplete) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: BioWayColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: BioWayColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: BioWayColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Transformación completada exitosamente',
                          style: TextStyle(
                            fontSize: 12,
                            color: BioWayColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  String _getStatusText() {
    switch (transformacion.estado) {
      case 'documentacion':
        return 'Requiere documentación';
      case 'en_proceso':
        return 'En proceso';
      case 'completado':
        return 'Completado';
      default:
        return transformacion.estado;
    }
  }
  
  Color _getStatusColor() {
    switch (transformacion.estado) {
      case 'documentacion':
        return Colors.orange;
      case 'en_proceso':
        return Colors.blue;
      case 'completado':
        return BioWayColors.success;
      default:
        return Colors.grey;
    }
  }
  
  Widget _buildMaterialComposition() {
    // Calcular composición de materiales agrupando por tipo
    Map<String, double> composicion = {};
    double pesoTotal = 0;
    
    // Log para debug
    print('[TransformacionCard] Lotes entrada: ${transformacion.lotesEntrada.length}');
    
    for (final lote in transformacion.lotesEntrada) {
      // Remover prefijo EPF- para mejor visualización
      final material = lote.tipoMaterial.replaceAll('EPF-', '');
      final peso = lote.peso ?? 0;
      print('[TransformacionCard] Lote: ${lote.loteId}, Material: $material, Peso: $peso, Porcentaje guardado: ${lote.porcentaje}');
      composicion[material] = (composicion[material] ?? 0) + peso;
      pesoTotal += peso;
    }
    
    // Si no hay materiales, devolver widget vacío
    if (composicion.isEmpty || pesoTotal == 0) {
      return const SizedBox.shrink();
    }
    
    // Calcular porcentajes y ordenar por mayor porcentaje
    List<MapEntry<String, double>> porcentajes = [];
    composicion.forEach((material, peso) {
      final porcentaje = (peso / pesoTotal) * 100;
      porcentajes.add(MapEntry(material, porcentaje));
    });
    porcentajes.sort((a, b) => b.value.compareTo(a.value));
    
    // Construir widgets de materiales
    List<Widget> materialChips = [];
    for (final entry in porcentajes) {
      final material = entry.key;
      final porcentaje = entry.value;
      // Agregar EPF- para obtener el color correcto
      final color = MaterialUtils.getMaterialColor('EPF-$material');
      
      materialChips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.polymer,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                '$material ${porcentaje.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Usar Wrap para hacer la composición adaptativa
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: materialChips,
    );
  }
  
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}