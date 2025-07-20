import 'package:flutter/material.dart';
import 'dart:io';
import '../../../utils/colors.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/photo_evidence_widget.dart';
import '../shared/utils/dialog_utils.dart';
import '../shared/utils/shared_input_decorations.dart';
import 'reciclador_services.dart';
import 'reciclador_documentacion.dart';

/// Unified forms screen for reciclador entrada and salida
class RecicladorFormsScreen extends StatefulWidget {
  final FormType formType;
  final List<String>? lotIds;
  final int? totalLotes;
  final Map<String, dynamic>? lotData; // For salida form
  
  const RecicladorFormsScreen({
    super.key,
    required this.formType,
    this.lotIds,
    this.totalLotes,
    this.lotData,
  });
  
  /// Create entrada form
  static Widget entrada({
    required List<String> lotIds,
    required int totalLotes,
  }) {
    return RecicladorFormsScreen(
      formType: FormType.entrada,
      lotIds: lotIds,
      totalLotes: totalLotes,
    );
  }
  
  /// Create salida form
  static Widget salida({
    required Map<String, dynamic> lotData,
  }) {
    return RecicladorFormsScreen(
      formType: FormType.salida,
      lotData: lotData,
    );
  }

  @override
  State<RecicladorFormsScreen> createState() => _RecicladorFormsScreenState();
}

enum FormType { entrada, salida }

class _RecicladorFormsScreenState extends State<RecicladorFormsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  
  // Common controllers
  final TextEditingController _operadorController = TextEditingController();
  
  // Entrada controllers
  final TextEditingController _pesoBrutoController = TextEditingController();
  final TextEditingController _pesoNetoController = TextEditingController();
  
  // Salida controllers
  final TextEditingController _pesoSalidaController = TextEditingController();
  final TextEditingController _destinoController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();
  
  // Form variables
  String? _selectedPolimero;
  final List<String> _selectedProcesses = [];
  List<Offset?> _signaturePoints = [];
  bool _hasSignature = false;
  List<File> _photos = [];
  
  // Calculated values
  double _mermaPercentage = 0.0;
  
  @override
  void initState() {
    super.initState();
    if (widget.formType == FormType.salida && widget.lotData != null) {
      _calculateMerma();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _operadorController.dispose();
    _pesoBrutoController.dispose();
    _pesoNetoController.dispose();
    _pesoSalidaController.dispose();
    _destinoController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }

  void _calculateMerma() {
    if (widget.lotData == null || _pesoSalidaController.text.isEmpty) return;
    
    final pesoEntrada = widget.lotData!['peso'] ?? 0.0;
    final pesoSalida = double.tryParse(_pesoSalidaController.text) ?? 0.0;
    
    setState(() {
      _mermaPercentage = RecicladorServices.calculateMerma(pesoEntrada, pesoSalida);
    });
  }

  void _showSignatureDialog() {
    FocusScope.of(context).unfocus();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        SignatureDialog.show(
          context: context,
          title: 'Firma del Operador',
          initialSignature: _signaturePoints,
          onSignatureSaved: (points) {
            setState(() {
              _signaturePoints = List.from(points);
              _hasSignature = points.isNotEmpty;
            });
          },
          primaryColor: BioWayColors.recycleOrange,
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
    
    if (widget.formType == FormType.salida) {
      if (_selectedProcesses.isEmpty) {
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Proceso requerido',
          message: 'Seleccione al menos un proceso aplicado',
        );
        return;
      }
      
      if (_photos.isEmpty) {
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Evidencia requerida',
          message: 'Agregue al menos una foto de evidencia',
        );
        return;
      }
    }
    
    // Show loading
    DialogUtils.showLoadingDialog(
      context: context,
      message: widget.formType == FormType.entrada 
        ? 'Registrando entrada...' 
        : 'Registrando salida...',
    );
    
    // Simulate save operation
    await Future.delayed(const Duration(seconds: 2));
    
    // Hide loading
    if (mounted) DialogUtils.hideLoadingDialog(context);
    
    // Navigate based on form type
    if (widget.formType == FormType.entrada) {
      _navigateToHome();
    } else {
      _navigateToDocumentation();
    }
  }

  void _navigateToHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/reciclador_inicio',
      (route) => false,
    );
  }

  void _navigateToDocumentation() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RecicladorDocumentacion(
          loteData: {
            ...widget.lotData!,
            'pesoSalida': double.parse(_pesoSalidaController.text),
            'merma': _mermaPercentage,
            'procesos': _selectedProcesses,
            'destino': _destinoController.text,
            'comentarios': _comentariosController.text,
            'operador': _operadorController.text,
            'fotos': _photos,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEntrada = widget.formType == FormType.entrada;
    final primaryColor = BioWayColors.recycleOrange;
    
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
          isEntrada ? 'Formulario de Entrada' : 'Formulario de Salida',
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
              // Lot info header
              _buildLotInfoHeader(),
              const SizedBox(height: 24),
              
              // Form fields based on type
              if (isEntrada) ...[
                _buildPolymerSelection(),
                const SizedBox(height: 20),
                _buildWeightFields(),
              ] else ...[
                _buildSalidaWeightField(),
                const SizedBox(height: 20),
                _buildProcessSelection(),
                const SizedBox(height: 20),
                _buildPhotoEvidence(),
                const SizedBox(height: 20),
                _buildDestinationField(),
                const SizedBox(height: 20),
                _buildCommentsField(),
              ],
              
              const SizedBox(height: 20),
              _buildOperatorField(),
              const SizedBox(height: 20),
              _buildSignatureSection(),
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
                    isEntrada ? 'Registrar Entrada' : 'Registrar Salida',
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

  Widget _buildLotInfoHeader() {
    final isEntrada = widget.formType == FormType.entrada;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BioWayColors.recycleOrange.withValues(alpha: 0.1),
            BioWayColors.recycleOrange.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BioWayColors.recycleOrange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: BioWayColors.recycleOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEntrada ? Icons.inbox : Icons.outbox,
              color: BioWayColors.recycleOrange,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEntrada 
                    ? 'Registrando ${widget.totalLotes} lote${widget.totalLotes! > 1 ? 's' : ''}'
                    : 'Lote ${widget.lotData?['id'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
                if (!isEntrada) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Material: ${widget.lotData?['material'] ?? ''} • ${RecicladorServices.formatWeight(widget.lotData?['peso'] ?? 0)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolymerSelection() {
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
            'Tipo de Polímero',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BioWayColors.darkGreen,
            ),
          ),
          const SizedBox(height: 16),
          for (final polymer in RecicladorServices.polymerTypes) ...[
            Builder(
              builder: (context) {
                final isSelected = _selectedPolimero == polymer['id'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => setState(() => _selectedPolimero = polymer['id']),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected 
                            ? polymer['color'] as Color
                            : Colors.grey.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected 
                          ? (polymer['color'] as Color).withValues(alpha: 0.1)
                          : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            polymer['icon'] as IconData,
                            color: polymer['color'] as Color,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  polymer['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  polymer['description'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Radio<String>(
                            value: polymer['id'],
                            groupValue: _selectedPolimero,
                            onChanged: (value) => setState(() => _selectedPolimero = value),
                            activeColor: polymer['color'] as Color,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightFields() {
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
            'Información de Peso',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BioWayColors.darkGreen,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pesoBrutoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: SharedInputDecorations.ecoceStyle(
              hintText: 'Ingrese el peso bruto',
              labelText: 'Peso Bruto (kg)',
              primaryColor: BioWayColors.recycleOrange,
              prefixIcon: Icons.scale,
            ),
            validator: (value) => RecicladorServices.validateWeight(value, min: 0.1),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pesoNetoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: SharedInputDecorations.ecoceStyle(
              hintText: 'Ingrese el peso neto',
              labelText: 'Peso Neto (kg)',
              primaryColor: BioWayColors.recycleOrange,
              prefixIcon: Icons.scale_outlined,
            ),
            validator: (value) => RecicladorServices.validateWeight(value, min: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildSalidaWeightField() {
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
            'Peso de Salida',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BioWayColors.darkGreen,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pesoSalidaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: SharedInputDecorations.ecoceStyle(
              hintText: 'Ingrese el peso de salida',
              labelText: 'Peso de Salida (kg)',
              primaryColor: BioWayColors.recycleOrange,
              prefixIcon: Icons.scale,
            ),
            onChanged: (value) => _calculateMerma(),
            validator: (value) => RecicladorServices.validateWeight(value, min: 0.1),
          ),
          if (_mermaPercentage > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BioWayColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: BioWayColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_down,
                    color: BioWayColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Merma: ${_mermaPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BioWayColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProcessSelection() {
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
            'Procesos Aplicados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BioWayColors.darkGreen,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RecicladorServices.processTypes.map((process) {
              final isSelected = _selectedProcesses.contains(process);
              return FilterChip(
                label: Text(process),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedProcesses.add(process);
                    } else {
                      _selectedProcesses.remove(process);
                    }
                  });
                },
                selectedColor: BioWayColors.recycleOrange.withValues(alpha: 0.2),
                checkmarkColor: BioWayColors.recycleOrange,
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected 
                      ? BioWayColors.recycleOrange 
                      : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoEvidence() {
    return PhotoEvidenceWidget(
      title: 'Evidencia Fotográfica',
      maxPhotos: 4,
      minPhotos: 1,
      onPhotosChanged: (photos) {
        setState(() {
          _photos = photos;
        });
      },
      primaryColor: BioWayColors.recycleOrange,
    );
  }

  Widget _buildDestinationField() {
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
            'Destino del Material',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BioWayColors.darkGreen,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _destinoController,
            decoration: SharedInputDecorations.ecoceStyle(
              hintText: 'Ingrese el destino del material',
              labelText: 'Dirección de destino',
              primaryColor: BioWayColors.recycleOrange,
              prefixIcon: Icons.location_on,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es requerido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsField() {
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
            controller: _comentariosController,
            maxLines: 3,
            decoration: SharedInputDecorations.ecoceStyle(
              hintText: 'Agregue cualquier observación relevante',
              primaryColor: BioWayColors.recycleOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorField() {
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
            'Nombre del Operador',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BioWayColors.darkGreen,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _operadorController,
            textCapitalization: TextCapitalization.words,
            decoration: SharedInputDecorations.ecoceStyle(
              hintText: 'Ingrese su nombre completo',
              primaryColor: BioWayColors.recycleOrange,
              prefixIcon: Icons.person,
            ),
            validator: RecicladorServices.validateOperatorName,
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
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
              const Text(
                'Firma del Operador',
                style: TextStyle(
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