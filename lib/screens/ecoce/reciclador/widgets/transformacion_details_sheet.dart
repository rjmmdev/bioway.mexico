import 'package:flutter/material.dart';
import '../../../../models/lotes/transformacion_model.dart';
import '../../../../utils/colors.dart';

/// Bottom sheet para mostrar detalles de una transformación
class TransformacionDetailsSheet extends StatelessWidget {
  final TransformacionModel transformacion;
  
  const TransformacionDetailsSheet({
    super.key,
    required this.transformacion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detalles del Megalote',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Información general
                _buildDetailSection(
                  'Información General',
                  [
                    _buildDetailRow('ID', transformacion.id.substring(0, 8).toUpperCase()),
                    _buildDetailRow('Peso entrada', '${transformacion.pesoTotalEntrada.toStringAsFixed(2)} kg'),
                    _buildDetailRow('Peso asignado', '${transformacion.pesoAsignadoSublotes.toStringAsFixed(2)} kg'),
                    _buildDetailRow('Peso disponible', '${transformacion.pesoDisponible.toStringAsFixed(2)} kg'),
                    _buildDetailRow('Merma', '${transformacion.mermaProceso.toStringAsFixed(2)} kg'),
                    _buildDetailRow('Estado', transformacion.estado),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Composición de materiales
                _buildMaterialCompositionSection(),
                const SizedBox(height: 20),
                
                // Lotes de entrada
                _buildDetailSection(
                  'Lotes de Entrada (${transformacion.lotesEntrada.length})',
                  transformacion.lotesEntrada.map((lote) =>
                    _buildDetailRow(
                      'Lote ${lote.loteId.substring(0, 8).toUpperCase()}',
                      '${lote.peso.toStringAsFixed(2)} kg'
                    )
                  ).toList(),
                ),
                const SizedBox(height: 20),
                
                // Sublotes generados
                if (transformacion.sublotesGenerados.isNotEmpty) ...[
                  _buildDetailSection(
                    'Sublotes Generados (${transformacion.sublotesGenerados.length})',
                    transformacion.sublotesGenerados.map((subloteId) =>
                      _buildDetailRow(
                        'Sublote ${subloteId.substring(0, 8).toUpperCase()}',
                        'Ver detalles'
                      )
                    ).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Muestras de laboratorio - NUEVO SISTEMA INDEPENDIENTE
                // Ahora mostramos los IDs de referencia en lugar del array antiguo
                if (transformacion.muestrasLaboratorioIds.isNotEmpty || transformacion.tieneMuestraLaboratorio) ...[
                  _buildDetailSection(
                    'Muestras de Laboratorio (${transformacion.muestrasLaboratorioIds.length})',
                    // SISTEMA NUEVO: Solo mostramos información básica ya que los detalles están en colección independiente
                    transformacion.muestrasLaboratorioIds.map((muestraId) {
                      // Con el sistema independiente, no tenemos acceso directo a los detalles
                      // Solo mostramos el ID de referencia
                      final muestraIdCorto = muestraId.length > 8 ? muestraId.substring(0, 8).toUpperCase() : muestraId.toUpperCase();
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Muestra $muestraIdCorto',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Registrada',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Sin información de peso individual en el sistema nuevo
                            // El peso total se muestra abajo
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  // Mostrar peso total de muestras tomadas
                  if (transformacion.pesoMuestrasTotal > 0)
                    _buildDetailRow(
                      'Peso total muestras',
                      '${transformacion.pesoMuestrasTotal.toStringAsFixed(2)} kg',
                      valueColor: Colors.purple,
                    ),
                  const SizedBox(height: 20),
                ],
                
                // Documentación
                _buildDetailSection(
                  'Documentación',
                  [
                    _buildDetailRow(
                      'Ficha técnica',
                      _hasDocument(transformacion, ['f_tecnica_pellet', 'ficha_tecnica']) ? 'Cargada' : 'Pendiente',
                      valueColor: _hasDocument(transformacion, ['f_tecnica_pellet', 'ficha_tecnica']) ? Colors.green : Colors.orange,
                    ),
                    _buildDetailRow(
                      'Reporte de resultado',
                      _hasDocument(transformacion, ['rep_result_reci', 'reporte_transformacion']) ? 'Cargado' : 'Pendiente',
                      valueColor: _hasDocument(transformacion, ['rep_result_reci', 'reporte_transformacion']) ? Colors.green : Colors.orange,
                    ),
                    if (_hasDocument(transformacion, ['certificado_calidad']))
                      _buildDetailRow(
                        'Certificado de calidad',
                        'Cargado',
                        valueColor: Colors.green,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Helper para verificar si existe un documento con cualquiera de las claves dadas
  /// Esto maneja la compatibilidad con documentos antiguos y nuevos
  bool _hasDocument(TransformacionModel transformacion, List<String> keys) {
    for (final key in keys) {
      if (transformacion.documentosAsociados[key] != null && 
          transformacion.documentosAsociados[key]!.isNotEmpty) {
        return true;
      }
    }
    return false;
  }
  
  Widget _buildMaterialCompositionSection() {
    // Calcular composición de materiales
    Map<String, double> composicion = {};
    Map<String, double> pesosPorMaterial = {};
    
    for (final lote in transformacion.lotesEntrada) {
      final material = lote.tipoMaterial;
      composicion[material] = (composicion[material] ?? 0) + lote.porcentaje;
      pesosPorMaterial[material] = (pesosPorMaterial[material] ?? 0) + lote.peso;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: BioWayColors.ecoceGreen, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Composición de Materiales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...composicion.entries.map((entry) {
            final material = entry.key;
            final porcentaje = entry.value;
            final peso = pesosPorMaterial[material] ?? 0;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getMaterialColor(material),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      material,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${porcentaje.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getMaterialColor(material),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${peso.toStringAsFixed(2)} kg)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          if (composicion.length == 1) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BioWayColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: BioWayColors.info),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Megalote de material único',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Color _getMaterialColor(String material) {
    switch (material.toUpperCase()) {
      case 'PEBD':
        return BioWayColors.pebdPink;
      case 'PP':
        return BioWayColors.ppPurple;
      case 'MULTILAMINADO':
        return BioWayColors.multilaminadoBrown;
      default:
        return BioWayColors.ecoceGreen;
    }
  }
  
  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}