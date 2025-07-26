import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../utils/colors.dart';
import '../../../services/firebase/ecoce_profile_service.dart';

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
      // Detectar si se escaneó un código de lote en lugar de usuario
      if (codigo.startsWith('LOTE-')) {
        _mostrarError('Has escaneado un código de lote. Por favor escanea el código QR del receptor');
        return;
      }
      
      // Detectar si se escaneó un código de entrega
      if (codigo.startsWith('ENTREGA-')) {
        _mostrarError('Has escaneado un código de entrega. Por favor escanea el código QR del receptor');
        return;
      }
      
      // Validar formato del código QR del usuario
      if (!codigo.startsWith('USER-')) {
        _mostrarError('Por favor escanea el código QR de identificación del receptor');
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
      
      // Devolver los datos del receptor a la pantalla anterior
      if (mounted) {
        Navigator.pop(context, datosReceptor);
      }
      
    } catch (e) {
      debugPrint('Error al procesar QR: $e');
      _mostrarError('Error al procesar el código QR');
      // No reiniciamos _isProcessing aquí porque _mostrarError ya lo maneja
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
    // Vibración de error
    HapticFeedback.heavyImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: BioWayColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(20),
      ),
    );
    
    // Esperar un poco antes de permitir el siguiente escaneo
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Identificar Receptor',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_scannerController != null)
            IconButton(
              icon: Icon(
                _flashEnabled ? Icons.flash_on : Icons.flash_off,
                color: _flashEnabled ? Colors.yellow : Colors.white,
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
      body: Stack(
        children: [
          // Scanner de pantalla completa
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
          
          // Overlay con marco de escaneo
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.transparent),
            ),
            child: Stack(
              children: [
                // Oscurecer áreas fuera del recuadro
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.srcOut,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          backgroundBlendMode: BlendMode.dstOut,
                        ),
                      ),
                      Center(
                        child: Container(
                          height: 300,
                          width: 300,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Marco del escáner
                Center(
                  child: Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        // Esquinas decorativas
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Color(0xFF1490EE), width: 4),
                                left: BorderSide(color: Color(0xFF1490EE), width: 4),
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Color(0xFF1490EE), width: 4),
                                right: BorderSide(color: Color(0xFF1490EE), width: 4),
                              ),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFF1490EE), width: 4),
                                left: BorderSide(color: Color(0xFF1490EE), width: 4),
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFF1490EE), width: 4),
                                right: BorderSide(color: Color(0xFF1490EE), width: 4),
                              ),
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(20),
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
          ),
          
          // Información de lotes en la parte superior
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        color: const Color(0xFF1490EE),
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
          ),
          
          // Instrucciones en la parte inferior
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 40,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Escanea el código QR del receptor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Solicita al ${_getTipoReceptor()} que muestre\nsu código QR de identificación',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Indicador de procesamiento
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