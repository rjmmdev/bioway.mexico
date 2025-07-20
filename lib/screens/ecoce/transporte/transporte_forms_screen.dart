import 'package:flutter/material.dart';
import 'dart:io';
import '../../../utils/colors.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/photo_evidence_widget.dart';
import '../shared/utils/dialog_utils.dart';
import '../shared/utils/shared_input_decorations.dart';
import 'transporte_services.dart';

/// Unified forms screen for transport pickup and delivery
class TransporteFormsScreen extends StatefulWidget {
  final TransportFormType formType;
  final List<Map<String, dynamic>> lots;
  final Map<String, dynamic>? recipientData; // For delivery
  final String? qrData; // For delivery
  
  const TransporteFormsScreen({
    super.key,
    required this.formType,
    required this.lots,
    this.recipientData,
    this.qrData,
  });
  
  /// Create pickup form
  static Widget pickup({required List<Map<String, dynamic>> lots}) {
    return TransporteFormsScreen(
      formType: TransportFormType.pickup,
      lots: lots,
    );
  }
  
  /// Create delivery form
  static Widget delivery({
    required List<Map<String, dynamic>> lots,
    required Map<String, dynamic> recipientData,
    required String qrData,
  }) {
    return TransporteFormsScreen(
      formType: TransportFormType.delivery,
      lots: lots,
      recipientData: recipientData,
      qrData: qrData,
    );
  }

  @override
  State<TransporteFormsScreen> createState() => _TransporteFormsScreenState();
}

class _TransporteFormsScreenState extends State<TransporteFormsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  
  // Common controllers
  final TextEditingController _transportNumberController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _operatorController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  
  // Delivery specific controllers
  final TextEditingController _recipientNameController = TextEditingController();
  final TextEditingController _confirmWeightController = TextEditingController();
  
  // Form variables
  String? _selectedVehicleType;
  List<Offset?> _signaturePoints = [];
  bool _hasSignature = false;
  List<String> _photosPaths = [];
  
  @override
  void initState() {
    super.initState();
    if (widget.formType == TransportFormType.delivery && widget.recipientData != null) {
      _recipientNameController.text = widget.recipientData!['nombre'] ?? '';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _transportNumberController.dispose();
    _plateController.dispose();
    _operatorController.dispose();
    _commentsController.dispose();
    _recipientNameController.dispose();
    _confirmWeightController.dispose();
    super.dispose();
  }

  void _showSignatureDialog() {
    FocusScope.of(context).unfocus();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        SignatureDialog.show(
          context: context,
          title: 'Firma del ${widget.formType == TransportFormType.pickup ? "Operador" : "Receptor"}',
          initialSignature: _signaturePoints,
          onSignatureSaved: (points) {
            setState(() {
              _signaturePoints = List.from(points);
              _hasSignature = points.isNotEmpty;
            });
          },
          primaryColor: TransporteServices.getFormColor(widget.formType),
        );
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_hasSignature) {
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Firma requerida',
        message: 'Por favor, agregue su firma para continuar',
      );
      return;
    }
    
    if (_photosPaths.isEmpty) {
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Evidencia requerida',
        message: 'Agregue al menos una foto de evidencia',
      );
      return;
    }
    
    // Show loading
    DialogUtils.showLoadingDialog(
      context: context,
      message: widget.formType == TransportFormType.pickup 
        ? 'Registrando recolección...' 
        : 'Registrando entrega...',
    );
    
    // Simulate save operation
    await Future.delayed(const Duration(seconds: 2));
    
    // Hide loading
    if (mounted) DialogUtils.hideLoadingDialog(context);
    
    // Show success and navigate
    if (mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: BioWayColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: BioWayColors.success,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.formType == TransportFormType.pickup
                  ? 'Recolección Exitosa'
                  : 'Entrega Exitosa',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: BioWayColors.darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.formType == TransportFormType.pickup
                  ? 'Se han recogido ${widget.lots.length} lote(s) correctamente'
                  : 'Se han entregado ${widget.lots.length} lote(s) correctamente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/transporte_inicio',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TransporteServices.getFormColor(widget.formType),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Aceptar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = TransporteServices.getFormColor(widget.formType);
    final totalWeight = TransporteServices.calculateTotalWeight(widget.lots);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: BioWayColors.darkGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          TransporteServices.getFormTitle(widget.formType),
          style: const TextStyle(
            color: BioWayColors.darkGreen,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary header
              _buildSummaryHeader(primaryColor, totalWeight),
              const SizedBox(height: 24),
              
              // Transport info
              _buildTransportInfoSection(primaryColor),
              const SizedBox(height: 20),
              
              // Form specific sections
              if (widget.formType == TransportFormType.delivery) ...[
                _buildDeliverySection(primaryColor),
                const SizedBox(height: 20),
              ],
              
              // Photo evidence
              _buildPhotoEvidenceSection(primaryColor),
              const SizedBox(height: 20),
              
              // Comments
              _buildCommentsSection(primaryColor),
              const SizedBox(height: 20),
              
              // Operator/Recipient info
              _buildPersonInfoSection(primaryColor),
              const SizedBox(height: 20),
              
              // Signature
              _buildSignatureSection(primaryColor),
              const SizedBox(height: 32),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    widget.formType == TransportFormType.pickup
                        ? 'Confirmar Recolección'
                        : 'Confirmar Entrega',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(Color primaryColor, double totalWeight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.1),
            primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.formType == TransportFormType.pickup
                  ? Icons.download_rounded
                  : Icons.upload_rounded,
              color: primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.formType == TransportFormType.pickup
                      ? 'Recolectando ${widget.lots.length} lote${widget.lots.length > 1 ? 's' : ''}'
                      : 'Entregando ${widget.lots.length} lote${widget.lots.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Peso total: ${TransporteServices.formatWeight(totalWeight)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (widget.formType == TransportFormType.delivery && widget.recipientData != null)
                  Text(
                    'Para: ${widget.recipientData!['id']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportInfoSection(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información del Transporte',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BioWayColors.darkGreen,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _transportNumberController,
            textCapitalization: TextCapitalization.characters,
            decoration: SharedInputDecorations.ecoceStyle(
              hintText: 'Ej: T-ABC-1234',
              labelText: 'Número de Transporte',
              primaryColor: primaryColor,
              prefixIcon: Icons.local_shipping,
            ),
            validator: TransporteServices.validateTransportNumber,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedVehicleType,
            decoration: SharedInputDecorations.ecoceStyle(
              hintText: 'Selecciona el tipo',
              labelText: 'Tipo de Vehículo',
              primaryColor: primaryColor,
              prefixIcon: Icons.directions_car,
            ),
            items: TransporteServices.vehicleTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedVehicleType = value),
            validator: (value) => value == null ? 'Este campo es requerido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _plateController,
            textCapitalization: TextCapitalization.characters,
            decoration: SharedInputDecorations.ecoceStyle(
              hintText: 'Ej: ABC-123',
              labelText: 'Placas del Vehículo',
              primaryColor: primaryColor,
              prefixIcon: Icons.pin,
            ),
            validator: TransporteServices.validatePlateNumber,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de Entrega',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BioWayColors.darkGreen,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _recipientNameController,
            enabled: false,
            decoration: SharedInputDecorations.ecoceStyle(
              labelText: 'Destinatario',
              primaryColor: primaryColor,
              prefixIcon: Icons.business,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmWeightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: SharedInputDecorations.ecoceStyle(
              hintText: 'Confirma el peso recibido',
              labelText: 'Peso Confirmado (kg)',
              primaryColor: primaryColor,
              prefixIcon: Icons.scale,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es requerido';
              }
              final weight = double.tryParse(value);
              if (weight == null || weight <= 0) {
                return 'Ingrese un peso válido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoEvidenceSection(Color primaryColor) {
    return PhotoEvidenceWidget(
      title: 'Evidencia Fotográfica',
      maxPhotos: 3,
      minPhotos: 1,
      onPhotosChanged: (photos) {
        setState(() {
          _photosPaths = photos.map((file) => file.path).toList();
        });
      },
      primaryColor: primaryColor,
    );
  }

  Widget _buildCommentsSection(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comentarios Adicionales',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BioWayColors.darkGreen,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _commentsController,
            maxLines: 3,
            decoration: SharedInputDecorations.ecoceStyle(
              hintText: 'Agregue cualquier observación relevante',
              primaryColor: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonInfoSection(Color primaryColor) {
    final isPickup = widget.formType == TransportFormType.pickup;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPickup ? 'Nombre del Operador' : 'Nombre del Receptor',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BioWayColors.darkGreen,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _operatorController,
            textCapitalization: TextCapitalization.words,
            decoration: SharedInputDecorations.ecoceStyle(
              hintText: 'Ingrese su nombre completo',
              primaryColor: primaryColor,
              prefixIcon: Icons.person,
            ),
            validator: TransporteServices.validateOperatorName,
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection(Color primaryColor) {
    final isPickup = widget.formType == TransportFormType.pickup;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                isPickup ? 'Firma del Operador' : 'Firma del Receptor',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
              ),
              if (_hasSignature)
                TextButton(
                  onPressed: _showSignatureDialog,
                  child: const Text('Cambiar'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showSignatureDialog,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasSignature 
                    ? BioWayColors.success 
                    : Colors.grey.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: _hasSignature
                ? CustomPaint(
                    painter: SignaturePainter(
                      points: _signaturePoints,
                      color: BioWayColors.darkGreen,
                    ),
                    size: Size.infinite,
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.draw,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toque para firmar',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Signature painter for preview
class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;

  SignaturePainter({
    required this.points,
    this.color = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}