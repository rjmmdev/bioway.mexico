import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../models/lotes/lote_unificado_model.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/dialog_utils.dart';
import 'reciclador_lote_qr_screen.dart';
import 'reciclador_documentacion.dart';
import 'reciclador_formulario_salida.dart';
import '../shared/screens/receptor_recepcion_pasos_screen.dart';

/// Pantalla de administración de lotes del reciclador usando el sistema unificado
class RecicladorAdministracionLotesV2 extends StatefulWidget {
  final int initialTab;
  
  const RecicladorAdministracionLotesV2({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<RecicladorAdministracionLotesV2> createState() => _RecicladorAdministracionLotesV2State();
}

class _RecicladorAdministracionLotesV2State extends State<RecicladorAdministracionLotesV2>
    with SingleTickerProviderStateMixin {
  // Controladores
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Servicios
  final LoteUnificadoService _loteService = LoteUnificadoService();
  
  // Estados
  Stream<List<LoteUnificadoModel>>? _lotesStream;
  String _selectedMaterial = 'Todos';
  String _selectedTime = 'Todos';
  final String _selectedDocFilter = 'Todos'; // Nuevo filtro para documentación
  String _selectedPresentacion = 'Todos'; // Filtro de presentación
  int _selectedIndex = 1; // Bottom nav index
  
  
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
        });
      }
    });
    _loadLotes();
  }
  
  void _loadLotes() {
    setState(() {
      _lotesStream = _loteService.obtenerLotesRecicladorConPendientes();
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
          // Solo mostrar lotes que están en proceso reciclador y no tienen fecha de salida
          return lote.datosGenerales.procesoActual == 'reciclador' &&
                 reciclador != null && 
                 reciclador.fechaSalida == null;
        }).toList();
        
      case 1: // Completados
        var completados = filteredLotes.where((lote) {
          final reciclador = lote.reciclador;
          // Mostrar lotes con fecha de salida (en reciclador) o transferidos sin documentación
          return reciclador != null && (
            (lote.datosGenerales.procesoActual == 'reciclador' && reciclador.fechaSalida != null) ||
            (lote.datosGenerales.procesoActual != 'reciclador')
          );
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
        backgroundColor: BioWayColors.primaryGreen,
        elevation: 0,
        title: const Text(
          'Administración de Lotes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
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
          
          if (filteredLotes.isEmpty && _tabController.index == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
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
            );
          }
          
          return Column(
            children: [
              // Contenido con TabBarView
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _loadLotes();
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTabContent(filteredLotes), // Pestaña 0: Salida
                      _buildTabContent(filteredLotes), // Pestaña 1: Completados
                    ],
                  ),
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
      floatingActionButton: EcoceFloatingActionButton(
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
    final polimeroInfo = _calcularPolimeroMasComun(lotes);
    final tabColor = _getTabColor();
    
    return Column(
      children: [
        // Filtros horizontales
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
        
        // Tarjetas de estadísticas
        Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Número de lotes
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: tabColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.inventory_2, color: tabColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lotes.length.toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Lotes',
                                  style: TextStyle(
                                    fontSize: 12,
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
                  const SizedBox(width: 12),
                  // Peso total
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.scale, color: Colors.orange, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${pesoTotal.toStringAsFixed(1)} kg',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Peso Total',
                                  style: TextStyle(
                                    fontSize: 12,
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
              const SizedBox(height: 12),
              // Polímero más común
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: BioWayColors.ppPurple.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.polymer, color: BioWayColors.ppPurple, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${polimeroInfo['material']} (${polimeroInfo['porcentaje']}%)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Polímero más común',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Lista de lotes
        Expanded(
          child: lotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
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
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: lotes.length,
                  itemBuilder: (context, index) {
                    final lote = lotes[index];
                    return _buildLoteCard(lote);
                  },
                ),
        ),
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
    
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => _showLoteDetails(lote),
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
                      if (_tabController.index == 0) ...[
                        // Pestaña Salida - Botón Formulario de Salida
                        IconButton(
                      icon: Icon(
                        Icons.assignment_outlined,
                        color: BioWayColors.ecoceGreen,
                      ),
                      onPressed: () => _openFormularioSalida(lote),
                      tooltip: 'Formulario de salida',
                        ),
                      ] else if (_tabController.index == 1) ...[
                        // Pestaña Completados
                        // Botón QR (solo si está en reciclador y tiene firma de salida)
                        if (lote.datosGenerales.procesoActual == 'reciclador' && isCompleted)
                          IconButton(
                        icon: Icon(Icons.qr_code_2, color: BioWayColors.ecoceGreen),
                        onPressed: () => _showQRCode(lote),
                        tooltip: 'Ver código QR',
                          ),
                        // Botón Documentación (siempre visible en completados)
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
  
  void _showQRCode(LoteUnificadoModel lote) {
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

  void _openFormularioSalida(LoteUnificadoModel lote) {
    final reciclador = lote.reciclador!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecicladorFormularioSalida(
          loteId: lote.id,
          pesoOriginal: reciclador.pesoEntrada,
        ),
      ),
    ).then((_) {
      // Recargar los lotes después del formulario
      _loadLotes();
    });
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
  
  // Calcular polímero más común
  Map<String, dynamic> _calcularPolimeroMasComun(List<LoteUnificadoModel> lotes) {
    if (lotes.isEmpty) return {'material': 'N/A', 'porcentaje': 0};
    
    final Map<String, int> conteo = {};
    for (final lote in lotes) {
      final material = lote.datosGenerales.tipoMaterial;
      conteo[material] = (conteo[material] ?? 0) + 1;
    }
    
    String materialMasComun = '';
    int maxConteo = 0;
    conteo.forEach((material, cantidad) {
      if (cantidad > maxConteo) {
        maxConteo = cantidad;
        materialMasComun = material;
      }
    });
    
    final porcentaje = (maxConteo / lotes.length * 100).toInt();
    return {'material': materialMasComun, 'porcentaje': porcentaje};
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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