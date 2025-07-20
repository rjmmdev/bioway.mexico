import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import '../../../utils/colors.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/unified_stat_card.dart';
import '../shared/utils/dialog_utils.dart';
import 'transporte_services.dart';
import 'transporte_forms_screen.dart';

/// Unified delivery screen combining lot selection and QR generation
class TransporteDeliveryScreen extends StatefulWidget {
  const TransporteDeliveryScreen({super.key});

  @override
  State<TransporteDeliveryScreen> createState() => _TransporteDeliveryScreenState();
}

class _TransporteDeliveryScreenState extends State<TransporteDeliveryScreen> {
  DeliveryState _currentState = DeliveryState.selecting;
  final List<Map<String, dynamic>> _selectedLots = [];
  
  // QR generation state
  String? _qrData;
  DateTime? _qrExpirationTime;
  Timer? _qrTimer;
  String _recipientId = '';
  final TextEditingController _recipientController = TextEditingController();
  Map<String, dynamic>? _recipientData;
  
  // Mock in-transit lots
  final List<Map<String, dynamic>> _inTransitLots = [
    {
      'id': 'LOTE-PEBD-004',
      'material': 'PEBD',
      'peso': 245.5,
      'origen': 'Centro Acopio Norte',
      'fechaRecogida': DateTime.now().subtract(const Duration(hours: 3)),
      'selected': false,
    },
    {
      'id': 'LOTE-PP-005',
      'material': 'PP',
      'peso': 180.0,
      'origen': 'Centro Acopio Norte',
      'fechaRecogida': DateTime.now().subtract(const Duration(hours: 3)),
      'selected': false,
    },
    {
      'id': 'LOTE-MULTI-006',
      'material': 'Multi',
      'peso': 320.0,
      'origen': 'Planta Separación Este',
      'fechaRecogida': DateTime.now().subtract(const Duration(days: 1)),
      'selected': false,
    },
  ];

  @override
  void dispose() {
    _qrTimer?.cancel();
    _recipientController.dispose();
    super.dispose();
  }

  void _toggleLotSelection(int index) {
    setState(() {
      _inTransitLots[index]['selected'] = !_inTransitLots[index]['selected'];
      
      if (_inTransitLots[index]['selected']) {
        _selectedLots.add(_inTransitLots[index]);
      } else {
        _selectedLots.removeWhere((lot) => lot['id'] == _inTransitLots[index]['id']);
      }
    });
  }

  void _selectAll() {
    setState(() {
      for (var lot in _inTransitLots) {
        lot['selected'] = true;
      }
      _selectedLots.clear();
      _selectedLots.addAll(_inTransitLots);
    });
  }

  void _deselectAll() {
    setState(() {
      for (var lot in _inTransitLots) {
        lot['selected'] = false;
      }
      _selectedLots.clear();
    });
  }

  Future<void> _searchRecipient() async {
    final query = _recipientController.text.trim();
    if (query.isEmpty) return;
    
    DialogUtils.showLoadingDialog(
      context: context,
      message: 'Buscando destinatario...',
    );
    
    try {
      final recipient = await TransporteServices.searchRecipient(query);
      
      if (mounted) DialogUtils.hideLoadingDialog(context);
      
      if (recipient != null && recipient.isNotEmpty) {
        setState(() {
          _recipientData = recipient;
          _recipientId = recipient['id'];
        });
      } else {
        if (mounted) {
          DialogUtils.showErrorDialog(
            context: context,
            title: 'No encontrado',
            message: 'No se encontró un destinatario con ese ID o folio',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        DialogUtils.hideLoadingDialog(context);
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al buscar destinatario',
        );
      }
    }
  }

  void _generateQR() {
    if (_selectedLots.isEmpty) {
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Sin lotes',
        message: 'Selecciona al menos un lote para entregar',
      );
      return;
    }
    
    if (_recipientId.isEmpty || _recipientData == null) {
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Destinatario requerido',
        message: 'Busca y selecciona un destinatario válido',
      );
      return;
    }
    
    setState(() {
      _currentState = DeliveryState.qrGenerated;
      _qrData = TransporteServices.generateDeliveryQR(
        lotIds: _selectedLots.map((lot) => lot['id'] as String).toList(),
        transportId: TransporteServices.generateTransportId(),
        recipientId: _recipientId,
      );
      _qrExpirationTime = DateTime.now().add(
        const Duration(minutes: TransporteServices.qrExpirationMinutes),
      );
    });
    
    // Start countdown timer
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_qrExpirationTime != null && DateTime.now().isAfter(_qrExpirationTime!)) {
        _qrTimer?.cancel();
        if (mounted) {
          setState(() {
            _currentState = DeliveryState.selecting;
            _qrData = null;
            _qrExpirationTime = null;
          });
          DialogUtils.showErrorDialog(
            context: context,
            title: 'QR Expirado',
            message: 'El código QR ha expirado. Genera uno nuevo.',
          );
        }
      } else {
        if (mounted) setState(() {}); // Update timer display
      }
    });
  }

  void _proceedToForm() {
    _qrTimer?.cancel();
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TransporteFormsScreen.delivery(
          lots: _selectedLots,
          recipientData: _recipientData!,
          qrData: _qrData!,
        ),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/transporte_recoger');
        break;
      case 1:
        // Already on entregar
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/transporte_ayuda');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/transporte_perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: _currentState == DeliveryState.selecting
            ? _buildSelectionView()
            : _buildQRView(),
      ),
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: 1,
        onItemTapped: _onBottomNavTapped,
        primaryColor: BioWayColors.petBlue,
        items: EcoceNavigationConfigs.transporteItems,
        fabConfig: null, // Transportista no tiene FAB
      ),
    );
  }

  Widget _buildSelectionView() {
    final totalWeight = TransporteServices.calculateTotalWeight(_selectedLots);
    final groupedLots = TransporteServices.groupLotsByOrigin(_inTransitLots);
    
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => Navigator.pop(context),
                    color: BioWayColors.darkGreen,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Entregar Lotes',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                        Text(
                          'Selecciona los lotes a entregar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'select_all') {
                        _selectAll();
                      } else if (value == 'deselect_all') {
                        _deselectAll();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'select_all',
                        child: Text('Seleccionar todos'),
                      ),
                      const PopupMenuItem(
                        value: 'deselect_all',
                        child: Text('Deseleccionar todos'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Recipient search
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _recipientController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'ID o Folio del destinatario',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      onFieldSubmitted: (_) => _searchRecipient(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _searchRecipient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BioWayColors.petBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Buscar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              if (_recipientData != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BioWayColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: BioWayColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: BioWayColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _recipientData!['nombre'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${_recipientData!['tipo']} • ${_recipientData!['id']}',
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
              if (_selectedLots.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Seleccionados',
                        value: _selectedLots.length.toString(),
                        icon: Icons.check_box,
                        iconColor: BioWayColors.petBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Peso Total',
                        value: '${totalWeight.toStringAsFixed(1)} kg',
                        icon: Icons.scale,
                        iconColor: BioWayColors.info,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        // Lots list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: groupedLots.length,
            itemBuilder: (context, groupIndex) {
              final origin = groupedLots.keys.elementAt(groupIndex);
              final lots = groupedLots[origin]!;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (groupIndex > 0) const SizedBox(height: 20),
                  // Origin header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: BioWayColors.petBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 18,
                          color: BioWayColors.petBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            origin,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: BioWayColors.darkGreen,
                            ),
                          ),
                        ),
                        Text(
                          '${lots.length} ${lots.length == 1 ? 'lote' : 'lotes'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Lots for this origin
                  ...lots.map((lot) {
                    final index = _inTransitLots.indexOf(lot);
                    return _buildLotCard(lot, index);
                  }),
                ],
              );
            },
          ),
        ),
        
        // Generate QR button
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedLots.isNotEmpty && _recipientData != null
                  ? _generateQR
                  : null,
              icon: const Icon(Icons.qr_code),
              label: const Text('Generar Código QR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BioWayColors.petBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRView() {
    final timeRemaining = _qrExpirationTime != null
        ? TransporteServices.getTimeRemaining(_qrExpirationTime!)
        : 'Expirado';
    final isExpired = timeRemaining == 'Expirado';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            BioWayColors.petBlue,
            BioWayColors.petBlue.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _currentState = DeliveryState.selecting;
                      _qrData = null;
                      _qrExpirationTime = null;
                      _qrTimer?.cancel();
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    'Código QR de Entrega',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // QR Code container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Timer
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isExpired
                                ? BioWayColors.error.withValues(alpha: 0.1)
                                : BioWayColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isExpired ? Icons.error : Icons.timer,
                                size: 18,
                                color: isExpired
                                    ? BioWayColors.error
                                    : BioWayColors.warning,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isExpired ? 'Código expirado' : 'Expira en: $timeRemaining',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isExpired
                                      ? BioWayColors.error
                                      : BioWayColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // QR Code
                        if (!isExpired && _qrData != null)
                          QrImageView(
                            data: _qrData!,
                            version: QrVersions.auto,
                            size: 250,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                          )
                        else
                          Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.qr_code,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        // Recipient info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.business,
                                    size: 20,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _recipientData!['nombre'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.badge,
                                    size: 20,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_recipientData!['tipo']} • ${_recipientData!['id']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Instrucciones:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInstruction(
                          '1',
                          'Muestra este código al destinatario',
                        ),
                        _buildInstruction(
                          '2',
                          'El destinatario debe escanear el código',
                        ),
                        _buildInstruction(
                          '3',
                          'Una vez confirmado, continúa con el formulario',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: !isExpired ? _proceedToForm : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continuar con Formulario'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: BioWayColors.petBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLotCard(Map<String, dynamic> lot, int index) {
    final material = lot['material'] as String;
    final materialColor = TransporteServices.getMaterialColor(material);
    final isSelected = lot['selected'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected ? materialColor.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: () => _toggleLotSelection(index),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleLotSelection(index),
                  activeColor: BioWayColors.petBlue,
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: materialColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    TransporteServices.getMaterialIcon(material),
                    color: materialColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lot['id'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$material • ${TransporteServices.formatWeight(lot['peso'])}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Recogido ${TransporteServices.formatDateTime(lot['fechaRecogida'])}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
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
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: BioWayColors.petBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.petBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}