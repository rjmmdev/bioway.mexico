import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../utils/colors.dart';
import '../../../utils/ui_constants.dart';
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
      torchEnabled: false,  // Inicializar estado del torch explícitamente
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
        _mostrarError('Código incorrecto. Por favor escanea el código QR de identificación del receptor, no un lote');
        return;
      }
      
      // Detectar si se escaneó un código de entrega
      if (codigo.startsWith('ENTREGA-')) {
        _mostrarError('Código incorrecto. Por favor escanea el código QR de identificación del receptor, no una entrega');
        return;
      }
      
      // Detectar si se escaneó un código de transformación/megalote
      if (codigo.startsWith('TRANSFORMACION-') || codigo.startsWith('MEGALOTE-')) {
        _mostrarError('Código incorrecto. Por favor escanea el código QR de identificación del receptor, no un megalote');
        return;
      }
      
      // Detectar si se escaneó un código de sublote
      if (codigo.startsWith('SUBLOTE-')) {
        _mostrarError('Código incorrecto. Por favor escanea el código QR de identificación del receptor, no un sublote');
        return;
      }
      
      // Validar formato del código QR del usuario
      if (!codigo.startsWith('USER-')) {
        // Mostrar mensaje genérico para cualquier otro tipo de código no reconocido
        _mostrarError('Código QR no válido. Por favor escanea el código QR de identificación del receptor');
        return;
      }
      
      // Extraer información del código
      final partes = codigo.split('-');
      if (partes.length < 3) {
        _mostrarError('Formato de código QR inválido. Se requiere un código de identificación de usuario');
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
            SizedBox(width: UIConstants.spacing12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: BioWayColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusConstants.borderRadiusMedium,
        ),
        margin: EdgeInsetsConstants.paddingAll20,
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Volver a la pantalla anterior
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: UIConstants.elevationNone,
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
            fontSize: UIConstants.fontSizeXLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_scannerController != null)
            IconButton(
              icon: Icon(
                _flashEnabled 
                  ? Icons.flash_on 
                  : Icons.flash_off,
                color: _flashEnabled 
                  ? Colors.yellow  // Amarillo cuando está activo para mejor visibilidad
                  : Colors.white,
              ),
              onPressed: () async {
                try {
                  await _scannerController?.toggleTorch();
                  setState(() {
                    _flashEnabled = !_flashEnabled;  // Simplemente invertir el estado
                  });
                } catch (e) {
                  print('Error al activar flash: $e');
                  // Si hay error, revertir el estado
                  setState(() {
                    _flashEnabled = false;
                  });
                  _mostrarError('No se pudo activar la linterna');
                }
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
                    Colors.black.withValues(alpha: UIConstants.opacityHigh),
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
                          height: UIConstants.qrSizeMedium + UIConstants.iconSizeDialog + UIConstants.iconSizeMedium,
                          width: UIConstants.qrSizeMedium + UIConstants.iconSizeDialog + UIConstants.iconSizeMedium,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadiusConstants.borderRadiusLarge,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Marco del escáner
                Center(
                  child: Container(
                    height: UIConstants.qrSizeMedium + UIConstants.iconSizeDialog + UIConstants.iconSizeMedium,
                    width: UIConstants.qrSizeMedium + UIConstants.iconSizeDialog + UIConstants.iconSizeMedium,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: UIConstants.strokeWidth,
                      ),
                      borderRadius: BorderRadiusConstants.borderRadiusLarge,
                    ),
                    child: Stack(
                      children: [
                        // Esquinas decorativas
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            height: UIConstants.iconContainerMedium,
                            width: UIConstants.iconContainerMedium,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Color(0xFF1490EE), width: UIConstants.borderWidthThick),
                                left: BorderSide(color: Color(0xFF1490EE), width: UIConstants.borderWidthThick),
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(UIConstants.radiusLarge),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            height: UIConstants.iconContainerMedium,
                            width: UIConstants.iconContainerMedium,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Color(0xFF1490EE), width: UIConstants.borderWidthThick),
                                right: BorderSide(color: Color(0xFF1490EE), width: UIConstants.borderWidthThick),
                              ),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(UIConstants.radiusLarge),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            height: UIConstants.iconContainerMedium,
                            width: UIConstants.iconContainerMedium,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFF1490EE), width: UIConstants.borderWidthThick),
                                left: BorderSide(color: Color(0xFF1490EE), width: UIConstants.borderWidthThick),
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(UIConstants.radiusLarge),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            height: UIConstants.iconContainerMedium,
                            width: UIConstants.iconContainerMedium,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFF1490EE), width: UIConstants.borderWidthThick),
                                right: BorderSide(color: Color(0xFF1490EE), width: UIConstants.borderWidthThick),
                              ),
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(UIConstants.radiusLarge),
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
            top: UIConstants.spacing20,
            left: UIConstants.spacing20,
            right: UIConstants.spacing20,
            child: Container(
              padding: EdgeInsetsConstants.paddingAll16,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: UIConstants.opacityAlmostFull),
                borderRadius: BorderRadiusConstants.borderRadiusLarge,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: UIConstants.opacityLow),
                    blurRadius: UIConstants.blurRadiusMedium,
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
                        size: UIConstants.iconSizeMedium,
                      ),
                      SizedBox(width: UIConstants.spacing8),
                      Text(
                        'Lotes a entregar: ${widget.lotesSeleccionados.length}',
                        style: const TextStyle(
                          fontSize: UIConstants.fontSizeBody,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: UIConstants.spacing8),
                  Text(
                    'Peso total: ${_calcularPesoTotal()} kg',
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeMedium,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Instrucciones en la parte inferior
          Positioned(
            bottom: UIConstants.qrSizeSmall,
            left: UIConstants.spacing20,
            right: UIConstants.spacing20,
            child: Container(
              padding: EdgeInsetsConstants.paddingAll20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadiusConstants.borderRadiusLarge,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: UIConstants.iconSizeLarge,
                    color: Colors.grey[700],
                  ),
                  SizedBox(height: UIConstants.spacing12),
                  const Text(
                    'Escanea el código QR del receptor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                  SizedBox(height: UIConstants.spacing8),
                  Text(
                    'Solicita al ${_getTipoReceptor()} que muestre\nsu código QR de identificación',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeMedium,
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
              color: Colors.black.withValues(alpha: UIConstants.opacityHigh),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
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