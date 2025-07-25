import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../utils/colors.dart';
import '../../../services/user_session_service.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../services/firebase/ecoce_profile_service.dart';
import '../../../services/carga_transporte_service.dart';
import '../../../services/lote_unificado_service.dart';
import '../shared/widgets/shared_qr_scanner_screen.dart';
import '../shared/widgets/dialog_utils.dart';
import 'transporte_qr_entrega_screen.dart';
import 'transporte_formulario_entrega_screen.dart';

class TransporteEntregaPasosScreen extends StatefulWidget {
  final List<String> lotesSeleccionados;
  
  const TransporteEntregaPasosScreen({
    super.key,
    required this.lotesSeleccionados,
  });

  @override
  State<TransporteEntregaPasosScreen> createState() => _TransporteEntregaPasosScreenState();
}

class _TransporteEntregaPasosScreenState extends State<TransporteEntregaPasosScreen> {
  final UserSessionService _userSession = UserSessionService();
  final AuthService _authService = AuthService();
  final CargaTransporteService _cargaService = CargaTransporteService();
  final LoteUnificadoService _loteService = LoteUnificadoService();
  
  // Control de pasos
  int _currentStep = 0;
  bool _isProcessing = false;
  
  // Datos recolectados
  Map<String, dynamic>? _datosReceptor;
  String? _qrEntrega;
  List<Map<String, dynamic>> _lotesCompletos = [];
  
  // Steps definitions
  final List<_StepInfo> _steps = [
    _StepInfo(
      title: 'Identificar Receptor',
      subtitle: 'Escanear QR del destinatario',
      icon: Icons.qr_code_scanner,
      instructions: 'El receptor debe mostrar su código QR de identificación.\n\n'
          'Este código contiene la información necesaria para verificar que está autorizado para recibir los materiales.',
    ),
    _StepInfo(
      title: 'Generar QR de Entrega',
      subtitle: 'Crear código de entrega',
      icon: Icons.qr_code_2,
      instructions: 'Se generará un código QR único para esta entrega.\n\n'
          'Este código contendrá toda la información necesaria para que el receptor pueda confirmar la recepción.',
    ),
    _StepInfo(
      title: 'Mostrar QR al Receptor',
      subtitle: 'Presentar código para escaneo',
      icon: Icons.phone_android,
      instructions: 'Muestre este código QR al receptor para que lo escanee.\n\n'
          'El código tiene una validez de 15 minutos y permite al receptor confirmar la recepción de los materiales.',
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    // Pre-cargar datos del usuario si es necesario
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
  
  Future<void> _scanReceptorQR() async {
    HapticFeedback.lightImpact();
    
    final qrCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const SharedQRScannerScreen(),
      ),
    );
    
    if (qrCode != null && mounted) {
      await _processReceptorQR(qrCode);
    }
  }
  
  Future<void> _processReceptorQR(String qrCode) async {
    setState(() => _isProcessing = true);
    
    try {
      // Validar formato del QR
      if (!qrCode.startsWith('USER-')) {
        throw 'Código QR inválido. Debe ser un QR de identificación de usuario.';
      }
      
      final parts = qrCode.split('-');
      if (parts.length < 3) {
        throw 'Formato de QR inválido';
      }
      
      final tipoUsuario = parts[1].toLowerCase();
      final userId = parts[2];
      
      // Validar tipo de usuario (solo reciclador, laboratorio o transformador)
      if (!['reciclador', 'laboratorio', 'transformador'].contains(tipoUsuario)) {
        throw 'Este usuario no está autorizado para recibir materiales';
      }
      
      // Obtener información del usuario receptor desde Firebase
      final profileService = EcoceProfileService();
      final perfilReceptor = await profileService.getProfileByUserId(userId);
      
      if (perfilReceptor == null) {
        _mostrarError('Usuario receptor no encontrado');
        return;
      }
      
      // Verificar que el usuario esté aprobado
      if (!perfilReceptor.isApproved) {
        _mostrarError('El usuario receptor no está aprobado para recibir materiales');
        return;
      }
      
      setState(() {
        _datosReceptor = {
          'id': userId,
          'tipo': tipoUsuario,
          'folio': perfilReceptor.ecoceFolio,
          'nombre': perfilReceptor.ecoceNombre,
          'direccion': _construirDireccion(perfilReceptor),
        };
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
  
  Future<void> _generateDeliveryQR() async {
    setState(() => _isProcessing = true);
    
    try {
      // Generar QR de entrega
      final userData = _userSession.getUserData();
      
      // Cargar información completa de los lotes
      _lotesCompletos = [];
      double pesoTotal = 0.0;
      String? cargaId;
      
      for (final loteId in widget.lotesSeleccionados) {
        final lote = await _loteService.obtenerLotePorId(loteId);
        if (lote != null) {
          // Obtener datos del origen
          String origenNombre = 'Sin especificar';
          String origenFolio = 'Sin folio';
          if (lote.origen != null) {
            // Obtener el nombre del usuario origen desde Firebase
            final profileService = EcoceProfileService();
            final origenProfile = await profileService.getProfileByUserId(lote.origen!.usuarioId);
            if (origenProfile != null) {
              origenNombre = origenProfile.ecoceNombre;
              origenFolio = origenProfile.ecoceFolio;
            }
          }
          
          // Obtener carga_id del transporte si existe
          String loteCargoId = 'CARGA_TEMP';
          if (lote.transporte != null) {
            // El carga_id debería estar en el proceso de transporte
            // Por ahora usar el ID del lote transportista
            loteCargoId = 'CARGA_${lote.id}';
          }
          
          final loteData = {
            'id': loteId,
            'peso': lote.pesoActual,
            'peso_original': lote.datosGenerales.peso,
            'tiene_muestras_lab': lote.tieneAnalisisLaboratorio,
            'peso_muestras': lote.tieneAnalisisLaboratorio ? lote.pesoTotalMuestras : 0.0,
            'material': lote.datosGenerales.tipoMaterial,
            'origen_nombre': origenNombre,
            'origen_folio': origenFolio,
            'carga_id': loteCargoId,
          };
          _lotesCompletos.add(loteData);
          pesoTotal += lote.pesoActual;
          
          // Usar el carga_id del primer lote
          if (cargaId == null) {
            cargaId = loteCargoId;
          }
        }
      }
      
      // Si no se encontró carga_id, generar uno temporal
      cargaId ??= 'CARGA_${DateTime.now().millisecondsSinceEpoch}';
      
      // Crear la entrega en Firebase
      _qrEntrega = await _cargaService.crearEntrega(
        lotesIds: widget.lotesSeleccionados,
        cargaId: cargaId,
        transportistaFolio: userData?['folio'] ?? 'V0000000',
        destinatarioId: _datosReceptor!['id'],
        destinatarioFolio: _datosReceptor!['folio'],
        destinatarioNombre: _datosReceptor!['nombre'],
        destinatarioTipo: _datosReceptor!['tipo'],
        pesoTotalEntregado: pesoTotal,
      );
      
      // Avanzar al siguiente paso en lugar de navegar
      if (mounted) {
        _nextStep();
      }
      
    } catch (e) {
      DialogUtils.showErrorDialog(
        context,
        title: 'Error al generar QR',
        message: e.toString(),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
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
          backgroundColor: const Color(0xFF1490EE),
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
            'Entregar Materiales',
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
                              color: isCompleted
                                  ? const Color(0xFF1490EE)
                                  : Colors.grey[300],
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
                                  ? const Color(0xFF1490EE)
                                  : Colors.grey[300],
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFF1490EE)
                                    : Colors.transparent,
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
        return _buildIdentifyReceptorStep();
      case 1:
        return _buildGenerateQRStep();
      case 2:
        return _buildShowQRStep();
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildIdentifyReceptorStep() {
    return Column(
      children: [
        // Ícono grande
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF1490EE).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.qr_code_scanner,
            size: 60,
            color: const Color(0xFF1490EE),
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
        
        // Información de lotes
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
                'Lotes a entregar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.lotesSeleccionados.length} lotes seleccionados',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
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
            onPressed: _isProcessing ? null : _scanReceptorQR,
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
              _isProcessing ? 'Procesando...' : 'Escanear QR del Receptor',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1490EE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
          ),
        ),
        
        // Datos del receptor si ya se escaneó
        if (_datosReceptor != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receptor identificado',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        '${_datosReceptor!['nombre']} - ${_datosReceptor!['folio']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildGenerateQRStep() {
    return Column(
      children: [
        // Ícono grande
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF1490EE).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.qr_code_2,
            size: 60,
            color: const Color(0xFF1490EE),
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
        const SizedBox(height: 32),
        
        // Información del receptor
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
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: const Color(0xFF1490EE),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Receptor',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_datosReceptor?['nombre'] ?? 'No identificado'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Folio: ${_datosReceptor?['folio'] ?? '-'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
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
            onPressed: _isProcessing ? null : _generateDeliveryQR,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.qr_code),
            label: Text(
              _isProcessing ? 'Generando QR...' : 'Generar QR de Entrega',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1490EE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
          ),
        ),
        
        // Estado de generación
        if (_qrEntrega != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'QR de entrega generado exitosamente',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildShowQRStep() {
    if (_qrEntrega == null || _qrEntrega!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF1490EE),
            ),
            SizedBox(height: 16),
            Text('Preparando código QR...'),
          ],
        ),
      );
    }

    // Extraer el ID de la entrega del QR
    final entregaId = _qrEntrega!.split('-').last;

    return Column(
      children: [
        // QR Code Container
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
              // Título con icono
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_2,
                    color: const Color(0xFF1490EE),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'QR de Entrega',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
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
                    color: const Color(0xFF1490EE).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: QrImageView(
                  data: _qrEntrega!,
                  version: QrVersions.auto,
                  size: 218,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // ID del envío
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1490EE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1490EE).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fingerprint,
                      color: const Color(0xFF1490EE),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entregaId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1490EE),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Información del envío
        Container(
          padding: const EdgeInsets.all(20),
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
                color: const Color(0xFF1490EE),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.scale,
                label: 'Peso total',
                value: '${_calcularPesoTotal().toStringAsFixed(1)} kg',
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.person,
                label: 'Receptor',
                value: '${_datosReceptor?['nombre'] ?? 'No identificado'}',
                color: Colors.green,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
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
              const Icon(
                Icons.info_outline,
                color: Color(0xFFFF9800),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instrucciones:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE65100),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _steps[2].instructions,
                      style: const TextStyle(
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
        
        const SizedBox(height: 32),
        
        // Botón para completar el proceso
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _completeDelivery,
            icon: const Icon(Icons.check_circle),
            label: const Text(
              'Completar Formulario de Entrega',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: BioWayColors.primaryGreen,
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
  
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: BioWayColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
  
  double _calcularPesoTotal() {
    return _lotesCompletos.fold(
      0.0, 
      (sum, lote) => sum + (lote['peso'] as double? ?? 0.0)
    );
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
            color: color.withOpacity(0.1),
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
  
  void _completeDelivery() {
    // Navegar al formulario de entrega con los datos necesarios
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransporteFormularioEntregaScreen(
          lotes: _lotesCompletos.isNotEmpty 
              ? _lotesCompletos 
              : widget.lotesSeleccionados.map((id) => {
                  'id': id,
                  'peso': 0.0, // Se calculará en el formulario
                }).toList(),
          qrData: _qrEntrega!,
          nuevoLoteId: _qrEntrega!.split('-').last,
          datosReceptor: _datosReceptor,
        ),
      ),
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