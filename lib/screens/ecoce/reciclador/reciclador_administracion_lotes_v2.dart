import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/user_session_service.dart';
import '../../../models/lotes/lote_unificado_model.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/dialog_utils.dart';

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
  final UserSessionService _userSession = UserSessionService();
  
  // Estados
  Stream<List<LoteUnificadoModel>>? _lotesStream;
  String _selectedMaterial = 'Todos';
  String _selectedTime = 'Todos';
  int _selectedIndex = 1; // Bottom nav index
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != _tabController.previousIndex) {
        setState(() {});
      }
    });
    _loadLotes();
  }
  
  void _loadLotes() {
    setState(() {
      _lotesStream = _loteService.obtenerLotesPorProceso('reciclador');
    });
  }
  
  void _filterLotes() {
    setState(() {
      _lotesStream = _loteService.buscarLotes(
        query: _searchController.text.isEmpty ? null : _searchController.text,
        proceso: 'reciclador',
        tipoMaterial: _selectedMaterial == 'Todos' ? null : _selectedMaterial,
      );
    });
  }
  
  List<LoteUnificadoModel> _filterByTab(List<LoteUnificadoModel> lotes) {
    switch (_tabController.index) {
      case 0: // En proceso
        return lotes.where((lote) {
          final reciclador = lote.reciclador;
          return reciclador != null && reciclador.fechaSalida == null;
        }).toList();
        
      case 1: // Pendientes de salida
        return lotes.where((lote) {
          final reciclador = lote.reciclador;
          return reciclador != null && 
                 reciclador.pesoProcesado != null && 
                 reciclador.fechaSalida == null;
        }).toList();
        
      case 2: // Completados
        return lotes.where((lote) {
          final reciclador = lote.reciclador;
          return reciclador != null && reciclador.fechaSalida != null;
        }).toList();
        
      default:
        return [];
    }
  }
  
  void _handleSearch(String value) {
    _filterLotes();
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filtro por material
            DropdownButtonFormField<String>(
              value: _selectedMaterial,
              decoration: const InputDecoration(
                labelText: 'Tipo de Material',
                border: OutlineInputBorder(),
              ),
              items: ['Todos', 'PEBD', 'PP', 'Multilaminado']
                  .map((material) => DropdownMenuItem(
                        value: material,
                        child: Text(material),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMaterial = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            // Filtro por tiempo
            DropdownButtonFormField<String>(
              value: _selectedTime,
              decoration: const InputDecoration(
                labelText: 'Periodo',
                border: OutlineInputBorder(),
              ),
              items: ['Todos', 'Hoy', 'Esta semana', 'Este mes']
                  .map((time) => DropdownMenuItem(
                        value: time,
                        child: Text(time),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTime = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedMaterial = 'Todos';
                _selectedTime = 'Todos';
              });
              _loadLotes();
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
          ElevatedButton(
            onPressed: () {
              _filterLotes();
              Navigator.pop(context);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
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
              labelColor: BioWayColors.primaryGreen,
              unselectedLabelColor: Colors.grey,
              indicatorColor: BioWayColors.primaryGreen,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'En Proceso'),
                Tab(text: 'Pendientes'),
                Tab(text: 'Completados'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _handleSearch,
                    decoration: InputDecoration(
                      hintText: 'Buscar por ID o material...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showFilterDialog,
                  icon: Icon(
                    Icons.filter_list,
                    color: BioWayColors.primaryGreen,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: BioWayColors.primaryGreen.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
          // Lista de lotes
          Expanded(
            child: StreamBuilder<List<LoteUnificadoModel>>(
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
                
                if (filteredLotes.isEmpty) {
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
                
                return TabBarView(
                  controller: _tabController,
                  children: List.generate(3, (tabIndex) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredLotes.length,
                      itemBuilder: (context, index) {
                        final lote = filteredLotes[index];
                        return _buildLoteCard(lote);
                      },
                    );
                  }),
                );
              },
            ),
          ),
        ],
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
      ),
    );
  }
  
  Widget _buildLoteCard(LoteUnificadoModel lote) {
    final reciclador = lote.reciclador!;
    final isCompleted = reciclador.fechaSalida != null;
    final isPending = reciclador.pesoProcesado != null && reciclador.fechaSalida == null;
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (isCompleted) {
      statusColor = Colors.green;
      statusText = 'Completado';
      statusIcon = Icons.check_circle;
    } else if (isPending) {
      statusColor = Colors.orange;
      statusText = 'Pendiente de salida';
      statusIcon = Icons.pending_actions;
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
                      color: statusColor.withOpacity(0.1),
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
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
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
                      label: 'Peso Entrada',
                      value: '${reciclador.pesoEntrada} kg',
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
                  if (reciclador.pesoProcesado != null)
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