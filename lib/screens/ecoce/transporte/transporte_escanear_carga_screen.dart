import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../utils/colors.dart';
import '../../../utils/ui_constants.dart';
import '../../../utils/qr_utils.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/carga_transporte_service.dart';
import '../../../services/firebase/ecoce_profile_service.dart';
import '../../../models/lotes/lote_unificado_model.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import 'transporte_formulario_carga_screen.dart';

class TransporteEscanearCargaScreen extends StatefulWidget {
  const TransporteEscanearCargaScreen({super.key});

  @override
  State<TransporteEscanearCargaScreen> createState() => _TransporteEscanearCargaScreenState();
}

class _TransporteEscanearCargaScreenState extends State<TransporteEscanearCargaScreen> {
  final LoteUnificadoService _loteService = LoteUnificadoService();
  final EcoceProfileService _profileService = EcoceProfileService();
  
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  bool _flashEnabled = false;
  String? _lastScannedCode; // Para evitar procesar el mismo código múltiples veces
  DateTime? _lastScanTime; // Para implementar debounce
  
  // Datos de la carga
  final List<Map<String, dynamic>> _lotesEscaneados = [];
  Map<String, dynamic>? _datosOrigen; // Datos del usuario de donde se recogen los lotes
  final Set<String> _lotesIds = {}; // Para evitar duplicados
  bool _mostrarScanner = true; // Control para mostrar/ocultar scanner
  
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
    // Implementar debounce para evitar procesamiento múltiple
    final now = DateTime.now();
    if (_lastScannedCode == codigo && _lastScanTime != null) {
      // Si es el mismo código y han pasado menos de 2 segundos, ignorar
      if (now.difference(_lastScanTime!).inMilliseconds < 2000) {
        return;
      }
    }
    
    // Actualizar último código escaneado y tiempo
    _lastScannedCode = codigo;
    _lastScanTime = now;
    
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Extraer ID del lote del código QR usando la utilidad
      final loteId = QRUtils.extractLoteIdFromQR(codigo);
      
      // Verificar si ya agregamos este lote
      if (_lotesIds.contains(loteId)) {
        _mostrarError('Este lote ya fue agregado a la carga');
        return;
      }
      
      // Obtener información del lote
      final lote = await _loteService.obtenerLotePorId(loteId);
      
      if (lote == null) {
        _mostrarError('Código QR no válido. Por favor escanea un lote válido');
        return;
      }
      
      // Verificar que el lote no esté ya en transporte
      if (lote.datosGenerales.procesoActual == 'transporte') {
        // Verificar si está en una carga activa del transportista actual
        final cargaService = CargaTransporteService();
        final estaEnCargaActiva = await cargaService.loteEstaEnCargaActiva(loteId);
        
        if (estaEnCargaActiva) {
          _mostrarError('Este lote ya está en una de tus cargas activas');
          return;
        }
        
        // Si está en transporte pero no en una carga activa del usuario actual,
        // podría ser de otro transportista
        _mostrarError('Este lote ya está siendo transportado');
        return;
      }
      
      // Si es el primer lote, obtener datos del propietario actual
      if (_datosOrigen == null) {
        await _obtenerDatosOrigen(lote);
      } else {
        // Verificar que todos los lotes sean del mismo origen
        final origenActual = await _obtenerUsuarioPropietario(lote);
        if (origenActual['id'] != _datosOrigen!['id']) {
          _mostrarError('Este lote pertenece a un usuario diferente. Todos los lotes de una carga deben ser del mismo origen.');
          return;
        }
      }
      
      // Agregar lote a la lista
      setState(() {
        _lotesIds.add(loteId);
        _lotesEscaneados.add({
          'id': loteId,
          'codigo_qr': codigo,
          'material': lote.datosGenerales.tipoMaterial,
          'peso': lote.pesoActual, // Usar el peso actual calculado dinámicamente
          'presentacion': lote.datosGenerales.materialPresentacion ?? 'Sin especificar',
          'fecha_creacion': lote.datosGenerales.fechaCreacion,
        });
        // Ocultar scanner después de agregar el primer lote
        _mostrarScanner = false;
      });
      
      // Vibración de éxito
      HapticFeedback.mediumImpact();
      
      // Mostrar mensaje de éxito
      _mostrarExito('Lote agregado a la carga');
      
    } catch (e) {
      print('Error al procesar QR: $e');
      _mostrarError('Error al procesar el código QR');
    } finally {
      // Esperar un poco antes de permitir otro escaneo
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _obtenerDatosOrigen(LoteUnificadoModel lote) async {
    final usuarioPropietario = await _obtenerUsuarioPropietario(lote);
    
    setState(() {
      _datosOrigen = usuarioPropietario;
    });
  }
  
  Future<Map<String, dynamic>> _obtenerUsuarioPropietario(LoteUnificadoModel lote) async {
    // Determinar quién es el propietario actual según el proceso
    String? userId;
    String procesoActual = lote.datosGenerales.procesoActual;
    
    switch (procesoActual) {
      case 'origen':
        userId = lote.origen?.usuarioId;
        break;
      case 'reciclador':
        userId = lote.reciclador?.usuarioId;
        break;
      case 'transformador':
        userId = lote.transformador?.usuarioId;
        break;
      case 'laboratorio':
        // Laboratorio es un proceso paralelo, no toma posesión del lote
        // Por lo tanto, no debería aparecer como proceso actual
        // pero si aparece, usar el primer análisis
        userId = lote.analisisLaboratorio.isNotEmpty 
            ? lote.analisisLaboratorio.first.usuarioId 
            : null;
        break;
    }
    
    if (userId == null) {
      throw Exception('No se pudo determinar el propietario del lote');
    }
    
    // Obtener perfil del usuario
    final perfil = await _profileService.getProfileByUserId(userId);
    
    if (perfil == null) {
      throw Exception('No se encontró el perfil del usuario');
    }
    
    return {
      'id': userId,
      'folio': perfil.ecoceFolio,
      'nombre': perfil.ecoceNombre,
      'tipo': procesoActual,
      'direccion': '${perfil.ecoceCalle} ${perfil.ecoceNumExt}, ${perfil.ecoceColonia ?? ''}, ${perfil.ecoceMunicipio ?? ''}, ${perfil.ecoceEstado ?? ''}',
    };
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
  
  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: BioWayColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  void _eliminarLote(int index) {
    setState(() {
      final lote = _lotesEscaneados[index];
      _lotesIds.remove(lote['id']);
      _lotesEscaneados.removeAt(index);
      
      // Si no quedan lotes, limpiar datos de origen y mostrar scanner
      if (_lotesEscaneados.isEmpty) {
        _datosOrigen = null;
        _mostrarScanner = true;
      }
    });
  }
  
  void _continuarConFormulario() {
    if (_lotesEscaneados.isEmpty) {
      _mostrarError('Debe escanear al menos un lote');
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransporteFormularioCargaScreen(
          lotes: _lotesEscaneados,
          datosOrigen: _datosOrigen!,
        ),
      ),
    ).then((_) {
      // Limpiar datos al volver
      setState(() {
        _lotesEscaneados.clear();
        _lotesIds.clear();
        _datosOrigen = null;
        _mostrarScanner = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Volver a la pantalla de inicio
        Navigator.pushReplacementNamed(context, '/transporte_inicio');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: UIConstants.elevationNone,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pushReplacementNamed(context, '/transporte_inicio'),
          ),
        title: const Text(
          'Crear Carga',
          style: TextStyle(
            color: Colors.black87,
            fontSize: UIConstants.fontSizeXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_scannerController != null)
            IconButton(
              icon: Icon(
                _flashEnabled 
                  ? Icons.flash_on 
                  : Icons.flash_off,
                color: _flashEnabled 
                  ? Colors.yellow  // Amarillo cuando está activo para mejor visibilidad
                  : Colors.black87,
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
      body: Column(
        children: [
          // Scanner área
          if (_mostrarScanner)
            Expanded(
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _scannerController!,
                    onDetect: (capture) {
                      if (_isProcessing) return; // Evitar procesamiento múltiple
                      
                      final List<Barcode> barcodes = capture.barcodes;
                      // Procesar solo el primer código QR detectado
                      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                        _procesarCodigoQR(barcodes.first.rawValue!);
                      }
                    },
                  ),
                  // Overlay con instrucciones
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: UIConstants.opacityMedium),
                        width: UIConstants.strokeWidth,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: EdgeInsetsConstants.paddingAll20,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: UIConstants.opacityHigh),
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                              size: UIConstants.iconSizeXLarge - UIConstants.spacing16,
                            ),
                            SizedBox(height: UIConstants.spacing16),
                            Text(
                              'Escanea el código QR del lote',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: UIConstants.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: UIConstants.spacing8),
                            Text(
                              'Puedes escanear múltiples lotes\npara crear una carga',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: UIConstants.fontSizeMedium,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Información del origen
          if (_datosOrigen != null)
            Container(
              padding: EdgeInsetsConstants.paddingAll16,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: BioWayColors.primaryGreen,
                        size: UIConstants.iconSizeMedium,
                      ),
                      SizedBox(width: UIConstants.spacing8),
                      const Text(
                        'Recogiendo de:',
                        style: TextStyle(
                          fontSize: UIConstants.fontSizeBody,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: UIConstants.spacing8),
                  Text(
                    _datosOrigen!['nombre'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: UIConstants.spacing4),
                  Text(
                    'Folio: ${_datosOrigen!['folio']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _datosOrigen!['direccion'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          
          // Lista de lotes escaneados
          if (_lotesEscaneados.isNotEmpty && !_mostrarScanner)
            Expanded(
              child: Container(
                color: const Color(0xFFF5F5F5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsetsConstants.paddingAll16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lotes en la carga (${_lotesEscaneados.length})',
                            style: const TextStyle(
                              fontSize: UIConstants.fontSizeBody,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _mostrarScanner = true;
                              });
                            },
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Escanear más'),
                            style: TextButton.styleFrom(
                              foregroundColor: BioWayColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing16),
                        itemCount: _lotesEscaneados.length,
                        itemBuilder: (context, index) {
                          final lote = _lotesEscaneados[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: UIConstants.spacing8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: BioWayColors.primaryGreen.withValues(alpha: UIConstants.opacityLow),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: BioWayColors.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                lote['material'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${lote['peso']} kg - ${lote['presentacion']}'),
                                  Text(
                                    'ID: ${lote['id'].substring(0, 8)}...',
                                    style: TextStyle(
                                      fontSize: UIConstants.fontSizeXSmall,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _eliminarLote(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Botón continuar
          if (_lotesEscaneados.isNotEmpty)
            Container(
              padding: EdgeInsetsConstants.paddingAll16,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: UIConstants.opacityLow),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continuarConFormulario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: UIConstants.spacing16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusMedium,
                    ),
                  ),
                  child: Text(
                    'Continuar con ${_lotesEscaneados.length} lote${_lotesEscaneados.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: 0,
        onItemTapped: (index) {
          switch (index) {
            case 0:
              break; // Ya estamos aquí
            case 1:
              Navigator.pushReplacementNamed(context, '/transporte_entregar');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/transporte_ayuda');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/transporte_perfil');
              break;
          }
        },
        primaryColor: BioWayColors.primaryGreen,
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
}