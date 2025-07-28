import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/lotes/lote_transformador_model.dart';
import '../../../models/lotes/lote_unificado_model.dart';
import '../../../models/lotes/transformacion_model.dart';
import '../../../services/lote_service.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/transformacion_service.dart';
import '../../../services/user_session_service.dart';
import '../../../utils/colors.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/weight_input_widget.dart';
import '../../../utils/format_utils.dart';
import '../shared/utils/dialog_utils.dart';
import '../shared/utils/material_utils.dart';
import '../shared/utils/user_type_helper.dart';
import '../shared/screens/receptor_recepcion_pasos_screen.dart';
import 'transformador_escaneo_screen.dart';
import 'transformador_formulario_salida.dart';
import 'transformador_documentacion_screen.dart';
import 'transformador_lote_detalle_screen.dart';
import 'transformador_transformacion_documentacion.dart';
import 'utils/transformador_navigation_helper.dart';

class TransformadorProduccionScreen extends StatefulWidget {
  final int? initialTab;
  
  const TransformadorProduccionScreen({super.key, this.initialTab});

  @override
  State<TransformadorProduccionScreen> createState() => _TransformadorProduccionScreenState();
}

class _TransformadorProduccionScreenState extends State<TransformadorProduccionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LoteService _loteService = LoteService();
  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  final UserSessionService _userSession = UserSessionService();
  final TransformacionService _transformacionService = TransformacionService();

  // Listas de lotes
  List<LoteUnificadoModel> _lotesPendientes = [];
  List<LoteUnificadoModel> _lotesConDocumentacion = [];
  List<LoteUnificadoModel> _lotesCompletados = [];
  List<TransformacionModel> _transformaciones = [];
  
  // Estados
  bool _isLoading = true;
  bool _mostrarSoloMegalotes = false;
  bool _isSelectionMode = false;
  Set<String> _selectedLotes = {};
  
  // Filtros
  String _filtroMaterial = 'Todos';
  DateTime? _filtroFechaInicio;
  DateTime? _filtroFechaFin;
  
  // Estadísticas
  int _totalLotes = 0;
  double _pesoTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3, 
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );
    _tabController.addListener(() {
      setState(() {
        if (_tabController.indexIsChanging) {
          _isSelectionMode = false;
          _selectedLotes.clear();
        }
      });
    });
    _loadLotes();
    _loadTransformaciones();
  }

  Future<void> _loadLotes() async {
    try {
      final stream = _loteUnificadoService.obtenerLotesPorProceso('transformador');

      stream.listen((lotes) {
        if (mounted) {
          setState(() {
            // Aplicar filtros
            var lotesFiltrados = _aplicarFiltros(lotes);
            
            _lotesPendientes = lotesFiltrados.where((lote) {
              final estado = lote.transformador?.especificaciones?['estado'] ?? 'pendiente';
              return estado == 'pendiente';
            }).toList();

            _lotesConDocumentacion = lotesFiltrados.where((lote) {
              final estado = lote.transformador?.especificaciones?['estado'] ?? 'pendiente';
              return estado == 'documentacion';
            }).toList();

            _lotesCompletados = lotesFiltrados.where((lote) {
              final estado = lote.transformador?.especificaciones?['estado'] ?? 'pendiente';
              return estado == 'completado';
            }).toList();

            // Calcular estadísticas
            _calcularEstadisticas();
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error al cargar lotes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTransformaciones() async {
    try {
      // Get transformations of type 'agrupacion_transformador' only
      final userData = _userSession.getUserData();
      final userId = userData?['userId'] ?? userData?['uid'];
      if (userId == null) return;
      
      final stream = FirebaseFirestore.instance
          .collection('transformaciones')
          .where('tipo', isEqualTo: 'agrupacion_transformador')
          .where('usuario_id', isEqualTo: userId)
          .snapshots();
      
      stream.listen((snapshot) {
        if (mounted) {
          final transformaciones = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return TransformacionModel.fromMap(data, doc.id);
          }).toList();
          
          setState(() {
            _transformaciones = transformaciones;
          });
        }
      });
    } catch (e) {
      print('Error al cargar transformaciones: $e');
    }
  }

  List<LoteUnificadoModel> _aplicarFiltros(List<LoteUnificadoModel> lotes) {
    return lotes.where((lote) {
      // Filtro por material
      if (_filtroMaterial != 'Todos') {
        final material = lote.datosGenerales.tipoMaterial;
        if (!material.toLowerCase().contains(_filtroMaterial.toLowerCase())) {
          return false;
        }
      }
      
      // Filtro por fecha
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

  void _calcularEstadisticas() {
    _totalLotes = _lotesPendientes.length + _lotesConDocumentacion.length + _lotesCompletados.length;
    _pesoTotal = 0.0;
    
    for (var lote in [..._lotesPendientes, ..._lotesConDocumentacion, ..._lotesCompletados]) {
      _pesoTotal += lote.pesoActual;
    }
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

  void _selectAllLotes() {
    setState(() {
      List<LoteUnificadoModel> currentLotes;
      if (_tabController.index == 0) {
        currentLotes = _lotesPendientes;
      } else if (_tabController.index == 1) {
        currentLotes = _lotesConDocumentacion;
      } else {
        currentLotes = _lotesCompletados;
      }
      
      if (_selectedLotes.length == currentLotes.length) {
        _selectedLotes.clear();
      } else {
        _selectedLotes = currentLotes.map((lote) => lote.id).toSet();
      }
    });
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
    final estado = transformacion.datos['estado'] ?? 'en_proceso';
    final bool hasDocumentation = transformacion.tieneDocumentacion;
    final productoFabricado = transformacion.datos['producto_fabricado'] ?? 'Sin especificar';
    final cantidadProducto = transformacion.datos['cantidad_producto'] ?? 0.0;
    final tipoPolimero = transformacion.datos['tipo_polimero'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // View megalote details
          },
          borderRadius: BorderRadius.circular(16),
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
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange,
                            Colors.orange.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.merge_type,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MEGALOTE ${transformacion.id.substring(0, 8)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          Text(
                            FormatUtils.formatDateTime(transformacion.fechaInicio),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildTransformacionEstadoChip(estado),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Product info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.factory, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              productoFabricado,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: MaterialUtils.getMaterialColor(tipoPolimero).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tipoPolimero,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: MaterialUtils.getMaterialColor(tipoPolimero),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${cantidadProducto.toStringAsFixed(2)} kg',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Stats row
                Row(
                  children: [
                    Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${transformacion.lotesEntrada.length} lotes procesados',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (estado == 'completado') ...[
                      const SizedBox(width: 16),
                      Icon(Icons.check_circle, size: 16, color: BioWayColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Completado',
                        style: TextStyle(
                          fontSize: 13,
                          color: BioWayColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action button
                if (estado == 'documentacion') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _uploadDocumentacion(transformacion),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Cargar Documentación'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _createSublote(TransformacionModel transformacion) async {
    final TextEditingController pesoController = TextEditingController();
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.cut,
                      color: Colors.orange,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Crear Sublote',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.scale, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Peso disponible: ${transformacion.pesoDisponible.toStringAsFixed(2)} kg',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                WeightInputWidget(
                  controller: pesoController,
                  label: 'Peso del sublote (kg)',
                  primaryColor: Colors.orange,
                  quickAddValues: const [10, 25, 50, 100],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese el peso';
                    }
                    final peso = double.tryParse(value);
                    if (peso == null || peso <= 0) {
                      return 'Peso inválido';
                    }
                    if (peso > transformacion.pesoDisponible) {
                      return 'Peso excede el disponible';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    StatefulBuilder(
                      builder: (context, setState) {
                        bool isLoading = false;
                        
                        return ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final peso = double.tryParse(pesoController.text);
                                  if (peso == null || peso <= 0 || peso > transformacion.pesoDisponible) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Por favor ingrese un peso válido'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  
                                  setState(() => isLoading = true);
                                  
                                  try {
                                    await _transformacionService.crearSublote(
                                      transformacionId: transformacion.id,
                                      peso: peso,
                                    );
                                    
                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Sublote creado exitosamente'),
                                          backgroundColor: BioWayColors.success,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setState(() => isLoading = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Crear'),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _uploadDocumentacion(TransformacionModel transformacion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransformadorTransformacionDocumentacion(
          transformacionId: transformacion.id,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Navigate to completed tab after successful documentation
        setState(() {
          _tabController.animateTo(2);
        });
      }
    });
  }

  // Obtener color según el tab actual para indicar urgencia
  Color _getTabColor() {
    switch (_tabController.index) {
      case 0: // Salida - Urgente
        return BioWayColors.error;
      case 1: // Documentación - Medio
        return BioWayColors.warning;
      case 2: // Completados - Bajo
        return BioWayColors.success;
      default:
        return Colors.orange;
    }
  }

  void _onBottomNavTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == 1) return; // Ya estamos en producción
    
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/transformador_inicio');
        break;
      case 2:
        Navigator.pushNamed(context, '/transformador_ayuda');
        break;
      case 3:
        Navigator.pushNamed(context, '/transformador_perfil');
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.orange,
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        Navigator.pushReplacementNamed(context, '/transformador_inicio');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: _isSelectionMode
              ? Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black87),
                      onPressed: _toggleSelectionMode,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedLotes.length} seleccionados',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Gestión de Producción',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          actions: _isSelectionMode
              ? [
                  TextButton(
                    onPressed: _selectAllLotes,
                    child: Text(
                      _selectedLotes.length == _getCurrentTabLotes().length
                          ? 'Deseleccionar'
                          : 'Seleccionar todo',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.checklist, color: Colors.grey),
                    onPressed: _toggleSelectionMode,
                  ),
                ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: _getTabColor(),
                indicatorWeight: 3,
                labelColor: _getTabColor(),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Salida',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: _lotesPendientes.isNotEmpty
                                ? BioWayColors.error.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_lotesPendientes.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _lotesPendientes.isNotEmpty
                                  ? BioWayColors.error
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Docs',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: _lotesConDocumentacion.isNotEmpty
                                ? BioWayColors.warning.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_lotesConDocumentacion.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _lotesConDocumentacion.isNotEmpty
                                  ? BioWayColors.warning
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Completos',
                            style: TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: _lotesCompletados.isNotEmpty
                                ? BioWayColors.success.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_lotesCompletados.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _lotesCompletados.isNotEmpty
                                  ? BioWayColors.success
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTabContent(_lotesPendientes),
            _buildTabContent(_lotesConDocumentacion),
            _buildCompletadosTab(),
          ],
        ),
        bottomNavigationBar: _isSelectionMode
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Peso total',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${_calcularPesoSeleccionado().toStringAsFixed(2)} kg',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _selectedLotes.isNotEmpty
                          ? _procesarLotesSeleccionados
                          : null,
                      icon: const Icon(Icons.merge_type),
                      label: Text(
                        _selectedLotes.length > 1
                            ? 'Procesar ${_selectedLotes.length} lotes'
                            : 'Procesar lote',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : EcoceBottomNavigation(
                selectedIndex: 1, // Producción está en índice 1
                onItemTapped: _onBottomNavTapped,
                primaryColor: Colors.orange,
                items: EcoceNavigationConfigs.transformadorItems,
                fabConfig: UserTypeHelper.getFabConfig('T', context),
              ),
      floatingActionButton: EcoceFloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          // Usar el flujo de recepción por pasos igual que el reciclador
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReceptorRecepcionPasosScreen(
                userType: 'transformador',
              ),
            ),
          );
        },
        icon: Icons.add,
        backgroundColor: Colors.orange,
        tooltip: 'Recibir Lote',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildTabContent(List<LoteUnificadoModel> lotes) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // Filters container
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Show megalotes toggle for documentation tab
              if (_tabController.index == 1) ...[
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _mostrarSoloMegalotes = !_mostrarSoloMegalotes;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _mostrarSoloMegalotes
                                ? Colors.orange.withValues(alpha: 0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _mostrarSoloMegalotes
                                  ? Colors.orange
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _mostrarSoloMegalotes
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: _mostrarSoloMegalotes
                                    ? Colors.orange
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mostrar Megalotes',
                                style: TextStyle(
                                  color: _mostrarSoloMegalotes
                                      ? Colors.orange
                                      : Colors.grey[700],
                                  fontWeight: _mostrarSoloMegalotes
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.merge_type,
                                color: _mostrarSoloMegalotes
                                    ? Colors.orange
                                    : Colors.grey,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              if (!_mostrarSoloMegalotes || _tabController.index != 1) ...[
                // Material filter chips for individual lots
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'Todos',
                        isSelected: _filtroMaterial == 'Todos',
                        onSelected: (selected) {
                          setState(() {
                            _filtroMaterial = 'Todos';
                          });
                          _loadLotes();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'PEBD',
                        isSelected: _filtroMaterial == 'PEBD',
                        onSelected: (selected) {
                          setState(() {
                            _filtroMaterial = selected ? 'PEBD' : 'Todos';
                          });
                          _loadLotes();
                        },
                        color: BioWayColors.pebdPink,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'PP',
                        isSelected: _filtroMaterial == 'PP',
                        onSelected: (selected) {
                          setState(() {
                            _filtroMaterial = selected ? 'PP' : 'Todos';
                          });
                          _loadLotes();
                        },
                        color: BioWayColors.ppPurple,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Multilaminado',
                        isSelected: _filtroMaterial == 'Multilaminado',
                        onSelected: (selected) {
                          setState(() {
                            _filtroMaterial = selected ? 'Multilaminado' : 'Todos';
                          });
                          _loadLotes();
                        },
                        color: BioWayColors.multilaminadoBrown,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Statistics container
        if (_tabController.index == 1 && _mostrarSoloMegalotes)
          _buildMegaloteStatistics()
        else
          _buildStatistics(),
        
        // List items
        if (_tabController.index == 1 && _mostrarSoloMegalotes) ...[
          // Show megalotes with estado 'documentacion'
          if (_filterTransformacionesByState().isEmpty)
            _buildEmptyStateMegalotes()
          else
            ..._filterTransformacionesByState().map(
              (transformacion) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTransformacionCard(transformacion),
              ),
            ),
        ] else ...[
          // Show individual lots
          if (lotes.isEmpty)
            _buildEmptyState()
          else
            ...lotes.map((lote) => _buildLoteCard(lote)),
        ],
        
        const SizedBox(height: 100), // Space for FAB
      ],
    );
  }

  Widget _buildCompletadosTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // Filters container with megalote toggle
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Toggle for megalotes
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _mostrarSoloMegalotes = !_mostrarSoloMegalotes;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _mostrarSoloMegalotes
                              ? _getTabColor().withValues(alpha: 0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _mostrarSoloMegalotes
                                ? _getTabColor()
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _mostrarSoloMegalotes
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: _mostrarSoloMegalotes
                                  ? _getTabColor()
                                  : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Mostrar solo Megalotes',
                              style: TextStyle(
                                color: _mostrarSoloMegalotes
                                    ? _getTabColor()
                                    : Colors.grey[700],
                                fontWeight: _mostrarSoloMegalotes
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.merge_type,
                              color: _mostrarSoloMegalotes
                                  ? _getTabColor()
                                  : Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              if (!_mostrarSoloMegalotes) ...[
                const SizedBox(height: 12),
                // Material filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'Todos',
                        isSelected: _filtroMaterial == 'Todos',
                        onSelected: (selected) {
                          setState(() {
                            _filtroMaterial = 'Todos';
                          });
                          _loadLotes();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'PEBD',
                        isSelected: _filtroMaterial == 'PEBD',
                        onSelected: (selected) {
                          setState(() {
                            _filtroMaterial = selected ? 'PEBD' : 'Todos';
                          });
                          _loadLotes();
                        },
                        color: BioWayColors.pebdPink,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'PP',
                        isSelected: _filtroMaterial == 'PP',
                        onSelected: (selected) {
                          setState(() {
                            _filtroMaterial = selected ? 'PP' : 'Todos';
                          });
                          _loadLotes();
                        },
                        color: BioWayColors.ppPurple,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Multilaminado',
                        isSelected: _filtroMaterial == 'Multilaminado',
                        onSelected: (selected) {
                          setState(() {
                            _filtroMaterial = selected ? 'Multilaminado' : 'Todos';
                          });
                          _loadLotes();
                        },
                        color: BioWayColors.multilaminadoBrown,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Statistics container
        if (_mostrarSoloMegalotes)
          _buildMegaloteStatistics()
        else
          _buildStatistics(),
        
        // List items for completed tab - show megalotes
        if (_tabController.index == 2) ...[
          // Toggle between individual lots and megalotes
          if (_mostrarSoloMegalotes) ...[
          if (_transformaciones.isEmpty)
            _buildEmptyStateMegalotes()
          else
            ..._filterTransformacionesByState().map(
              (transformacion) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTransformacionCard(transformacion),
              ),
            ),
          ] else ...[
            if (_lotesCompletados.isEmpty)
              _buildEmptyState()
            else
              ..._lotesCompletados.map((lote) => _buildLoteCard(lote)),
          ],
        ] else ...[
          // For tabs 0 and 1, only show individual lots
          if (_lotesCompletados.isEmpty)
            _buildEmptyState()
          else
            ..._lotesCompletados.map((lote) => _buildLoteCard(lote)),
        ],
        
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: (color ?? Colors.orange).withValues(alpha: 0.2),
      checkmarkColor: color ?? Colors.orange,
      labelStyle: TextStyle(
        color: isSelected ? (color ?? Colors.orange) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? (color ?? Colors.orange) : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildStatistics() {
    final estadisticas = _calcularEstadisticasTab();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.inventory_2,
                  value: estadisticas['total'].toString(),
                  label: 'Lotes',
                  color: _getTabColor(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.scale,
                  value: '${(estadisticas['peso'] / 1000).toStringAsFixed(1)}',
                  label: 'Toneladas',
                  color: _getTabColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildStatCard(
            icon: Icons.factory,
            value: estadisticas['producto'],
            label: 'Producto más fabricado',
            color: _getTabColor(),
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMegaloteStatistics() {
    final transformacionesVisibles = _transformaciones.where((t) => !t.debeSerEliminada).toList();
    final totalMegalotes = transformacionesVisibles.length;
    final pesoDisponible = transformacionesVisibles.fold(0.0, (sum, t) => sum + t.pesoDisponible);
    final totalSublotes = transformacionesVisibles.fold(0, (sum, t) => sum + t.sublotesGenerados.length);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.merge_type,
                  value: totalMegalotes.toString(),
                  label: 'Megalotes',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.cut,
                  value: totalSublotes.toString(),
                  label: 'Sublotes',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildStatCard(
            icon: Icons.scale,
            value: '${pesoDisponible.toStringAsFixed(2)} kg',
            label: 'Peso disponible total',
            color: BioWayColors.success,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoteCard(LoteUnificadoModel lote) {
    final bool isSelected = _selectedLotes.contains(lote.id);
    final estado = lote.transformador?.especificaciones?['estado'] ?? 'pendiente';
    final canSelect = _tabController.index == 0 && estado == 'pendiente';
    final bool esSublote = lote.esSublote;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: isSelected ? 4 : 1,
        shadowColor: isSelected ? Colors.orange.withValues(alpha: 0.3) : Colors.black12,
        child: InkWell(
          onTap: () {
            if (_isSelectionMode && canSelect) {
              _toggleLoteSelection(lote.id);
            } else if (!_isSelectionMode) {
              _navigateToLoteDetail(lote);
            }
          },
          onLongPress: canSelect
              ? () {
                  if (!_isSelectionMode) {
                    _toggleSelectionMode();
                    _toggleLoteSelection(lote.id);
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? Colors.orange 
                    : (esSublote 
                        ? Colors.purple.withValues(alpha: 0.3)
                        : Colors.transparent),
                width: isSelected ? 2 : (esSublote ? 1.5 : 0),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    if (_isSelectionMode && canSelect) ...[
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
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.purple.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cut,
                                    size: 14,
                                    color: Colors.purple,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'SUBLOTE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              'Lote ${lote.id}',
                              style: const TextStyle(
                                fontSize: 16,
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
                const SizedBox(height: 12),
                
                // Material and weight info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: MaterialUtils.getMaterialColor(
                          lote.datosGenerales.tipoMaterial
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        lote.datosGenerales.tipoMaterial,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MaterialUtils.getMaterialColor(
                            lote.datosGenerales.tipoMaterial
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${lote.pesoActual.toStringAsFixed(2)} kg',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      FormatUtils.formatDate(lote.datosGenerales.fechaCreacion),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                // Action buttons for specific states
                if (!_isSelectionMode && _tabController.index == 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _procesarLote(lote),
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Procesar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _getTabColor(),
                            side: BorderSide(color: _getTabColor()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                if (!_isSelectionMode && _tabController.index == 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cargarDocumentacion(lote),
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Cargar Documentos'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BioWayColors.warning,
                            side: BorderSide(color: BioWayColors.warning),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
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

  // Helper methods
  List<LoteUnificadoModel> _getCurrentTabLotes() {
    switch (_tabController.index) {
      case 0:
        return _lotesPendientes;
      case 1:
        return _lotesConDocumentacion;
      case 2:
        return _lotesCompletados;
      default:
        return [];
    }
  }

  double _calcularPesoSeleccionado() {
    double peso = 0.0;
    final lotes = _getCurrentTabLotes();
    for (final lote in lotes) {
      if (_selectedLotes.contains(lote.id)) {
        peso += lote.pesoActual;
      }
    }
    return peso;
  }

  Map<String, dynamic> _calcularEstadisticasTab() {
    final lotes = _getCurrentTabLotes();
    final total = lotes.length;
    final peso = lotes.fold(0.0, (sum, lote) => sum + lote.pesoActual);
    
    // Calculate most produced product
    String producto = 'N/A';
    if (lotes.isNotEmpty) {
      final Map<String, int> productos = {};
      for (final lote in lotes) {
        final prod = lote.transformador?.especificaciones?['producto_fabricado'] ?? 'Sin especificar';
        productos[prod] = (productos[prod] ?? 0) + 1;
      }
      
      var maxCount = 0;
      productos.forEach((key, value) {
        if (value > maxCount) {
          maxCount = value;
          producto = key;
        }
      });
    }
    
    return {
      'total': total,
      'peso': peso,
      'producto': producto,
    };
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

  Widget _buildTransformacionEstadoChip(String estado) {
    Color color;
    String texto;
    IconData icon;
    
    switch (estado) {
      case 'en_proceso':
        color = Colors.blue;
        texto = 'En Proceso';
        icon = Icons.pending;
        break;
      case 'documentacion':
        color = Colors.orange;
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<TransformacionModel> _filterTransformacionesByState() {
    final estado = _tabController.index == 1 ? 'documentacion' : 'completado';
    return _transformaciones.where((t) {
      return t.estado == estado;
    }).toList();
  }

}