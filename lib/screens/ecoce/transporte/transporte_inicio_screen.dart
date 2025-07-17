import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import 'widgets/transporte_bottom_navigation.dart';
import 'transporte_recoger_screen.dart';
import 'transporte_entregar_screen.dart';
import 'transporte_ayuda_screen.dart';
import 'transporte_perfil_screen.dart';
import '../shared/widgets/qr_scanner_widget.dart';
import '../reciclador/widgets/reciclador_bottom_navigation.dart';

class TransporteInicioScreen extends StatefulWidget {
  const TransporteInicioScreen({super.key});

  @override
  State<TransporteInicioScreen> createState() => _TransporteInicioScreenState();
}

class _TransporteInicioScreenState extends State<TransporteInicioScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Estado del escaneo
  bool _isScanning = false;
  final TextEditingController _manualIdController = TextEditingController();
  bool _showManualInput = false;
  
  // Lotes escaneados temporalmente (para demo)
  final List<Map<String, dynamic>> _lotesEscaneados = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _manualIdController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        // Ya estamos en inicio/recoger
        break;
      case 1:
        NavigationHelper.navigateWithReplacement(
          context: context,
          destination: const TransporteEntregarScreen(),
        );
        break;
      case 2:
        NavigationHelper.navigateWithReplacement(
          context: context,
          destination: const TransporteAyudaScreen(),
        );
        break;
      case 3:
        NavigationHelper.navigateWithReplacement(
          context: context,
          destination: const TransportePerfilScreen(),
        );
        break;
    }
  }

  void _iniciarEscaneo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SharedQRScannerScreen(
          title: 'Escanear Lote',
          subtitle: 'Escanea el código QR del lote',
          onCodeScanned: (code) {
            Navigator.pop(context);
            _procesarEscaneoExitoso(code);
          },
          primaryColor: BioWayColors.deepBlue,
          headerLabel: 'Transportista',
          headerValue: 'T0000001',
          userType: 'transportista',
          scanPrompt: 'Apunta al código QR del lote',
        ),
      ),
    );
  }

  void _procesarEscaneoExitoso(String loteId) {
    setState(() {
      _isScanning = false;
      _lotesEscaneados.add({
        'id': loteId,
        'material': 'PET',
        'peso': 45.5,
        'presentacion': 'Pacas',
        'origen': 'Centro de Acopio Norte',
        'fechaEscaneo': DateTime.now(),
      });
    });
    
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('Lote $loteId escaneado correctamente'),
          ],
        ),
        backgroundColor: BioWayColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _ingresarManualmente() {
    if (_manualIdController.text.isNotEmpty) {
      _procesarEscaneoExitoso(_manualIdController.text);
      _manualIdController.clear();
      setState(() {
        _showManualInput = false;
      });
    }
  }

  void _continuarAlFormulario() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransporteRecogerScreen(
          lotesSeleccionados: _lotesEscaneados,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: BioWayColors.deepBlue,
        elevation: 0,
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/logos/ecoce_logo.svg',
              width: 60,
              height: 30,
            ),
            const SizedBox(width: 12),
            const Text(
              'Escanear para Recoger',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              // TODO: Mostrar historial de escaneos
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _lotesEscaneados.isEmpty ? _buildScannerView() : _buildConfirmacionView(),
      ),
      bottomNavigationBar: TransporteBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildScannerView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // Ilustración de escáner
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BioWayColors.deepBlue.withOpacity(0.1),
                    BioWayColors.deepBlue.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: BioWayColors.deepBlue.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: BioWayColors.deepBlue,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Escanea el código QR',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Apunta al código del lote para iniciar',
                    style: TextStyle(
                      fontSize: 14,
                      color: BioWayColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Botón de iniciar escaneo
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _iniciarEscaneo,
                icon: const Icon(Icons.camera_alt),
                label: const Text(
                  'Iniciar Escaneo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BioWayColors.deepBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Opción manual
            TextButton(
              onPressed: () {
                setState(() {
                  _showManualInput = !_showManualInput;
                });
              },
              child: Text(
                '¿No puedes escanear? Ingresa el ID manualmente',
                style: TextStyle(
                  color: BioWayColors.deepBlue,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            
            // Campo de entrada manual
            if (_showManualInput) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualIdController,
                      decoration: InputDecoration(
                        hintText: 'Ej: FID_1234567',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.keyboard),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _ingresarManualmente,
                    icon: const Icon(Icons.check_circle),
                    color: BioWayColors.success,
                    iconSize: 32,
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 40),
            
            // Información adicional
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BioWayColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: BioWayColors.info.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: BioWayColors.info,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Escanea el código QR del lote para agregarlo a tu carga',
                      style: TextStyle(
                        fontSize: 14,
                        color: BioWayColors.darkGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmacionView() {
    final pesoTotal = _lotesEscaneados.fold<double>(
      0, 
      (sum, lote) => sum + (lote['peso'] as double),
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Mensaje de éxito
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BioWayColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: BioWayColors.success.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: BioWayColors.success,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lotes escaneados correctamente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Puedes continuar escaneando o proceder al formulario',
                          style: TextStyle(
                            fontSize: 14,
                            color: BioWayColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Resumen de carga
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Resumen de Carga',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGrey,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: BioWayColors.deepBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_lotesEscaneados.length} lotes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: BioWayColors.deepBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.scale,
                        color: BioWayColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Peso total: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: BioWayColors.textGrey,
                        ),
                      ),
                      Text(
                        '${pesoTotal.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Lista de lotes escaneados
            ..._lotesEscaneados.map((lote) => _buildLoteCard(lote)).toList(),
            
            const SizedBox(height: 24),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _iniciarEscaneo,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Escanear Otro'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BioWayColors.deepBlue,
                      side: BorderSide(color: BioWayColors.deepBlue),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _continuarAlFormulario,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continuar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BioWayColors.deepBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoteCard(Map<String, dynamic> lote) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BioWayColors.lightGrey,
        ),
      ),
      child: Row(
        children: [
          // Ícono del material
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BioWayColors.petBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                lote['material'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.petBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Información del lote
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: BioWayColors.brightYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    lote['id'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: BioWayColors.darkGrey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildLoteInfo(
                      Icons.scale, 
                      '${lote['peso']} kg',
                    ),
                    const SizedBox(width: 16),
                    _buildLoteInfo(
                      Icons.inventory_2,
                      lote['presentacion'],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: BioWayColors.textGrey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lote['origen'],
                        style: TextStyle(
                          fontSize: 12,
                          color: BioWayColors.textGrey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Botón de eliminar
          IconButton(
            onPressed: () {
              setState(() {
                _lotesEscaneados.remove(lote);
              });
            },
            icon: Icon(
              Icons.close,
              color: BioWayColors.error,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoteInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: BioWayColors.textGrey,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: BioWayColors.darkGrey,
          ),
        ),
      ],
    );
  }
}