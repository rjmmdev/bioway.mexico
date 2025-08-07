import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/laboratorio/muestra_laboratorio_model.dart';
import '../../../../models/lotes/transformacion_model.dart';
import '../../../../services/transformacion_service.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/ui_constants.dart';
import '../../../../utils/format_utils.dart';

/// Bottom sheet para mostrar los resultados completos del análisis de una muestra
class MuestraAnalysisDetailsSheet extends StatefulWidget {
  final MuestraLaboratorioModel muestra;
  
  const MuestraAnalysisDetailsSheet({
    super.key,
    required this.muestra,
  });

  @override
  State<MuestraAnalysisDetailsSheet> createState() => _MuestraAnalysisDetailsSheetState();
}

class _MuestraAnalysisDetailsSheetState extends State<MuestraAnalysisDetailsSheet> {
  final TransformacionService _transformacionService = TransformacionService();
  TransformacionModel? _transformacion;
  bool _isLoadingTransformacion = true;

  @override
  void initState() {
    super.initState();
    _loadTransformacionData();
  }

  Future<void> _loadTransformacionData() async {
    if (widget.muestra.origenTipo == 'transformacion') {
      try {
        final transformacion = await _transformacionService.obtenerTransformacion(widget.muestra.origenId);
        if (mounted) {
          setState(() {
            _transformacion = transformacion;
            _isLoadingTransformacion = false;
          });
        }
      } catch (e) {
        debugPrint('Error cargando transformación: $e');
        if (mounted) {
          setState(() {
            _isLoadingTransformacion = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoadingTransformacion = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final analisis = widget.muestra.datosAnalisis;
    
    if (analisis == null) {
      return _buildEmptyState(context);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF9333EA).withOpacity(0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFF9333EA).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9333EA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.analytics,
                        color: Color(0xFF9333EA),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resultados del Análisis',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9333EA),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Muestra: ${_formatMuestraId(widget.muestra.id)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (widget.muestra.fechaAnalisis != null)
                            Text(
                              'Análisis: ${FormatUtils.formatDateTime(widget.muestra.fechaAnalisis!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Estado de cumplimiento
                    _buildComplianceCard(analisis),
                    const SizedBox(height: 20),
                    
                    // Características Físicas
                    _buildSection(
                      title: 'Características Físicas',
                      icon: Icons.science,
                      items: {
                        'Humedad': '${analisis.humedad?.toStringAsFixed(2) ?? 'N/A'}%',
                        'Pellets por gramo': analisis.pelletsGramo?.toStringAsFixed(2) ?? 'N/A',
                        'Tipo de Polímero (FTIR)': analisis.tipoPolimero ?? 'N/A',
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Temperatura de Fusión
                    _buildTemperatureSection(analisis.temperaturaFusion),
                    const SizedBox(height: 16),
                    
                    // Composición
                    _buildSection(
                      title: 'Composición',
                      icon: Icons.pie_chart,
                      items: {
                        'Contenido Orgánico': '${analisis.contenidoOrganico?.toStringAsFixed(2) ?? 'N/A'}%',
                        'Contenido Inorgánico': '${analisis.contenidoInorganico?.toStringAsFixed(2) ?? 'N/A'}%',
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Propiedades Técnicas
                    _buildSection(
                      title: 'Propiedades Técnicas',
                      icon: Icons.settings,
                      items: {
                        'OIT': analisis.oit ?? 'N/A',
                        'MFI': analisis.mfi ?? 'N/A',
                        'Densidad': analisis.densidad ?? 'N/A',
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Evaluación y Observaciones
                    _buildEvaluationSection(analisis),
                    
                    // Información adicional de la muestra
                    const SizedBox(height: 20),
                    _buildMuestraInfoSection(),
                    
                    const SizedBox(height: 80), // Espacio al final
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Sin datos de análisis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se encontraron resultados de análisis para esta muestra',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceCard(DatosAnalisis analisis) {
    final bool cumple = analisis.cumpleRequisitos;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cumple 
          ? BioWayColors.success.withOpacity(0.1)
          : BioWayColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cumple 
            ? BioWayColors.success.withOpacity(0.3)
            : BioWayColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cumple ? BioWayColors.success : BioWayColors.error,
              shape: BoxShape.circle,
            ),
            child: Icon(
              cumple ? Icons.check : Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cumple 
                    ? 'Cumple con los requisitos de transformación'
                    : 'No cumple con los requisitos de transformación',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cumple 
                      ? BioWayColors.success
                      : BioWayColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Map<String, String> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF9333EA),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9333EA),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: items.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureSection(TemperaturaFusion? temperatura) {
    if (temperatura == null) {
      return _buildSection(
        title: 'Temperatura de Fusión',
        icon: Icons.thermostat,
        items: {'Temperatura': 'N/A'},
      );
    }

    String tempDisplay;
    if (temperatura.tipo == 'unica') {
      tempDisplay = '${temperatura.valor?.toStringAsFixed(2) ?? 'N/A'} ${temperatura.unidad}';
    } else {
      tempDisplay = '${temperatura.minima?.toStringAsFixed(2) ?? 'N/A'} - ${temperatura.maxima?.toStringAsFixed(2) ?? 'N/A'} ${temperatura.unidad}';
    }

    return _buildSection(
      title: 'Temperatura de Fusión',
      icon: Icons.thermostat,
      items: {
        'Tipo': temperatura.tipo == 'unica' ? 'Única' : 'Rango',
        'Valor': tempDisplay,
      },
    );
  }

  Widget _buildEvaluationSection(DatosAnalisis analisis) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.assignment,
                  size: 20,
                  color: Color(0xFF9333EA),
                ),
                SizedBox(width: 8),
                Text(
                  'Evaluación',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9333EA),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (analisis.norma != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Norma/Método',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          analisis.norma!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (analisis.observaciones != null && analisis.observaciones!.isNotEmpty) ...[
                  Text(
                    'Observaciones / Interpretación Técnica',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      analisis.observaciones!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuestraInfoSection() {
    Map<String, String> items = {
      'Peso de muestra': '${widget.muestra.pesoMuestra.toStringAsFixed(2)} kg',
      'Origen': widget.muestra.tipo == 'megalote' ? 'Megalote' : 'Lote',
      'Fecha de toma': FormatUtils.formatDateTime(widget.muestra.fechaToma),
    };

    // Si viene de una transformación, agregar composición de polímeros
    if (widget.muestra.origenTipo == 'transformacion') {
      if (_isLoadingTransformacion) {
        items['Composición del megalote'] = 'Cargando...';
      } else if (_transformacion != null) {
        String composicion = _calcularComposicionPolimeros();
        if (composicion.isNotEmpty) {
          items['Composición del megalote'] = composicion;
        }
      }
    }

    if (widget.muestra.fechaDocumentacion != null) {
      items['Documentación completada'] = FormatUtils.formatDateTime(widget.muestra.fechaDocumentacion!);
    }

    return _buildSection(
      title: 'Información de la Muestra',
      icon: Icons.info_outline,
      items: items,
    );
  }

  String _calcularComposicionPolimeros() {
    if (_transformacion == null) return '';

    // Calcular totales por tipo de material
    Map<String, double> materialesPeso = {};
    double pesoTotal = 0;

    for (var lote in _transformacion!.lotesEntrada) {
      String material = lote.tipoMaterial;
      // Normalizar el material removiendo el prefijo EPF- si existe
      if (material.toUpperCase().startsWith('EPF-')) {
        material = material.substring(4);
      }
      material = material.toUpperCase();

      materialesPeso[material] = (materialesPeso[material] ?? 0) + lote.peso;
      pesoTotal += lote.peso;
    }

    // Calcular porcentajes y formatear
    List<String> componentes = [];
    materialesPeso.forEach((material, peso) {
      double porcentaje = (peso / pesoTotal) * 100;
      String materialDisplay = material;
      
      // Mapear nombres de materiales
      switch (material) {
        case 'PEBD':
        case 'PEAD':
          materialDisplay = 'PEBD';
          break;
        case 'PP':
          materialDisplay = 'PP';
          break;
        case 'MULTILAMINADO':
        case 'MULTI':
          materialDisplay = 'Multilaminado';
          break;
      }
      
      componentes.add('$materialDisplay ${porcentaje.toStringAsFixed(1)}%');
    });

    return componentes.join(', ');
  }

  String _formatMuestraId(String id) {
    if (id.isEmpty) return 'SIN-ID';
    if (id.length >= 8) {
      return id.substring(0, 8).toUpperCase();
    }
    return id.toUpperCase();
  }
}