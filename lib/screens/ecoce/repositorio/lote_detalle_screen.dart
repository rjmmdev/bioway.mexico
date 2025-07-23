import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../shared/utils/material_utils.dart';
import 'widgets/timeline_widget.dart';
import 'widgets/detail_info_card.dart';

class LoteDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> lote;
  final Color primaryColor;
  
  const LoteDetalleScreen({
    super.key,
    required this.lote,
    required this.primaryColor,
  });

  @override
  State<LoteDetalleScreen> createState() => _LoteDetalleScreenState();
}

class _LoteDetalleScreenState extends State<LoteDetalleScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  List<Map<String, dynamic>> _getTimelineEvents() {
    // Usar el historial de trazabilidad real si existe
    if (widget.lote['historialTrazabilidad'] != null) {
      final historial = widget.lote['historialTrazabilidad'] as List<dynamic>;
      
      return historial.map((evento) {
        IconData icon;
        Color color;
        
        // Asignar iconos y colores según el tipo de actor
        switch (evento['tipo']) {
          case 'Acopiador':
            icon = Icons.warehouse;
            color = BioWayColors.petBlue;
            break;
          case 'Planta de Separación':
            icon = Icons.sort;
            color = BioWayColors.hdpeGreen;
            break;
          case 'Transportista':
            icon = Icons.local_shipping;
            color = BioWayColors.info;
            break;
          case 'Reciclador':
            icon = Icons.recycling;
            color = BioWayColors.ecoceGreen;
            break;
          case 'Transformador':
            icon = Icons.factory;
            color = BioWayColors.ppOrange;
            break;
          case 'Laboratorio':
            icon = Icons.science;
            color = BioWayColors.otherPurple;
            break;
          default:
            icon = Icons.circle;
            color = widget.primaryColor;
        }
        
        return {
          'title': evento['accion'] ?? evento['etapa'],
          'subtitle': evento['actor'],
          'date': evento['fecha'],
          'icon': icon,
          'color': color,
          'isCompleted': true,
          'details': evento['detalles'],
          'peso': evento['peso'],
        };
      }).toList();
    }
    
    // Fallback: datos simulados si no hay historial
    return [
      {
        'title': 'Lote Creado',
        'subtitle': widget.lote['origen'] ?? 'Centro de Acopio',
        'date': widget.lote['fechaCreacion'],
        'icon': Icons.add_circle_outline,
        'color': BioWayColors.success,
        'isCompleted': true,
        'details': 'Creación inicial del lote',
        'peso': widget.lote['peso'],
      },
      {
        'title': 'En Proceso',
        'subtitle': widget.lote['ubicacionActual'],
        'date': DateTime.now(),
        'icon': Icons.sync,
        'color': widget.primaryColor,
        'isCompleted': true,
        'details': 'Ubicación actual del lote',
        'peso': widget.lote['peso'],
      },
    ];
  }

  Map<String, dynamic> _getDetailedInfo() {
    final infoBasica = {
      'ID del Lote': widget.lote['id']?.toString() ?? 'N/A',
      'Firebase ID': widget.lote['firebaseId']?.toString() ?? 'N/A',
      'Tipo de Material': widget.lote['material']?.toString() ?? 'Sin especificar',
      'Peso Inicial': '${widget.lote['peso'] ?? 0} kg',
      'Estado Actual': widget.lote['estado']?.toString() ?? 'activo',
      'Fecha de Creación': widget.lote['fechaCreacion'] != null 
          ? MaterialUtils.formatDate(widget.lote['fechaCreacion'] is DateTime 
              ? widget.lote['fechaCreacion'] 
              : DateTime.now())
          : 'N/A',
    };
    
    // Si hay historial, agregar peso actual
    if (widget.lote['historialTrazabilidad'] != null && 
        (widget.lote['historialTrazabilidad'] as List).isNotEmpty) {
      final ultimoEvento = (widget.lote['historialTrazabilidad'] as List).last;
      if (ultimoEvento['peso'] != null && widget.lote['peso'] != null) {
        infoBasica['Peso Actual'] = '${ultimoEvento['peso']} kg';
        final pesoInicial = (widget.lote['peso'] as num).toDouble();
        final pesoActual = (ultimoEvento['peso'] as num).toDouble();
        final perdida = pesoInicial - pesoActual;
        if (perdida > 0 && pesoInicial > 0) {
          infoBasica['Pérdida Total'] = '${perdida.toStringAsFixed(1)} kg (${((perdida / pesoInicial) * 100).toStringAsFixed(1)}%)';
        }
      }
    }
    
    final origenDestino = {
      'Centro de Origen': widget.lote['origen']?.toString() ?? 'Desconocido',
      'Ubicación Actual': widget.lote['ubicacionActual']?.toString() ?? 'En proceso',
    };
    
    // Agregar información del último actor si existe
    if (widget.lote['historialTrazabilidad'] != null && 
        (widget.lote['historialTrazabilidad'] as List).isNotEmpty) {
      final ultimoEvento = (widget.lote['historialTrazabilidad'] as List).last;
      origenDestino['Último Actor'] = ultimoEvento['actor'] ?? 'No especificado';
      origenDestino['Último Proceso'] = ultimoEvento['accion'] ?? 'No especificado';
    }
    
    // Información de trazabilidad
    final trazabilidadInfo = {
      'Total de Etapas': '${widget.lote['historialTrazabilidad']?.length ?? 0}',
    };
    
    // Calcular días en proceso si hay fecha de creación válida
    if (widget.lote['fechaCreacion'] != null) {
      try {
        final fechaCreacion = widget.lote['fechaCreacion'] is DateTime 
            ? widget.lote['fechaCreacion'] 
            : DateTime.now();
        trazabilidadInfo['Días en Proceso'] = '${DateTime.now().difference(fechaCreacion).inDays}';
      } catch (e) {
        trazabilidadInfo['Días en Proceso'] = 'N/A';
      }
    } else {
      trazabilidadInfo['Días en Proceso'] = 'N/A';
    }
    
    // Contar tipos de actores involucrados
    if (widget.lote['historialTrazabilidad'] != null) {
      final actores = <String>{};
      for (var evento in widget.lote['historialTrazabilidad']) {
        if (evento['tipo'] != null) {
          actores.add(evento['tipo']);
        }
      }
      trazabilidadInfo['Actores Involucrados'] = actores.length.toString();
      trazabilidadInfo['Tipos de Actores'] = actores.join(', ');
    }
    
    return {
      'Información Básica': infoBasica,
      'Origen y Destino': origenDestino,
      'Información de Trazabilidad': trazabilidadInfo,
    };
  }

  Widget _buildInfoTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final detailedInfo = _getDetailedInfo();
    
    return ListView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      children: detailedInfo.entries.map((entry) {
        return DetailInfoCard(
          title: entry.key,
          info: entry.value,
          primaryColor: widget.primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildTimelineTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final events = _getTimelineEvents();
    
    return ListView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trazabilidad del Lote',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              TimelineWidget(events: events),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return ListView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      children: [
        _buildDocumentItem(
          'Certificado de Origen',
          'PDF',
          '2.3 MB',
          Icons.picture_as_pdf,
          Colors.red,
        ),
        _buildDocumentItem(
          'Análisis de Calidad',
          'PDF',
          '1.8 MB',
          Icons.science,
          Colors.blue,
        ),
        _buildDocumentItem(
          'Guía de Transporte',
          'PDF',
          '890 KB',
          Icons.local_shipping,
          Colors.orange,
        ),
        _buildDocumentItem(
          'Fotos del Lote',
          'ZIP',
          '15.2 MB',
          Icons.photo_library,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildDocumentItem(
    String title,
    String type,
    String size,
    IconData icon,
    Color color,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Descargando $title...'),
                backgroundColor: widget.primaryColor,
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w600,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                      Text(
                        '$type • $size',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.download,
                  color: widget.primaryColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final materialStr = widget.lote['material']?.toString() ?? 'Sin especificar';
    final materialColor = MaterialUtils.getMaterialColor(materialStr);
    final materialIcon = MaterialUtils.getMaterialIcon(materialStr);
    
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Lote Info
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.primaryColor,
                    widget.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Detalles del Lote',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // Compartir detalles del lote
                        },
                        icon: const Icon(
                          Icons.share,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.04),
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          materialIcon,
                          color: materialColor,
                          size: 40,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.lote['id']?.toString() ?? 'Sin ID',
                              style: TextStyle(
                                fontSize: screenWidth * 0.06,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.03,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.lote['material']?.toString() ?? 'Sin especificar',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.03,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.03,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${widget.lote['peso'] ?? 0} kg',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.03,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: widget.primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: widget.primaryColor,
                tabs: const [
                  Tab(text: 'Información'),
                  Tab(text: 'Trazabilidad'),
                  Tab(text: 'Documentos'),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(),
                  _buildTimelineTab(),
                  _buildDocumentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}