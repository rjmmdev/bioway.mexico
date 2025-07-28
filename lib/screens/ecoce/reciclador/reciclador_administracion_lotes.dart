import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/transformacion_service.dart';
import '../../../models/lotes/lote_unificado_model.dart';
import '../../../models/lotes/transformacion_model.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/dialog_utils.dart';
import '../shared/widgets/weight_input_widget.dart';
import 'reciclador_lote_qr_screen.dart';
import 'reciclador_documentacion.dart';
import 'reciclador_transformacion_documentacion.dart';
import 'reciclador_formulario_salida.dart';
import '../shared/screens/receptor_recepcion_pasos_screen.dart';

/// Pantalla de administración de lotes del reciclador usando el sistema unificado
class RecicladorAdministracionLotes extends StatefulWidget {
  final int initialTab;
  
  const RecicladorAdministracionLotes({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<RecicladorAdministracionLotes> createState() => _RecicladorAdministracionLotesState();
}

class _RecicladorAdministracionLotesState extends State<RecicladorAdministracionLotes>
    with SingleTickerProviderStateMixin {
  // Controladores
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Servicios
  final LoteUnificadoService _loteService = LoteUnificadoService();
  final TransformacionService _transformacionService = TransformacionService();
  
  // Estados
  Stream<List<LoteUnificadoModel>>? _lotesStream;
  Stream<List<TransformacionModel>>? _transformacionesStream;
  String _selectedMaterial = 'Todos';
  String _selectedTime = 'Todos';
  final String _selectedDocFilter = 'Todos'; // Nuevo filtro para documentación
  String _selectedPresentacion = 'Todos'; // Filtro de presentación
  bool _showOnlyMegalotes = false; // Filtro para mostrar solo megalotes
  int _selectedIndex = 1; // Bottom nav index
  
  // Estados para selección múltiple
  bool _isSelectionMode = false;
  final Set<String> _selectedLoteIds = {};
  
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, // Reducido de 3 a 2 pestañas
      vsync: this,
      initialIndex: widget.initialTab > 1 ? 1 : widget.initialTab,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != _tabController.previousIndex) {
        setState(() {
          // Limpiar búsqueda al cambiar de pestaña
          _searchController.clear();
          // Salir del modo de selección al cambiar de pestaña
          _isSelectionMode = false;
          _selectedLoteIds.clear();
        });
      }
    });
    _loadLotes();
  }
  
  void _loadLotes() {
    setState(() {
      _lotesStream = _loteService.obtenerLotesRecicladorConPendientes();
      _transformacionesStream = _transformacionService.obtenerTransformacionesUsuario();
    });
  }
  
  void _filterLotes() {
    setState(() {
      // Por ahora recargar todos y filtrar localmente
      // TODO: Implementar filtros en el servicio si es necesario para optimización
      _loadLotes();
    });
  }
  
  List<LoteUnificadoModel> _filterByTab(List<LoteUnificadoModel> lotes) {
    // Primero aplicar filtros generales
    var filteredLotes = lotes.where((lote) {
      // Filtro por material
      if (_selectedMaterial != 'Todos' && lote.datosGenerales.tipoMaterial != _selectedMaterial) {
        return false;
      }
      
      // Filtro por presentación
      if (_selectedPresentacion != 'Todos' && lote.datosGenerales.materialPresentacion != _selectedPresentacion) {
        return false;
      }
      
      // Filtro por tiempo
      if (_selectedTime != 'Todos' && lote.reciclador != null) {
        final now = DateTime.now();
        final fechaEntrada = lote.reciclador!.fechaEntrada;
        
        switch (_selectedTime) {
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
      
      return true;
    }).toList();
    
    // Luego aplicar filtros específicos de la pestaña
    switch (_tabController.index) {
      case 0: // Salida
        return filteredLotes.where((lote) {
          final reciclador = lote.reciclador;
          // Verificar si es un sublote
          final bool esSublote = lote.datosGenerales.tipoLote == 'derivado' || 
                                lote.datosGenerales.qrCode.startsWith('SUBLOTE-');
          
          // Solo mostrar lotes que:
          // 1. NO sean sublotes (los sublotes ya pasaron por el proceso de salida)
          // 2. Estén en proceso reciclador
          // 3. No tengan fecha de salida
          // 4. NO estén consumidos en una transformación
          return !esSublote &&
                 lote.datosGenerales.procesoActual == 'reciclador' &&
                 reciclador != null && 
                 reciclador.fechaSalida == null &&
                 !lote.estaConsumido; // Excluir lotes consumidos
        }).toList();
        
      case 1: // Completados
        var completados = filteredLotes.where((lote) {
          // En la pestaña Completados SOLO mostrar sublotes que no han sido tomados por transportista
          // Los megalotes se muestran a través del stream de transformaciones
          return lote.esSublote && lote.datosGenerales.procesoActual == 'reciclador';
        }).toList();
        
        // Aplicar filtro de documentación si está activo
        if (_selectedDocFilter == 'Pendientes') {
          completados = completados.where((lote) {
            // Por ahora, consideramos que todos los lotes transferidos necesitan documentación
            // Esta lógica se puede refinar cuando se tenga acceso a los campos de documentación
            return lote.datosGenerales.procesoActual != 'reciclador';
          }).toList();
        }
        
        return completados;
        
      default:
        return [];
    }
  }
  
  
  Color _getTabColor() {
    switch (_tabController.index) {
      case 0:
        return BioWayColors.error; // Rojo para Salida
      case 1:
        return BioWayColors.success; // Verde para Completados
      default:
        return BioWayColors.ecoceGreen;
    }
  }
  
  
  void _showLoteDetails(LoteUnificadoModel lote) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LoteDetailsSheet(lote: lote),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _isSelectionMode ? BioWayColors.ecoceGreen : BioWayColors.primaryGreen,
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _cancelSelectionMode,
              )
            : null,
        title: Text(
          _isSelectionMode 
              ? '${_selectedLoteIds.length} lotes seleccionados'
              : 'Administración de Lotes',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: _isSelectionMode
            ? [
                TextButton.icon(
                  onPressed: _selectedLoteIds.isNotEmpty ? _processSelectedLotes : null,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    'Procesar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ]
            : null,
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
                Tab(text: 'Completados'),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<LoteUnificadoModel>>(
        stream: _lotesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
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
                    'Error al cargar lotes',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadLotes,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          
          final allLotes = snapshot.data ?? [];
          final filteredLotes = _filterByTab(allLotes);
          
          // SIEMPRE retornar la misma estructura para mantener la navegación funcionando
          return Column(
            children: [
              // Panel de selección múltiple
              if (_isSelectionMode && _tabController.index == 0)
                _buildSelectionPanel(filteredLotes),
              // Contenido con TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const PageScrollPhysics(), // Asegurar que el deslizamiento funcione
                  children: [
                    _buildTabWithRefresh(
                      child: _buildTabContent(filteredLotes), // Pestaña 0: Salida
                    ),
                    _buildTabWithRefresh(
                      child: _buildCompletadosTab(filteredLotes), // Pestaña 1: Completados
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedIndex = index;
          });
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/reciclador_inicio');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/reciclador_ayuda');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/reciclador_perfil');
              break;
          }
        },
        items: EcoceNavigationConfigs.recicladorItems,
        primaryColor: BioWayColors.ecoceGreen,
        fabConfig: FabConfig(
          icon: Icons.add,
          onPressed: _navigateToScanner,
          tooltip: 'Recibir lote',
        ),
      ),
      floatingActionButton: _tabController.index == 0 && _isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: _selectedLoteIds.isNotEmpty ? _processSelectedLotes : null,
              backgroundColor: _selectedLoteIds.isNotEmpty 
                  ? BioWayColors.ecoceGreen 
                  : Colors.grey,
              icon: Icon(
                Icons.merge_type, 
                color: _selectedLoteIds.isNotEmpty ? Colors.white : Colors.white70,
              ),
              label: Text(
                _selectedLoteIds.isEmpty 
                    ? 'Selecciona lotes para procesar'
                    : 'Procesar ${_selectedLoteIds.length} ${_selectedLoteIds.length == 1 ? "lote" : "lotes"}',
                style: TextStyle(
                  color: _selectedLoteIds.isNotEmpty ? Colors.white : Colors.white70,
                ),
              ),
            )
          : EcoceFloatingActionButton(
              onPressed: _navigateToScanner,
              icon: Icons.add,
              backgroundColor: BioWayColors.ecoceGreen,
              tooltip: 'Recibir lote',
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
  
  Widget _buildTabContent(List<LoteUnificadoModel> lotes) {
    final pesoTotal = _calcularPesoTotal(lotes);
    final tabColor = _getTabColor();
    
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
              // Filtros horizontales
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Indicador de selección múltiple (solo en pestaña Salida)
                    if (_tabController.index == 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: BioWayColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: BioWayColors.info.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: BioWayColors.info,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Selecciona múltiples lotes para procesarlos juntos como megalote',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: BioWayColors.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Filtro de materiales
                    SizedBox(
                      height: 40,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: ['Todos', 'PEBD', 'PP', 'Multilaminado'].map((material) {
                          final isSelected = _selectedMaterial == material;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(material),
                              selected: isSelected,
                              selectedColor: tabColor.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: isSelected ? tabColor : Colors.grey[700],
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedMaterial = material;
                                  _filterLotes();
                                });
                              },
                            ),
                          );
                        }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Filtros de tiempo y presentación
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownFilter(
                            label: 'Tiempo',
                            value: _selectedTime,
                            items: ['Todos', 'Hoy', 'Esta semana', 'Este mes'],
                            onChanged: (value) {
                              setState(() {
                                _selectedTime = value!;
                                _filterLotes();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdownFilter(
                            label: 'Presentación',
                            value: _selectedPresentacion,
                            items: ['Todos', 'Pacas', 'Costales', 'Separados'],
                            onChanged: (value) {
                              setState(() {
                                _selectedPresentacion = value!;
                                _filterLotes();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Tarjetas de estadísticas (más compactas)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Número de lotes
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
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
                                    color: tabColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.inventory_2, color: tabColor, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        lotes.length.toString(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        'Lotes',
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
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Peso total
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
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
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.scale, color: Colors.orange, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${pesoTotal.toStringAsFixed(1)} kg',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        'Peso Total',
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
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Lista de lotes o mensaje vacío
              if (lotes.isEmpty) ...[
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 60,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay lotes en esta categoría',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ...lotes.map((lote) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildLoteCard(lote),
                )),
              ],
              const SizedBox(height: 80), // Espacio adicional al final
            ],
          );
  }
  
  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: BioWayColors.backgroundGrey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: BioWayColors.darkGreen),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  color: BioWayColors.darkGreen,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLoteCard(LoteUnificadoModel lote) {
    final reciclador = lote.reciclador!;
    final isTransferred = lote.datosGenerales.procesoActual != 'reciclador';
    // Verificaremos el estado de documentación de forma asíncrona
    final isCompleted = reciclador.fechaSalida != null;
    
    // Verificar si es un sublote
    final bool esSublote = lote.datosGenerales.tipoLote == 'derivado' || 
                          lote.datosGenerales.qrCode.startsWith('SUBLOTE-');
    
    // Solo permitir selección en la pestaña de Salida y si el lote no está completado
    final canBeSelected = _tabController.index == 0 && !isCompleted && !isTransferred && !lote.estaConsumido;
    
    return FutureBuilder<bool>(
      future: _checkHasDocumentation(lote.id),
      builder: (context, snapshot) {
        final hasAllDocs = snapshot.data ?? false;
        
        Color statusColor;
        String statusText;
        IconData statusIcon;
        
        if (isTransferred) {
          if (hasAllDocs) {
            // Este caso no debería mostrarse según la lógica, pero por si acaso
            statusColor = Colors.grey;
            statusText = 'Transferido';
            statusIcon = Icons.done_all;
          } else {
            statusColor = Colors.orange;
            statusText = 'Transferido - Documentación pendiente';
            statusIcon = Icons.upload_file;
          }
        } else if (isCompleted) {
          if (hasAllDocs) {
            statusColor = Colors.green;
            statusText = 'Listo para transferir';
            statusIcon = Icons.check_circle;
          } else {
            statusColor = Colors.blue;
            statusText = 'Completado - Falta documentación';
            statusIcon = Icons.description;
          }
        } else {
          statusColor = Colors.blue;
          statusText = 'En proceso';
          statusIcon = Icons.autorenew;
        }
    
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: _selectedLoteIds.contains(lote.id) 
              ? Border.all(color: BioWayColors.ecoceGreen, width: 2)
              : esSublote
                ? Border.all(color: Colors.purple.withValues(alpha: 0.3), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: esSublote 
                  ? Colors.purple.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
                blurRadius: esSublote ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              if (_tabController.index == 0 && canBeSelected) {
                // En la pestaña Salida, el tap inicia/toggle selección
                if (!_isSelectionMode) {
                  _startSelectionMode(lote.id);
                } else {
                  _toggleLoteSelection(lote.id);
                }
              } else {
                // En otras pestañas, muestra detalles
                _showLoteDetails(lote);
              }
            },
            onLongPress: canBeSelected ? () => _startSelectionMode(lote.id) : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      // Checkbox para selección múltiple - Siempre visible en pestaña Salida
                      if (canBeSelected) ...[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _selectedLoteIds.contains(lote.id) 
                              ? BioWayColors.ecoceGreen
                              : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedLoteIds.contains(lote.id)
                                ? BioWayColors.ecoceGreen
                                : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Checkbox(
                            value: _selectedLoteIds.contains(lote.id),
                            onChanged: (_) {
                              if (!_isSelectionMode) {
                                _startSelectionMode(lote.id);
                              } else {
                                _toggleLoteSelection(lote.id);
                              }
                            },
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
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: esSublote 
                            ? Colors.purple.withValues(alpha: 0.1)
                            : statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          esSublote ? Icons.cut : statusIcon,
                          color: esSublote ? Colors.purple : statusColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    esSublote 
                                      ? 'SUBLOTE: ${lote.id.substring(0, 8).toUpperCase()}'
                                      : 'ID: ${lote.id.substring(0, 8).toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (esSublote) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.cut, size: 12, color: Colors.purple),
                                        SizedBox(width: 2),
                                        Text(
                                          'Derivado',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.purple,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
                      // Botones de acción según la pestaña
                      if (_tabController.index == 1) ...[
                        // Pestaña Completados
                        // Botón QR (solo si está en reciclador y tiene firma de salida O es sublote)
                        if (lote.datosGenerales.procesoActual == 'reciclador' && (isCompleted || esSublote))
                          IconButton(
                            icon: Icon(
                              Icons.qr_code_2, 
                              color: esSublote ? Colors.purple : BioWayColors.ecoceGreen,
                            ),
                            onPressed: () => _showQRCode(lote),
                            tooltip: 'Ver código QR',
                          ),
                        // Botón Documentación (NO mostrar para sublotes)
                        if (!esSublote)
                          IconButton(
                            icon: Icon(
                              hasAllDocs ? Icons.check_circle : Icons.upload_file,
                              color: hasAllDocs ? Colors.green : Colors.orange,
                            ),
                            onPressed: hasAllDocs ? null : () => _uploadDocuments(lote),
                            tooltip: hasAllDocs ? 'Documentación completa' : 'Subir documentación',
                          ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Información principal
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
                      label: lote.tieneAnalisisLaboratorio ? 'Peso Actual' : 'Peso Entrada',
                      value: '${lote.pesoActual.toStringAsFixed(2)} kg',
                      color: lote.tieneAnalisisLaboratorio ? Colors.blue : null,
                    ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Información secundaria
                  Row(
                    children: [
                      Expanded(
                    child: _buildInfoItem(
                      icon: Icons.calendar_today,
                      label: 'Entrada',
                      value: FormatUtils.formatDate(reciclador.fechaEntrada),
                      fontSize: 12,
                    ),
                      ),
                      if (lote.tieneAnalisisLaboratorio)
                        Expanded(
                      child: _buildInfoItem(
                        icon: Icons.science,
                        label: 'Muestras Lab',
                        value: '${lote.pesoTotalMuestras.toStringAsFixed(2)} kg',
                        fontSize: 12,
                        color: BioWayColors.ppPurple,
                      ),
                        )
                      else if (reciclador.pesoProcesado != null)
                        Expanded(
                      child: _buildInfoItem(
                        icon: Icons.trending_down,
                        label: 'Merma',
                        value: '${reciclador.mermaProceso ?? 0} kg',
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                        ),
                    ],
                  ),
                ],
          ),
        ),
      ),
    );
      },
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
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
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
  
  void _showQRCode(LoteUnificadoModel lote) async {
    // Verificar si es un sublote
    final bool esSublote = lote.datosGenerales.tipoLote == 'derivado' || 
                          lote.datosGenerales.qrCode.startsWith('SUBLOTE-');
    
    if (esSublote) {
      // Para sublotes, verificar si necesita crearse en el sistema unificado
      try {
        // Verificar si el sublote ya existe como lote
        final existeLote = await _loteService.obtenerLotePorId(lote.id);
        if (existeLote == null) {
          // Si no existe, crearlo desde el sublote
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
          
          // Obtener datos del sublote desde la colección sublotes
          final subloteDoc = await FirebaseFirestore.instance
              .collection('sublotes')
              .doc(lote.id)
              .get();
              
          if (subloteDoc.exists) {
            final subloteData = subloteDoc.data()!;
            await _loteService.crearLoteDesdeSubLote(
              subloteId: lote.id,
              datosSubLote: {
                'creado_por': subloteData['creado_por'],
                'creado_por_folio': subloteData['creado_por_folio'],
                'material_predominante': subloteData['material_predominante'] ?? 'Mixto',
                'peso': subloteData['peso'],
                'qr_code': subloteData['qr_code'],
                'transformacion_origen': subloteData['transformacion_origen'],
              },
            );
          }
          
          if (mounted) {
            Navigator.of(context).pop(); // Cerrar loading
          }
        }
      } catch (e) {
        if (mounted) {
          DialogUtils.showErrorDialog(
            context,
            title: 'Error',
            message: 'Error al procesar sublote: ${e.toString()}',
          );
        }
        return;
      }
      
      // Para sublotes, usar los datos generales directamente
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecicladorLoteQRScreen(
            loteId: lote.id,
            material: lote.datosGenerales.tipoMaterial,
            pesoOriginal: lote.datosGenerales.pesoInicial,
            pesoFinal: lote.datosGenerales.peso,
            presentacion: lote.datosGenerales.materialPresentacion ?? 'Sublote',
            origen: 'Sublote de Reciclador',
            fechaEntrada: lote.datosGenerales.fechaCreacion,
            fechaSalida: DateTime.now(), // Los sublotes se crean ya procesados
            pesoMuestrasLaboratorio: null,
          ),
        ),
      );
    } else {
      // Para lotes regulares, usar los datos del reciclador
      final reciclador = lote.reciclador!;
      // Usar el peso actual que ya considera las muestras del laboratorio
      final pesoActual = lote.pesoActual;
      
      // Calcular el peso de las muestras del laboratorio
      final pesoMuestras = lote.pesoTotalMuestras;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecicladorLoteQRScreen(
            loteId: lote.id,
            material: lote.datosGenerales.tipoMaterial,
            pesoOriginal: reciclador.pesoEntrada,
            pesoFinal: pesoActual, // Peso con muestras de laboratorio descontadas
            presentacion: lote.datosGenerales.materialPresentacion ?? 'Pacas',
            origen: 'Reciclador',
            fechaEntrada: reciclador.fechaEntrada,
            fechaSalida: reciclador.fechaSalida,
            pesoMuestrasLaboratorio: pesoMuestras > 0 ? pesoMuestras : null,
          ),
        ),
      );
    }
  }
  
  void _uploadDocuments(LoteUnificadoModel lote) async {
    // Verificar si ya tiene documentación completa
    final hasAllDocs = await _checkHasDocumentation(lote.id);
    
    if (hasAllDocs) {
      // Mostrar alerta de que la documentación ya está completa
      if (!mounted) return;
      DialogUtils.showInfoDialog(
        context,
        title: 'Documentación Completa',
        message: 'La documentación para este lote ya ha sido enviada correctamente.\n\n'
                'No es necesario volver a cargar documentos.',
      );
    } else {
      // Navegar a la pantalla de documentación
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecicladorDocumentacion(
            lotId: lote.id,
          ),
        ),
      ).then((_) {
        // Recargar los lotes después de subir documentación
        _loadLotes();
      });
    }
  }


  /// Navegar a la pantalla de recepción de lotes
  void _navigateToScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReceptorRecepcionPasosScreen(
          userType: 'reciclador',
        ),
      ),
    );
  }

  /// Verificar si el lote tiene documentación completa
  Future<bool> _checkHasDocumentation(String loteId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('lotes')
          .doc(loteId)
          .collection('reciclador')
          .doc('data')
          .get();
      
      if (doc.exists) {
        final data = doc.data() ?? {};
        return data['f_tecnica_pellet'] != null && data['rep_result_reci'] != null;
      }
      return false;
    } catch (e) {
      debugPrint('Error verificando documentación: $e');
      return false;
    }
  }

  // Calcular peso total de lotes filtrados
  double _calcularPesoTotal(List<LoteUnificadoModel> lotes) {
    double total = 0.0;
    for (final lote in lotes) {
      // Usar pesoActual que ya considera las muestras del laboratorio
      total += lote.pesoActual;
    }
    return total;
  }
  

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // Métodos para selección múltiple
  void _startSelectionMode(String loteId) {
    setState(() {
      _isSelectionMode = true;
      _selectedLoteIds.add(loteId);
    });
    HapticFeedback.lightImpact();
  }
  
  void _toggleLoteSelection(String loteId) {
    setState(() {
      if (_selectedLoteIds.contains(loteId)) {
        _selectedLoteIds.remove(loteId);
        if (_selectedLoteIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedLoteIds.add(loteId);
      }
    });
    HapticFeedback.selectionClick();
  }
  
  void _cancelSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedLoteIds.clear();
    });
  }
  
  void _processSelectedLotes() async {
    if (_selectedLoteIds.isEmpty) return;
    
    try {
      // TODOS los lotes se procesan como transformación (megalote)
      // incluso si es solo uno - para tener funcionalidad de sublotes
      
      // Navegar al formulario con los lotes seleccionados
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecicladorFormularioSalida(
            lotesIds: _selectedLoteIds.toList(),
          ),
        ),
      ).then((_) {
        _cancelSelectionMode();
        _loadLotes();
      });
    } catch (e) {
      DialogUtils.showErrorDialog(
        context,
        title: 'Error',
        message: 'Error al procesar los lotes seleccionados',
      );
    }
  }
  
  Widget _buildSelectionPanel(List<LoteUnificadoModel> allLotes) {
    // Obtener solo los lotes seleccionados
    final selectedLotes = allLotes.where((l) => _selectedLoteIds.contains(l.id)).toList();
    final totalPeso = selectedLotes.fold(0.0, (total, lote) => total + lote.pesoActual);
    
    return Container(
      color: BioWayColors.ecoceGreen.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: BioWayColors.ecoceGreen, size: 24),
              const SizedBox(width: 8),
              Text(
                '${_selectedLoteIds.length} lotes seleccionados',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _cancelSelectionMode,
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
                onPressed: _selectedLoteIds.length >= 2 ? _processSelectedLotes : null,
                icon: const Icon(Icons.merge_type),
                label: const Text('Procesar juntos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BioWayColors.ecoceGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Construir pestaña con RefreshIndicator
  Widget _buildTabWithRefresh({required Widget child}) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadLotes();
        await Future.delayed(const Duration(seconds: 1));
      },
      notificationPredicate: (notification) {
        // Solo activar refresh si es el scroll principal
        return notification.depth == 0;
      },
      child: child,
    );
  }

  // Construir pestaña de completados
  Widget _buildCompletadosTab(List<LoteUnificadoModel> lotes) {
    // Mostrar tanto transformaciones como lotes normales completados
    return StreamBuilder<List<TransformacionModel>>(
      stream: _transformacionesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // NO filtrar transformaciones - mostrar todas
        final transformaciones = snapshot.data ?? [];
        final pesoTotal = _calcularPesoTotal(lotes);
        final tabColor = _getTabColor();
        // Solo sublotes en lotes (los megalotes están en transformaciones)
        final sublotes = lotes.where((lote) => lote.esSublote).toList();
        final bool hasNoItems = _showOnlyMegalotes ? transformaciones.isEmpty : (sublotes.isEmpty && transformaciones.isEmpty);
        
        return ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            // Filtros horizontales (siempre visibles)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Filtro de materiales
                  SizedBox(
                    height: 40,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: ['Todos', 'PEBD', 'PP', 'Multilaminado'].map((material) {
                          final isSelected = _selectedMaterial == material;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(material),
                              selected: isSelected,
                              selectedColor: tabColor.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: isSelected ? tabColor : Colors.grey[700],
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedMaterial = material;
                                  _filterLotes();
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filtros de tiempo y presentación
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownFilter(
                          label: 'Tiempo',
                          value: _selectedTime,
                          items: ['Todos', 'Hoy', 'Esta semana', 'Este mes'],
                          onChanged: (value) {
                            setState(() {
                              _selectedTime = value!;
                              _filterLotes();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdownFilter(
                          label: 'Presentación',
                          value: _selectedPresentacion,
                          items: ['Todos', 'Pacas', 'Sacos'],
                          onChanged: (value) {
                            setState(() {
                              _selectedPresentacion = value!;
                              _filterLotes();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Filtro de megalotes
                  Container(
                    decoration: BoxDecoration(
                      color: _showOnlyMegalotes 
                        ? Colors.deepPurple.withValues(alpha: 0.1)
                        : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _showOnlyMegalotes 
                          ? Colors.deepPurple.withValues(alpha: 0.3)
                          : Colors.grey[300]!,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showOnlyMegalotes = !_showOnlyMegalotes;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.merge_type,
                              size: 20,
                              color: _showOnlyMegalotes 
                                ? Colors.deepPurple
                                : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Mostrar solo Megalotes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _showOnlyMegalotes 
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                                color: _showOnlyMegalotes 
                                  ? Colors.deepPurple
                                  : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _showOnlyMegalotes 
                                  ? Colors.deepPurple
                                  : Colors.grey[400],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${transformaciones.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tarjetas de estadísticas (más compactas)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
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
                              color: tabColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.inventory_2, color: tabColor, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${lotes.length + transformaciones.length}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Total',
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
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
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
                              color: Colors.orange.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.scale, color: Colors.orange, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(pesoTotal / 1000).toStringAsFixed(2)} ton',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Peso Total',
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
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista combinada de transformaciones y lotes o mensaje de vacío
            if (hasNoItems) ...[
              Container(
                height: 200,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showOnlyMegalotes ? Icons.merge_type : Icons.inventory_2_outlined,
                      size: 60,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _showOnlyMegalotes 
                        ? 'No hay megalotes'
                        : 'No hay megalotes ni sublotes',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Si el filtro de megalotes está activo, solo mostrar transformaciones
              if (_showOnlyMegalotes) ...[
                ...transformaciones.map((transformacion) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildTransformacionCard(transformacion),
                  )
                ),
              ] else ...[
                // Mostrar transformaciones (megalotes) y sublotes únicamente
                // Primero mostrar transformaciones
                ...transformaciones.map((transformacion) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildTransformacionCard(transformacion),
                  )
                ),
                // Luego mostrar SOLO sublotes (no lotes normales)
                ...lotes.where((lote) => lote.esSublote).map((lote) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildLoteCard(lote),
                  )
                ),
              ],
            ],
            const SizedBox(height: 80), // Espacio adicional al final
          ],
        );
      },
    );
  }

  // Construir tarjeta de transformación
  Widget _buildTransformacionCard(TransformacionModel transformacion) {
    final bool isComplete = transformacion.estado == 'completada';
    final hasAvailableWeight = transformacion.pesoDisponible > 0;
    final hasDocumentation = transformacion.tieneDocumentacion;
    
    // Ocultar megalotes solo cuando peso=0 Y tiene documentación
    if (transformacion.debeSerEliminada) {
      return const SizedBox.shrink();
    }
    
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
        onTap: () => _showTransformacionDetails(transformacion),
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
                      color: BioWayColors.ecoceGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.merge_type,
                      color: BioWayColors.ecoceGreen,
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
                          isComplete ? 'Completado' : 'En proceso',
                          style: TextStyle(
                            fontSize: 12,
                            color: isComplete ? Colors.grey : BioWayColors.ecoceGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Remover botones duplicados del header
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Información de peso
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.scale,
                    label: 'Entrada',
                    value: '${transformacion.pesoTotalEntrada.toStringAsFixed(2)} kg',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.inventory_2,
                    label: 'Disponible',
                    value: '${transformacion.pesoDisponible.toStringAsFixed(2)} kg',
                    color: hasAvailableWeight ? Colors.green : Colors.grey,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Lotes de entrada
              Text(
                '${transformacion.lotesEntrada.length} lotes combinados',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              
              // Mostrar advertencia si no tiene peso pero falta documentación
              if (!hasAvailableWeight && !hasDocumentation) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sube la documentación para completar este megalote',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Mostrar información cuando el megalote será eliminado
              if (!hasAvailableWeight && hasDocumentation) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Megalote completado y documentado',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              if (transformacion.sublotesGenerados.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${transformacion.sublotesGenerados.length} sublotes generados',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón Crear Sublote
                  _buildActionButton(
                    icon: Icons.cut,
                    label: 'Sublote',
                    onPressed: hasAvailableWeight
                        ? () => _createSublote(transformacion)
                        : null,
                    enabled: hasAvailableWeight,
                    color: BioWayColors.ecoceGreen,
                  ),
                  
                  // Botón Muestra
                  _buildActionButton(
                    icon: Icons.science,
                    label: 'Muestra',
                    onPressed: hasAvailableWeight
                        ? () => _createMuestra(transformacion)
                        : null,
                    enabled: hasAvailableWeight,
                    color: Colors.orange,
                  ),
                  
                  // Botón Documentación
                  _buildActionButton(
                    icon: transformacion.tieneDocumentacion 
                      ? Icons.check_circle 
                      : Icons.upload_file,
                    label: 'Documentación',
                    onPressed: transformacion.tieneDocumentacion 
                      ? null 
                      : () => _uploadTransformacionDocuments(transformacion),
                    enabled: !transformacion.tieneDocumentacion,
                    color: transformacion.tieneDocumentacion 
                      ? Colors.green 
                      : BioWayColors.info,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Construir botón de acción para las tarjetas de transformación
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool enabled,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: enabled ? (color ?? BioWayColors.ecoceGreen) : Colors.grey[400],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: enabled ? (color ?? BioWayColors.ecoceGreen) : Colors.grey[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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

  // Mostrar detalles de transformación
  void _showTransformacionDetails(TransformacionModel transformacion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                        _buildDetailRow('Material', transformacion.materialPredominante ?? 'Mixto'),
                        _buildDetailRow('Peso entrada', '${transformacion.pesoTotalEntrada.toStringAsFixed(2)} kg'),
                        _buildDetailRow('Peso asignado', '${transformacion.pesoAsignadoSublotes.toStringAsFixed(2)} kg'),
                        _buildDetailRow('Peso disponible', '${transformacion.pesoDisponible.toStringAsFixed(2)} kg'),
                        _buildDetailRow('Merma', '${transformacion.mermaProceso.toStringAsFixed(2)} kg'),
                        _buildDetailRow('Estado', transformacion.estado),
                      ],
                    ),
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
                    
                    // Muestras de laboratorio
                    if (transformacion.muestrasLaboratorio.isNotEmpty) ...[
                      _buildDetailSection(
                        'Muestras de Laboratorio (${transformacion.muestrasLaboratorio.length})',
                        transformacion.muestrasLaboratorio.map((muestra) {
                          final estado = muestra['estado'] ?? 'pendiente';
                          final peso = muestra['peso'] ?? muestra['peso_muestra'] ?? 0;
                          final analisisCompletado = muestra['analisis_completado'] ?? false;
                          final tieneCertificado = muestra['certificado'] != null;
                          
                          String estadoTexto = 'Pendiente';
                          Color estadoColor = Colors.orange;
                          
                          if (tieneCertificado) {
                            estadoTexto = 'Finalizada';
                            estadoColor = Colors.green;
                          } else if (analisisCompletado) {
                            estadoTexto = 'Análisis completado';
                            estadoColor = Colors.blue;
                          } else if (estado == 'completado') {
                            estadoTexto = 'Muestra tomada';
                            estadoColor = Colors.indigo;
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Muestra ${muestra['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: estadoColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    estadoTexto,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: estadoColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  peso > 0 ? '${peso.toStringAsFixed(2)} kg' : 'Sin peso',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: peso > 0 ? Colors.black87 : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Documentación
                    _buildDetailSection(
                      'Documentación',
                      [
                        _buildDetailRow(
                          'Ficha técnica',
                          transformacion.documentosAsociados['f_tecnica_pellet'] != null ? 'Cargada' : 'Pendiente',
                          valueColor: transformacion.documentosAsociados['f_tecnica_pellet'] != null ? Colors.green : Colors.orange,
                        ),
                        _buildDetailRow(
                          'Reporte de resultado',
                          transformacion.documentosAsociados['rep_result_reci'] != null ? 'Cargado' : 'Pendiente',
                          valueColor: transformacion.documentosAsociados['rep_result_reci'] != null ? Colors.green : Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
  
  // Subir documentación de transformación
  void _uploadTransformacionDocuments(TransformacionModel transformacion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecicladorTransformacionDocumentacion(
          transformacionId: transformacion.id,
        ),
      ),
    );
  }
  
  // Crear muestra de laboratorio
  void _createMuestra(TransformacionModel transformacion) async {
    try {
      // Generar QR para la muestra
      final muestraId = await _transformacionService.crearMuestraLaboratorio(
        transformacionId: transformacion.id,
        pesoMuestra: 0, // Peso pendiente, será llenado por laboratorio
      );
      
      if (!mounted) return;
      
      // Mostrar pantalla de QR
      // El código QR será generado internamente por RecicladorLoteQRScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecicladorLoteQRScreen(
            loteId: muestraId,
            material: 'Muestra de Laboratorio',
            pesoOriginal: transformacion.pesoDisponible,
            pesoFinal: null,
            presentacion: 'Megalote ${transformacion.id.substring(0, 8).toUpperCase()}',
            origen: 'Reciclador',
            fechaEntrada: transformacion.fechaInicio,
            fechaSalida: DateTime.now(),
            documentosCargados: [],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        DialogUtils.showErrorDialog(
          context,
          title: 'Error',
          message: 'No se pudo crear la muestra: ${e.toString()}',
        );
      }
    }
  }

  // Crear sublote
  void _createSublote(TransformacionModel transformacion) {
    final TextEditingController pesoController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              Icon(
                Icons.cut,
                color: BioWayColors.ecoceGreen,
                size: 48,
              ),
              const SizedBox(height: 8),
              const Text(
                'Crear Sublote',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peso disponible: ${transformacion.pesoDisponible.toStringAsFixed(2)} kg',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                // Usar WeightInputWidget para entrada de peso
                WeightInputWidget(
                  controller: pesoController,
                  label: 'Peso del sublote',
                  primaryColor: BioWayColors.ecoceGreen,
                  minValue: 0.01,
                  maxValue: transformacion.pesoDisponible,
                  incrementValue: 0.5,
                  quickAddValues: [10, 25, 50, 100],
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un peso';
                    }
                    final peso = double.tryParse(value);
                    if (peso == null || peso <= 0) {
                      return 'Ingrese un peso válido';
                    }
                    if (peso > transformacion.pesoDisponible) {
                      return 'Excede el peso disponible';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pesoText = pesoController.text.trim();
                if (pesoText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingrese un peso'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final peso = double.tryParse(pesoText);
                if (peso == null || peso <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingrese un peso válido'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (peso > transformacion.pesoDisponible) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('El peso excede el disponible (${transformacion.pesoDisponible.toStringAsFixed(2)} kg)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Mostrar loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                try {
                  final subloteId = await _transformacionService.crearSublote(
                    transformacionId: transformacion.id,
                    peso: peso,
                  );
                  
                  if (!mounted) return;
                  
                  // Cerrar loading
                  Navigator.of(context).pop();
                  // Cerrar diálogo
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  
                  // Crear el lote en el sistema unificado
                  final subloteDoc = await FirebaseFirestore.instance
                      .collection('sublotes')
                      .doc(subloteId)
                      .get();
                      
                  if (subloteDoc.exists) {
                    final subloteData = subloteDoc.data()!;
                    await _loteService.crearLoteDesdeSubLote(
                      subloteId: subloteId,
                      datosSubLote: {
                        'creado_por': subloteData['creado_por'],
                        'creado_por_folio': subloteData['creado_por_folio'],
                        'material_predominante': subloteData['material_predominante'] ?? 'Mixto',
                        'peso': subloteData['peso'],
                        'qr_code': subloteData['qr_code'],
                        'transformacion_origen': subloteData['transformacion_origen'],
                      },
                    );
                  }
                  
                  // Recargar los lotes
                  _loadLotes();
                  
                  // Asegurar que estamos en la pestaña Completados
                  if (_tabController.index != 1) {
                    _tabController.animateTo(1);
                  }
                  
                  // Mostrar éxito
                  if (mounted) {
                    DialogUtils.showSuccessDialog(
                      context,
                      title: 'Sublote Creado',
                      message: 'Se ha creado el sublote con ID: ${subloteId.substring(0, 8).toUpperCase()}',
                      onAccept: () {
                        Navigator.of(context).pop();
                      },
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  
                  // Cerrar loading
                  Navigator.of(context).pop();
                  
                  if (mounted) {
                    DialogUtils.showErrorDialog(
                      context,
                      title: 'Error',
                      message: 'Error al crear sublote: ${e.toString()}',
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BioWayColors.ecoceGreen,
              ),
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }
}

// Widget para mostrar detalles del lote
class _LoteDetailsSheet extends StatelessWidget {
  final LoteUnificadoModel lote;
  
  const _LoteDetailsSheet({required this.lote});
  
  @override
  Widget build(BuildContext context) {
    final reciclador = lote.reciclador!;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalles del Lote',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: ${lote.id.substring(0, 8).toUpperCase()}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
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
                    _buildDetailSection(
                      title: 'Información General',
                      items: {
                        'Material': lote.datosGenerales.tipoMaterial,
                        'Presentación': lote.datosGenerales.materialPresentacion ?? 'N/A',
                        'Fuente': lote.datosGenerales.materialFuente ?? 'N/A',
                        'QR Code': lote.datosGenerales.qrCode,
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildDetailSection(
                      title: 'Información del Proceso',
                      items: {
                        'Fecha de Entrada': FormatUtils.formatDateTime(reciclador.fechaEntrada),
                        if (reciclador.fechaSalida != null)
                          'Fecha de Salida': FormatUtils.formatDateTime(reciclador.fechaSalida!),
                        'Peso de Entrada': '${reciclador.pesoEntrada} kg',
                        if (reciclador.pesoProcesado != null)
                          'Peso Procesado': '${reciclador.pesoProcesado} kg',
                        if (reciclador.mermaProceso != null)
                          'Merma': '${reciclador.mermaProceso} kg',
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildDetailSection(
                      title: 'Trazabilidad',
                      items: {
                        'Proceso Actual': lote.datosGenerales.procesoActual,
                        'Historial': lote.datosGenerales.historialProcesos.join(' → '),
                        'Usuario': reciclador.usuarioFolio,
                      },
                    ),
                    const SizedBox(height: 20),
                    // Botón para completar proceso si está pendiente
                    if (reciclador.pesoProcesado != null && reciclador.fechaSalida == null)
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implementar completar proceso
                          Navigator.pop(context);
                          DialogUtils.showSuccessDialog(
                            context,
                            title: 'Próximamente',
                            message: 'Función de completar proceso en desarrollo',
                          );
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Completar Proceso'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BioWayColors.primaryGreen,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDetailSection({
    required String title,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
}