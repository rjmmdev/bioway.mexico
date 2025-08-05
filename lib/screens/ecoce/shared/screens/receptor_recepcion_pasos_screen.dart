import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../utils/colors.dart';
import '../../../../services/user_session_service.dart';
import '../../../../services/firebase/auth_service.dart';
import '../../../../services/carga_transporte_service.dart';
import '../../../../services/lote_unificado_service.dart';
import '../../reciclador/reciclador_formulario_recepcion.dart';
import '../../transformador/transformador_formulario_recepcion.dart';
import '../widgets/shared_qr_scanner_screen.dart';
import '../widgets/dialog_utils.dart';

class ReceptorRecepcionPasosScreen extends StatefulWidget {
  final String userType; // 'reciclador', 'laboratorio', 'transformador'
  
  const ReceptorRecepcionPasosScreen({
    super.key,
    required this.userType,
  });

  @override
  State<ReceptorRecepcionPasosScreen> createState() => _ReceptorRecepcionPasosScreenState();
}

class _ReceptorRecepcionPasosScreenState extends State<ReceptorRecepcionPasosScreen> {
  final UserSessionService _userSession = UserSessionService();
  final AuthService _authService = AuthService();
  final CargaTransporteService _cargaService = CargaTransporteService();
  final LoteUnificadoService _loteService = LoteUnificadoService();
  
  // Control de pasos
  int _currentStep = 0;
  bool _isProcessing = false;
  bool _isLoading = false;
  
  // Datos recolectados
  String? _qrData;
  Map<String, dynamic>? _datosEntrega;
  List<Map<String, dynamic>> _lotes = [];
  
  // Steps definitions
  late final List<_StepInfo> _steps;
  
  @override
  void initState() {
    super.initState();
    _initializeSteps();
    _generateUserQR();
  }
  
  void _initializeSteps() {
    _steps = [
      _StepInfo(
        title: 'Mostrar mi QR',
        subtitle: 'Identificación para el transportista',
        icon: Icons.qr_code_2,
        instructions: 'Muestra tu código QR de identificación al transportista.\n\n'
            'Este código le permite verificar que estás autorizado para recibir los materiales.',
      ),
      _StepInfo(
        title: 'Escanear Entrega',
        subtitle: 'Código QR del transportista',
        icon: Icons.qr_code_scanner,
        instructions: 'El transportista te mostrará un código QR con la información de la entrega.\n\n'
            'Escanea este código para recibir los materiales.',
      ),
      _StepInfo(
        title: 'Completar Recepción',
        subtitle: 'Formulario de ${_getTipoUsuarioLabel()}',
        icon: _getUserIcon(),
        instructions: 'Completa el formulario de recepción con los detalles específicos de tu proceso.\n\n'
            'Esto incluye pesos, firmas y cualquier observación relevante.',
      ),
    ];
  }
  
  String _getTipoUsuarioLabel() {
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
  
  IconData _getUserIcon() {
    switch (widget.userType) {
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
  
  Color get _primaryColor {
    switch (widget.userType) {
      case 'reciclador':
        return BioWayColors.primaryGreen;
      case 'laboratorio':
        return BioWayColors.petBlue;
      case 'transformador':
        return Colors.orange;
      default:
        return BioWayColors.primaryGreen;
    }
  }
  
  Future<void> _generateUserQR() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = _authService.currentUser;
      
      if (currentUser != null) {
        final userId = currentUser.uid;
        setState(() {
          _qrData = 'USER-${widget.userType.toUpperCase()}-$userId';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
  
  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }
  
  Future<void> _scanDeliveryQR() async {
    HapticFeedback.lightImpact();
    
    final qrCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const SharedQRScannerScreen(),
      ),
    );
    
    if (qrCode != null && mounted) {
      await _processDeliveryQR(qrCode);
    }
  }
  
  Future<void> _processDeliveryQR(String qrCode) async {
    setState(() => _isProcessing = true);
    
    try {
      // Validar formato del QR
      if (!qrCode.startsWith('ENTREGA-')) {
        throw 'Código QR inválido. Debe ser un QR de entrega.';
      }
      
      // Obtener datos de la entrega
      final entrega = await _cargaService.getEntregaPorQR(qrCode);
      if (entrega == null) {
        throw 'No se encontró información de esta entrega';
      }
      
      // Validar que la entrega es para este tipo de usuario
      if (entrega.destinatarioTipo != widget.userType) {
        throw 'Esta entrega es para un ${entrega.destinatarioTipo}, no para ${widget.userType}';
      }
      
      // Cargar información de los lotes
      final lotesInfo = <Map<String, dynamic>>[];
      for (final loteId in entrega.lotesIds) {
        final lote = await _loteService.obtenerLotePorId(loteId);
        if (lote != null) {
          // Usar pesoActual para obtener el peso correcto (considera sublotes y procesamiento)
          final pesoActual = lote.pesoActual;
          
          // Determinar origen para mostrar información adicional
          String origen = 'Sin especificar';
          if (lote.reciclador != null) {
            origen = lote.reciclador!.usuarioFolio ?? 'Reciclador';
          } else if (lote.origen != null) {
            origen = lote.origen!.usuarioFolio ?? 'Origen';
          }
          
          // Verificar si es un sublote
          final esSublote = lote.datosGenerales.tipoLote == 'derivado' || 
                           lote.datosGenerales.qrCode.startsWith('SUBLOTE-');
          
          lotesInfo.add({
            'id': loteId,
            'material': lote.datosGenerales.tipoMaterial,
            'peso': pesoActual, // Usar peso actual en lugar de peso original
            'presentacion': lote.datosGenerales.materialPresentacion,
            'origen_nombre': origen,
            'origen_folio': origen,
            'es_sublote': esSublote,
          });
        }
      }
      
      setState(() {
        _datosEntrega = {
          'entrega_id': entrega.id,
          'transportista_folio': entrega.transportistaFolio,
          'transportista_nombre': entrega.transportistaNombre,
          'lotes_count': entrega.lotesIds.length,
          'peso_total': entrega.pesoTotalEntregado,
        };
        _lotes = lotesInfo;
      });
      
      // Avanzar al siguiente paso
      _nextStep();
      
    } catch (e) {
      DialogUtils.showErrorDialog(
        context,
        title: 'Error',
        message: e.toString(),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }
  
  void _navigateToForm() {
    if (_datosEntrega == null || _lotes.isEmpty) return;
    
    Widget formScreen;
    
    switch (widget.userType) {
      case 'reciclador':
        formScreen = RecicladorFormularioRecepcion(
          lotes: _lotes,
          datosEntrega: _datosEntrega!,
        );
        break;
      case 'laboratorio':
        // El laboratorio no recibe lotes completos, solo toma muestras por QR
        DialogUtils.showErrorDialog(
          context,
          title: 'No disponible',
          message: 'El laboratorio solo puede tomar muestras mediante escaneo de código QR de megalotes',
        );
        return;
        break;
      case 'transformador':
        formScreen = TransformadorFormularioRecepcion(
          lotes: _lotes,
          datosEntrega: _datosEntrega!,
        );
        break;
      default:
        return;
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => formScreen),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final currentStepInfo = _steps[_currentStep];
    
    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0) {
          _previousStep();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: _primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              HapticFeedback.lightImpact();
              if (_currentStep > 0) {
                _previousStep();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text(
            'Recibir Materiales',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Progress indicator
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // Step indicators
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      children: List.generate(_steps.length * 2 - 1, (index) {
                        if (index.isOdd) {
                          // Línea conectora
                          final stepIndex = index ~/ 2;
                          final isCompleted = stepIndex < _currentStep;
                          return Expanded(
                            child: Container(
                              height: 2,
                              color: isCompleted ? _primaryColor : Colors.grey[300],
                            ),
                          );
                        } else {
                          // Círculo del paso
                          final stepIndex = index ~/ 2;
                          final isActive = stepIndex == _currentStep;
                          final isCompleted = stepIndex < _currentStep;
                          
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive || isCompleted
                                  ? _primaryColor
                                  : Colors.grey[300],
                              border: Border.all(
                                color: isActive ? _primaryColor : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : Text(
                                      '${stepIndex + 1}',
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          );
                        }
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Step title
                  Text(
                    'Paso ${_currentStep + 1} de ${_steps.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentStepInfo.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentStepInfo.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: _buildStepContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildShowQRStep();
      case 1:
        return _buildScanDeliveryStep();
      case 2:
        return _buildCompleteFormStep();
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildShowQRStep() {
    final userData = _userSession.getUserData();
    
    return Column(
      children: [
        // Instrucciones
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Instrucciones',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _steps[0].instructions,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // QR Code
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Mi Código QR',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 24),
              
              // QR Code
              Container(
                width: 250,
                height: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: _primaryColor,
                        ),
                      )
                    : QrImageView(
                        data: _qrData ?? '',
                        version: QrVersions.auto,
                        size: 218,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                      ),
              ),
              
              const SizedBox(height: 24),
              
              // Usuario info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      userData?['nombre'] ?? 'Usuario',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userData?['folio'] ?? '-',
                      style: TextStyle(
                        fontSize: 14,
                        color: _primaryColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        
        // Botón para continuar
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _nextStep,
            icon: const Icon(Icons.arrow_forward),
            label: const Text(
              'Continuar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildScanDeliveryStep() {
    return Column(
      children: [
        // Ícono grande
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.qr_code_scanner,
            size: 60,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 32),
        
        // Instrucciones
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Instrucciones',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _steps[1].instructions,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        
        // Botón de acción
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _scanDeliveryQR,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.qr_code_scanner),
            label: Text(
              _isProcessing ? 'Procesando...' : 'Escanear QR de Entrega',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
          ),
        ),
        
        // Datos de la entrega si ya se escaneó
        if (_datosEntrega != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: _primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Entrega identificada',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Transportista: ${_datosEntrega!['transportista_nombre'] ?? _datosEntrega!['transportista_folio']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: _primaryColor,
                  ),
                ),
                Text(
                  'Folio: ${_datosEntrega!['transportista_folio']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  'Lotes: ${_datosEntrega!['lotes_count']} - Peso total: ${_datosEntrega!['peso_total']} kg',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildCompleteFormStep() {
    return Column(
      children: [
        // Ícono grande
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getUserIcon(),
            size: 60,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 32),
        
        // Instrucciones
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Instrucciones',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _steps[2].instructions,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Resumen de la entrega
        if (_lotes.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                Text(
                  'Resumen de Materiales',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                ..._lotes.map((lote) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2,
                            size: 20,
                            color: _primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${lote['material']} - ${lote['peso']} kg',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (lote['es_sublote'] == true) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'SUBLOTE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.purple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              lote['presentacion'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 12,
                                color: _primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Origen: ${lote['origen_nombre'] ?? 'Sin especificar'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        // Botón para ir al formulario
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _navigateToForm,
            icon: const Icon(Icons.assignment),
            label: const Text(
              'Completar Formulario de Recepción',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final String instructions;
  
  const _StepInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.instructions,
  });
}