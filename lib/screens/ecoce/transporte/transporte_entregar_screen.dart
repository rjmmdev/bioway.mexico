import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../services/user_session_service.dart';
import '../../../services/lote_service.dart';
import '../../../models/lotes/lote_transportista_model.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import 'transporte_qr_entrega_screen.dart';

class TransporteEntregarScreen extends StatefulWidget {
  const TransporteEntregarScreen({super.key});

  @override
  State<TransporteEntregarScreen> createState() => _TransporteEntregarScreenState();
}

class _TransporteEntregarScreenState extends State<TransporteEntregarScreen> {
  final UserSessionService _userSession = UserSessionService();
  final LoteService _loteService = LoteService();
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
      
      // Obtener lotes de transportista con estado 'en_transporte'
      final lotesTransportista = await _loteService.getLotesTransportista(estado: 'en_transporte').first;
      
      List<Map<String, dynamic>> lotesFormateados = [];
      
      for (var loteTransportista in lotesTransportista) {
        // Obtener información de los lotes originales
        final lotesInfo = await _loteService.getLotesInfo(loteTransportista.lotesEntrada);
        
        // Determinar el material predominante
        String materialPredominante = 'Mixto';
        if (lotesInfo.isNotEmpty) {
          final tipoPolimeros = await _loteService.calcularTipoPolimeroPredominante(loteTransportista.lotesEntrada);
          if (tipoPolimeros.isNotEmpty) {
            materialPredominante = tipoPolimeros.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key;
          }
        }
        
        // Formatear el lote para la vista
        lotesFormateados.add({
          'id': loteTransportista.id,
          'material': materialPredominante,
          'peso': loteTransportista.pesoRecibido,
          'origen': loteTransportista.direccionOrigen,
          'presentacion': 'Pacas', // TODO: Obtener del lote original
          'fecha_carga': loteTransportista.fechaRecepcion,
          'lotes_originales': loteTransportista.lotesEntrada,
        });
      }
      
      // Agrupar por origen
      Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var lote in lotesFormateados) {
        final origen = lote['origen'] as String;
        grouped.putIfAbsent(origen, () => []);
        grouped[origen]!.add(lote);
      }
      
      setState(() {
        _lotesEnTransito = lotesFormateados;
        _lotesPorOrigen = grouped;
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
  
  void _selectAllFromGroup(String origen) {
    setState(() {
      final lotesDelGrupo = _lotesPorOrigen[origen] ?? [];
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
        .toList();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransporteQREntregaScreen(
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
        break; // Ya estamos aquí
      case 2:
        Navigator.pushNamed(context, '/transporte_ayuda');
        break;
      case 3:
        Navigator.pushNamed(context, '/transporte_perfil');
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
    
    return Scaffold(
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Entregar Materiales',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      userFolio,
                      style: const TextStyle(
                        fontSize: 14,
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Total de Lotes',
                        _lotesEnTransito.length.toString(),
                        Icons.inventory_2,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay materiales en tránsito',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _lotesPorOrigen.length,
                        itemBuilder: (context, index) {
                          final origen = _lotesPorOrigen.keys.elementAt(index);
                          final lotes = _lotesPorOrigen[origen]!;
                          
                          return _buildOrigenGroup(origen, lotes);
                        },
                      ),
          ),
        ],
      ),
      
      // Banda fija inferior
      bottomSheet: _selectedLotes.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
                          fontSize: 16,
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
                          borderRadius: BorderRadius.circular(24),
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
    );
  }
  
  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1490EE), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
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
  
  Widget _buildOrigenGroup(String origen, List<Map<String, dynamic>> lotes) {
    final allSelected = lotes.every((lote) => _selectedLotes.contains(lote['id']));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header del grupo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  origen,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _selectAllFromGroup(origen),
                child: Text(
                  allSelected ? 'Deseleccionar Todos' : 'Seleccionar Todos',
                  style: TextStyle(
                    color: const Color(0xFF1490EE),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                key: Key('btn_select_group_$origen'),
              ),
            ],
          ),
        ),
        
        // Lista de lotes del grupo
        ...lotes.map((lote) => _buildLoteCard(lote)),
      ],
    );
  }
  
  Widget _buildLoteCard(Map<String, dynamic> lote) {
    final isSelected = _selectedLotes.contains(lote['id']);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF1490EE) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _toggleLoteSelection(lote['id']),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 24,
                height: 24,
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
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              
              const SizedBox(width: 16),
              
              // Contenido del lote
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chip con ID
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9C4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFD54F)),
                      ),
                      child: Text(
                        lote['id'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF827717),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Datos del lote
                    Row(
                      children: [
                        _buildLoteData('Material', lote['material']),
                        const SizedBox(width: 16),
                        _buildLoteData('Peso', '${lote['peso']} kg'),
                        const SizedBox(width: 16),
                        _buildLoteData('Formato', lote['presentacion']),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoteData(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: BioWayColors.darkGreen,
          ),
        ),
      ],
    );
  }
}