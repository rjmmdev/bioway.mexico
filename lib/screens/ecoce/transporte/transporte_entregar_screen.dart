import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../utils/colors.dart';
import '../../../services/image_service.dart';
import 'widgets/transporte_bottom_navigation.dart';
import 'transporte_inicio_screen.dart';
import 'transporte_ayuda_screen.dart';
import 'transporte_perfil_screen.dart';
import '../shared/widgets/signature_dialog.dart';
import '../reciclador/widgets/reciclador_bottom_navigation.dart';

class TransporteEntregarScreen extends StatefulWidget {
  const TransporteEntregarScreen({super.key});

  @override
  State<TransporteEntregarScreen> createState() => _TransporteEntregarScreenState();
}

class _TransporteEntregarScreenState extends State<TransporteEntregarScreen> {
  int _selectedIndex = 1;
  int _currentStep = 0;
  
  // Controladores para búsqueda de destinatario
  final TextEditingController _destinatarioIdController = TextEditingController();
  
  // Controladores para formulario de entrega
  final TextEditingController _pesoEntregadoController = TextEditingController();
  final TextEditingController _nombreRecibeController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();
  
  // Variables para la firma
  List<Offset?> _signaturePoints = [];
  bool _hasSignature = false;
  
  // Variables para la imagen
  File? _selectedImage;
  bool _hasImage = false;
  
  // Estado del destinatario
  Map<String, dynamic>? _destinatarioEncontrado;
  
  // Lotes en tránsito (datos de ejemplo)
  final Map<String, List<Map<String, dynamic>>> _lotesPorOrigen = {
    'Centro de Acopio Norte': [
      {'id': 'FID_1234567', 'material': 'PET', 'peso': 45.5, 'presentacion': 'Pacas'},
      {'id': 'FID_1234568', 'material': 'PP', 'peso': 32.0, 'presentacion': 'Sacos'},
    ],
    'Centro de Acopio Sur': [
      {'id': 'FID_1234569', 'material': 'Multi', 'peso': 28.5, 'presentacion': 'Pacas'},
    ],
  };
  
  // Lotes seleccionados para entrega
  final Set<String> _lotesSeleccionados = {};
  
  // Timer para expiración del QR
  Timer? _qrTimer;
  int _tiempoRestante = 900; // 15 minutos en segundos
  
  @override
  void dispose() {
    _destinatarioIdController.dispose();
    _pesoEntregadoController.dispose();
    _nombreRecibeController.dispose();
    _comentariosController.dispose();
    _qrTimer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        NavigationHelper.navigateWithReplacement(
          context: context,
          destination: const TransporteInicioScreen(),
        );
        break;
      case 1:
        // Ya estamos en entregar
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

  void _seleccionarTodosLotes(String origen) {
    setState(() {
      for (var lote in _lotesPorOrigen[origen]!) {
        _lotesSeleccionados.add(lote['id']);
      }
    });
  }

  void _deseleccionarTodosLotes(String origen) {
    setState(() {
      for (var lote in _lotesPorOrigen[origen]!) {
        _lotesSeleccionados.remove(lote['id']);
      }
    });
  }

  void _generarQREntrega() {
    if (_lotesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona al menos un lote para entregar'),
          backgroundColor: BioWayColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    
    setState(() {
      _currentStep = 1;
      _iniciarTimerQR();
    });
  }

  void _iniciarTimerQR() {
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_tiempoRestante > 0) {
          _tiempoRestante--;
        } else {
          timer.cancel();
          // QR expirado
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('El código QR ha expirado'),
              backgroundColor: BioWayColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      });
    });
  }

  String _formatTiempo(int segundos) {
    int minutos = segundos ~/ 60;
    int segs = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }

  void _buscarDestinatario() {
    if (_destinatarioIdController.text.isEmpty) return;
    
    // Simulación de búsqueda exitosa
    setState(() {
      _destinatarioEncontrado = {
        'id': _destinatarioIdController.text,
        'nombre': 'Recicladora Industrial del Norte S.A.',
        'direccion': 'Av. Industrial #456, Zona Norte, CP 12345',
        'tipo': 'R', // Reciclador
      };
    });
    
    HapticFeedback.mediumImpact();
    
    // Calcular peso total
    double pesoTotal = 0;
    for (var origen in _lotesPorOrigen.keys) {
      for (var lote in _lotesPorOrigen[origen]!) {
        if (_lotesSeleccionados.contains(lote['id'])) {
          pesoTotal += lote['peso'] as double;
        }
      }
    }
    _pesoEntregadoController.text = pesoTotal.toStringAsFixed(1);
  }

  void _showSignatureDialog() {
    SignatureDialog.show(
      context: context,
      title: 'Firma del Receptor',
      initialSignature: _signaturePoints,
      onSignatureSaved: (points) {
        setState(() {
          _signaturePoints = List.from(points);
          _hasSignature = points.isNotEmpty;
        });
      },
      primaryColor: BioWayColors.deepBlue,
    );
  }

  Future<void> _takePicture() async {
    final File? image = await ImageService.takePhoto();
    
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _hasImage = true;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final File? image = await ImageService.pickFromGallery();
    
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _hasImage = true;
      });
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seleccionar imagen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _takePicture();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _completarEntrega() {
    // Sin validaciones para diseño visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Entrega completada exitosamente'),
        backgroundColor: BioWayColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
    
    // Resetear estado
    setState(() {
      _currentStep = 0;
      _lotesSeleccionados.clear();
      _destinatarioEncontrado = null;
      _hasSignature = false;
      _hasImage = false;
      _selectedImage = null;
      _signaturePoints.clear();
      _nombreRecibeController.clear();
      _comentariosController.clear();
      _destinatarioIdController.clear();
      _pesoEntregadoController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: BioWayColors.deepBlue,
        elevation: 0,
        title: Text(
          _currentStep == 0 
              ? 'Materiales para Entrega'
              : _currentStep == 1
                  ? 'QR de Entrega'
                  : 'Formulario de Entrega',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _buildCurrentStep(),
      bottomNavigationBar: _currentStep == 0 
          ? TransporteBottomNavigation(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            )
          : null,
      floatingActionButton: _currentStep == 0 && _lotesSeleccionados.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _generarQREntrega,
              backgroundColor: BioWayColors.deepBlue,
              icon: const Icon(Icons.qr_code),
              label: Text('Generar QR (${_lotesSeleccionados.length})'),
            )
          : null,
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildSeleccionMateriales();
      case 1:
        return _buildQREntrega();
      case 2:
        return _buildFormularioEntrega();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSeleccionMateriales() {
    // Calcular totales
    int totalLotes = 0;
    double pesoTotal = 0;
    for (var lotes in _lotesPorOrigen.values) {
      totalLotes += lotes.length;
      for (var lote in lotes) {
        pesoTotal += lote['peso'] as double;
      }
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Resumen superior
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: BioWayColors.deepBlue,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Materiales en Tránsito',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResumenItem(
                      Icons.inventory_2,
                      '$totalLotes lotes',
                      Colors.white,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildResumenItem(
                      Icons.scale,
                      '${pesoTotal.toStringAsFixed(1)} kg',
                      Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Lista de materiales por origen
          ..._lotesPorOrigen.entries.map((entry) {
            final origen = entry.key;
            final lotes = entry.value;
            final todosSeleccionados = lotes.every(
              (lote) => _lotesSeleccionados.contains(lote['id']),
            );
            
            return Container(
              margin: const EdgeInsets.all(20),
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
                children: [
                  // Encabezado del origen
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: BioWayColors.lightGrey.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: BioWayColors.deepBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                origen,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.darkGrey,
                                ),
                              ),
                              Text(
                                'Código: A0000${_lotesPorOrigen.keys.toList().indexOf(origen) + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: BioWayColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (todosSeleccionados) {
                              _deseleccionarTodosLotes(origen);
                            } else {
                              _seleccionarTodosLotes(origen);
                            }
                          },
                          child: Text(
                            todosSeleccionados ? 'Deseleccionar todos' : 'Seleccionar todos',
                            style: TextStyle(
                              color: BioWayColors.deepBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Lista de lotes
                  ...lotes.map((lote) => _buildLoteEntrega(lote)),
                ],
              ),
            );
          }).toList(),
          
          const SizedBox(height: 100), // Espacio para el FAB
        ],
      ),
    );
  }

  Widget _buildLoteEntrega(Map<String, dynamic> lote) {
    final isSelected = _lotesSeleccionados.contains(lote['id']);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: BioWayColors.lightGrey,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value!) {
                  _lotesSeleccionados.add(lote['id']);
                } else {
                  _lotesSeleccionados.remove(lote['id']);
                }
              });
            },
            activeColor: BioWayColors.deepBlue,
          ),
          
          const SizedBox(width: 12),
          
          // Información del lote
          Expanded(
            child: Row(
              children: [
                // ID del lote
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                
                const SizedBox(width: 16),
                
                // Material
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getColorForMaterial(lote['material']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lote['material'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getColorForMaterial(lote['material']),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Peso
                Row(
                  children: [
                    Icon(
                      Icons.scale,
                      size: 16,
                      color: BioWayColors.textGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${lote['peso']} kg',
                      style: TextStyle(
                        fontSize: 14,
                        color: BioWayColors.darkGrey,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // Presentación
                Row(
                  children: [
                    Icon(
                      lote['presentacion'] == 'Pacas' 
                          ? Icons.inventory_2 
                          : Icons.shopping_bag,
                      size: 16,
                      color: BioWayColors.textGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      lote['presentacion'],
                      style: TextStyle(
                        fontSize: 14,
                        color: BioWayColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQREntrega() {
    // Datos del QR
    final qrData = {
      'lotes': _lotesSeleccionados.toList(),
      'fecha': DateTime.now().toIso8601String(),
      'transportista': 'V0000001',
    };
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Título
            Text(
              'QR de Entrega Generado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: BioWayColors.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Muestra este código al receptor',
              style: TextStyle(
                fontSize: 16,
                color: BioWayColors.textGrey,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Código QR
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData.toString(),
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Timer de expiración
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _tiempoRestante < 60 
                    ? BioWayColors.error.withOpacity(0.1)
                    : BioWayColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _tiempoRestante < 60 
                      ? BioWayColors.error.withOpacity(0.3)
                      : BioWayColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    color: _tiempoRestante < 60 
                        ? BioWayColors.error
                        : BioWayColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Este código expira en ${_formatTiempo(_tiempoRestante)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _tiempoRestante < 60 
                          ? BioWayColors.error
                          : BioWayColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Resumen de entrega
            Container(
              width: double.infinity,
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
                  Text(
                    'Resumen de Entrega',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildResumenRow(
                    'Total de lotes:',
                    '${_lotesSeleccionados.length}',
                  ),
                  const SizedBox(height: 8),
                  _buildResumenRow(
                    'Peso total:',
                    '${_calcularPesoTotal().toStringAsFixed(1)} kg',
                  ),
                  const SizedBox(height: 8),
                  _buildResumenRow(
                    'Orígenes:',
                    _obtenerOrigenes().join(', '),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Instrucciones
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BioWayColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: BioWayColors.info.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instrucciones para el receptor:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInstruccion('1', 'El receptor debe escanear este QR'),
                  const SizedBox(height: 8),
                  _buildInstruccion('2', 'Se cargarán automáticamente todos los lotes'),
                  const SizedBox(height: 8),
                  _buildInstruccion('3', 'Deberá verificar el peso total'),
                  const SizedBox(height: 8),
                  _buildInstruccion('4', 'Completar el formulario de recepción'),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Botón continuar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 2;
                    _qrTimer?.cancel();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BioWayColors.deepBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'Continuar al Formulario de Entrega',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioEntrega() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Identificar Destinatario
            Container(
              width: double.infinity,
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
                    children: [
                      Icon(
                        Icons.person_search,
                        color: BioWayColors.deepBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Identificar Destinatario',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  if (_destinatarioEncontrado == null) ...[
                    TextField(
                      controller: _destinatarioIdController,
                      decoration: InputDecoration(
                        hintText: 'Ej: R0000003, T0000012',
                        labelText: 'Ingresa el ID o Folio del receptor',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.qr_code),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _buscarDestinatario,
                        icon: const Icon(Icons.search),
                        label: const Text('Buscar Usuario'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BioWayColors.info,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Usuario encontrado
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: BioWayColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: BioWayColors.success.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: BioWayColors.success,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Usuario Encontrado',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _destinatarioEncontrado!['nombre'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: BioWayColors.darkGrey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _destinatarioEncontrado!['direccion'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: BioWayColors.textGrey,
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
              ),
            ),
            
            if (_destinatarioEncontrado != null) ...[
              const SizedBox(height: 20),
              
              // Información de Entrega
              Container(
                width: double.infinity,
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
                      children: [
                        Icon(
                          Icons.local_shipping,
                          color: BioWayColors.deepBlue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Información de Entrega',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Peso Total Entregado
                    _buildFieldLabel('Peso Total Entregado'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pesoEntregadoController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _buildInputDecoration(
                              hintText: 'XXXXX.XXX',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            color: BioWayColors.lightGrey.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'kg',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: BioWayColors.darkGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Evidencia Fotográfica
                    _buildFieldLabel('Evidencia Fotográfica'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _hasImage ? null : _showImageOptions,
                      child: Container(
                        width: double.infinity,
                        height: _hasImage ? null : 150,
                        decoration: BoxDecoration(
                          color: _hasImage ? null : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: _hasImage ? null : Border.all(
                            color: BioWayColors.lightGrey,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _hasImage
                            ? Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _selectedImage!,
                                      width: double.infinity,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: _showImageOptions,
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Cambiar foto'),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tomar Fotografía de la Descarga',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: BioWayColors.darkGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Muestra los lotes en el destino',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: BioWayColors.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Firma y Confirmación
              Container(
                width: double.infinity,
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
                      children: [
                        Icon(
                          Icons.draw,
                          color: BioWayColors.deepBlue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Firma del Receptor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Nombre de quien recibe
                    _buildFieldLabel('Nombre de quien recibe'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nombreRecibeController,
                      decoration: _buildInputDecoration(
                        hintText: 'Nombre completo de quien recibe',
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Área de firma
                    GestureDetector(
                      onTap: _showSignatureDialog,
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hasSignature ? BioWayColors.success : BioWayColors.lightGrey,
                            width: 2,
                          ),
                        ),
                        child: _hasSignature
                            ? Stack(
                                children: [
                                  CustomPaint(
                                    painter: SignaturePainter(_signaturePoints),
                                    size: Size.infinite,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: BioWayColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.draw,
                                    size: 32,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Toca para firmar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: BioWayColors.darkGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Text(
                                      'La persona que recibe el material en destino confirma la recepción correcta de los lotes',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: BioWayColors.textGrey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Comentarios
                    _buildFieldLabel('Comentarios (Opcional)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _comentariosController,
                      maxLines: 3,
                      maxLength: 150,
                      decoration: _buildInputDecoration(
                        hintText: 'Observaciones adicionales',
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Botón completar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _completarEntrega,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.info,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Completar Entrega',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResumenItem(IconData icon, String text, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildResumenRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: BioWayColors.textGrey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: BioWayColors.darkGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildInstruccion(String numero, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: BioWayColors.info,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              numero,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 14,
              color: BioWayColors.darkGrey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: BioWayColors.darkGrey,
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.grey[500],
      ),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: BioWayColors.lightGrey,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: BioWayColors.lightGrey,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: BioWayColors.deepBlue,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Color _getColorForMaterial(String material) {
    switch (material) {
      case 'PET':
        return BioWayColors.petBlue;
      case 'PP':
        return BioWayColors.ppOrange;
      case 'Multi':
        return BioWayColors.otherPurple;
      default:
        return BioWayColors.darkGrey;
    }
  }

  double _calcularPesoTotal() {
    double total = 0;
    for (var origen in _lotesPorOrigen.keys) {
      for (var lote in _lotesPorOrigen[origen]!) {
        if (_lotesSeleccionados.contains(lote['id'])) {
          total += lote['peso'] as double;
        }
      }
    }
    return total;
  }

  List<String> _obtenerOrigenes() {
    Set<String> origenes = {};
    for (var origen in _lotesPorOrigen.keys) {
      for (var lote in _lotesPorOrigen[origen]!) {
        if (_lotesSeleccionados.contains(lote['id'])) {
          origenes.add('A0000${_lotesPorOrigen.keys.toList().indexOf(origen) + 1}');
          break;
        }
      }
    }
    return origenes.toList();
  }
}