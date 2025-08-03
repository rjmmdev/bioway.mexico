import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../utils/qr_utils.dart';
import '../../../services/firebase/auth_service.dart';
import 'laboratorio_registro_muestras.dart';
import 'laboratorio_toma_muestra_megalote_screen.dart';
import 'laboratorio_formulario.dart';
import 'laboratorio_documentacion.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/shared_qr_scanner_screen.dart';

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
  
  // Servicios
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Datos
  bool _isLoading = false;
  List<Map<String, dynamic>> _muestrasAnalisis = [];
  List<Map<String, dynamic>> _muestrasDocumentacion = [];
  List<Map<String, dynamic>> _muestrasFinalizadas = [];

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

  void _loadMuestras() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        debugPrint('[LABORATORIO] No hay usuario autenticado');
        return;
      }
      
      debugPrint('[LABORATORIO] Cargando muestras para usuario: $userId');
      
      // Obtener TODAS las transformaciones que tengan el campo muestras_laboratorio
      // Nota: No podemos filtrar por array-contains con objetos complejos en Firestore
      final transformacionesSnapshot = await _firestore
          .collection('transformaciones')
          .get();
      
      debugPrint('[LABORATORIO] Transformaciones encontradas: ${transformacionesSnapshot.docs.length}');
      
      List<Map<String, dynamic>> todasLasMuestras = [];
      
      for (var doc in transformacionesSnapshot.docs) {
        final data = doc.data();
        
        // Verificar si tiene muestras_laboratorio y no está vacío
        if (data['muestras_laboratorio'] == null || 
            (data['muestras_laboratorio'] is List && (data['muestras_laboratorio'] as List).isEmpty)) {
          continue;
        }
        
        final muestrasLab = List<Map<String, dynamic>>.from(data['muestras_laboratorio'] ?? []);
        
        debugPrint('[LABORATORIO] Transformación ${doc.id} tiene ${muestrasLab.length} muestras');
        
        for (var muestra in muestrasLab) {
          debugPrint('[LABORATORIO] Evaluando muestra:');
          debugPrint('  - usuario_id: ${muestra['usuario_id']}');
          debugPrint('  - laboratorio_id: ${muestra['laboratorio_id']}');
          debugPrint('  - estado: ${muestra['estado']}');
          debugPrint('  - comparando con userId actual: $userId');
          
          if (muestra['usuario_id'] == userId || muestra['laboratorio_id'] == userId) {
            debugPrint('[LABORATORIO] ✓ Muestra coincide con el usuario');
            // Generar un ID si no existe (usando fecha_toma como parte del ID único)
            final muestraId = muestra['id'] ?? 
                '${doc.id.substring(0, 8)}-${muestra['fecha_toma']?.toString().replaceAll(RegExp(r'[^0-9]'), '').substring(0, 6) ?? 'NODATE'}';
            
            // Agregar información del megalote a la muestra
            todasLasMuestras.add({
              ...muestra,
              'id': muestraId, // Asegurar que siempre haya un ID
              'transformacion_id': doc.id,
              'material_predominante': data['material_predominante'] ?? 'Mixto',
              'fecha_megalote': data['fecha_inicio'],
            });
            
            debugPrint('[LABORATORIO] ✓ Muestra agregada a la lista');
          } else {
            debugPrint('[LABORATORIO] ✗ Muestra no coincide con el usuario');
          }
        }
      }
      
      debugPrint('[LABORATORIO] Total de muestras del usuario: ${todasLasMuestras.length}');
      
      // Clasificar las muestras por estado
      // Usar el campo 'estado' que se crea al registrar la muestra
      _muestrasAnalisis = todasLasMuestras.where((m) => 
        m['estado'] == 'pendiente_analisis'
      ).toList();
      
      _muestrasDocumentacion = todasLasMuestras.where((m) => 
        m['estado'] == 'analisis_completado'
      ).toList();
      
      _muestrasFinalizadas = todasLasMuestras.where((m) => 
        m['estado'] == 'documentacion_completada'
      ).toList();
      
      debugPrint('[LABORATORIO] Muestras en Análisis: ${_muestrasAnalisis.length}');
      debugPrint('[LABORATORIO] Muestras en Documentación: ${_muestrasDocumentacion.length}');
      debugPrint('[LABORATORIO] Muestras Finalizadas: ${_muestrasFinalizadas.length}');
      
    } catch (e) {
      debugPrint('Error cargando muestras: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  List<Map<String, dynamic>> get _muestrasFiltradas {
    List<Map<String, dynamic>> muestras;
    
    // Seleccionar muestras según la pestaña activa
    switch (_tabController.index) {
      case 0:
        muestras = _muestrasAnalisis;
        break;
      case 1:
        muestras = _muestrasDocumentacion;
        break;
      case 2:
        muestras = _muestrasFinalizadas;
        break;
      default:
        muestras = [];
    }
    
    // Aplicar filtros
    return muestras.where((muestra) {
      // Filtro por material
      if (_selectedMaterial != 'Todos') {
        final material = muestra['material_predominante'] ?? 'Mixto';
        if (!material.toString().toLowerCase().contains(_selectedMaterial.toLowerCase())) {
          return false;
        }
      }
      
      // Aquí se pueden agregar más filtros si es necesario
      
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
  
  double _calcularPesoTotal() {
    double pesoTotal = 0.0;
    
    // Sumar el peso de todas las muestras filtradas
    for (var muestra in _muestrasFiltradas) {
      pesoTotal += (muestra['peso_muestra'] ?? 0.0).toDouble();
    }
    
    return pesoTotal;
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

  void _navigateToNewMuestra() async {
    HapticFeedback.lightImpact();
    
    // Navegar directamente al escáner QR (como Reciclador y Transformador)
    final qrCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const SharedQRScannerScreen(),
      ),
    );
    
    if (qrCode != null && mounted) {
      // Verificar si es un código QR de muestra de megalote
      if (qrCode.startsWith('MUESTRA-MEGALOTE-')) {
        // Es una muestra de megalote, ir directamente al formulario
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaboratorioTomaMuestraMegaloteScreen(
              qrCode: qrCode,
            ),
          ),
        );
      } else {
        // Es un lote normal, extraer el ID y procesar
        final loteId = QRUtils.extractLoteIdFromQR(qrCode);
        
        // Navegar a la pantalla de registro de muestras
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaboratorioRegistroMuestrasScreen(
              initialMuestraId: loteId,
              isMegaloteSample: false,
            ),
          ),
        );
      }
    }
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
                        _tabController.index == 0 ? Icons.analytics : 
                        _tabController.index == 1 ? Icons.upload_file : Icons.check_circle,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _tabController.index == 0 ? 'No hay muestras pendientes de análisis' :
                        _tabController.index == 1 ? 'No hay muestras pendientes de documentación' :
                        'No hay muestras finalizadas',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_tabController.index == 0)
                        ElevatedButton.icon(
                          onPressed: _navigateToNewMuestra,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Escanear Nueva Muestra'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9333EA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: _muestrasFiltradas.length,
                  itemBuilder: (context, index) {
                    final muestra = _muestrasFiltradas[index];
                    return _buildMuestraCard(muestra);
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
  
  Widget _buildMuestraCard(Map<String, dynamic> muestra) {
    final tabColor = _getTabColor();
    final muestraId = muestra['id'] ?? '';
    final material = muestra['material_predominante'] ?? 'Mixto';
    final peso = (muestra['peso_muestra'] ?? 0.0).toDouble();
    // fecha_toma es un String ISO8601, no un Timestamp
    DateTime fecha;
    if (muestra['fecha_toma'] != null) {
      if (muestra['fecha_toma'] is String) {
        fecha = DateTime.parse(muestra['fecha_toma']);
      } else if (muestra['fecha_toma'] is Timestamp) {
        fecha = (muestra['fecha_toma'] as Timestamp).toDate();
      } else {
        fecha = DateTime.now();
      }
    } else {
      fecha = DateTime.now();
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _tabController.index == 2 ? null : () {
          // Navegar según la pestaña
          _navigateToMuestraDetail(muestra);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con ID y material
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Muestra ${_formatMuestraId(muestraId)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getMaterialColor(material).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                material,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getMaterialColor(material),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Icono de acción según pestaña
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tabColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _tabController.index == 0 ? Icons.analytics :
                      _tabController.index == 1 ? Icons.upload_file :
                      Icons.check_circle,
                      color: tabColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Información adicional
              Row(
                children: [
                  Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${peso.toStringAsFixed(2)} kg',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${fecha.day}/${fecha.month}/${fecha.year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // Botón de acción solo si no está en Finalizadas
              if (_tabController.index != 2) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToMuestraDetail(muestra),
                    icon: Icon(
                      _tabController.index == 0 ? Icons.analytics : Icons.upload_file,
                      size: 18,
                    ),
                    label: Text(
                      _tabController.index == 0 ? 'Realizar Análisis' : 'Subir Documentos',
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tabColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getMaterialColor(String material) {
    switch (material.toUpperCase()) {
      case 'PEBD':
        return BioWayColors.pebdPink;
      case 'PP':
        return BioWayColors.ppPurple;
      case 'MULTILAMINADO':
        return BioWayColors.multilaminadoBrown;
      default:
        return Colors.grey;
    }
  }
  
  String _formatMuestraId(String id) {
    if (id.isEmpty) return 'SIN-ID';
    if (id.length >= 8) {
      return id.substring(0, 8).toUpperCase();
    }
    return id.toUpperCase();
  }
  
  void _navigateToMuestraDetail(Map<String, dynamic> muestra) {
    HapticFeedback.lightImpact();
    
    if (_tabController.index == 0) {
      // Navegar al formulario de análisis
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LaboratorioFormulario(
            muestraId: muestra['id'] ?? '',
            transformacionId: muestra['transformacion_id'] ?? '',
            datosMuestra: muestra,
          ),
        ),
      ).then((_) => _loadMuestras()); // Recargar al volver
    } else if (_tabController.index == 1) {
      // Navegar a la carga de documentación
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LaboratorioDocumentacion(
            muestraId: muestra['id'] ?? '',
            transformacionId: muestra['transformacion_id'],
          ),
        ),
      ).then((_) => _loadMuestras()); // Recargar al volver
    }
  }
}