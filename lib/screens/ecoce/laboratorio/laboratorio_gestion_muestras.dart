import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../models/lotes/lote_unificado_model.dart';
import 'laboratorio_escaneo.dart';
import 'laboratorio_formulario.dart';
import 'laboratorio_documentacion.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import 'widgets/laboratorio_muestra_card.dart';

class LaboratorioGestionMuestras extends StatefulWidget {
  final int initialTab;
  
  const LaboratorioGestionMuestras({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<LaboratorioGestionMuestras> createState() => _LaboratorioGestionMuestrasState();
}

class _LaboratorioGestionMuestrasState extends State<LaboratorioGestionMuestras> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Filtros
  String _selectedMaterial = 'Todos';
  String _selectedTiempo = 'Este Mes';
  String _selectedPresentacion = 'Todos';
  
  // Bottom navigation
  final int _selectedIndex = 1; // Muestras está seleccionado
  
  // Servicio y datos
  final LoteUnificadoService _loteService = LoteUnificadoService();
  List<LoteUnificadoModel> _todosLotes = [];
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
    _loadMuestras();
  }

  void _loadMuestras() {
    _loteService.obtenerLotesConAnalisisLaboratorio().listen((lotes) {
      if (mounted) {
        setState(() {
          _todosLotes = lotes;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      debugPrint('Error cargando lotes con análisis: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }
  
  void _handleSearch(String value) {
    // Implementar búsqueda si es necesario
    setState(() {});
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
              value: _selectedTiempo,
              decoration: const InputDecoration(
                labelText: 'Periodo',
                border: OutlineInputBorder(),
              ),
              items: ['Esta Semana', 'Este Mes', 'Últimos tres meses', 'Este Año']
                  .map((time) => DropdownMenuItem(
                        value: time,
                        child: Text(time),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTiempo = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<LoteUnificadoModel> get _muestrasFiltradas {
    // Para cada lote, obtener solo los análisis del usuario actual
    final userId = _loteService.currentUserId;
    
    return _todosLotes.where((lote) {
      // Filtrar por material
      if (_selectedMaterial != 'Todos' && lote.datosGenerales.tipoMaterial != _selectedMaterial) {
        return false;
      }
      
      // Obtener análisis del usuario actual
      final analisisUsuario = lote.analisisLaboratorio.where(
        (analisis) => analisis.usuarioId == userId
      ).toList();
      
      if (analisisUsuario.isEmpty) return false;
      
      // Filtrar por estado según la pestaña
      switch (_tabController.index) {
        case 0: // Pendientes de análisis
          // Lotes que aún no tienen certificado
          return analisisUsuario.any((a) => a.certificado == null);
        case 1: // Pendientes de documentación
          // Lotes con certificado pero sin todos los documentos
          return analisisUsuario.any((a) => 
            a.certificado != null && a.evidenciasFoto.isEmpty
          );
        case 2: // Finalizados
          // Lotes con certificado y documentación completa
          return analisisUsuario.any((a) => 
            a.certificado != null && a.evidenciasFoto.isNotEmpty
          );
      }
      
      return true;
    }).toList();
  }

  Color _getTabColor() {
    switch (_tabController.index) {
      case 0:
        return const Color(0xFF9333EA); // Morado para análisis
      case 1:
        return BioWayColors.warning; // Naranja para documentación  
      case 2:
        return BioWayColors.success; // Verde para finalizados
      default:
        return const Color(0xFF9333EA);
    }
  }

  // Obtener texto del botón según el estado
  String _getActionButtonText(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Análisis';
      case 'analizado':
        return 'Añadir Documentación';
      case 'finalizado':
        return 'Ver Resultados';
      default:
        return '';
    }
  }

  // Obtener color del botón según el estado
  Color _getActionButtonColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFF9333EA); // Morado para análisis
      case 'analizado':
        return BioWayColors.warning; // Naranja para documentación
      case 'finalizado':
        return BioWayColors.success; // Verde para finalizados
      default:
        return const Color(0xFF9333EA);
    }
  }


  void _onBottomNavTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/laboratorio_inicio');
        break;
      case 1:
        // Ya estamos en muestras
        break;
      case 2:
        Navigator.pushNamed(context, '/laboratorio_ayuda');
        break;
      case 3:
        Navigator.pushNamed(context, '/laboratorio_perfil');
        break;
    }
  }

  void _navigateToNewMuestra() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LaboratorioEscaneoScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF9333EA), // Morado laboratorio
          elevation: 0,
          title: const Text(
            'Gestión de Muestras',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: _showFilterDialog,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF9333EA), // Morado laboratorio
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF9333EA), // Morado laboratorio
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Análisis'),
                  Tab(text: 'Documentación'),
                  Tab(text: 'Finalizadas'),
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
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        onChanged: _handleSearch,
                        decoration: InputDecoration(
                          hintText: 'Buscar por ID de lote...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Lista de muestras
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _loadMuestras();
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent(),
                    _buildTabContent(),
                    _buildTabContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onBottomNavTapped,
        primaryColor: const Color(0xFF9333EA),
        items: const [
          NavigationItem(
            icon: Icons.home,
            label: 'Inicio',
            testKey: 'laboratorio_nav_inicio',
          ),
          NavigationItem(
            icon: Icons.science,
            label: 'Muestras',
            testKey: 'laboratorio_nav_muestras',
          ),
          NavigationItem(
            icon: Icons.help_outline,
            label: 'Ayuda',
            testKey: 'laboratorio_nav_ayuda',
          ),
          NavigationItem(
            icon: Icons.person,
            label: 'Perfil',
            testKey: 'laboratorio_nav_perfil',
          ),
        ],
        fabConfig: FabConfig(
          icon: Icons.add,
          onPressed: _navigateToNewMuestra,
          tooltip: 'Nueva muestra',
        ),
      ),
      floatingActionButton: EcoceFloatingActionButton(
        onPressed: _navigateToNewMuestra,
        icon: Icons.add,
        backgroundColor: const Color(0xFF9333EA),
        tooltip: 'Nueva muestra',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF9333EA)),
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
                      items: ['Todos', 'Muestra'],
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
        
        // Tarjeta de estadísticas con diseño moderno
        Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
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
                        child: Icon(Icons.science, color: tabColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _muestrasFiltradas.length.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Muestras',
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
                              '${_calcularPesoTotal().toStringAsFixed(1)} kg',
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
        ),
        
        // Lista de muestras
        Expanded(
          child: _muestrasFiltradas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.science_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay muestras en esta sección',
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
                  itemCount: _muestrasFiltradas.length,
                  itemBuilder: (context, index) {
                    final lote = _muestrasFiltradas[index];
                    final userId = _loteService.currentUserId;
                    // Obtener el último análisis del usuario actual
                    final analisisUsuario = lote.analisisLaboratorio
                        .where((a) => a.usuarioId == userId)
                        .toList();
                    if (analisisUsuario.isEmpty) return const SizedBox.shrink();
                    
                    final ultimoAnalisis = analisisUsuario.last;
                    final estado = _determinarEstadoAnalisis(ultimoAnalisis);
                    
                    final muestraMap = {
                      'id': lote.id,
                      'analisisId': ultimoAnalisis.id,
                      'material': lote.datosGenerales.tipoMaterial,
                      'peso': ultimoAnalisis.pesoMuestra,
                      'presentacion': 'Muestra',
                      'origen': lote.origen?.usuarioFolio ?? 'Desconocido',
                      'fecha': _formatDate(ultimoAnalisis.fechaToma),
                      'fechaAnalisis': _formatDate(ultimoAnalisis.fechaToma),
                      'estado': estado,
                      'tieneDocumentacion': ultimoAnalisis.evidenciasFoto.isNotEmpty,
                    };
                    
                    return _buildMuestraCard(lote, ultimoAnalisis);
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


  void _onMuestraTap(LoteUnificadoModel lote, AnalisisLaboratorioData analisis) {
    HapticFeedback.lightImpact();
    
    final estado = _determinarEstadoAnalisis(analisis);
    
    switch (estado) {
      case 'pendiente':
        // Navegar a formulario de análisis
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaboratorioFormulario(
              muestraId: analisis.id,
              peso: analisis.pesoMuestra,
            ),
          ),
        );
        break;
      case 'analizado':
        // Navegar a documentación
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaboratorioDocumentacion(
              muestraId: analisis.id,
            ),
          ),
        );
        break;
      case 'finalizado':
        // Ver resultados de análisis
        _showResultadosDialog(lote, analisis);
        break;
    }
  }

  void _showResultadosDialog(LoteUnificadoModel lote, AnalisisLaboratorioData analisis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resultados de Análisis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID Lote: ${lote.id.substring(0, 8).toUpperCase()}'),
            Text('Material: ${lote.datosGenerales.tipoMaterial}'),
            Text('Peso Muestra: ${analisis.pesoMuestra} kg'),
            const SizedBox(height: 8),
            Text('Fecha de Toma: ${_formatDate(analisis.fechaToma)}'),
            if (analisis.certificado != null) ...[
              const SizedBox(height: 8),
              const Text('Certificado: Disponible', style: TextStyle(color: Colors.green)),
            ],
            if (analisis.evidenciasFoto.isNotEmpty) ...[
              Text('Evidencias: ${analisis.evidenciasFoto.length} fotos'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
  
  double _calcularPesoTotal() {
    final userId = _loteService.currentUserId;
    double total = 0.0;
    
    for (final lote in _muestrasFiltradas) {
      final analisisUsuario = lote.analisisLaboratorio
          .where((a) => a.usuarioId == userId)
          .toList();
      
      for (final analisis in analisisUsuario) {
        total += analisis.pesoMuestra;
      }
    }
    
    return total;
  }
  
  String _determinarEstadoAnalisis(AnalisisLaboratorioData analisis) {
    if (analisis.certificado == null) {
      return 'pendiente';
    } else if (analisis.evidenciasFoto.isEmpty) {
      return 'analizado';
    } else {
      return 'finalizado';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  Widget _buildMuestraCard(LoteUnificadoModel lote, AnalisisLaboratorioData analisis) {
    final estado = _determinarEstadoAnalisis(analisis);
    final material = lote.datosGenerales.tipoMaterial;
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (estado) {
      case 'pendiente':
        statusColor = Colors.orange;
        statusText = 'Pendiente de análisis';
        statusIcon = Icons.pending_actions;
        break;
      case 'analizado':
        statusColor = Colors.blue;
        statusText = 'Pendiente de documentación';
        statusIcon = Icons.description;
        break;
      case 'finalizado':
        statusColor = Colors.green;
        statusText = 'Finalizado';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Desconocido';
        statusIcon = Icons.help_outline;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _onMuestraTap(lote, analisis),
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
                      value: material,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.scale,
                      label: 'Peso Muestra',
                      value: '${analisis.pesoMuestra} kg',
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
                      label: 'Fecha',
                      value: _formatDate(analisis.fechaToma),
                      fontSize: 12,
                    ),
                  ),
                  if (lote.origen != null)
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.business,
                        label: 'Origen',
                        value: lote.origen!.usuarioFolio ?? 'Desconocido',
                        fontSize: 12,
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
        Icon(
          icon,
          size: 16,
          color: color ?? Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: color ?? Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}