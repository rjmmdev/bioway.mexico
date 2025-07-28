import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../utils/colors.dart';
import '../../../../services/carga_transporte_service.dart';
import '../../../../services/lote_unificado_service.dart';
import '../widgets/ecoce_bottom_navigation.dart';
import '../utils/dialog_utils.dart';

class ReceptorEscanearEntregaScreen extends StatefulWidget {
  final String userType; // 'reciclador', 'laboratorio', 'transformador'
  
  const ReceptorEscanearEntregaScreen({
    super.key,
    required this.userType,
  });

  @override
  State<ReceptorEscanearEntregaScreen> createState() => _ReceptorEscanearEntregaScreenState();
}

class _ReceptorEscanearEntregaScreenState extends State<ReceptorEscanearEntregaScreen> {
  final CargaTransporteService _cargaService = CargaTransporteService();
  final LoteUnificadoService _loteService = LoteUnificadoService();
  
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
      // Validar formato del código QR de entrega
      if (!codigo.startsWith('ENTREGA-')) {
        _mostrarError('Este no es un código QR de entrega válido');
        return;
      }
      
      // Obtener información de la entrega
      final entrega = await _cargaService.getEntregaPorQR(codigo);
      
      if (entrega == null) {
        _mostrarError('Entrega no encontrada');
        return;
      }
      
      // Verificar que la entrega sea para este tipo de usuario
      if (entrega.destinatarioTipo != widget.userType) {
        _mostrarError('Esta entrega no está destinada a un ${_getUserTypeLabel()}');
        return;
      }
      
      // Verificar que la entrega esté pendiente
      if (entrega.estadoEntrega != 'pendiente') {
        _mostrarError('Esta entrega ya fue procesada');
        return;
      }
      
      // Obtener información de los lotes incluidos en la entrega
      List<Map<String, dynamic>> lotesInfo = [];
      
      for (final loteId in entrega.lotesIds) {
        final lote = await _loteService.obtenerLotePorId(loteId);
        if (lote != null) {
          lotesInfo.add({
            'id': loteId,
            'material': lote.datosGenerales.tipoMaterial,
            'peso': lote.datosGenerales.peso,
            'origen_nombre': lote.origen?.nombreOperador ?? 'Sin especificar',
            'origen_folio': lote.origen?.usuarioFolio ?? 'Sin folio',
          });
        }
      }
      
      // Vibración de éxito
      HapticFeedback.mediumImpact();
      
      // Navegar a la pantalla de formulario correspondiente con los datos pre-cargados
      if (mounted) {
        _navegarAFormulario(entrega, lotesInfo);
      }
      
    } catch (e) {
      debugPrint('Error al procesar QR: $e');
      _mostrarError('Error al procesar el código QR');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  void _navegarAFormulario(dynamic entrega, List<Map<String, dynamic>> lotesInfo) {
    // Preparar datos para el formulario
    final datosEntrega = {
      'entrega_id': entrega.id,
      'transportista_id': entrega.transportistaId,
      'transportista_folio': entrega.transportistaFolio,
      'lotes': lotesInfo,
      'peso_total': entrega.pesoTotalEntregado,
    };
    
    // Navegar según el tipo de usuario
    switch (widget.userType) {
      case 'reciclador':
        Navigator.pushNamed(
          context,
          '/reciclador_formulario_recepcion',
          arguments: datosEntrega,
        );
        break;
      case 'laboratorio':
        // El laboratorio no recibe lotes completos
        DialogUtils.showErrorDialog(
          context: context,
          title: 'No disponible',
          message: 'El laboratorio solo puede tomar muestras mediante escaneo de código QR de megalotes',
        );
        break;
      case 'transformador':
        Navigator.pushNamed(
          context,
          '/transformador_formulario_recepcion',
          arguments: datosEntrega,
        );
        break;
    }
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
  
  Color get _primaryColor {
    switch (widget.userType) {
      case 'reciclador':
        return BioWayColors.primaryGreen;
      case 'laboratorio':
        return BioWayColors.petBlue;
      case 'transformador':
        return BioWayColors.ppPurple;
      default:
        return BioWayColors.primaryGreen;
    }
  }
  
  String _getUserTypeLabel() {
    switch (widget.userType) {
      case 'reciclador':
        return 'Reciclador';
      case 'laboratorio':
        return 'Laboratorio';
      case 'transformador':
        return 'Transformador';
      default:
        return 'Usuario';
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
          'Escanear Entrega',
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
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            color: _primaryColor,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Escanea el código QR de entrega',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Solicita al transportista que muestre\nel código QR de la entrega',
                            style: TextStyle(
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
                    color: Colors.black.withValues(alpha: 0.5),
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
                Icon(
                  Icons.local_shipping,
                  color: _primaryColor,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Recepción de Materiales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'El transportista debe mostrar el código QR de la entrega para continuar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFCC80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFFF9800),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Al escanear, se cargarán automáticamente los lotes incluidos en la entrega',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }
  
  Widget _buildBottomNavigation() {
    // Configuración específica por tipo de usuario
    switch (widget.userType) {
      case 'reciclador':
        return EcoceBottomNavigation(
          selectedIndex: 1, // Recibir
          onItemTapped: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, '/reciclador_inicio');
                break;
              case 1:
                break; // Ya estamos aquí
              case 2:
                Navigator.pushReplacementNamed(context, '/reciclador_historial');
                break;
              case 3:
                Navigator.pushReplacementNamed(context, '/reciclador_perfil');
                break;
            }
          },
          primaryColor: BioWayColors.primaryGreen,
          items: const [
            NavigationItem(
              icon: Icons.home_rounded,
              label: 'Inicio',
              testKey: 'reciclador_nav_inicio',
            ),
            NavigationItem(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Recibir',
              testKey: 'reciclador_nav_recibir',
            ),
            NavigationItem(
              icon: Icons.history_rounded,
              label: 'Historial',
              testKey: 'reciclador_nav_historial',
            ),
            NavigationItem(
              icon: Icons.person_outline_rounded,
              label: 'Perfil',
              testKey: 'reciclador_nav_perfil',
            ),
          ],
        );
        
      case 'laboratorio':
        return EcoceBottomNavigation(
          selectedIndex: 1, // Recibir
          onItemTapped: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, '/laboratorio_inicio');
                break;
              case 1:
                break; // Ya estamos aquí
              case 2:
                Navigator.pushReplacementNamed(context, '/laboratorio_muestras');
                break;
              case 3:
                Navigator.pushReplacementNamed(context, '/laboratorio_perfil');
                break;
            }
          },
          primaryColor: BioWayColors.petBlue,
          items: const [
            NavigationItem(
              icon: Icons.home_rounded,
              label: 'Inicio',
              testKey: 'laboratorio_nav_inicio',
            ),
            NavigationItem(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Recibir',
              testKey: 'laboratorio_nav_recibir',
            ),
            NavigationItem(
              icon: Icons.science_rounded,
              label: 'Muestras',
              testKey: 'laboratorio_nav_muestras',
            ),
            NavigationItem(
              icon: Icons.person_outline_rounded,
              label: 'Perfil',
              testKey: 'laboratorio_nav_perfil',
            ),
          ],
        );
        
      case 'transformador':
        return EcoceBottomNavigation(
          selectedIndex: 1, // Recibir
          onItemTapped: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, '/transformador_inicio');
                break;
              case 1:
                break; // Ya estamos aquí
              case 2:
                Navigator.pushReplacementNamed(context, '/transformador_produccion');
                break;
              case 3:
                Navigator.pushReplacementNamed(context, '/transformador_perfil');
                break;
            }
          },
          primaryColor: BioWayColors.ppPurple,
          items: const [
            NavigationItem(
              icon: Icons.home_rounded,
              label: 'Inicio',
              testKey: 'transformador_nav_inicio',
            ),
            NavigationItem(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Recibir',
              testKey: 'transformador_nav_recibir',
            ),
            NavigationItem(
              icon: Icons.precision_manufacturing_rounded,
              label: 'Producción',
              testKey: 'transformador_nav_produccion',
            ),
            NavigationItem(
              icon: Icons.person_outline_rounded,
              label: 'Perfil',
              testKey: 'transformador_nav_perfil',
            ),
          ],
        );
        
      default:
        return const SizedBox.shrink();
    }
  }
}