import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../../utils/colors.dart';
import '../shared/utils/dialog_utils.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/photo_evidence_widget.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/user_session_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../models/lotes/lote_unificado_model.dart';

class LaboratorioTomaMuestraScreen extends StatefulWidget {
  final String loteId;
  final LoteUnificadoModel lote;
  
  const LaboratorioTomaMuestraScreen({
    super.key,
    required this.loteId,
    required this.lote,
  });
  
  @override
  State<LaboratorioTomaMuestraScreen> createState() => _LaboratorioTomaMuestraScreenState();
}

class _LaboratorioTomaMuestraScreenState extends State<LaboratorioTomaMuestraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pesoMuestraController = TextEditingController();
  
  // Servicios
  final LoteUnificadoService _loteService = LoteUnificadoService();
  final UserSessionService _userSession = UserSessionService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  // Estado
  bool _isLoading = false;
  List<Offset?> _signaturePoints = [];
  List<String> _capturedPhotos = [];
  
  @override
  void dispose() {
    _pesoMuestraController.dispose();
    super.dispose();
  }
  
  Future<void> _guardarTomaMuestra() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_signaturePoints.isEmpty) {
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Firma requerida',
        message: 'Por favor firme el formulario antes de continuar',
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Convertir firma a base64
      final firmaBase64 = await _convertirFirmaABase64(_signaturePoints);
      
      // Subir firma
      String? firmaUrl;
      if (firmaBase64 != null) {
        firmaUrl = await _storageService.uploadBase64Image(
          firmaBase64,
          'laboratorio_muestra_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      
      // Subir fotos
      final fotosUrls = <String>[];
      for (final foto in _capturedPhotos) {
        final url = await _storageService.uploadBase64Image(
          foto,
          'laboratorio_evidencia_${DateTime.now().millisecondsSinceEpoch}_${fotosUrls.length}',
        );
        if (url != null) {
          fotosUrls.add(url);
        }
      }
      
      // Obtener folio del usuario
      final userData = _userSession.getUserData();
      final folioLaboratorio = userData?['folio'] ?? 'L0000001';
      
      // Registrar análisis (sin transferir el lote)
      await _loteService.registrarAnalisisLaboratorio(
        loteId: widget.loteId,
        pesoMuestra: double.parse(_pesoMuestraController.text),
        folioLaboratorio: folioLaboratorio,
        firmaOperador: firmaUrl,
        evidenciasFoto: fotosUrls,
      );
      
      // Mostrar éxito
      if (mounted) {
        DialogUtils.showSuccessDialog(
          context: context,
          title: 'Muestra registrada',
          message: 'La toma de muestra se ha registrado exitosamente',
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/laboratorio_inicio',
              (route) => false,
            );
          },
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al registrar la muestra: ${e.toString()}',
        );
      }
    }
  }
  
  Future<String?> _convertirFirmaABase64(List<Offset?> points) async {
    // Filtrar puntos null
    final nonNullPoints = points.whereType<Offset>().toList();
    if (nonNullPoints.isEmpty) return null;
    
    // Esta implementación es simplificada
    // En producción se usaría el SignaturePainter para generar la imagen
    return 'data:image/png;base64,placeholder_signature';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: BioWayColors.ecoceGreen,
        title: const Text(
          'Toma de Muestra',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: BioWayColors.ecoceGreen,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del lote
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    
                    // Peso de la muestra
                    _buildPesoMuestraField(),
                    const SizedBox(height: 20),
                    
                    // Firma
                    _buildFirmaSection(),
                    const SizedBox(height: 20),
                    
                    // Evidencias fotográficas
                    _buildEvidenciasSection(),
                    const SizedBox(height: 30),
                    
                    // Botón guardar
                    _buildGuardarButton(),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Lote',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BioWayColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('ID Lote:', widget.lote.id),
            _buildInfoRow('Material:', widget.lote.datosGenerales.tipoMaterial),
            _buildInfoRow('Peso actual:', '${widget.lote.pesoActual.toStringAsFixed(2)} kg'),
            _buildInfoRow('Proceso actual:', widget.lote.datosGenerales.procesoActual),
            if (widget.lote.reciclador != null)
              _buildInfoRow('Reciclador:', widget.lote.reciclador!.usuarioFolio),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPesoMuestraField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peso de la muestra (kg) *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: BioWayColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _pesoMuestraController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: 'Ingrese el peso de la muestra tomada',
            prefixIcon: Icon(Icons.scale, color: BioWayColors.primaryGreen),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: BioWayColors.primaryGreen, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El peso es requerido';
            }
            final peso = double.tryParse(value);
            if (peso == null || peso <= 0) {
              return 'Ingrese un peso válido';
            }
            if (peso > widget.lote.pesoActual) {
              return 'La muestra no puede exceder el peso del lote';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildFirmaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Firma del Operador',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: BioWayColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            // Primero ocultar el teclado
            FocusScope.of(context).unfocus();
            
            // Esperar un breve momento para que el teclado se oculte completamente
            await Future.delayed(const Duration(milliseconds: 300));
            
            if (!mounted) return;
            
            SignatureDialog.show(
              context: context,
              title: 'Firma del Operador',
              initialSignature: _signaturePoints,
              onSignatureSaved: (points) {
                setState(() {
                  _signaturePoints = points;
                });
              },
              primaryColor: BioWayColors.ecoceGreen,
            );
          },
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: _signaturePoints.isEmpty ? Colors.grey[100] : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _signaturePoints.isEmpty ? Colors.grey[300]! : BioWayColors.ecoceGreen,
                width: 2,
              ),
            ),
            child: _signaturePoints.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.draw, size: 32, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Toca para firmar',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : CustomPaint(
                    painter: SignaturePainter(_signaturePoints),
                    size: Size.infinite,
                  ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEvidenciasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evidencias Fotográficas (Opcional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: BioWayColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        PhotoEvidenceFormField(
          title: '',
          maxPhotos: 3,
          minPhotos: 0,
          isRequired: false,
          onPhotosChanged: (photos) {
            setState(() {
              _capturedPhotos = photos.map((file) {
                // Convertir File a base64 string
                final bytes = file.readAsBytesSync();
                return 'data:image/png;base64,${base64Encode(bytes)}';
              }).toList();
            });
          },
          primaryColor: BioWayColors.ecoceGreen,
        ),
      ],
    );
  }
  
  Widget _buildGuardarButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _guardarTomaMuestra,
        style: ElevatedButton.styleFrom(
          backgroundColor: BioWayColors.ecoceGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Registrar Toma de Muestra',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}