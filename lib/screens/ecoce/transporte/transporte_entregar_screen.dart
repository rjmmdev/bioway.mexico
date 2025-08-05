import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../utils/ui_constants.dart';
import '../../../services/user_session_service.dart';
import '../../../services/carga_transporte_service.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import 'transporte_entrega_pasos_screen.dart';

class TransporteEntregarScreen extends StatefulWidget {
  const TransporteEntregarScreen({super.key});

  @override
  State<TransporteEntregarScreen> createState() => _TransporteEntregarScreenState();
}

class _TransporteEntregarScreenState extends State<TransporteEntregarScreen> {
  final UserSessionService _userSession = UserSessionService();
  final CargaTransporteService _cargaService = CargaTransporteService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _lotesEnTransito = [];
  Map<String, List<Map<String, dynamic>>> _lotesPorOrigen = {};
  final Set<String> _selectedLotes = {};
  
  @override
  void initState() {
    super.initState();
    _loadLotesEnTransito();
  }
  
  Future<void> _loadLotesEnTransito() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Primero limpiar posibles duplicados
      await _cargaService.limpiarLotesDuplicados();
      
      // Obtener lotes individuales en transporte desde las cargas
      final lotesInfo = await _cargaService.getLotesEnTransporte();
      
      List<Map<String, dynamic>> lotesFormateados = [];
      Map<String, List<Map<String, dynamic>>> grouped = {};
      
      for (var lote in lotesInfo) {
        // Formatear el lote para la vista
        final loteFormateado = {
          'id': lote['lote_id'],
          'carga_id': lote['carga_id'],
          'material': lote['material'],
          'peso': lote['peso'],
          'origen_nombre': lote['origen_nombre'],
          'origen_folio': lote['origen_folio'],
          'fecha_recogida': lote['fecha_recogida'],
          'tiene_muestras_lab': lote['tiene_muestras_lab'],
          'peso_muestras': lote['peso_muestras'],
        };
        
        lotesFormateados.add(loteFormateado);
        
        // Agrupar por origen (nombre del lugar)
        final origenKey = '${lote['origen_nombre']} (${lote['origen_folio']})';
        grouped.putIfAbsent(origenKey, () => []);
        grouped[origenKey]!.add(loteFormateado);
      }
      
      // Ordenar los grupos alfabéticamente por nombre de origen
      final sortedKeys = grouped.keys.toList()..sort();
      final sortedGrouped = <String, List<Map<String, dynamic>>>{};
      for (final key in sortedKeys) {
        sortedGrouped[key] = grouped[key]!;
      }
      
      setState(() {
        _lotesEnTransito = lotesFormateados;
        _lotesPorOrigen = sortedGrouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar lotes: $e'),
            backgroundColor: BioWayColors.error,
          ),
        );
      }
    }
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
  
  void _selectAllFromGroup(String origenKey) {
    setState(() {
      final lotesDelGrupo = _lotesPorOrigen[origenKey] ?? [];
      final idsDelGrupo = lotesDelGrupo.map((lote) => lote['id'] as String).toSet();
      
      // Si todos están seleccionados, deseleccionar todos
      if (idsDelGrupo.every((id) => _selectedLotes.contains(id))) {
        _selectedLotes.removeAll(idsDelGrupo);
      } else {
        // Si no, seleccionar todos
        _selectedLotes.addAll(idsDelGrupo);
      }
    });
  }
  
  void _generateQR() {
    if (_selectedLotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar al menos un lote'),
          backgroundColor: BioWayColors.error,
        ),
      );
      return;
    }
    
    // Obtener los lotes seleccionados
    final lotesSeleccionados = _lotesEnTransito
        .where((lote) => _selectedLotes.contains(lote['id']))
        .map((lote) => lote['id'] as String)
        .toList();
    
    // Navegar al flujo por pasos
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransporteEntregaPasosScreen(
          lotesSeleccionados: lotesSeleccionados,
        ),
      ),
    );
  }
  
  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/transporte_inicio');
        break;
      case 1:
        // Si el usuario hace clic en 'Entregar' estando en la pantalla de entregar,
        // lo llevamos a la pantalla de inicio del transportista
        Navigator.pushReplacementNamed(context, '/transporte_inicio');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/transporte_ayuda');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/transporte_perfil');
        break;
    }
  }
  
  double get _pesoTotalEnTransito => 
      _lotesEnTransito.fold(0.0, (sum, lote) => sum + (lote['peso'] as double));
  
  @override
  Widget build(BuildContext context) {
    final userData = _userSession.userData;
    final userName = userData?['nombre'] ?? 'Usuario';
    final userFolio = userData?['folio'] ?? 'V0000001';
    
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
        children: [
          // Header con gradiente azul
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1490EE), Color(0xFF70B7F9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsetsConstants.paddingAll20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Entregar Materiales',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeTitle,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: UIConstants.spacing8),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: UIConstants.fontSizeBody,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      userFolio,
                      style: const TextStyle(
                        fontSize: UIConstants.fontSizeMedium,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Panel de materiales en tránsito
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Materiales en Tránsito',
                  style: TextStyle(
                    fontSize: UIConstants.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
                SizedBox(height: UIConstants.spacing16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Total de Lotes',
                        _lotesEnTransito.length.toString(),
                        Icons.inventory_2,
                      ),
                    ),
                    SizedBox(width: UIConstants.spacing12),
                    Expanded(
                      child: _buildMetricCard(
                        'Peso Total',
                        '${_pesoTotalEnTransito.toStringAsFixed(1)} kg',
                        Icons.scale,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Lista de lotes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _lotesEnTransito.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_shipping_outlined,
                              size: UIConstants.iconSizeDialog,
                              color: Colors.grey.shade300,
                            ),
                            SizedBox(height: UIConstants.spacing16),
                            Text(
                              'No hay materiales en tránsito',
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeBody,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(
                          top: 8,
                          bottom: _selectedLotes.isNotEmpty ? 100 : 8,
                        ),
                        itemCount: _lotesPorOrigen.length,
                        itemBuilder: (context, index) {
                          final origenKey = _lotesPorOrigen.keys.elementAt(index);
                          final lotes = _lotesPorOrigen[origenKey]!;
                          
                          return _buildOrigenGroup(origenKey, lotes);
                        },
                      ),
          ),
        ],
      ),
      
      // Banda fija inferior
      bottomSheet: _selectedLotes.isNotEmpty
          ? Container(
              padding: EdgeInsetsConstants.paddingAll16,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: UIConstants.opacityLow),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_selectedLotes.length} ${_selectedLotes.length == 1 ? 'lote seleccionado' : 'lotes seleccionados'}',
                        style: const TextStyle(
                          fontSize: UIConstants.fontSizeBody,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _generateQR,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Generar QR de Entrega'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1490EE),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusConstants.borderRadiusRound,
                        ),
                      ),
                      key: const Key('btn_generate_qr'),
                    ),
                  ],
                ),
              ),
            )
          : null,
      
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: 1,
        onItemTapped: _onBottomNavTapped,
        primaryColor: const Color(0xFF1490EE),
        items: const [
          NavigationItem(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Recoger',
            testKey: 'transporte_nav_recoger',
          ),
          NavigationItem(
            icon: Icons.local_shipping_rounded,
            label: 'Entregar',
            testKey: 'transporte_nav_entregar',
          ),
          NavigationItem(
            icon: Icons.help_outline_rounded,
            label: 'Ayuda',
            testKey: 'transporte_nav_ayuda',
          ),
          NavigationItem(
            icon: Icons.person_outline_rounded,
            label: 'Perfil',
            testKey: 'transporte_nav_perfil',
          ),
        ],
        fabConfig: null,
      ),
      ),
    );
  }
  
  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadiusConstants.borderRadiusMedium,
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1490EE), size: UIConstants.iconSizeMedium),
          SizedBox(width: UIConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: UIConstants.fontSizeXSmall,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: UIConstants.spacing4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: UIConstants.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrigenGroup(String origenKey, List<Map<String, dynamic>> lotes) {
    final allSelected = lotes.every((lote) => _selectedLotes.contains(lote['id']));
    final totalPesoGrupo = lotes.fold(0.0, (sum, lote) => sum + (lote['peso'] as double));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header del grupo con información del origen
        Container(
          margin: EdgeInsets.symmetric(horizontal: UIConstants.spacing16, vertical: UIConstants.spacing4),
          decoration: BoxDecoration(
            color: const Color(0xFF1490EE).withValues(alpha: UIConstants.opacityLow),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(UIConstants.radiusMedium),
              topRight: Radius.circular(UIConstants.radiusMedium),
            ),
            border: Border.all(
              color: const Color(0xFF1490EE).withValues(alpha: UIConstants.opacityMedium),
              width: UIConstants.dividerThickness,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing16, vertical: UIConstants.spacing12),
            child: Row(
              children: [
                // Ícono de ubicación
                Container(
                  padding: EdgeInsetsConstants.paddingAll8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadiusConstants.borderRadiusSmall,
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: const Color(0xFF1490EE),
                    size: UIConstants.iconSizeMedium,
                  ),
                ),
                SizedBox(width: UIConstants.spacing12),
                
                // Información del origen
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        origenKey,
                        style: const TextStyle(
                          fontSize: UIConstants.fontSizeBody,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGreen,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      SizedBox(height: UIConstants.spacing4),
                      Wrap(
                        spacing: UIConstants.spacing8,
                        runSpacing: 4,
                        children: [
                          Text(
                            '${lotes.length} ${lotes.length == 1 ? 'lote' : 'lotes'}',
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeSmall,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Container(
                            width: UIConstants.spacing4,
                            height: UIConstants.spacing4,
                            margin: EdgeInsets.only(top: UIConstants.spacing4 + 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            '${totalPesoGrupo.toStringAsFixed(1)} kg total',
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeSmall,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Botón de selección
                SizedBox(width: UIConstants.spacing8),
                TextButton(
                  onPressed: () => _selectAllFromGroup(origenKey),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing8, vertical: UIConstants.spacing4 + 2),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    allSelected ? 'Deseleccionar' : 'Seleccionar',
                    style: const TextStyle(
                      color: Color(0xFF1490EE),
                      fontWeight: FontWeight.w600,
                      fontSize: UIConstants.fontSizeXSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Container para los lotes con borde
        Container(
          margin: EdgeInsets.only(left: UIConstants.spacing16, right: UIConstants.spacing16, bottom: UIConstants.spacing16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(UIConstants.radiusMedium),
              bottomRight: Radius.circular(UIConstants.radiusMedium),
            ),
            border: Border.all(
              color: Colors.grey.shade200,
              width: UIConstants.dividerThickness,
            ),
          ),
          child: Column(
            children: [
              // Lista de lotes del grupo
              ...lotes.asMap().entries.map((entry) {
                final index = entry.key;
                final lote = entry.value;
                final isLast = index == lotes.length - 1;
                
                return Column(
                  children: [
                    _buildLoteItem(lote),
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade100,
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoteItem(Map<String, dynamic> lote) {
    final isSelected = _selectedLotes.contains(lote['id']);
    
    return InkWell(
      onTap: () => _toggleLoteSelection(lote['id']),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1490EE) : Colors.white,
                border: Border.all(
                  color: isSelected ? const Color(0xFF1490EE) : Colors.grey.shade400,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isSelected
                  ? const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                  : null,
            ),
            
            SizedBox(width: UIConstants.spacing12),
            
            // Contenido del lote
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primera fila: ID y Material
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // ID del lote
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          lote['id'].toString().substring(0, 8),
                          style: const TextStyle(
                            fontSize: UIConstants.fontSizeXSmall,
                            fontWeight: FontWeight.w600,
                            color: BioWayColors.darkGreen,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      // Material
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              lote['material'],
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeMedium,
                                color: Colors.grey.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Segunda fila: Peso y muestra de laboratorio
                  Row(
                    children: [
                      // Peso
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.scale_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${lote['peso']} kg',
                            style: const TextStyle(
                              fontSize: UIConstants.fontSizeMedium,
                              fontWeight: FontWeight.w600,
                              color: BioWayColors.darkGreen,
                            ),
                          ),
                        ],
                      ),
                      // Indicador de muestras de laboratorio
                      if (lote['tiene_muestras_lab'] == true) ...[
                        SizedBox(width: UIConstants.spacing12),
                        Tooltip(
                          message: 'Muestras de laboratorio: ${lote['peso_muestras']} kg',
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: BioWayColors.psYellow.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.science,
                              size: 16,
                              color: BioWayColors.psYellow,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
}