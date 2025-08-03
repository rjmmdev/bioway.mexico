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
import '../shared/widgets/lote_filter_section.dart';
import '../shared/widgets/lote_stats_section.dart';
import '../shared/widgets/lote_card_general.dart';
import '../shared/widgets/lote_details_sheet.dart';
import 'widgets/selection_panel.dart';
import 'widgets/transformacion_card.dart';
import 'widgets/transformacion_details_sheet.dart';
import 'widgets/sublote_dialog.dart';
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
          // 2. Estén en proceso reciclador O transporte (cuando reciclador ya recibió pero espera confirmación)
          // 3. No tengan fecha de salida
          // 4. NO estén consumidos en una transformación
          return !esSublote &&
                 (lote.datosGenerales.procesoActual == 'reciclador' || 
                  lote.datosGenerales.procesoActual == 'transporte') &&
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
      builder: (context) => LoteDetailsSheet(
        lote: lote,
        title: 'Detalles del Lote',
        additionalInfo: {
          'Estado Documentación': lote.reciclador?.fechaSalida != null 
            ? 'Completa' 
            : 'Pendiente',
        },
      ),
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
          // Estructura principal siempre visible
          return Column(
            children: [
              // Panel de selección múltiple
              if (_isSelectionMode && _tabController.index == 0)
                Builder(
                  builder: (context) {
                    final allLotes = snapshot.data ?? [];
                    final filteredLotes = _filterByTab(allLotes);
                    return SelectionPanel(
                      selectedLoteIds: _selectedLoteIds,
                      allLotes: filteredLotes,
                      onCancel: _cancelSelectionMode,
                      onProcess: _processSelectedLotes,
                    );
                  },
                ),
              // Contenido con TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const PageScrollPhysics(),
                  children: [
                    // Pestaña 0: Salida
                    _buildTabWithRefresh(
                      child: _buildTabContentWithData(snapshot, 0),
                    ),
                    // Pestaña 1: Completados
                    _buildTabWithRefresh(
                      child: _buildTabContentWithData(snapshot, 1),
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
        LoteFilterSection(
          selectedMaterial: _selectedMaterial,
          selectedTime: _selectedTime,
          selectedPresentacion: _selectedPresentacion,
          onMaterialChanged: (value) {
            setState(() {
              _selectedMaterial = value;
              _filterLotes();
            });
          },
          onTimeChanged: (value) {
            setState(() {
              _selectedTime = value;
              _filterLotes();
            });
          },
          onPresentacionChanged: (value) {
            setState(() {
              _selectedPresentacion = value;
              _filterLotes();
            });
          },
          tabColor: tabColor,
          showSelectionIndicator: _tabController.index == 0,
          selectionIndicatorText: 'Selecciona múltiples lotes para procesarlos juntos como megalote',
        ),
        
        // Tarjetas de estadísticas
        LoteStatsSection(
          lotesCount: lotes.length,
          pesoTotal: pesoTotal,
          tabColor: tabColor,
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
  

  Widget _buildLoteCard(LoteUnificadoModel lote) {
    final reciclador = lote.reciclador!;
    final isTransferred = lote.datosGenerales.procesoActual != 'reciclador';
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
        
        // Crear trailing widgets para acciones
        Widget? trailing;
        if (_tabController.index == 1) {
          final List<Widget> actions = [];
          
          // Botón QR
          if (lote.datosGenerales.procesoActual == 'reciclador' && (isCompleted || esSublote)) {
            actions.add(IconButton(
              icon: Icon(
                Icons.qr_code_2, 
                color: esSublote ? Colors.purple : BioWayColors.ecoceGreen,
              ),
              onPressed: () => _showQRCode(lote),
              tooltip: 'Ver código QR',
            ));
          }
          
          // Botón Documentación
          if (!esSublote) {
            actions.add(IconButton(
              icon: Icon(
                hasAllDocs ? Icons.check_circle : Icons.upload_file,
                color: hasAllDocs ? Colors.green : Colors.orange,
              ),
              onPressed: hasAllDocs ? null : () => _uploadDocuments(lote),
              tooltip: hasAllDocs ? 'Documentación completa' : 'Subir documentación',
            ));
          }
          
          if (actions.isNotEmpty) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: actions,
            );
          }
        }
        
        // Información adicional
        Widget additionalInfo = Row(
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
        );
        
        return LoteCardGeneral(
          lote: lote,
          isSelected: _selectedLoteIds.contains(lote.id),
          canBeSelected: canBeSelected,
          onTap: () {
            if (_tabController.index == 0 && canBeSelected) {
              if (!_isSelectionMode) {
                _startSelectionMode(lote.id);
              } else {
                _toggleLoteSelection(lote.id);
              }
            } else {
              _showLoteDetails(lote);
            }
          },
          onLongPress: canBeSelected ? () => _startSelectionMode(lote.id) : null,
          trailing: trailing,
          additionalInfo: additionalInfo,
          showCheckbox: _tabController.index == 0,
          hasDocumentation: hasAllDocs,
          statusColor: statusColor,
          statusText: statusText,
          statusIcon: statusIcon,
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
            // Filtros horizontales
            LoteFilterSection(
              selectedMaterial: _selectedMaterial,
              selectedTime: _selectedTime,
              selectedPresentacion: _selectedPresentacion,
              onMaterialChanged: (value) {
                setState(() {
                  _selectedMaterial = value;
                  _filterLotes();
                });
              },
              onTimeChanged: (value) {
                setState(() {
                  _selectedTime = value;
                  _filterLotes();
                });
              },
              onPresentacionChanged: (value) {
                setState(() {
                  _selectedPresentacion = value;
                  _filterLotes();
                });
              },
              tabColor: tabColor,
              showMegaloteFilter: true,
              showOnlyMegalotes: _showOnlyMegalotes,
              onMegaloteFilterToggle: () {
                setState(() {
                  _showOnlyMegalotes = !_showOnlyMegalotes;
                });
              },
              megaloteCount: transformaciones.length,
            ),
            
            // Tarjetas de estadísticas
            LoteStatsSection(
              lotesCount: lotes.length + transformaciones.length,
              pesoTotal: pesoTotal,
              tabColor: tabColor,
              showInTons: true,
              customLotesLabel: 'Total',
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

  Widget _buildTransformacionCard(TransformacionModel transformacion) {
    return TransformacionCard(
      transformacion: transformacion,
      onTap: () => _showTransformacionDetails(transformacion),
      onCreateSublote: () => _createSublote(transformacion),
      onCreateMuestra: () => _createMuestra(transformacion),
      onUploadDocuments: () => _uploadTransformacionDocuments(transformacion),
    );
  }

  // Mostrar detalles de transformación
  void _showTransformacionDetails(TransformacionModel transformacion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransformacionDetailsSheet(
        transformacion: transformacion,
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return SubloteDialog(
          transformacion: transformacion,
          onCreateSublote: (peso) async {
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
              
              // NOTA: Ya no es necesario crear el lote manualmente
              // El servicio de transformación ahora crea el sublote directamente
              // en la colección 'lotes' dentro de la transacción
              
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
                    // Solo cerrar el diálogo, no navegar
                    // La lista ya se recargó con _loadLotes()
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
        );
      },
    );
  }
  
  Widget _buildTabContentWithData(AsyncSnapshot<List<LoteUnificadoModel>> snapshot, int tabIndex) {
    // Mostrar indicador de carga solo en el área de contenido
    if (snapshot.connectionState == ConnectionState.waiting) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // Mantener filtros visibles durante la carga
          LoteFilterSection(
            selectedMaterial: _selectedMaterial,
            selectedTime: _selectedTime,
            selectedPresentacion: _selectedPresentacion,
            onMaterialChanged: (value) {
              setState(() {
                _selectedMaterial = value;
                _filterLotes();
              });
            },
            onTimeChanged: (value) {
              setState(() {
                _selectedTime = value;
                _filterLotes();
              });
            },
            onPresentacionChanged: (value) {
              setState(() {
                _selectedPresentacion = value;
                _filterLotes();
              });
            },
            tabColor: _getTabColor(),
            showSelectionIndicator: tabIndex == 0,
            selectionIndicatorText: 'Selecciona múltiples lotes para procesarlos juntos como megalote',
          ),
          // Indicador de carga en lugar de las tarjetas
          const SizedBox(height: 100),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 100),
        ],
      );
    }
    
    // Manejar errores
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
    
    // Datos cargados exitosamente
    final allLotes = snapshot.data ?? [];
    final filteredLotes = _filterByTab(allLotes);
    
    // Retornar el contenido apropiado según la pestaña
    if (tabIndex == 0) {
      return _buildTabContent(filteredLotes);
    } else {
      return _buildCompletadosTab(filteredLotes);
    }
  }
}