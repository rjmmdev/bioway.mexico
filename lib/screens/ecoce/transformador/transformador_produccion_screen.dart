// Migración a estructura del Reciclador - Fase 1 - 2025-01-05
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../models/lotes/lote_unificado_model.dart';
import '../../../models/lotes/transformacion_model.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/transformacion_service.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
import '../shared/utils/material_utils.dart';
// Widgets compartidos del Reciclador
import '../shared/widgets/lote_filter_section.dart';
import '../shared/widgets/lote_stats_section.dart';
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
  
  // Datos en caché para mostrar inmediatamente
  List<LoteUnificadoModel> _lotesCache = [];
  List<TransformacionModel> _transformacionesCache = [];
  StreamSubscription<List<LoteUnificadoModel>>? _lotesSubscription;
  StreamSubscription<List<TransformacionModel>>? _transformacionesSubscription;
  
  // Estados
  bool _isSelectionMode = false;
  bool _autoSelectionMode = false; // Para el tab de Salida
  Set<String> _selectedLotes = {};
  
  // Filtros
  String _filtroMaterial = 'Todos';
  String _filtroTiempo = 'Todos';
  String _filtroPresentacion = 'Todas';
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
    print('[INIT] Inicializando streams en initState');
    _lotesStream = _loteUnificadoService.obtenerMisLotesPorProcesoActual('transformador');
    _transformacionesStream = _transformacionService.obtenerTransformacionesUsuario();
    
    // Escuchar el stream de lotes y actualizar el caché
    _lotesSubscription = _lotesStream.listen((lotes) {
      print('[CACHE UPDATE] Actualizando caché con ${lotes.length} lotes');
      if (mounted) {
        setState(() {
          _lotesCache = lotes;
        });
      }
    });
    
    // Escuchar el stream de transformaciones y actualizar el caché
    _transformacionesSubscription = _transformacionesStream.listen((transformaciones) {
      print('[CACHE UPDATE] Actualizando caché con ${transformaciones.length} transformaciones');
      if (mounted) {
        setState(() {
          _transformacionesCache = transformaciones;
        });
      }
    });
    
    print('[INIT] Streams inicializados');
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
      // Filtro por material - Manejar prefijo "EPF-"
      if (_filtroMaterial != 'Todos') {
        String materialLote = lote.datosGenerales.tipoMaterial;
        String materialBuscado = _filtroMaterial;
        
        // Comparación directa
        if (materialLote == materialBuscado) {
          // Match directo
        } else if (materialLote.toUpperCase().startsWith('EPF-')) {
          // Si el material tiene prefijo "EPF-", comparar sin él
          String materialSinPrefijo = materialLote.substring(4);
          if (materialSinPrefijo.toUpperCase() != materialBuscado.toUpperCase()) {
            return false;
          }
        } else if ('EPF-$materialLote'.toUpperCase() == 'EPF-$materialBuscado'.toUpperCase()) {
          // Si el material no tiene prefijo, probar agregándolo
        } else {
          return false;
        }
      }
      
      // Filtro por presentación
      if (_filtroPresentacion != 'Todas' && lote.datosGenerales.materialPresentacion != _filtroPresentacion) {
        return false;
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
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detalles del Megalote',
                    style: TextStyle(
                      fontSize: 20,
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('ID', transformacion.id),
                    _buildDetailSection('Estado', transformacion.estado),
                    _buildDetailSection('Fecha Inicio', FormatUtils.formatDateTime(transformacion.fechaInicio)),
                    if (transformacion.fechaFin != null)
                      _buildDetailSection('Fecha Fin', FormatUtils.formatDateTime(transformacion.fechaFin!)),
                    _buildDetailSection('Peso Entrada', '${transformacion.pesoTotalEntrada.toStringAsFixed(2)} kg'),
                    if (transformacion.datos['peso_salida'] != null)
                      _buildDetailSection('Peso Salida', '${transformacion.datos['peso_salida'].toStringAsFixed(2)} kg'),
                    _buildDetailSection('Merma', '${transformacion.mermaProceso.toStringAsFixed(2)} kg'),
                    if (transformacion.datos['producto_fabricado'] != null)
                      _buildDetailSection('Producto', transformacion.datos['producto_fabricado']),
                    if (transformacion.datos['cantidad_producto'] != null && transformacion.datos['cantidad_producto'] > 0)
                      _buildDetailSection('Cantidad', '${transformacion.datos['cantidad_producto']} unidades'),
                    const SizedBox(height: 20),
                    const Text(
                      'Lotes Procesados',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...transformacion.lotesEntrada.map((lote) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lote.loteId,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                          Text(
                            '${lote.tipoMaterial} - ${lote.peso.toStringAsFixed(2)} kg',
                            style: TextStyle(color: Colors.grey[600]),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
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
    _lotesSubscription?.cancel();
    _transformacionesSubscription?.cancel();
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
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Gestión de Producción',
            style: TextStyle(
              fontSize: 20,
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
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: const [
                  Tab(text: 'Salida'),
                  Tab(text: 'Documentación'),
                  Tab(text: 'Completados'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTabWithRefresh(
              child: _buildSalidaTabContent(),
            ),
            _buildTabWithRefresh(
              child: _buildDocumentacionTabContent(),
            ),
            _buildTabWithRefresh(
              child: _buildCompletadosTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletadosTabContent() {
    print('[COMPLETADOS TAB BUILD] Building completados tab with cache: ${_transformacionesCache.length} items');
    
    // Filtrar transformaciones completadas del caché
    final transformacionesCompletadas = _transformacionesCache.where((t) {
      return t.tipo == 'agrupacion_transformador' &&
             t.estado == 'completado' && 
             (_filtroMaterial == 'Todos' || _megaloteContieneMaterial(t, _filtroMaterial));
    }).toList();
    
    print('[COMPLETADOS FILTERED] Completadas count: ${transformacionesCompletadas.length}');
    
    // Siempre mostrar la UI completa inmediatamente
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
        
        // Contenido
        if (_transformacionesCache.isEmpty && transformacionesCompletadas.isEmpty)
          Container(
            height: 200,
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              color: BioWayColors.success,
            ),
          )
        else if (transformacionesCompletadas.isEmpty)
          _buildEmptyStateMegalotes()
        else
          ...transformacionesCompletadas.map(
            (transformacion) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTransformacionCard(transformacion),
            ),
          ),
        
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildDocumentacionTabContent() {
    print('[DOCUMENTACION TAB BUILD] Building documentacion tab with cache: ${_transformacionesCache.length} items');
    
    // Filtrar transformaciones del transformador del caché
    final transformacionesTransformador = _transformacionesCache.where((t) {
      return t.tipo == 'agrupacion_transformador';
    }).toList();
    
    // Filtrar por estado documentacion
    final transformacionesDocumentacion = transformacionesTransformador.where((t) {
      return (t.estado == 'documentacion' || t.estado == 'en_proceso') && 
             (_filtroMaterial == 'Todos' || _megaloteContieneMaterial(t, _filtroMaterial));
    }).toList();
    
    print('[DOCUMENTACION FILTERED] Documentacion count: ${transformacionesDocumentacion.length}');
    
    // Siempre mostrar la UI completa inmediatamente
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
        
        // Contenido basado en el estado
        if (_transformacionesCache.isEmpty && transformacionesDocumentacion.isEmpty)
          Container(
            height: 200,
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              color: Colors.orange,
            ),
          )
        else if (transformacionesDocumentacion.isEmpty)
          _buildEmptyStateMegalotes()
        else
          ...transformacionesDocumentacion.map(
            (transformacion) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTransformacionCard(transformacion),
            ),
          ),
        
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSalidaTabContent() {
    print('[SALIDA TAB BUILD] Building salida tab with cache: ${_lotesCache.length} items');
    
    // Filtrar lotes consumidos del caché
    final lotesNoConsumidos = _lotesCache.where((lote) {
      final estaConsumido = lote.datosGenerales.consumidoEnTransformacion ?? false;
      return !estaConsumido;
    }).toList();
    
    // Aplicar filtros y obtener solo lotes pendientes
    final lotesFiltrados = _aplicarFiltros(lotesNoConsumidos);
    final lotesPendientes = lotesFiltrados.where((lote) {
      final estado = _getEstadoLote(lote);
      return estado == 'pendiente';
    }).toList();
    
    print('[SALIDA FILTERED] Pendientes count: ${lotesPendientes.length}');
        
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
              // Filtros usando widget compartido
              LoteFilterSection(
                selectedMaterial: _filtroMaterial,
                selectedTime: _filtroTiempo,
                selectedPresentacion: _filtroPresentacion,
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
                onPresentacionChanged: (value) {
                  setState(() {
                    _filtroPresentacion = value;
                  });
                },
                tabColor: _getTabColor(),
                showSelectionIndicator: true,
                selectionIndicatorText: 'Selecciona múltiples lotes para procesarlos juntos como megalote',
              ),
              
              // Estadísticas
              LoteStatsSection(
                lotesCount: lotesPendientes.length,
                pesoTotal: lotesPendientes.fold(0.0, (sum, lote) => sum + lote.pesoActual),
                tabColor: _getTabColor(),
                showInTons: true,
              ),
              
              // Contenido basado en el estado
              if (_lotesCache.isEmpty && lotesPendientes.isEmpty)
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    color: _getTabColor(),
                  ),
                )
              else if (lotesPendientes.isEmpty)
                _buildEmptyState()
              else
                ...lotesPendientes.map((lote) => _buildLoteCard(lote)),
              
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ],
    );
  }






  Widget _buildLoteCard(LoteUnificadoModel lote) {
    final bool isSelected = _selectedLotes.contains(lote.id);
    final estado = _getEstadoLote(lote);
    final canSelect = _tabController.index == 0 && estado == 'pendiente';
    final bool esSublote = lote.esSublote;
    // Mostrar checkboxes por defecto en el tab de Salida
    final bool showCheckbox = _autoSelectionMode && canSelect;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: isSelected ? 3 : 1,
        shadowColor: isSelected ? Colors.orange.withValues(alpha: 0.25) : Colors.black12,
        child: InkWell(
          onTap: () {
            if ((showCheckbox || _isSelectionMode) && canSelect) {
              _toggleLoteSelection(lote.id);
            } else if (!_isSelectionMode && !showCheckbox) {
              _navigateToLoteDetail(lote);
            }
          },
          onLongPress: canSelect && !_autoSelectionMode
              ? () {
                  if (!_isSelectionMode) {
                    _toggleSelectionMode();
                    _toggleLoteSelection(lote.id);
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? Colors.orange 
                    : (esSublote 
                        ? Colors.purple.withValues(alpha: 0.3)
                        : Colors.transparent),
                width: isSelected ? 2 : (esSublote ? 1.5 : 0),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    if ((showCheckbox || _isSelectionMode) && canSelect) ...[
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleLoteSelection(lote.id),
                        activeColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Row(
                        children: [
                          if (esSublote) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.purple.withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cut,
                                    size: 10,
                                    color: Colors.purple,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'SUBLOTE',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              'Lote ${lote.id}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildEstadoChip(estado),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Material and weight info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: MaterialUtils.getMaterialColor(
                          lote.datosGenerales.tipoMaterial
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        lote.datosGenerales.tipoMaterial,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: MaterialUtils.getMaterialColor(
                            lote.datosGenerales.tipoMaterial
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.scale, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 3),
                    Text(
                      '${lote.pesoActual.toStringAsFixed(2)} kg',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 3),
                    Text(
                      FormatUtils.formatDate(lote.datosGenerales.fechaCreacion),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                // Action buttons for specific states (hide when checkboxes are shown)
                if (!showCheckbox && !_isSelectionMode && _tabController.index == 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: OutlinedButton.icon(
                            onPressed: () => _procesarLote(lote),
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text('Procesar', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _getTabColor(),
                              side: BorderSide(color: _getTabColor()),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                if (!_isSelectionMode && _tabController.index == 1) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: OutlinedButton.icon(
                            onPressed: () => _cargarDocumentacion(lote),
                            icon: const Icon(Icons.upload_file, size: 16),
                            label: const Text('Cargar Documentos', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BioWayColors.warning,
                              side: BorderSide(color: BioWayColors.warning),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            texto,
            style: TextStyle(
              fontSize: 10,
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
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
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
          const SizedBox(height: 16),
          Text(
            'No hay megalotes disponibles',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los megalotes procesados aparecerán aquí',
            style: TextStyle(
              fontSize: 14,
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


  List<TransformacionModel> _filterTransformacionesByState([
    List<TransformacionModel>? transformaciones,
    String? estado,
  ]) {
    final list = transformaciones ?? [];
    
    return list.where((t) {
      // Primero filtrar por estado
      bool passesStateFilter = false;
      if (estado != null) {
        passesStateFilter = t.estado == estado;
      } else if (_tabController.index == 1) {
        passesStateFilter = t.estado == 'documentacion' || t.estado == 'en_proceso';
      } else {
        passesStateFilter = t.estado == 'completado';
      }
      
      if (!passesStateFilter) return false;
      
      // Luego filtrar por material si no es "Todos"
      if (_filtroMaterial != 'Todos') {
        return _megaloteContieneMaterial(t, _filtroMaterial);
      }
      
      return true;
    }).toList();
  }
  
  // Método helper para verificar si un megalote contiene >50% del material seleccionado
  bool _megaloteContieneMaterial(TransformacionModel megalote, String material) {
    if (material == 'Todos') return true;
    
    // Calcular porcentaje del material en el megalote
    final lotesDelMaterial = megalote.lotesEntrada.where((lote) {
      final materialLote = lote.tipoMaterial.trim();
      final materialBuscado = material.trim();
      
      // Comparación directa
      if (materialLote == materialBuscado) {
        return true;
      }
      
      // Comparación case-insensitive
      if (materialLote.toUpperCase() == materialBuscado.toUpperCase()) {
        return true;
      }
      
      // Manejar el caso donde el material tiene prefijo "EPF-"
      String materialLoteSinPrefijo = materialLote;
      if (materialLote.toUpperCase().startsWith('EPF-')) {
        materialLoteSinPrefijo = materialLote.substring(4); // Remover "EPF-"
      }
      
      // Comparar sin prefijo
      if (materialLoteSinPrefijo.toUpperCase() == materialBuscado.toUpperCase()) {
        return true;
      }
      
      // También probar agregando el prefijo al material buscado
      final materialBuscadoConPrefijo = 'EPF-$materialBuscado';
      if (materialLote.toUpperCase() == materialBuscadoConPrefijo.toUpperCase()) {
        return true;
      }
      
      return false;
    }).toList();
    
    if (lotesDelMaterial.isEmpty) {
      return false;
    }
    
    final pesoMaterial = lotesDelMaterial.fold<double>(
      0, (sum, lote) => sum + lote.peso
    );
    
    final porcentaje = (pesoMaterial / megalote.pesoTotalEntrada) * 100;
    
    return porcentaje > 50; // Más del 50% del material
  }

}