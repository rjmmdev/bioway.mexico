import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:io';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
import '../../../utils/ui_constants.dart';
import '../../../services/user_session_service.dart';
import '../../../services/carga_transporte_service.dart';
import 'transporte_formulario_entrega_screen.dart';
import 'transporte_escanear_carga_screen.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';

class TransporteQREntregaScreen extends StatefulWidget {
  final List<Map<String, dynamic>> lotesSeleccionados;
  final Map<String, dynamic>? datosReceptor;
  
  const TransporteQREntregaScreen({
    super.key,
    required this.lotesSeleccionados,
    this.datosReceptor,
  });

  @override
  State<TransporteQREntregaScreen> createState() => _TransporteQREntregaScreenState();
}

class _TransporteQREntregaScreenState extends State<TransporteQREntregaScreen> {
  final UserSessionService _userSession = UserSessionService();
  final CargaTransporteService _cargaService = CargaTransporteService();
  final ScreenshotController _screenshotController = ScreenshotController();
  String? _qrData;
  String? _entregaId;
  late DateTime _expirationTime;
  Timer? _timer;
  int _remainingMinutes = 15;
  int _remainingSeconds = 0;
  bool _isExpired = false;
  bool _isProcessing = false;
  bool _isCreatingEntrega = true;
  
  @override
  void initState() {
    super.initState();
    _createEntrega();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  Future<void> _createEntrega() async {
    try {
      print('Iniciando creación de entrega...');
      print('Lotes seleccionados: ${widget.lotesSeleccionados}');
      print('Datos receptor: ${widget.datosReceptor}');
      
      // Calcular datos agregados
      final pesoTotal = widget.lotesSeleccionados.fold(
        0.0, 
        (sum, lote) => sum + (lote['peso'] as double)
      );
      print('Peso total calculado: $pesoTotal');
      
      // Obtener información del usuario actual
      final userProfile = await _userSession.getUserProfile();
      if (userProfile == null) {
        throw Exception('No se pudo obtener el perfil del usuario');
      }
      print('Perfil usuario transportista: ${userProfile['folio']}');
      
      // Obtener la carga ID del primer lote (todos deben pertenecer a la misma carga)
      final cargaId = widget.lotesSeleccionados.first['carga_id'] as String;
      print('Carga ID: $cargaId');
      
      // Crear la entrega con los datos del receptor
      print('Llamando a crearEntrega...');
      final qrEntrega = await _cargaService.crearEntrega(
        lotesIds: widget.lotesSeleccionados.map((lote) => lote['id'] as String).toList(),
        cargaId: cargaId,
        transportistaFolio: userProfile['folio'] ?? 'V0000001',
        destinatarioId: widget.datosReceptor?['id'] ?? 'pendiente',
        destinatarioFolio: widget.datosReceptor?['folio'] ?? 'pendiente',
        destinatarioNombre: widget.datosReceptor?['nombre'] ?? 'Pendiente de recepción',
        destinatarioTipo: widget.datosReceptor?['tipo'] ?? 'pendiente',
        pesoTotalEntregado: pesoTotal,
      );
      print('QR Entrega recibido del servicio: $qrEntrega');
      
      if (mounted) {
        print('QR Entrega generado: $qrEntrega');
        setState(() {
          _entregaId = qrEntrega.split('-').last; // Extraer ID del QR
          _qrData = qrEntrega; // El QR completo para escanear
          _isCreatingEntrega = false;
        });
        print('_qrData establecido: $_qrData');
        print('_entregaId establecido: $_entregaId');
        
        // Iniciar el timer solo después de crear la entrega
        _expirationTime = DateTime.now().add(const Duration(minutes: 15));
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreatingEntrega = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear entrega: $e'),
            backgroundColor: BioWayColors.error,
          ),
        );
      }
    }
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final now = DateTime.now();
      final difference = _expirationTime.difference(now);
      
      if (difference.isNegative) {
        setState(() {
          _isExpired = true;
          _remainingMinutes = 0;
          _remainingSeconds = 0;
        });
        timer.cancel();
      } else {
        setState(() {
          _remainingMinutes = difference.inMinutes;
          _remainingSeconds = difference.inSeconds % 60;
        });
      }
    });
  }
  
  void _regenerateQR() {
    setState(() {
      _isCreatingEntrega = true;
      _qrData = null;
      _entregaId = null;
      _remainingMinutes = 15;
      _remainingSeconds = 0;
      _isExpired = false;
    });
    _timer?.cancel();
    _createEntrega();
  }
  
  void _continueToForm() {
    if (_isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El código QR ha expirado. Por favor genere uno nuevo.'),
          backgroundColor: BioWayColors.error,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransporteFormularioEntregaScreen(
          lotes: widget.lotesSeleccionados,
          qrData: _qrData!,
          nuevoLoteId: _entregaId!,
          datosReceptor: widget.datosReceptor,
        ),
      ),
    );
  }
  
  double get _pesoTotal => widget.lotesSeleccionados.fold(
    0.0, 
    (sum, lote) => sum + (lote['peso'] as double)
  );
  
  bool _tieneMuestrasLab() {
    return widget.lotesSeleccionados.any((lote) => lote['tiene_muestras_lab'] == true);
  }
  
  double _pesoTotalMuestras() {
    return widget.lotesSeleccionados.fold(
      0.0,
      (sum, lote) => sum + (lote['peso_muestras'] as double? ?? 0.0)
    );
  }
  
  String get _origenInfo {
    // Obtener información del origen del primer lote (todos deben ser del mismo origen en una carga)
    final primerLote = widget.lotesSeleccionados.first;
    return '${primerLote['origen_nombre']} (${primerLote['origen_folio']})';
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
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
        backgroundColor: BioWayColors.deepBlue,
        elevation: UIConstants.elevationNone,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Código QR de Entrega',
          style: TextStyle(
            fontSize: UIConstants.fontSizeXLarge,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header con información del transportista
            Container(
              width: double.infinity,
              padding: EdgeInsetsConstants.paddingAll20,
              decoration: BoxDecoration(
                color: BioWayColors.deepBlue.withValues(alpha: UIConstants.opacityVeryLow),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.local_shipping,
                    size: UIConstants.iconSizeXLarge - UIConstants.spacing16,
                    color: BioWayColors.deepBlue,
                  ),
                  SizedBox(height: UIConstants.spacing12),
                  const Text(
                    'Código QR de Entrega',
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeTitle,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                  SizedBox(height: UIConstants.spacing8),
                  Text(
                    'Transportista: ${_userSession.getUserData()?['folio'] ?? 'V0000001'}',
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeMedium,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: UIConstants.spacing20),
            
            Padding(
              padding: EdgeInsetsConstants.paddingAll20,
              child: Column(
                children: [
            
                  // QR Code Container similar to shared widget
                  Container(
                    padding: EdgeInsets.all(UIConstants.spacing32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadiusConstants.borderRadiusLarge,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow + 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Título con icono
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              color: BioWayColors.deepBlue,
                              size: UIConstants.iconSizeMedium,
                            ),
                            SizedBox(width: UIConstants.spacing8),
                            Text(
                              'QR Code',
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeBody,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: UIConstants.spacing24),
                        
                        // QR Code
                        Screenshot(
                          controller: _screenshotController,
                          child: Container(
                            width: UIConstants.qrSizeMedium,
                            height: UIConstants.qrSizeMedium,
                            padding: EdgeInsetsConstants.paddingAll8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadiusConstants.borderRadiusLarge,
                              border: Border.all(
                                color: _isExpired 
                                    ? Colors.grey.withValues(alpha: UIConstants.opacityMedium)
                                    : BioWayColors.deepBlue.withValues(alpha: UIConstants.opacityMedium),
                                width: UIConstants.strokeWidth,
                              ),
                            ),
                            child: _isCreatingEntrega
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: BioWayColors.deepBlue,
                                    ),
                                  )
                                : _qrData == null || _qrData!.isEmpty
                                    ? Container(
                                        width: UIConstants.qrSizeMedium - UIConstants.spacing16,
                                        height: 184,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.qr_code_2,
                                              size: 80,
                                              color: Colors.grey[400],
                                            ),
                                            SizedBox(height: UIConstants.spacing8),
                                            Text(
                                              'Generando QR...',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: UIConstants.fontSizeMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : QrImageView(
                                        data: _qrData!,
                                        version: QrVersions.auto,
                                        size: 184,
                                        backgroundColor: Colors.white,
                                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                                        eyeStyle: QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: _isExpired ? Colors.grey : Colors.black,
                                        ),
                                        dataModuleStyle: QrDataModuleStyle(
                                          dataModuleShape: QrDataModuleShape.square,
                                          color: _isExpired ? Colors.grey : Colors.black,
                                        ),
                                      ),
                          ),
                        ),
                        
                        if (_isExpired) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: BioWayColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadiusConstants.borderRadiusLarge,
                            ),
                            child: const Text(
                              'CÓDIGO EXPIRADO',
                              style: TextStyle(
                                color: BioWayColors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: UIConstants.fontSizeMedium,
                              ),
                            ),
                          ),
                        ],
                        
                        SizedBox(height: UIConstants.spacing24),
                        
                        // ID del envío
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: BioWayColors.deepBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: BioWayColors.deepBlue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fingerprint,
                                color: BioWayColors.deepBlue,
                                size: 20,
                              ),
                              SizedBox(width: UIConstants.spacing8),
                              Text(
                                _isCreatingEntrega 
                                    ? 'Generando...' 
                                    : _entregaId ?? 'Sin ID',
                                style: TextStyle(
                                  fontSize: UIConstants.fontSizeBody,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.deepBlue.withValues(alpha: 0.9),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            
                  SizedBox(height: UIConstants.spacing20),
                  
                  // Información del envío
                  Container(
                    padding: EdgeInsetsConstants.paddingAll20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.inventory_2,
                          label: 'Total de lotes',
                          value: widget.lotesSeleccionados.length.toString(),
                          color: BioWayColors.deepBlue,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.scale,
                          label: 'Peso total actual',
                          value: '${_pesoTotal.toStringAsFixed(1)} kg',
                          color: Colors.blue,
                        ),
                        if (_tieneMuestrasLab()) ...[
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            icon: Icons.science,
                            label: 'Muestras de laboratorio',
                            value: '${_pesoTotalMuestras().toStringAsFixed(1)} kg',
                            color: BioWayColors.info,
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.location_on,
                          label: 'Origen',
                          value: _origenInfo,
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.local_shipping,
                          label: 'Transportista',
                          value: _userSession.getUserData()?['folio'] ?? 'V0000001',
                          color: Colors.green,
                        ),
                        if (widget.datosReceptor != null) ...[
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            icon: _getReceptorIcon(),
                            label: 'Receptor',
                            value: '${widget.datosReceptor!['nombre']} (${widget.datosReceptor!['folio']})',
                            color: _getReceptorColor(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.access_time,
                          label: 'Fecha de generación',
                          value: FormatUtils.formatDateTime(DateTime.now()),
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
            
            
                  SizedBox(height: UIConstants.spacing20),
                  
                  // Instrucciones
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFCC80)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: const Color(0xFFFF9800),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Instrucciones para el receptor:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                              SizedBox(height: UIConstants.spacing8),
                              const Text(
                                '1. Escanee este código QR\n'
                                '2. Verifique los datos de la carga\n'
                                '3. Confirme la recepción de los materiales',
                                style: TextStyle(
                                  color: Color(0xFFBF360C),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: UIConstants.spacing20),
                  
                  // Timer de validez con estilo mejorado
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isExpired 
                          ? BioWayColors.error.withValues(alpha: 0.1)
                          : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isExpired 
                            ? BioWayColors.error.withValues(alpha: 0.3)
                            : const Color(0xFF90CAF9),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isExpired ? Icons.timer_off : Icons.timer,
                          color: _isExpired ? BioWayColors.error : BioWayColors.info,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isExpired 
                              ? 'Código expirado' 
                              : 'Válido por: ${_remainingMinutes.toString().padLeft(2, '0')}:${_remainingSeconds.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isExpired ? BioWayColors.error : const Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                  ),
            
                  const SizedBox(height: 32),
                  
                  // Botones de acción estilo compartido
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _descargarQR,
                          icon: const Icon(Icons.download),
                          label: const Text('Descargar QR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BioWayColors.deepBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: UIConstants.elevationNone,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _imprimirQR,
                          icon: const Icon(Icons.print),
                          label: const Text('Imprimir'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Colors.grey[400]!,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: UIConstants.spacing12),
                  
                  // Botón compartir
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _isProcessing ? null : _compartirQR,
                      icon: const Icon(Icons.share),
                      label: const Text('Compartir'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botón continuar o regenerar
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      key: Key(_isExpired ? 'btn_regenerate_qr' : 'btn_to_form_entrega'),
                      onPressed: _isCreatingEntrega 
                          ? null 
                          : (_isExpired ? _regenerateQR : _continueToForm),
                      icon: Icon(
                        _isCreatingEntrega 
                            ? Icons.hourglass_empty
                            : (_isExpired ? Icons.refresh : Icons.arrow_forward),
                        size: 24,
                      ),
                      label: Text(
                        _isCreatingEntrega 
                            ? 'Generando entrega...'
                            : (_isExpired ? 'Generar nuevo código' : 'Continuar al Formulario'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCreatingEntrega 
                            ? Colors.grey
                            : (_isExpired ? BioWayColors.warning : BioWayColors.primaryGreen),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  
                  if (_isExpired) ...[
                    SizedBox(height: UIConstants.spacing12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Volver a seleccionar lotes',
                        style: TextStyle(
                          color: BioWayColors.deepBlue,
                          fontSize: UIConstants.fontSizeMedium,
                        ),
                      ),
                    ),
                  ],
                  
                  SizedBox(height: UIConstants.spacing20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: 1, // Entregar
        onItemTapped: _onBottomNavTapped,
        primaryColor: BioWayColors.deepBlue,
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
        break; // Ya estamos aquí
      case 2:
        Navigator.pushNamed(context, '/transporte_ayuda');
        break;
      case 3:
        Navigator.pushNamed(context, '/transporte_perfil');
        break;
    }
  }

  Future<void> _descargarQR() async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final Uint8List? image = await _screenshotController.capture();
      if (image == null) {
        throw Exception('Error al capturar el código QR');
      }
      
      await _guardarDirectamente(image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: BioWayColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _guardarDirectamente(Uint8List image) async {
    try {
      final hasAccess = await Gal.hasAccess();
      
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          throw Exception('Se requiere permiso para guardar imágenes');
        }
      }
      
      final tempDir = await getTemporaryDirectory();
      final fileName = 'QR_Entrega_${DateTime.now().millisecondsSinceEpoch}.png';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(image);
      
      await Gal.putImage(tempFile.path, album: 'BioWay México');
      
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('QR guardado en galería'),
            backgroundColor: BioWayColors.success,
            action: SnackBarAction(
              label: 'Abrir',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  await Gal.open();
                } catch (e) {
                  // Ignore
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      await _compartirImagen(image);
    }
  }

  Future<void> _compartirImagen(Uint8List image) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/QR_Entrega_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(image);
      
      final String shareText = '''
Código QR de Entrega
Total de lotes: ${widget.lotesSeleccionados.length}
Peso total: ${_pesoTotal.toStringAsFixed(1)} kg
Origen: $_origenInfo
Transportista: ${_userSession.getUserData()?['folio'] ?? 'V0000001'}
      ''';
      
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: shareText,
        subject: 'Código QR de Entrega',
      );
      
      Future.delayed(const Duration(seconds: 10), () {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      });
    } catch (e) {
      throw Exception('Error al compartir: $e');
    }
  }

  Future<void> _imprimirQR() async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final Uint8List? image = await _screenshotController.capture();
      if (image == null) {
        throw Exception('Error al capturar el código QR');
      }
      
      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(image);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Código QR de Entrega',
                    style: pw.TextStyle(
                      fontSize: UIConstants.fontSizeTitle,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    width: 300,
                    height: 300,
                    child: pw.Image(pdfImage),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('Total de lotes: ${widget.lotesSeleccionados.length}'),
                  pw.Text('Peso total: ${_pesoTotal.toStringAsFixed(1)} kg'),
                  pw.Text('Origen: $_origenInfo'),
                  pw.Text('Transportista: ${_userSession.getUserData()?['folio'] ?? 'V0000001'}'),
                  pw.Text('Fecha: ${FormatUtils.formatDateTime(DateTime.now())}'),
                ],
              ),
            );
          },
        ),
      );
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'QR_Entrega_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al imprimir: $e'),
            backgroundColor: BioWayColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _compartirQR() async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final Uint8List? image = await _screenshotController.capture();
      if (image == null) {
        throw Exception('Error al capturar el código QR');
      }
      
      await _compartirImagen(image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: BioWayColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  IconData _getReceptorIcon() {
    switch (widget.datosReceptor?['tipo']) {
      case 'reciclador':
        return Icons.recycling;
      case 'laboratorio':
        return Icons.science;
      case 'transformador':
        return Icons.precision_manufacturing;
      default:
        return Icons.person;
    }
  }
  
  Color _getReceptorColor() {
    switch (widget.datosReceptor?['tipo']) {
      case 'reciclador':
        return BioWayColors.primaryGreen;
      case 'laboratorio':
        return BioWayColors.petBlue;
      case 'transformador':
        return BioWayColors.ppPurple;
      default:
        return Colors.grey;
    }
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}