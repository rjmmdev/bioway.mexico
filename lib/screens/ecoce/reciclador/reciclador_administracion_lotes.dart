import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import 'reciclador_formulario_salida.dart';
import 'reciclador_documentacion.dart';
import 'reciclador_lote_qr_screen.dart';
import 'widgets/reciclador_bottom_navigation.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import 'widgets/reciclador_lote_card.dart';
import '../../../services/lote_service.dart';
import '../../../models/lotes/lote_reciclador_model.dart';

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
  late TabController _tabController;
  
  // Filtros
  String _selectedMaterial = 'Todos';
  String _selectedTiempo = 'Este Mes';
  String _selectedPresentacion = 'Todos';
  
  // Bottom navigation
  final int _selectedIndex = 1; // Lotes está seleccionado
  
  // Servicio y datos
  final LoteService _loteService = LoteService();
  List<LoteRecicladorModel> _todosLotes = [];
  bool _isLoading = true;

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
    _loteService.getLotesReciclador().listen((lotes) {
      if (mounted) {
        setState(() {
          _todosLotes = lotes;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<LoteRecicladorModel> get _lotesFiltrados {
    // Obtener lotes según la pestaña actual
    switch (_tabController.index) {
      case 0:
        // Lotes listos para salida (incluye: recibido, salida, procesado)
        return _todosLotes.where((lote) {
          final estado = lote.estado;
          // Incluir lotes que pueden procesarse para salida
          if (estado != 'recibido' && estado != 'salida' && estado != 'procesado') return false;
          
          // Aplicar otros filtros
          if (_selectedMaterial != 'Todos') {
            final material = _getTipoPredominante(lote.tipoPoli);
            if (material != _selectedMaterial) return false;
          }
          
          // Aplicar filtro de tiempo
          return _aplicarFiltroTiempo(lote);
        }).toList();
        
      case 1:
        // Lotes enviados pendientes de documentación
        return _todosLotes.where((lote) {
          if (lote.estado != 'enviado') return false;
          
          // Aplicar otros filtros
          if (_selectedMaterial != 'Todos') {
            final material = _getTipoPredominante(lote.tipoPoli);
            if (material != _selectedMaterial) return false;
          }
          
          return _aplicarFiltroTiempo(lote);
        }).toList();
        
      case 2:
        // Lotes con documentación completa
        return _todosLotes.where((lote) {
          if (lote.estado != 'finalizado') return false;
          
          // Aplicar otros filtros
          if (_selectedMaterial != 'Todos') {
            final material = _getTipoPredominante(lote.tipoPoli);
            if (material != _selectedMaterial) return false;
          }
          
          return _aplicarFiltroTiempo(lote);
        }).toList();
        
      default:
        return [];
    }
  }
  
  bool _aplicarFiltroTiempo(LoteRecicladorModel lote) {
    // Por ahora siempre retornar true ya que no tenemos fecha de creación en el modelo
    // TODO: Agregar campo de fecha al modelo LoteRecicladorModel
    return true;
  }
  
  String _getTipoPredominante(Map<String, double>? tipoPoli) {
    if (tipoPoli == null || tipoPoli.isEmpty) return 'N/A';
    
    String tipoPredominante = '';
    double maxPorcentaje = 0;
    
    tipoPoli.forEach((tipo, porcentaje) {
      if (porcentaje > maxPorcentaje) {
        maxPorcentaje = porcentaje;
        tipoPredominante = tipo;
      }
    });
    
    return tipoPredominante.isEmpty ? 'N/A' : tipoPredominante;
  }

  Color _getTabColor() {
    switch (_tabController.index) {
      case 0:
        return BioWayColors.error; // Rojo para salida
      case 1:
        return BioWayColors.warning; // Naranja/amarillo para documentación
      case 2:
        return BioWayColors.success; // Verde para finalizados
      default:
        return BioWayColors.ecoceGreen;
    }
  }

  // Obtener texto del botón según el estado
  String _getActionButtonText(String estado) {
    switch (estado) {
      case 'recibido':
        return 'Formulario Salida';
      case 'salida':
        return 'Formulario Salida';
      case 'procesado':
        return 'Formulario Salida';
      case 'enviado':
        return 'Añadir Documentación';
      case 'finalizado':
        return 'Ver Código QR';
      default:
        return '';
    }
  }

  // Obtener color del botón según el estado
  Color _getActionButtonColor(String estado) {
    switch (estado) {
      case 'recibido':
        return BioWayColors.error; // Rojo para salida
      case 'salida':
        return BioWayColors.error; // Rojo para salida
      case 'procesado':
        return BioWayColors.error; // Rojo para salida
      case 'enviado':
        return BioWayColors.warning; // Naranja para documentación
      case 'finalizado':
        return BioWayColors.ecoceGreen; // Verde para finalizados
      default:
        return BioWayColors.ecoceGreen;
    }
  }

  String _getMaterialMasPredominante() {
    if (_lotesFiltrados.isEmpty) return 'N/A';
    
    Map<String, int> conteo = {};
    for (var lote in _lotesFiltrados) {
      final material = _getTipoPredominante(lote.tipoPoli);
      conteo[material] = (conteo[material] ?? 0) + 1;
    }
    
    var entrada = conteo.entries.reduce((a, b) => a.value > b.value ? a : b);
    double porcentaje = (entrada.value / _lotesFiltrados.length) * 100;
    
    return '${entrada.key} (${porcentaje.toStringAsFixed(0)}%)';
  }

  void _onBottomNavTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/reciclador_inicio');
        break;
      case 1:
        // Ya estamos en lotes
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/reciclador_ayuda');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/reciclador_perfil');
        break;
    }
  }

  void _navigateToNewLot() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/reciclador_escaneo');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevenir que el botón atrás cierre la sesión
        return false;
      },
      child: Scaffold(
        backgroundColor: BioWayColors.backgroundGrey,
        appBar: AppBar(
        backgroundColor: BioWayColors.ecoceGreen,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Administración de Lotes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white.withValues(alpha: 0.1),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Salida'),
                Tab(text: 'Documentación'),
                Tab(text: 'Finalizados'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent(),
          _buildTabContent(),
          _buildTabContent(),
        ],
      ),
      bottomNavigationBar: _isLoading ? null : RecicladorBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onBottomNavTapped,
        onFabPressed: _navigateToNewLot,
      ),
      floatingActionButton: _isLoading ? null : EcoceFloatingActionButton(
        onPressed: _navigateToNewLot,
        icon: Icons.add,
        backgroundColor: BioWayColors.ecoceGreen,
        tooltip: 'Escanear Nuevo Lote',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: BioWayColors.ecoceGreen),
      );
    }
    
    final tabColor = _getTabColor();
    
    return Column(
      children: [
        // Filtros
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Filtro de materiales
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
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
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              // Filtros de tiempo y presentación
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownFilter(
                      label: 'Tiempo',
                      value: _selectedTiempo,
                      items: ['Esta Semana', 'Este Mes', 'Últimos tres meses', 'Este Año'],
                      onChanged: (value) {
                        setState(() {
                          _selectedTiempo = value!;
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
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Tarjeta de estadísticas
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                tabColor,
                tabColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: tabColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.inventory_2,
                value: _lotesFiltrados.length.toString(),
                label: 'Lotes',
              ),
              _buildStatItem(
                icon: Icons.scale,
                value: '${_lotesFiltrados.fold(0.0, (sum, lote) => sum + (lote.pesoResultante ?? 0.0)).toStringAsFixed(1)} kg',
                label: 'Peso Total',
              ),
              _buildStatItem(
                icon: Icons.category,
                value: _getMaterialMasPredominante(),
                label: 'Predominante',
              ),
            ],
          ),
        ),
        
        // Lista de lotes
        Expanded(
          child: _lotesFiltrados.isEmpty
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
                        'No hay lotes en esta sección',
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
                  itemCount: _lotesFiltrados.length,
                  itemBuilder: (context, index) {
                    final lote = _lotesFiltrados[index];
                    final loteMap = {
                      'id': lote.id,
                      'material': _getTipoPredominante(lote.tipoPoli),
                      'peso': lote.pesoNeto ?? lote.pesoBruto ?? 0.0, // Usar peso neto primero, luego bruto
                      'presentacion': 'Procesado',
                      'origen': lote.nombreOpeEntrada ?? 'Desconocido',
                      'fecha': _formatDate(DateTime.now()), // Temporal
                      'fechaSalida': null,
                      'estado': lote.estado,
                      'tieneDocumentacion': (lote.fTecnicaPellet != null && lote.fTecnicaPellet!.isNotEmpty) || 
                                          (lote.repResultReci != null && lote.repResultReci!.isNotEmpty),
                    };
                    
                    // Para lotes finalizados, usar el estilo original con botón QR lateral
                    if (lote.estado == 'finalizado') {
                      return RecicladorLoteCard(
                        lote: loteMap,
                        onTap: () => _onLoteTap(lote),
                        showActionButton: false,
                        trailing: IconButton(
                          onPressed: () => _onLoteTap(lote),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: BioWayColors.ecoceGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.qr_code,
                              color: BioWayColors.ecoceGreen,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    }
                    
                    // Para otros estados, mostrar con botón de acción
                    return RecicladorLoteCard(
                      lote: loteMap,
                      onTap: () => _onLoteTap(lote),
                      showActionButton: true,
                      actionButtonText: _getActionButtonText(lote.estado),
                      actionButtonColor: _getActionButtonColor(lote.estado),
                      onActionPressed: () => _onLoteTap(lote),
                    );
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

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  void _onLoteTap(LoteRecicladorModel lote) {
    HapticFeedback.lightImpact();
    
    final material = _getTipoPredominante(lote.tipoPoli);
    
    switch (lote.estado) {
      case 'recibido':
      case 'salida':
      case 'procesado':
        // Navegar a formulario de salida
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorFormularioSalida(
              loteId: lote.id!,
              pesoOriginal: lote.pesoNeto ?? 0.0,
            ),
          ),
        );
        break;
      case 'enviado':
        // Navegar a documentación
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorDocumentacion(
              lotId: lote.id!,
            ),
          ),
        );
        break;
      case 'finalizado':
        // Ver código QR
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorLoteQRScreen(
              loteId: lote.id!,
              material: material,
              pesoOriginal: lote.pesoNeto ?? 0.0,
              pesoFinal: lote.pesoResultante,
              presentacion: 'Procesado',
              origen: lote.nombreOpeEntrada ?? 'Desconocido',
              fechaEntrada: DateTime.now(), // Temporal
              fechaSalida: DateTime.now(), // Temporal
            ),
          ),
        );
        break;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// Floating Action Button separado para mayor reusabilidad
