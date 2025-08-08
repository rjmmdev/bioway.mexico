// Migración a estructura del Reciclador - Fase 1 - 2025-01-05
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../models/lotes/lote_unificado_model.dart';
import '../../../models/lotes/transformacion_model.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/transformacion_service.dart';
import '../../../utils/colors.dart';
import '../../../utils/ui_constants.dart';
import '../../../utils/format_utils.dart';
import '../shared/utils/material_utils.dart';
// Widgets compartidos del Reciclador
import '../shared/widgets/lote_filter_section.dart';
import '../shared/widgets/lote_stats_section.dart';
import '../shared/widgets/lote_card_general.dart';
// Pantallas propias del Transformador
import 'transformador_formulario_salida.dart';
import 'transformador_documentacion_screen.dart';
import 'transformador_lote_detalle_screen.dart';
import 'transformador_documentacion_megalote_screen.dart';
import 'widgets/selection_panel.dart';
import 'widgets/transformacion_card_transformador.dart';

class TransformadorProduccionScreen extends StatefulWidget {
  final int? initialTab;
  
  const TransformadorProduccionScreen({super.key, this.initialTab});

  @override
  State<TransformadorProduccionScreen> createState() => _TransformadorProduccionScreenState();
}

class _TransformadorProduccionScreenState extends State<TransformadorProduccionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  final TransformacionService _transformacionService = TransformacionService();

  // Streams de datos - inicializar con streams vacíos para evitar null
  late Stream<List<LoteUnificadoModel>> _lotesStream;
  late Stream<List<TransformacionModel>> _transformacionesStream;
  
  // Estados
  bool _isSelectionMode = false;
  bool _autoSelectionMode = false; // Para el tab de Salida
  final Set<String> _selectedLotes = {};
  
  // Filtros
  String _filtroMaterial = 'Todos';
  String _filtroTiempo = 'Todos';
  DateTime? _filtroFechaInicio;
  DateTime? _filtroFechaFin;
  

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3, 
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );
    // Activar modo de selección automática si iniciamos en el tab de Salida
    _autoSelectionMode = (widget.initialTab ?? 0) == 0;
    _tabController.addListener(() {
      setState(() {
        // Forzar actualización del UI cuando cambia el tab para actualizar colores
        if (_tabController.indexIsChanging || _tabController.index != _tabController.previousIndex) {
          // Activar modo de selección automática solo en el tab de Salida (índice 0)
          _autoSelectionMode = _tabController.index == 0;
          // Limpiar selecciones al cambiar de tab
          _selectedLotes.clear();
          // Solo mantener el modo de selección manual si NO estamos en el tab de Salida
          if (_tabController.index != 0) {
            _isSelectionMode = false;
          }
        }
      });
    });
    // Inicializar streams inmediatamente para evitar delays
    _loadLotes();
    _loadTransformaciones();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we need to update the tab based on navigation arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      // Handle initial tab
      if (args['initialTab'] != null) {
        final tabIndex = args['initialTab'] as int;
        if (tabIndex >= 0 && tabIndex < 3 && _tabController.index != tabIndex) {
          _tabController.animateTo(tabIndex);
          // Force refresh when changing tabs via navigation
          _loadLotes();
          _loadTransformaciones();
        }
      }
      
      // Handle show megalotes flag
      // Ya no necesitamos el filtro de megalotes
    }
  }
  
  // Helper para obtener el estado de un lote
  String _getEstadoLote(LoteUnificadoModel lote) {
    // Buscar estado en especificaciones del transformador
    // Si el transformador tiene especificaciones, buscar ahí el estado
    if (lote.transformador?.especificaciones != null && 
        lote.transformador!.especificaciones!.containsKey('estado')) {
      final estado = lote.transformador!.especificaciones!['estado'] as String;
      return estado;
    }
    
    // Si no se encuentra, usar 'pendiente' como valor por defecto
    return 'pendiente';
  }

  void _loadLotes() {
    // Recargar el stream de lotes
    setState(() {
      _lotesStream = _loteUnificadoService.obtenerMisLotesPorProcesoActual('transformador');
    });
  }

  void _loadTransformaciones() {
    // Recargar el stream de transformaciones
    setState(() {
      _transformacionesStream = _transformacionService.obtenerTransformacionesUsuario();
    });
  }

  List<LoteUnificadoModel> _aplicarFiltros(List<LoteUnificadoModel> lotes) {
    return lotes.where((lote) {
      // Filtro por material - Manejar prefijo "EPF-" y variaciones
      if (_filtroMaterial != 'Todos') {
        String materialLote = lote.datosGenerales.tipoMaterial.trim();
        String materialBuscado = _filtroMaterial.trim();
        
        // Normalizar removiendo prefijo EPF- si existe
        String materialLoteNormalizado = materialLote.toUpperCase();
        if (materialLoteNormalizado.startsWith('EPF-')) {
          materialLoteNormalizado = materialLoteNormalizado.substring(4);
        }
        
        // Normalizar el material buscado
        String materialBuscadoNormalizado = materialBuscado.toUpperCase();
        
        // Manejar caso especial de Multilaminado
        if (materialBuscadoNormalizado == 'MULTILAMINADO') {
          if (materialLoteNormalizado != 'MULTILAMINADO' && 
              materialLoteNormalizado != 'MULTI' &&
              !materialLoteNormalizado.startsWith('MULTILAM')) {
            return false;
          }
        } 
        // Manejar caso de POLI
        else if (materialBuscadoNormalizado == 'POLI') {
          if (materialLoteNormalizado != 'POLI' && 
              materialLoteNormalizado != 'POLIETILENO' &&
              !materialLoteNormalizado.startsWith('POLI')) {
            return false;
          }
        }
        // Comparación directa para otros casos (PP)
        else if (materialLoteNormalizado != materialBuscadoNormalizado) {
          return false;
        }
      }
      
      // Filtro por tiempo
      if (_filtroTiempo != 'Todos' && lote.transformador != null) {
        final now = DateTime.now();
        final fechaEntrada = lote.transformador!.fechaEntrada;
        
        switch (_filtroTiempo) {
          case 'Hoy':
            return fechaEntrada.day == now.day && 
                   fechaEntrada.month == now.month && 
                   fechaEntrada.year == now.year;
          case 'Esta semana':
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            return fechaEntrada.isAfter(startOfWeek);
          case 'Este mes':
            return fechaEntrada.month == now.month && fechaEntrada.year == now.year;
        }
      }
      
      // Mantener filtro por fecha si existe
      if (_filtroFechaInicio != null || _filtroFechaFin != null) {
        final fechaCreacion = lote.datosGenerales.fechaCreacion;
        if (_filtroFechaInicio != null && fechaCreacion.isBefore(_filtroFechaInicio!)) {
          return false;
        }
        if (_filtroFechaFin != null && fechaCreacion.isAfter(_filtroFechaFin!)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }


  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedLotes.clear();
      }
    });
  }
  
  void _startSelectionMode(String loteId) {
    setState(() {
      _isSelectionMode = true;
      _selectedLotes.clear();
      _selectedLotes.add(loteId);
    });
  }

  void _toggleLoteSelection(String loteId) {
    setState(() {
      if (_selectedLotes.contains(loteId)) {
        _selectedLotes.remove(loteId);
      } else {
        _selectedLotes.add(loteId);
      }
    });
  }


  // Construir pestaña con RefreshIndicator
  Widget _buildTabWithRefresh({required Widget child}) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        _loadLotes();
        _loadTransformaciones();
        await Future.delayed(const Duration(seconds: 1));
      },
      color: Colors.orange,
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 40.0,
      notificationPredicate: (notification) {
        // Solo activar refresh si es el scroll principal
        return notification.depth == 0;
      },
      child: child,
    );
  }

  void _procesarLotesSeleccionados() async {
    if (_selectedLotes.isEmpty) return;
    
    // Navigate to the form with selected lots
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransformadorFormularioSalida(
          lotesIds: _selectedLotes.toList(),
        ),
      ),
    );
    
    // Clear selection after processing
    setState(() {
      _isSelectionMode = false;
      _selectedLotes.clear();
    });
  }

  Widget _buildTransformacionCard(TransformacionModel transformacion) {
    return TransformacionCardTransformador(
      transformacion: transformacion,
      onTap: () => _showTransformacionDetails(transformacion),
      onUploadDocuments: transformacion.estado == 'documentacion' 
        ? () => _uploadDocumentacion(transformacion) 
        : null,
    );
  }


  void _showTransformacionDetails(TransformacionModel transformacion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(UIConstants.radiusLarge),
            topRight: Radius.circular(UIConstants.radiusLarge),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: UIConstants.spacing12, bottom: UIConstants.spacing20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(UIConstants.radiusSmall / 2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detalles del Megalote',
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeXLarge,
                      fontWeight: FontWeight.bold,
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
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsetsConstants.paddingAll20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('ID', transformacion.id),
                    _buildDetailSection('Estado', transformacion.estado),
                    
                    // Indicador de formulario de salida completado
                    if (transformacion.datos['operador_salida'] != null || 
                        transformacion.datos['producto_fabricado'] != null) ...[
                      Container(
                        margin: EdgeInsets.only(bottom: UIConstants.spacing16),
                        padding: EdgeInsets.all(UIConstants.spacing12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            SizedBox(width: UIConstants.spacing8),
                            Text(
                              'Formulario de salida completado',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    _buildDetailSection('Fecha Inicio', FormatUtils.formatDateTime(transformacion.fechaInicio)),
                    if (transformacion.fechaFin != null)
                      _buildDetailSection('Fecha Fin', FormatUtils.formatDateTime(transformacion.fechaFin!)),
                    _buildDetailSection('Peso Entrada', '${transformacion.pesoTotalEntrada.toStringAsFixed(2)} kg'),
                    if (transformacion.datos['peso_salida'] != null)
                      _buildDetailSection('Peso Salida', '${transformacion.datos['peso_salida'].toStringAsFixed(2)} kg'),
                    _buildDetailSection('Merma', '${transformacion.mermaProceso.toStringAsFixed(2)} kg'),
                    if (transformacion.datos['producto_fabricado'] != null)
                      _buildDetailSection('Producto Fabricado', transformacion.datos['producto_fabricado']),
                    if (transformacion.datos['cantidad_generada'] != null)
                      _buildDetailSection('Cantidad Generada', '${transformacion.datos['cantidad_generada']} kg'),
                    if (transformacion.datos['procesos_aplicados'] != null && transformacion.datos['procesos_aplicados'] is List) ...[
                      SizedBox(height: UIConstants.spacing8),
                      const Text(
                        'Procesos Aplicados:',
                        style: TextStyle(
                          fontSize: UIConstants.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: UIConstants.spacing8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (transformacion.datos['procesos_aplicados'] as List).map((proceso) =>
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              proceso.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ).toList(),
                      ),
                      SizedBox(height: UIConstants.spacing12),
                    ],
                    if (transformacion.datos['confirma_porcentaje'] == true) ...[
                      _buildDetailSection('Material Reciclado', '33% del producto total'),
                      _buildDetailSection('Compuesto Adicional', '67% del producto total'),
                    ],
                    if (transformacion.datos['descripcion_compuesto'] != null && 
                        transformacion.datos['descripcion_compuesto'].toString().isNotEmpty)
                      _buildDetailSection('Descripción del Compuesto', transformacion.datos['descripcion_compuesto']),
                    if (transformacion.datos['operador_salida'] != null)
                      _buildDetailSection('Operador', transformacion.datos['operador_salida']),
                    if (transformacion.datos['comentarios'] != null && transformacion.datos['comentarios'].toString().isNotEmpty)
                      _buildDetailSection('Comentarios', transformacion.datos['comentarios']),
                    if (transformacion.datos['firma_salida'] != null)
                      _buildDetailSection('Firma', '✓ Documento firmado'),
                    if (transformacion.datos['evidencias_salida'] != null && 
                        transformacion.datos['evidencias_salida'] is List &&
                        (transformacion.datos['evidencias_salida'] as List).isNotEmpty)
                      _buildDetailSection('Evidencias Fotográficas', 
                        '${(transformacion.datos['evidencias_salida'] as List).length} fotos'),
                    SizedBox(height: UIConstants.spacing20),
                    const Text(
                      'Lotes Procesados',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeBody,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: UIConstants.spacing8 + 2),
                    ...transformacion.lotesEntrada.map((lote) => Container(
                      margin: EdgeInsets.only(bottom: UIConstants.spacing8),
                      padding: EdgeInsetsConstants.paddingAll12,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadiusConstants.borderRadiusSmall,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              lote.loteId,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(width: UIConstants.spacing8),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${lote.tipoMaterial} - ${lote.peso.toStringAsFixed(2)} kg',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String label, String value) {
    // Para valores muy largos o IDs, usar diseño en columna
    final bool useColumnLayout = value.length > 30 || label == 'ID' || label.contains('Descripción');
    
    if (useColumnLayout) {
      return Padding(
        padding: EdgeInsets.only(bottom: UIConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: UIConstants.fontSizeMedium,
              ),
            ),
            SizedBox(height: UIConstants.spacing4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: UIConstants.fontSizeMedium,
              ),
              softWrap: true,
            ),
          ],
        ),
      );
    }
    
    // Diseño en fila para valores cortos
    return Padding(
      padding: EdgeInsets.only(bottom: UIConstants.spacing16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: UIConstants.fontSizeMedium,
              ),
            ),
          ),
          SizedBox(width: UIConstants.spacing12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: UIConstants.fontSizeMedium,
              ),
              textAlign: TextAlign.end,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  void _uploadDocumentacion(TransformacionModel transformacion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransformadorDocumentacionMegaloteScreen(
          transformacionId: transformacion.id,
          transformacion: transformacion,
        ),
      ),
    ).then((result) {
      // Refresh transformaciones after returning
      _loadTransformaciones();
    });
  }

  // Obtener color según el tab actual para indicar urgencia
  Color _getTabColor() {
    switch (_tabController.index) {
      case 0: // Salida - Urgente (Rojo)
        return BioWayColors.error;
      case 1: // Documentación - Medio (Naranja)
        return Colors.orange;
      case 2: // Completados - Bajo (Verde)
        return BioWayColors.success;
      default:
        return Colors.orange;
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        Navigator.pushReplacementNamed(context, '/transformador_inicio');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.orange,
          elevation: UIConstants.elevationNone,
          automaticallyImplyLeading: false,
          centerTitle: true,  // Centrar el título
          title: const Text(
            'Gestión de Producción',
            style: TextStyle(
              fontSize: UIConstants.fontSizeXLarge,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            if (!_autoSelectionMode && _tabController.index == 0)
              IconButton(
                icon: const Icon(Icons.checklist, color: Colors.white),
                onPressed: _toggleSelectionMode,
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: _getTabColor(),
                unselectedLabelColor: Colors.grey,
                indicatorColor: _getTabColor(),
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: EdgeInsets.symmetric(horizontal: UIConstants.spacing16),
                tabs: const [
                  Tab(text: 'Salida'),
                  Tab(text: 'Documentación'),
                  Tab(text: 'Completados'),
                ],
              ),
            ),
          ),
        ),
        body: StreamBuilder<List<LoteUnificadoModel>>(
          stream: _lotesStream,
          builder: (context, lotesSnapshot) {
            return StreamBuilder<List<TransformacionModel>>(
              stream: _transformacionesStream,
              builder: (context, transformacionesSnapshot) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabWithRefresh(
                      child: _buildSalidaTabContent(lotesSnapshot),
                    ),
                    _buildTabWithRefresh(
                      child: _buildDocumentacionTabContent(transformacionesSnapshot),
                    ),
                    _buildTabWithRefresh(
                      child: _buildCompletadosTabContent(transformacionesSnapshot),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompletadosTabContent(AsyncSnapshot<List<TransformacionModel>> snapshot) {
    // Manejo de estados
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildLoadingWithFilters(BioWayColors.success);
    }
    
    if (snapshot.hasError) {
      return _buildErrorState(snapshot.error);
    }
    
    final allTransformaciones = snapshot.data ?? [];
    
    // Filtrar transformaciones completadas
    final transformacionesCompletadas = allTransformaciones.where((t) {
      return t.tipo == 'agrupacion_transformador' &&
             t.estado == 'completado' && 
             (_filtroMaterial == 'Todos' || _megaloteContieneMaterial(t, _filtroMaterial));
    }).toList();
    
    // Siempre mostrar la UI completa
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // Filtros
        LoteFilterSection(
          selectedMaterial: _filtroMaterial,
          selectedTime: _filtroTiempo,
          selectedPresentacion: null,
          onMaterialChanged: (value) {
            setState(() {
              _filtroMaterial = value;
            });
          },
          onTimeChanged: (value) {
            setState(() {
              _filtroTiempo = value;
            });
          },
          onPresentacionChanged: null,
          tabColor: Colors.orange,
          showMegaloteFilter: false,
        ),
        
        // Estadísticas
        LoteStatsSection(
          lotesCount: transformacionesCompletadas.length,
          pesoTotal: transformacionesCompletadas.fold(0.0, 
            (sum, t) => sum + (t.datos['peso_salida'] ?? t.pesoTotalEntrada)),
          tabColor: BioWayColors.success,
          showInTons: true,
          customLotesLabel: 'Megalotes Completados',
        ),
        
        // Lista de transformaciones o estado vacío
        if (transformacionesCompletadas.isEmpty)
          _buildEmptyStateMegalotes()
        else
          ...transformacionesCompletadas.map(
            (transformacion) => Padding(
              padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing16),
              child: _buildTransformacionCard(transformacion),
            ),
          ),
        
        SizedBox(height: UIConstants.qrSizeSmall),
      ],
    );
  }

  Widget _buildDocumentacionTabContent(AsyncSnapshot<List<TransformacionModel>> snapshot) {
    // Manejo de estados
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildLoadingWithFilters(Colors.orange);
    }
    
    if (snapshot.hasError) {
      return _buildErrorState(snapshot.error);
    }
    
    final allTransformaciones = snapshot.data ?? [];
    
    // Filtrar transformaciones del transformador
    final transformacionesTransformador = allTransformaciones.where((t) {
      return t.tipo == 'agrupacion_transformador';
    }).toList();
    
    // Filtrar por estado documentacion
    final transformacionesDocumentacion = transformacionesTransformador.where((t) {
      return (t.estado == 'documentacion' || t.estado == 'en_proceso') && 
             (_filtroMaterial == 'Todos' || _megaloteContieneMaterial(t, _filtroMaterial));
    }).toList();
    
    // Siempre mostrar la UI completa
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // Filtros sin presentación
        LoteFilterSection(
          selectedMaterial: _filtroMaterial,
          selectedTime: _filtroTiempo,
          selectedPresentacion: null,
          onMaterialChanged: (value) {
            setState(() {
              _filtroMaterial = value;
            });
          },
          onTimeChanged: (value) {
            setState(() {
              _filtroTiempo = value;
            });
          },
          onPresentacionChanged: null,
          tabColor: Colors.orange,
        ),
        
        // Estadísticas de megalotes
        LoteStatsSection(
          lotesCount: transformacionesDocumentacion.length,
          pesoTotal: transformacionesDocumentacion.fold(0.0, 
            (sum, t) => sum + (t.datos['peso_salida'] ?? t.pesoTotalEntrada)),
          tabColor: Colors.orange,
          showInTons: true,
          customLotesLabel: 'Megalotes en Documentación',
        ),
        
        // Lista de transformaciones o estado vacío
        if (transformacionesDocumentacion.isEmpty)
          _buildEmptyStateMegalotes()
        else
          ...transformacionesDocumentacion.map(
            (transformacion) => Padding(
              padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing16),
              child: _buildTransformacionCard(transformacion),
            ),
          ),
        
        SizedBox(height: UIConstants.qrSizeSmall),
      ],
    );
  }

  Widget _buildSalidaTabContent(AsyncSnapshot<List<LoteUnificadoModel>> snapshot) {
    // Manejo de estados
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildLoadingWithFilters(_getTabColor());
    }
    
    if (snapshot.hasError) {
      return _buildErrorState(snapshot.error);
    }
    
    final allLotes = snapshot.data ?? [];
    
    // Filtrar lotes consumidos
    final lotesNoConsumidos = allLotes.where((lote) {
      final estaConsumido = lote.datosGenerales.consumidoEnTransformacion == true;
      return !estaConsumido;
    }).toList();
    
    // Aplicar filtros y obtener solo lotes pendientes
    final lotesFiltrados = _aplicarFiltros(lotesNoConsumidos);
    final lotesPendientes = lotesFiltrados.where((lote) {
      final estado = _getEstadoLote(lote);
      return estado == 'pendiente';
    }).toList();
        
    return Column(
      children: [
        // Panel de selección múltiple
        if ((_isSelectionMode || _autoSelectionMode) && _selectedLotes.isNotEmpty)
          SelectionPanel(
            selectedLoteIds: _selectedLotes,
            allLotes: lotesPendientes,
            onCancel: () {
              setState(() {
                _isSelectionMode = false;
                _selectedLotes.clear();
              });
            },
            onProcess: _procesarLotesSeleccionados,
          ),
        // Contenido scrollable
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              // Filtros usando widget compartido - sin presentación pero con indicador
              LoteFilterSection(
                selectedMaterial: _filtroMaterial,
                selectedTime: _filtroTiempo,
                selectedPresentacion: null,  // Sin filtro de presentación
                onMaterialChanged: (value) {
                  setState(() {
                    _filtroMaterial = value;
                  });
                },
                onTimeChanged: (value) {
                  setState(() {
                    _filtroTiempo = value;
                  });
                },
                onPresentacionChanged: null,  // Sin callback para presentación
                tabColor: _getTabColor(),
                showSelectionIndicator: true,  // Mostrar indicador azul
                selectionIndicatorText: 'Selecciona múltiples lotes para procesarlos juntos como megalote',
              ),
              
              // Estadísticas
              LoteStatsSection(
                lotesCount: lotesPendientes.length,
                pesoTotal: lotesPendientes.fold(0.0, (sum, lote) => sum + lote.pesoActual),
                tabColor: _getTabColor(),
                showInTons: true,
              ),
              
              // Lista de lotes o estado vacío
              if (lotesPendientes.isEmpty)
                _buildEmptyState()
              else
                ...lotesPendientes.map((lote) => _buildLoteCard(lote)),
              
              SizedBox(height: UIConstants.qrSizeSmall), // Space for FAB
            ],
          ),
        ),
      ],
    );
  }






  Widget _buildLoteCard(LoteUnificadoModel lote) {
    final bool isSelected = _selectedLotes.contains(lote.id);
    final estado = _getEstadoLote(lote);
    final canSelect = _tabController.index == 0 && estado == 'pendiente' && !lote.estaConsumido;
    final bool esSublote = lote.esSublote;
    final bool showCheckbox = (_autoSelectionMode || _isSelectionMode) && canSelect;
    
    // Determinar color y texto del estado
    Color statusColor;
    String? statusText;  // Hacer nullable para poder omitir el texto
    IconData statusIcon;
    
    switch (estado) {
      case 'pendiente':
        statusColor = Colors.orange;
        statusText = null;  // No mostrar texto para pendiente
        statusIcon = Icons.pending;
        break;
      case 'documentacion':
        statusColor = BioWayColors.warning;
        statusText = 'Esperando documentación';
        statusIcon = Icons.description;
        break;
      case 'completado':
        statusColor = BioWayColors.success;
        statusText = 'Completado';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.blue;
        statusText = 'En proceso';
        statusIcon = Icons.autorenew;
    }
    
    // Información adicional - mostrar composición de materiales
    Widget? additionalInfo;
    
    // Primero, verificar si hay composición de materiales (viene de megalote)
    final composicionMateriales = lote.transformador?.especificaciones?['composicion_materiales'] as List?;
    
    if (composicionMateriales != null && composicionMateriales.isNotEmpty) {
      // Mostrar composición de materiales con porcentajes
      additionalInfo = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Composición del material:',
            style: TextStyle(
              fontSize: UIConstants.fontSizeXSmall,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: UIConstants.spacing4),
          ...composicionMateriales.map((material) {
            final tipo = material['tipo_material'] ?? 'Desconocido';
            final porcentaje = (material['porcentaje'] ?? 0.0).toDouble();
            return Padding(
              padding: EdgeInsets.only(bottom: UIConstants.spacing4 - 2),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getColorForMaterial(tipo),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: UIConstants.spacing4),
                  Expanded(
                    child: Text(
                      '$tipo: ${porcentaje.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeXSmall - 1,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      );
    }
    
    // Trailing widgets para acciones
    Widget? trailing;
    if (_tabController.index == 0 && !showCheckbox && !_isSelectionMode) {
      trailing = IconButton(
        icon: Icon(Icons.play_arrow, color: Colors.orange),
        onPressed: () => _procesarLote(lote),
        tooltip: 'Procesar lote',
      );
    } else if (_tabController.index == 1) {
      trailing = IconButton(
        icon: Icon(Icons.upload_file, color: BioWayColors.warning),
        onPressed: () => _cargarDocumentacion(lote),
        tooltip: 'Cargar documentación',
      );
    }
    
    // Crear widget personalizado para mostrar la merma en la fila principal
    Widget? customInfoRow;
    if (lote.transformador?.mermaTransformacion != null && 
        lote.transformador!.mermaTransformacion! > 0) {
      customInfoRow = Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildInfoItem(
              icon: Icons.category,
              label: 'Material',
              value: lote.datosGenerales.tipoMaterial,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _buildInfoItem(
              icon: Icons.scale,
              label: 'Peso',
              value: '${lote.pesoActual.toStringAsFixed(2)} kg',
              fontSize: 14,
              color: lote.tieneAnalisisLaboratorio ? Colors.blue : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _buildInfoItem(
              icon: Icons.trending_down,
              label: 'Merma',
              value: '${lote.transformador!.mermaTransformacion!.toStringAsFixed(2)} kg',
              fontSize: 14,
              color: BioWayColors.warning,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing16),
      child: _buildCustomLoteCard(
        lote: lote,
        isSelected: isSelected,
        canSelect: canSelect,
        showCheckbox: showCheckbox || _isSelectionMode,
        statusColor: statusColor,
        statusText: statusText,
        statusIcon: statusIcon,
        trailing: trailing,
        additionalInfo: additionalInfo,
        customInfoRow: customInfoRow,
        onTap: () {
          if ((_isSelectionMode || _autoSelectionMode) && canSelect) {
            _toggleLoteSelection(lote.id);
          } else if (!_isSelectionMode && _tabController.index == 0 && canSelect) {
            _procesarLote(lote);
          } else {
            _navigateToLoteDetail(lote);
          }
        },
        onLongPress: canSelect ? () => _startSelectionMode(lote.id) : null,
      ),
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    double fontSize = 14,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: UIConstants.iconSizeSmall, color: color ?? Colors.grey[600]),
        SizedBox(width: UIConstants.spacing8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: UIConstants.fontSizeXSmall + 1,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color color;
    String texto;
    IconData icon;
    
    switch (estado) {
      case 'pendiente':
        color = Colors.orange;
        texto = 'Pendiente';
        icon = Icons.pending;
        break;
      case 'documentacion':
        color = BioWayColors.warning;
        texto = 'Documentación';
        icon = Icons.description;
        break;
      case 'completado':
        color = BioWayColors.success;
        texto = 'Completado';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        texto = estado;
        icon = Icons.help_outline;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing8, vertical: UIConstants.spacing4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: UIConstants.opacityLow),
        borderRadius: BorderRadiusConstants.borderRadiusMedium,
        border: Border.all(color: color, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: UIConstants.spacing4 - 1),
          Text(
            texto,
            style: TextStyle(
              fontSize: UIConstants.fontSizeXSmall - 1,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (_tabController.index) {
      case 0:
        message = 'No hay lotes pendientes de procesar';
        icon = Icons.pending_actions;
        break;
      case 1:
        message = 'No hay lotes esperando documentación';
        icon = Icons.description_outlined;
        break;
      case 2:
        message = 'No hay lotes completados';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'No hay lotes';
        icon = Icons.inventory_2_outlined;
    }
    
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: UIConstants.spacing16),
          Text(
            message,
            style: TextStyle(
              fontSize: UIConstants.fontSizeBody,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateMegalotes() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.merge_type,
            size: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: UIConstants.spacing16),
          Text(
            'No hay megalotes disponibles',
            style: TextStyle(
              fontSize: UIConstants.fontSizeBody,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: UIConstants.spacing8),
          Text(
            'Los megalotes procesados aparecerán aquí',
            style: TextStyle(
              fontSize: UIConstants.fontSizeMedium,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }



  void _navigateToLoteDetail(LoteUnificadoModel lote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransformadorLoteDetalleScreen(
          firebaseId: lote.id,
          peso: lote.pesoActual,
          tiposAnalisis: (lote.transformador?.especificaciones?['tipos_analisis'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          productoFabricado: lote.transformador?.especificaciones?['producto_fabricado'] ?? 'Sin especificar',
          composicionMaterial: lote.transformador?.especificaciones?['composicion_material'] ?? 'Sin especificar',
          fechaCreacion: lote.datosGenerales.fechaCreacion,
          tipoPolimero: lote.datosGenerales.tipoMaterial,
        ),
      ),
    );
  }

  void _procesarLote(LoteUnificadoModel lote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransformadorFormularioSalida(
          loteId: lote.id,
          peso: lote.pesoActual,
          tipoPolimero: lote.datosGenerales.tipoMaterial,
        ),
      ),
    );
  }

  void _cargarDocumentacion(LoteUnificadoModel lote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransformadorDocumentacionScreen(
          loteId: lote.id,
          material: lote.datosGenerales.tipoMaterial,
          peso: lote.pesoActual,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh after successful documentation upload
        _loadLotes();
      }
    });
  }


  // Método para construir estado de carga con filtros visibles
  Widget _buildLoadingWithFilters(Color tabColor) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // Mantener filtros visibles
        LoteFilterSection(
          selectedMaterial: _filtroMaterial,
          selectedTime: _filtroTiempo,
          selectedPresentacion: null,
          onMaterialChanged: (value) {
            setState(() {
              _filtroMaterial = value;
            });
          },
          onTimeChanged: (value) {
            setState(() {
              _filtroTiempo = value;
            });
          },
          onPresentacionChanged: null,
          tabColor: tabColor,
        ),
        
        // Indicador de carga centrado
        SizedBox(height: UIConstants.qrSizeSmall),
        Center(
          child: CircularProgressIndicator(
            color: tabColor,
          ),
        ),
        SizedBox(height: UIConstants.qrSizeSmall),
      ],
    );
  }
  
  // Método para construir estado de error
  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: UIConstants.spacing16),
          Text(
            'Error al cargar datos',
            style: TextStyle(
              fontSize: UIConstants.fontSizeBody,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: UIConstants.spacing8),
          TextButton(
            onPressed: () {
              _loadLotes();
              _loadTransformaciones();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
  
  // Método helper para obtener color según el material
  Color _getColorForMaterial(String material) {
    final materialUpper = material.toUpperCase();
    
    // Remover prefijo EPF- si existe
    final materialSinPrefijo = materialUpper.startsWith('EPF-') 
        ? materialUpper.substring(4) 
        : materialUpper;
    
    switch (materialSinPrefijo) {
      case 'POLI':
      case 'POLIETILENO':
        return BioWayColors.pebdPink;
      case 'PP':
      case 'POLIPROPILENO':
        return BioWayColors.ppPurple;
      case 'MULTI':
      case 'MULTILAMINADO':
        return BioWayColors.multilaminadoBrown;
      default:
        return Colors.grey;
    }
  }
  
  // Método helper para verificar si un megalote contiene >50% del material seleccionado
  // Método para construir tarjeta de lote personalizada con merma en la fila principal
  Widget _buildCustomLoteCard({
    required LoteUnificadoModel lote,
    required bool isSelected,
    required bool canSelect,
    required bool showCheckbox,
    required Color statusColor,
    String? statusText,
    required IconData statusIcon,
    Widget? trailing,
    Widget? additionalInfo,
    Widget? customInfoRow,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final bool esSublote = lote.esSublote;
    
    // Para sublotes, usar diseño intermedio más equilibrado
    if (esSublote) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: isSelected 
            ? Border.all(color: BioWayColors.ecoceGreen, width: 2)
            : Border.all(color: Colors.purple.withValues(alpha: 0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con ID y estado
                Row(
                  children: [
                    // Checkbox si aplica
                    if (showCheckbox && canSelect) ...[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? BioWayColors.ecoceGreen
                            : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                              ? BioWayColors.ecoceGreen
                              : Colors.grey[300]!,
                            width: 1.8,
                          ),
                        ),
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) => onTap(),
                          activeColor: BioWayColors.ecoceGreen,
                          fillColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return Colors.transparent;
                          }),
                          checkColor: BioWayColors.ecoceGreen,
                        ),
                      ),
                      const SizedBox(width: 11),
                    ],
                    
                    // Icono de sublote
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.cut,
                        color: Colors.purple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    
                    // Info principal: ID y estado
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SUBLOTE: ${lote.id.substring(0, 8).toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (statusText != null)
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Trailing widget
                    if (trailing != null) trailing,
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Información de Material, Peso y Merma
                Row(
                  children: [
                    // Material
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.category, size: 15, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Material',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  lote.datosGenerales.tipoMaterial,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Peso
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.scale, size: 15, color: lote.tieneAnalisisLaboratorio ? Colors.blue : Colors.grey[600]),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Peso',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${lote.pesoActual.toStringAsFixed(2)} kg',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: lote.tieneAnalisisLaboratorio ? Colors.blue : Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Merma si existe
                    if (lote.transformador?.mermaTransformacion != null && 
                        lote.transformador!.mermaTransformacion! > 0)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.trending_down, size: 15, color: BioWayColors.warning),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Merma',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${lote.transformador!.mermaTransformacion!.toStringAsFixed(2)} kg',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: BioWayColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                // Información adicional si existe (composición)
                if (additionalInfo != null) ...[
                  const SizedBox(height: 10),
                  additionalInfo,
                ],
              ],
            ),
          ),
        ),
      );
    }
    
    // Para lotes normales, mantener diseño original
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected 
          ? Border.all(color: BioWayColors.ecoceGreen, width: 2)
          : null,
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
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Checkbox para selección múltiple
                  if (showCheckbox && canSelect) ...[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? BioWayColors.ecoceGreen
                          : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                            ? BioWayColors.ecoceGreen
                            : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => onTap(),
                        activeColor: BioWayColors.ecoceGreen,
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return Colors.transparent;
                        }),
                        checkColor: BioWayColors.ecoceGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  
                  // Status icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Info principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID: ${lote.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (statusText != null)
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Trailing widget
                  if (trailing != null) trailing,
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Información principal - usar customInfoRow si existe, sino usar el default
              if (customInfoRow != null)
                customInfoRow
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.category,
                        label: 'Material',
                        value: lote.datosGenerales.tipoMaterial,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.scale,
                        label: 'Peso',
                        value: '${lote.pesoActual.toStringAsFixed(2)} kg',
                        color: lote.tieneAnalisisLaboratorio ? Colors.blue : null,
                      ),
                    ),
                  ],
                ),
              
              // Información adicional personalizable
              if (additionalInfo != null) ...[
                const SizedBox(height: 12),
                additionalInfo,
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _megaloteContieneMaterial(TransformacionModel megalote, String material) {
    if (material == 'Todos') return true;
    
    // Si no hay lotes de entrada, mostrar el megalote por defecto
    if (megalote.lotesEntrada.isEmpty) {
      return true;
    }
    
    // Debug: Ver qué materiales tiene el megalote
    print('[Filter Debug] Megalote ${megalote.id.substring(0, 8)}: Materiales = ${megalote.lotesEntrada.map((l) => l.tipoMaterial).toList()}');
    print('[Filter Debug] Buscando material: "$material"');
    
    // Calcular porcentaje del material en el megalote
    final lotesDelMaterial = megalote.lotesEntrada.where((lote) {
      final materialLote = lote.tipoMaterial.trim();
      final materialBuscado = material.trim().toUpperCase();
      
      // Normalizar removiendo prefijo EPF- si existe (insensible a mayúsculas)
      String materialLoteNormalizado = materialLote.toUpperCase();
      if (materialLoteNormalizado.startsWith('EPF-')) {
        materialLoteNormalizado = materialLoteNormalizado.substring(4);
      }
      
      // Manejar diferentes variaciones de Multilaminado
      // El filtro ahora dice "Multilaminado" en lugar de "MULTI"
      if ((materialLoteNormalizado == 'MULTILAMINADO' || 
           materialLoteNormalizado == 'MULTI' ||
           materialLoteNormalizado.startsWith('MULTILAM')) && 
          materialBuscado == 'MULTILAMINADO') {
        return true;
      }
      
      // Manejar variaciones de POLI
      if ((materialLoteNormalizado == 'POLI' || 
           materialLoteNormalizado == 'POLIETILENO' ||
           materialLoteNormalizado.startsWith('POLI')) && 
          materialBuscado == 'POLI') {
        return true;
      }
      
      // Comparación directa para otros casos
      return materialLoteNormalizado == materialBuscado;
    }).toList();
    
    if (lotesDelMaterial.isEmpty) {
      return false;
    }
    
    // Calcular el peso total del material específico
    final pesoMaterial = lotesDelMaterial.fold<double>(
      0, (sum, lote) => sum + lote.peso
    );
    
    // Usar el peso total de entrada para el cálculo del porcentaje
    final pesoTotal = megalote.pesoTotalEntrada > 0 ? megalote.pesoTotalEntrada : 1;
    final porcentaje = (pesoMaterial / pesoTotal) * 100;
    
    // Mostrar si el material representa más del 50% de la composición
    return porcentaje > 50;
  }

}