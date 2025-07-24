import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../utils/colors.dart';
import '../../../services/firebase/ecoce_profile_service.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/utils/dialog_utils.dart';
import 'transporte_qr_entrega_screen.dart';
import 'transporte_escanear_carga_screen.dart';

class TransporteEscanearReceptorScreen extends StatefulWidget {
  final List<Map<String, dynamic>> lotesSeleccionados;
  
  const TransporteEscanearReceptorScreen({
    super.key,
    required this.lotesSeleccionados,
  });

  @override
  State<TransporteEscanearReceptorScreen> createState() => _TransporteEscanearReceptorScreenState();
}

class _TransporteEscanearReceptorScreenState extends State<TransporteEscanearReceptorScreen> {
  final EcoceProfileService _profileService = EcoceProfileService();
  
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  bool _flashEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  void _initScanner() {
    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _procesarCodigoQR(String codigo) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Validar formato del código QR del usuario
      if (!codigo.startsWith('USER-')) {
        _mostrarError('Este no es un código QR de usuario válido');
        return;
      }
      
      // Extraer información del código
      final partes = codigo.split('-');
      if (partes.length < 3) {
        _mostrarError('Formato de código QR inválido');
        return;
      }
      
      final tipoUsuario = partes[1].toLowerCase();
      final userId = partes[2];
      
      // Validar tipo de usuario (solo puede entregar a reciclador, laboratorio o transformador)
      if (!['reciclador', 'laboratorio', 'transformador'].contains(tipoUsuario)) {
        _mostrarError('Solo puedes entregar a Recicladores, Laboratorios o Transformadores');
        return;
      }
      
      // Obtener información del usuario receptor
      final perfilReceptor = await _profileService.getProfileByUserId(userId);
      
      if (perfilReceptor == null) {
        _mostrarError('Usuario receptor no encontrado');
        return;
      }
      
      // Verificar que el usuario esté aprobado
      if (!perfilReceptor.isApproved) {
        _mostrarError('El usuario receptor no está aprobado para recibir materiales');
        return;
      }
      
      // Datos del receptor para pasar a la siguiente pantalla
      final datosReceptor = {
        'id': userId,
        'tipo': tipoUsuario,
        'folio': perfilReceptor.ecoceFolio,
        'nombre': perfilReceptor.ecoceNombre,
        'direccion': _construirDireccion(perfilReceptor),
      };
      
      // Vibración de éxito
      HapticFeedback.mediumImpact();
      
      // Navegar a la pantalla de generación de QR de entrega
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TransporteQREntregaScreen(
              lotesSeleccionados: widget.lotesSeleccionados,
              datosReceptor: datosReceptor,
            ),
          ),
        );
      }
      
    } catch (e) {
      print('Error al procesar QR: $e');
      _mostrarError('Error al procesar el código QR');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  String _construirDireccion(dynamic perfil) {
    final calle = perfil.ecoceCalle ?? '';
    final numExt = perfil.ecoceNumExt ?? '';
    final numInt = perfil.ecoceNumInt ?? '';
    final colonia = perfil.ecoceColonia ?? '';
    final municipio = perfil.ecoceMunicipio ?? '';
    final estado = perfil.ecoceEstado ?? '';
    final cp = perfil.ecoceCp ?? '';
    
    String direccion = calle;
    if (numExt.isNotEmpty) direccion += ' $numExt';
    if (numInt.isNotEmpty) direccion += ' Int. $numInt';
    if (colonia.isNotEmpty) direccion += ', $colonia';
    if (municipio.isNotEmpty) direccion += ', $municipio';
    if (estado.isNotEmpty) direccion += ', $estado';
    if (cp.isNotEmpty) direccion += ', CP $cp';
    
    return direccion.trim();
  }
  
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: BioWayColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TransporteEscanearCargaScreen(),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/transporte_entregar');
        break;
      case 2:
        Navigator.pushNamed(context, '/transporte_ayuda');
        break;
      case 3:
        Navigator.pushNamed(context, '/transporte_perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Identificar Receptor',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_scannerController != null)
            IconButton(
              icon: Icon(
                _flashEnabled ? Icons.flash_on : Icons.flash_off,
                color: Colors.black87,
              ),
              onPressed: () {
                setState(() {
                  _flashEnabled = !_flashEnabled;
                });
                _scannerController!.toggleTorch();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Información de los lotes a entregar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: BioWayColors.info.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      color: BioWayColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lotes a entregar: ${widget.lotesSeleccionados.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Peso total: ${_calcularPesoTotal()} kg',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          
          // Scanner área
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController!,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null && !_isProcessing) {
                        _procesarCodigoQR(barcode.rawValue!);
                      }
                    }
                  },
                ),
                // Overlay con instrucciones
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Escanea el código QR del receptor',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Solicita al ${_getTipoReceptor()} que muestre\nsu código QR de identificación',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Información adicional
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: BioWayColors.warning,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Identificación Requerida',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'El receptor debe mostrar su código QR de usuario para continuar con la entrega',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
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
      ),
    );
  }
  
  String _calcularPesoTotal() {
    final pesoTotal = widget.lotesSeleccionados.fold(
      0.0,
      (sum, lote) => sum + (lote['peso'] as double),
    );
    return pesoTotal.toStringAsFixed(1);
  }
  
  String _getTipoReceptor() {
    // Por ahora devuelve un genérico, pero podría determinar el tipo esperado
    return 'Reciclador, Laboratorio o Transformador';
  }
}