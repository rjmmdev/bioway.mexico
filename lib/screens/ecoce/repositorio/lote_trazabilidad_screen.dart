import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/utils/colors.dart';
import 'package:app/models/lotes/lote_unificado_model.dart';
import 'package:app/services/lote_unificado_service.dart';
import 'package:app/screens/ecoce/shared/widgets/loading_indicator.dart';
import 'package:app/screens/ecoce/shared/utils/material_utils.dart';
import 'package:app/utils/format_utils.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// Pantalla que muestra la trazabilidad completa de un lote
class LoteTrazabilidadScreen extends StatefulWidget {
  final String loteId;
  
  const LoteTrazabilidadScreen({
    super.key,
    required this.loteId,
  });

  @override
  State<LoteTrazabilidadScreen> createState() => _LoteTrazabilidadScreenState();
}

class _LoteTrazabilidadScreenState extends State<LoteTrazabilidadScreen> {
  final LoteUnificadoService _loteService = LoteUnificadoService();
  LoteUnificadoModel? _lote;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarLote();
  }

  Future<void> _cargarLote() async {
    try {
      final lote = await _loteService.obtenerLotePorId(widget.loteId);
      if (mounted) {
        setState(() {
          _lote = lote;
          _isLoading = false;
          if (lote == null) {
            _error = 'Lote no encontrado';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error al cargar el lote: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Trazabilidad del Lote'),
        backgroundColor: BioWayColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _cargarLote();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_lote == null) {
      return const Center(
        child: Text('No se encontró información del lote'),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarLote,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderInfo(),
            const SizedBox(height: 24),
            _buildEstadisticas(),
            const SizedBox(height: 24),
            _buildTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code_2,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'ID: ${_lote!.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getEstadoColor(_lote!.datosGenerales.estadoActual).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getEstadoColor(_lote!.datosGenerales.estadoActual),
                  ),
                ),
                child: Text(
                  _getEstadoLabel(_lote!.datosGenerales.estadoActual),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getEstadoColor(_lote!.datosGenerales.estadoActual),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.category,
                  label: 'Material',
                  value: _lote!.datosGenerales.tipoMaterial,
                  color: MaterialUtils.getMaterialColor(
                    _lote!.origen?.tipoPoli ?? '',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.calendar_today,
                  label: 'Creado',
                  value: FormatUtils.formatDate(_lote!.datosGenerales.fechaCreacion),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEstadisticas() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Estadísticas del Lote',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Peso Inicial',
                  value: '${_lote!.datosGenerales.pesoInicial.toStringAsFixed(2)} kg',
                  icon: Icons.scale,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Peso Actual',
                  value: '${_lote!.pesoActual.toStringAsFixed(2)} kg',
                  icon: Icons.scale_outlined,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Merma Total',
                  value: '${_lote!.mermaTotal.toStringAsFixed(2)} kg',
                  icon: Icons.trending_down,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: '% Merma',
                  value: '${_lote!.porcentajeMerma.toStringAsFixed(1)}%',
                  icon: Icons.percent,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Recorrido del Lote',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildTimelineItems(),
        ],
      ),
    );
  }

  List<Widget> _buildTimelineItems() {
    final items = <Widget>[];
    final historial = _lote!.datosGenerales.historialProcesos;
    
    for (int i = 0; i < historial.length; i++) {
      final proceso = historial[i];
      final isFirst = i == 0;
      final isLast = i == historial.length - 1;
      final isCurrent = proceso == _lote!.datosGenerales.procesoActual;
      
      items.add(
        TimelineTile(
          isFirst: isFirst,
          isLast: isLast,
          beforeLineStyle: LineStyle(
            color: _getProcesoColor(proceso).withOpacity(0.3),
            thickness: 3,
          ),
          afterLineStyle: LineStyle(
            color: isLast 
                ? Colors.grey.withOpacity(0.3)
                : _getProcesoColor(historial[i + 1]).withOpacity(0.3),
            thickness: 3,
          ),
          indicatorStyle: IndicatorStyle(
            width: 40,
            height: 40,
            indicator: Container(
              decoration: BoxDecoration(
                color: isCurrent 
                    ? _getProcesoColor(proceso)
                    : _getProcesoColor(proceso).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getProcesoColor(proceso),
                  width: 2,
                ),
              ),
              child: Icon(
                _getProcesoIcon(proceso),
                color: isCurrent ? Colors.white : _getProcesoColor(proceso),
                size: 20,
              ),
            ),
          ),
          endChild: Container(
            padding: const EdgeInsets.only(left: 16, bottom: 20),
            child: _buildProcesoCard(proceso, isCurrent),
          ),
        ),
      );
    }
    
    return items;
  }

  Widget _buildProcesoCard(String proceso, bool isCurrent) {
    final data = _getProcesoData(proceso);
    if (data == null) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: () => _showProcesoDetails(proceso),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrent 
              ? _getProcesoColor(proceso).withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent 
                ? _getProcesoColor(proceso)
                : Colors.grey[300]!,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _getProcesoLabel(proceso),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getProcesoColor(proceso),
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getProcesoColor(proceso),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACTUAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: _getProcesoColor(proceso),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...data.entries.map<Widget>((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key}: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
      ),
    );
  }

  Map<String, String>? _getProcesoData(String proceso) {
    switch (proceso) {
      case 'origen':
        if (_lote!.origen == null) return null;
        return {
          'Usuario': _lote!.origen!.usuarioFolio,
          'Fecha': FormatUtils.formatDateTime(_lote!.origen!.fechaEntrada),
          'Peso': '${_lote!.origen!.pesoNace} kg',
          'Material': _lote!.origen!.tipoPoli,
          'Presentación': _lote!.origen!.presentacion,
        };
        
      case 'transporte':
        if (_lote!.transporte == null) return null;
        return {
          'Usuario': _lote!.transporte!.usuarioFolio,
          'Entrada': FormatUtils.formatDateTime(_lote!.transporte!.fechaEntrada),
          if (_lote!.transporte!.fechaSalida != null)
            'Salida': FormatUtils.formatDateTime(_lote!.transporte!.fechaSalida!),
          'Peso recogido': '${_lote!.transporte!.pesoRecogido} kg',
          if (_lote!.transporte!.pesoEntregado != null)
            'Peso entregado': '${_lote!.transporte!.pesoEntregado} kg',
          if (_lote!.transporte!.merma != null)
            'Merma': '${_lote!.transporte!.merma} kg',
        };
        
      case 'reciclador':
        if (_lote!.reciclador == null) return null;
        return {
          'Usuario': _lote!.reciclador!.usuarioFolio,
          'Entrada': FormatUtils.formatDateTime(_lote!.reciclador!.fechaEntrada),
          if (_lote!.reciclador!.fechaSalida != null)
            'Salida': FormatUtils.formatDateTime(_lote!.reciclador!.fechaSalida!),
          'Peso entrada': '${_lote!.reciclador!.pesoEntrada} kg',
          if (_lote!.reciclador!.pesoProcesado != null)
            'Peso procesado': '${_lote!.reciclador!.pesoProcesado} kg',
          if (_lote!.reciclador!.mermaProceso != null)
            'Merma': '${_lote!.reciclador!.mermaProceso} kg',
        };
        
      case 'laboratorio':
        if (_lote!.laboratorio == null) return null;
        return {
          'Usuario': _lote!.laboratorio!.usuarioFolio,
          'Entrada': FormatUtils.formatDateTime(_lote!.laboratorio!.fechaEntrada),
          'Peso muestra': '${_lote!.laboratorio!.pesoMuestra} kg',
          'Análisis': _lote!.laboratorio!.tipoAnalisis.join(', '),
        };
        
      case 'transformador':
        if (_lote!.transformador == null) return null;
        return {
          'Usuario': _lote!.transformador!.usuarioFolio,
          'Entrada': FormatUtils.formatDateTime(_lote!.transformador!.fechaEntrada),
          'Peso entrada': '${_lote!.transformador!.pesoEntrada} kg',
          if (_lote!.transformador!.pesoSalida != null)
            'Peso salida': '${_lote!.transformador!.pesoSalida} kg',
          if (_lote!.transformador!.tipoProducto != null)
            'Producto': _lote!.transformador!.tipoProducto!,
        };
        
      default:
        return null;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'en_origen':
        return Colors.green;
      case 'en_transporte':
        return Colors.blue;
      case 'en_reciclador':
        return Colors.orange;
      case 'en_laboratorio':
        return Colors.purple;
      case 'en_transformador':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoLabel(String estado) {
    switch (estado) {
      case 'en_origen':
        return 'En Origen';
      case 'en_transporte':
        return 'En Transporte';
      case 'en_reciclador':
        return 'En Reciclador';
      case 'en_laboratorio':
        return 'En Laboratorio';
      case 'en_transformador':
        return 'En Transformador';
      default:
        return estado;
    }
  }

  Color _getProcesoColor(String proceso) {
    switch (proceso) {
      case 'origen':
        return const Color(0xFF2E7D32);
      case 'transporte':
        return const Color(0xFF1976D2);
      case 'reciclador':
        return const Color(0xFF388E3C);
      case 'laboratorio':
        return const Color(0xFF7B1FA2);
      case 'transformador':
        return const Color(0xFFD32F2F);
      default:
        return Colors.grey;
    }
  }

  IconData _getProcesoIcon(String proceso) {
    switch (proceso) {
      case 'origen':
        return Icons.source;
      case 'transporte':
        return Icons.local_shipping;
      case 'reciclador':
        return Icons.recycling;
      case 'laboratorio':
        return Icons.science;
      case 'transformador':
        return Icons.precision_manufacturing;
      default:
        return Icons.circle;
    }
  }

  String _getProcesoLabel(String proceso) {
    switch (proceso) {
      case 'origen':
        return 'Origen';
      case 'transporte':
        return 'Transporte';
      case 'reciclador':
        return 'Reciclador';
      case 'laboratorio':
        return 'Laboratorio';
      case 'transformador':
        return 'Transformador';
      default:
        return proceso;
    }
  }
  
  void _showProcesoDetails(String proceso) {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProcesoDetailsSheet(
        lote: _lote!,
        proceso: proceso,
      ),
    );
  }
}

class _ProcesoDetailsSheet extends StatelessWidget {
  final LoteUnificadoModel lote;
  final String proceso;
  
  const _ProcesoDetailsSheet({
    required this.lote,
    required this.proceso,
  });
  
  @override
  Widget build(BuildContext context) {
    final procesoData = _getProcesoCompleteData();
    
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
                  color: _getProcesoColor(proceso).withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: _getProcesoColor(proceso).withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getProcesoColor(proceso),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getProcesoIcon(proceso),
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
                            _getProcesoLabel(proceso),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (procesoData['fecha_entrada'] != null)
                            Text(
                              'Entrada: ${procesoData['fecha_entrada']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
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
                    // Información del usuario
                    if (procesoData['usuario_folio'] != null)
                      _buildInfoCard(
                        title: 'Información del Usuario',
                        icon: Icons.person,
                        items: {
                          'Folio': procesoData['usuario_folio']!,
                          if (procesoData['nombre_operador'] != null)
                            'Operador': procesoData['nombre_operador']!,
                        },
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Información del proceso
                    _buildInfoCard(
                      title: 'Detalles del Proceso',
                      icon: Icons.info,
                      items: _getProcesoSpecificInfo(procesoData),
                    ),
                    
                    // Firma
                    if (procesoData['firma_operador'] != null ||
                        procesoData['firma_entrada'] != null ||
                        procesoData['firma_salida'] != null) ...[
                      const SizedBox(height: 16),
                      _buildSignatureSection(context, procesoData),
                    ],
                    
                    // Evidencias fotográficas
                    if (procesoData['evidencias_foto'] != null) ...[
                      const SizedBox(height: 16),
                      _buildPhotosSection(procesoData['evidencias_foto'] as List),
                    ],
                    
                    // Comentarios
                    if (procesoData['comentarios'] != null &&
                        procesoData['comentarios']!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildCommentsSection(procesoData['comentarios']!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Map<String, dynamic> _getProcesoCompleteData() {
    switch (proceso) {
      case 'origen':
        if (lote.origen == null) return {};
        return {
          'usuario_folio': lote.origen!.usuarioFolio,
          'fecha_entrada': FormatUtils.formatDateTime(lote.origen!.fechaEntrada),
          'fecha_salida': lote.origen!.fechaSalida != null
              ? FormatUtils.formatDateTime(lote.origen!.fechaSalida!)
              : null,
          'direccion': lote.origen!.direccion,
          'fuente': lote.origen!.fuente,
          'presentacion': lote.origen!.presentacion,
          'tipo_poli': lote.origen!.tipoPoli,
          'origen': lote.origen!.origen,
          'peso_nace': '${lote.origen!.pesoNace} kg',
          'condiciones': lote.origen!.condiciones,
          'nombre_operador': lote.origen!.nombreOperador,
          'firma_operador': lote.origen!.firmaOperador,
          'evidencias_foto': lote.origen!.evidenciasFoto,
          'comentarios': lote.origen!.comentarios,
        };
        
      case 'transporte':
        if (lote.transporte == null) return {};
        return {
          'usuario_folio': lote.transporte!.usuarioFolio,
          'fecha_entrada': FormatUtils.formatDateTime(lote.transporte!.fechaEntrada),
          'fecha_salida': lote.transporte!.fechaSalida != null
              ? FormatUtils.formatDateTime(lote.transporte!.fechaSalida!)
              : null,
          'peso_recogido': '${lote.transporte!.pesoRecogido} kg',
          'peso_entregado': lote.transporte!.pesoEntregado != null
              ? '${lote.transporte!.pesoEntregado} kg'
              : null,
          'merma': lote.transporte!.merma != null
              ? '${lote.transporte!.merma} kg'
              : null,
          'firma_recogida': lote.transporte!.firmaRecogida ?? '',
          'firma_entrega': lote.transporte!.firmaEntrega ?? '',
          'evidencias_foto': lote.transporte!.evidenciasFoto,
        };
        
      case 'reciclador':
        if (lote.reciclador == null) return {};
        return {
          'usuario_folio': lote.reciclador!.usuarioFolio,
          'fecha_entrada': FormatUtils.formatDateTime(lote.reciclador!.fechaEntrada),
          'fecha_salida': lote.reciclador!.fechaSalida != null
              ? FormatUtils.formatDateTime(lote.reciclador!.fechaSalida!)
              : null,
          'peso_entrada': '${lote.reciclador!.pesoEntrada} kg',
          'peso_procesado': lote.reciclador!.pesoProcesado != null
              ? '${lote.reciclador!.pesoProcesado} kg'
              : null,
          'merma_proceso': lote.reciclador!.mermaProceso != null
              ? '${lote.reciclador!.mermaProceso} kg'
              : null,
          'evidencias_foto': lote.reciclador!.evidenciasFoto,
        };
        
      case 'laboratorio':
        if (lote.laboratorio == null) return {};
        return {
          'usuario_folio': lote.laboratorio!.usuarioFolio,
          'fecha_entrada': FormatUtils.formatDateTime(lote.laboratorio!.fechaEntrada),
          'peso_muestra': '${lote.laboratorio!.pesoMuestra} kg',
          'tipo_analisis': lote.laboratorio!.tipoAnalisis.join(', '),
          'resultados': lote.laboratorio!.resultados,
          'observaciones': lote.laboratorio!.observaciones ?? '',
        };
        
      case 'transformador':
        if (lote.transformador == null) return {};
        return {
          'usuario_folio': lote.transformador!.usuarioFolio,
          'fecha_entrada': FormatUtils.formatDateTime(lote.transformador!.fechaEntrada),
          'fecha_salida': lote.transformador!.fechaSalida != null
              ? FormatUtils.formatDateTime(lote.transformador!.fechaSalida!)
              : null,
          'peso_entrada': '${lote.transformador!.pesoEntrada} kg',
          'peso_salida': lote.transformador!.pesoSalida != null
              ? '${lote.transformador!.pesoSalida} kg'
              : null,
          'tipo_producto': lote.transformador!.tipoProducto,
          'evidencias_foto': lote.transformador!.evidenciasFoto,
        };
        
      default:
        return {};
    }
  }
  
  Map<String, String> _getProcesoSpecificInfo(Map<String, dynamic> data) {
    final info = <String, String>{};
    
    // Agregar campos específicos según el proceso
    switch (proceso) {
      case 'origen':
        if (data['direccion'] != null) info['Dirección'] = data['direccion'];
        if (data['fuente'] != null) info['Fuente'] = data['fuente'];
        if (data['presentacion'] != null) info['Presentación'] = data['presentacion'];
        if (data['tipo_poli'] != null) info['Tipo de Polímero'] = data['tipo_poli'];
        if (data['origen'] != null) info['Origen'] = data['origen'];
        if (data['peso_nace'] != null) info['Peso'] = data['peso_nace'];
        if (data['condiciones'] != null) info['Condiciones'] = data['condiciones'];
        break;
        
      case 'transporte':
        if (data['vehiculo_placas'] != null) info['Placas del Vehículo'] = data['vehiculo_placas'];
        if (data['peso_recogido'] != null) info['Peso Recogido'] = data['peso_recogido'];
        if (data['peso_entregado'] != null) info['Peso Entregado'] = data['peso_entregado'];
        if (data['merma'] != null) info['Merma'] = data['merma'];
        break;
        
      case 'reciclador':
        if (data['peso_entrada'] != null) info['Peso de Entrada'] = data['peso_entrada'];
        if (data['peso_procesado'] != null) info['Peso Procesado'] = data['peso_procesado'];
        if (data['merma_proceso'] != null) info['Merma del Proceso'] = data['merma_proceso'];
        break;
        
      case 'laboratorio':
        if (data['peso_muestra'] != null) info['Peso de la Muestra'] = data['peso_muestra'];
        if (data['tipo_analisis'] != null) info['Tipo de Análisis'] = data['tipo_analisis'];
        if (data['resultados'] != null) info['Resultados'] = data['resultados'];
        break;
        
      case 'transformador':
        if (data['peso_entrada'] != null) info['Peso de Entrada'] = data['peso_entrada'];
        if (data['peso_salida'] != null) info['Peso de Salida'] = data['peso_salida'];
        if (data['tipo_producto'] != null) info['Tipo de Producto'] = data['tipo_producto'];
        break;
    }
    
    return info;
  }
  
  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Map<String, String> items,
  }) {
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
              Icon(icon, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key}: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildSignatureSection(BuildContext context, Map<String, dynamic> data) {
    final signatures = <String, String>{};
    
    if (data['firma_operador'] != null) signatures['Firma del Operador'] = data['firma_operador'];
    if (data['firma_entrada'] != null) signatures['Firma de Entrada'] = data['firma_entrada'];
    if (data['firma_salida'] != null) signatures['Firma de Salida'] = data['firma_salida'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.draw, size: 20, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Firmas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...signatures.entries.map((entry) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showFullImage(context, entry.value),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      entry.value,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          )),
        ],
      ),
    );
  }
  
  Widget _buildPhotosSection(List<dynamic> photos) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, size: 20, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'Evidencias Fotográficas (${photos.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showPhotoGallery(context, photos, index),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photos[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCommentsSection(String comments) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.comment, size: 20, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Comentarios',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comments,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
  
    void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Center(
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
          ),
        ),
      ),
    );
  }
  
  void _showPhotoGallery(BuildContext context, List<dynamic> photos, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('${initialIndex + 1} / ${photos.length}'),
          ),
          body: PhotoViewGallery.builder(
            itemCount: photos.length,
            pageController: PageController(initialPage: initialIndex),
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(photos[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            onPageChanged: (index) {
              // Actualizar el título si lo necesitas
            },
          ),
        ),
      ),
    );
  }
  
  Color _getProcesoColor(String proceso) {
    switch (proceso) {
      case 'origen':
        return const Color(0xFF2E7D32);
      case 'transporte':
        return const Color(0xFF1976D2);
      case 'reciclador':
        return const Color(0xFF388E3C);
      case 'laboratorio':
        return const Color(0xFF7B1FA2);
      case 'transformador':
        return const Color(0xFFD32F2F);
      default:
        return Colors.grey;
    }
  }
  
  IconData _getProcesoIcon(String proceso) {
    switch (proceso) {
      case 'origen':
        return Icons.source;
      case 'transporte':
        return Icons.local_shipping;
      case 'reciclador':
        return Icons.recycling;
      case 'laboratorio':
        return Icons.science;
      case 'transformador':
        return Icons.precision_manufacturing;
      default:
        return Icons.circle;
    }
  }
  
  String _getProcesoLabel(String proceso) {
    switch (proceso) {
      case 'origen':
        return 'Origen';
      case 'transporte':
        return 'Transporte';
      case 'reciclador':
        return 'Reciclador';
      case 'laboratorio':
        return 'Laboratorio';
      case 'transformador':
        return 'Transformador';
      default:
        return proceso;
    }
  }
}