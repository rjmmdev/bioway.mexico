import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../shared/widgets/photo_evidence_widget.dart';
import '../shared/widgets/signature_dialog.dart';

class TransporteFormularioEntregaScreen extends StatefulWidget {
  final List<String> lotesEntrega;
  final double pesoTotal;
  
  const TransporteFormularioEntregaScreen({
    super.key,
    required this.lotesEntrega,
    required this.pesoTotal,
  });

  @override
  State<TransporteFormularioEntregaScreen> createState() => _TransporteFormularioEntregaScreenState();
}

class _TransporteFormularioEntregaScreenState extends State<TransporteFormularioEntregaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final TextEditingController _idDestinoController = TextEditingController();
  final TextEditingController _pesoEntregadoController = TextEditingController();
  final TextEditingController _nombreRecibeController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();
  
  // Estado del destinatario
  Map<String, dynamic>? _destinatarioEncontrado;
  bool _buscandoDestinatario = false;
  
  // Variables para la firma
  List<Offset?> _signaturePoints = [];
  bool _hasSignature = false;
  
  // Evidencias fotográficas
  List<File> _photos = [];
  
  @override
  void initState() {
    super.initState();
    // Inicializar peso con el total
    _pesoEntregadoController.text = widget.pesoTotal.toStringAsFixed(1);
  }
  
  @override
  void dispose() {
    _idDestinoController.dispose();
    _pesoEntregadoController.dispose();
    _nombreRecibeController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }
  
  void _buscarUsuario() async {
    if (_idDestinoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un ID o folio'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
      return;
    }
    
    setState(() {
      _buscandoDestinatario = true;
    });
    
    // TODO: Implementar GET /usuarios/:folio
    // Simulación de búsqueda
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _buscandoDestinatario = false;
      _destinatarioEncontrado = {
        'id': _idDestinoController.text,
        'nombre': 'Recicladora Industrial Norte S.A. de C.V.',
        'direccion': 'Av. Industrial #456, Zona Norte, Ciudad, CP 12345',
        'tipo': 'R', // Reciclador
      };
    });
    
    HapticFeedback.mediumImpact();
  }
  
  void _showSignatureDialog() {
    SignatureDialog.show(
      context: context,
      title: 'Firma del Responsable',
      initialSignature: _signaturePoints,
      onSignatureSaved: (points) {
        setState(() {
          _signaturePoints = List.from(points);
          _hasSignature = points.isNotEmpty;
          // TODO: Convertir firma a base64 y guardar en _firmaBase64
        });
      },
      primaryColor: const Color(0xFF1490EE),
    );
  }
  

  
  void _completarEntrega() {
    if (_destinatarioEncontrado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Busca y selecciona un destinatario'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      // TODO: Implementar POST /api/v1/transporte/salida
      // Enviar:
      // - lotes_salida: widget.lotesEntrega
      // - tipo_destino: _destinatarioEncontrado!['tipo']
      // - peso_entregado: _pesoEntregadoController.text
      // - firma_recibe: _firmaBase64
      // - evi_foto: _imagenBase64
      // - comentarios: _comentariosController.text
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrega completada exitosamente'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      
      // Navegar de vuelta al inicio
      Navigator.of(context).popUntil((route) => route.settings.name == '/transporte_inicio');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1490EE), Color(0xFF70B7F9)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Text(
                    'Formulario de Entrega',
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            // Formulario
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      children: [
                        // Identificar Destinatario
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
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
                                    color: const Color(0xFF1490EE),
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Text(
                                    'Identificar Destinatario',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              
                              // Campo de búsqueda
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      key: const Key('input_id_destino'),
                                      controller: _idDestinoController,
                                      textCapitalization: TextCapitalization.characters,
                                      decoration: InputDecoration(
                                        labelText: 'ID o Folio del receptor',
                                        labelStyle: const TextStyle(
                                          color: Color(0xFF606060),
                                          fontSize: 14,
                                        ),
                                        hintText: 'Ej: R0000003',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF9A9A9A),
                                          fontSize: 14,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE0E0E0),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF1490EE),
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      key: const Key('btn_buscar_usuario'),
                                      onPressed: _buscandoDestinatario ? null : _buscarUsuario,
                                      icon: _buscandoDestinatario
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Icon(Icons.search),
                                      label: const Text('Buscar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1490EE),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Resultado de búsqueda
                              if (_destinatarioEncontrado != null) ...[
                                SizedBox(height: screenHeight * 0.02),
                                Container(
                                  padding: EdgeInsets.all(screenWidth * 0.04),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF4CAF50),
                                        size: 24,
                                      ),
                                      SizedBox(width: screenWidth * 0.03),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _destinatarioEncontrado!['nombre'],
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.04,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF2E7D32),
                                              ),
                                            ),
                                            SizedBox(height: screenHeight * 0.005),
                                            Text(
                                              _destinatarioEncontrado!['direccion'],
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.035,
                                                color: const Color(0xFF424242),
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
                        
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Información de Entrega
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
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
                                    color: const Color(0xFF1490EE),
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Text(
                                    'Información de Entrega',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              
                              // Peso Total Entregado
                              TextFormField(
                                key: const Key('input_peso_entregado'),
                                controller: _pesoEntregadoController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Peso Total Entregado*',
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF606060),
                                    fontSize: 14,
                                  ),
                                  hintText: '0.0',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9A9A9A),
                                    fontSize: 14,
                                  ),
                                  suffixText: 'kg',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1490EE),
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE74C3C),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Este campo es obligatorio';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Evidencia Fotográfica
                        PhotoEvidenceFormField(
                          title: 'Evidencia Fotográfica',
                          maxPhotos: 1,
                          minPhotos: 1,
                          isRequired: true,
                          onPhotosChanged: (photos) {
                            setState(() {
                              _photos = photos;
                            });
                          },
                          primaryColor: const Color(0xFF1490EE),
                        ),
                        
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Firma del Responsable
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    color: const Color(0xFF1490EE),
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Text(
                                    'Firma del Responsable',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              
                              // Nombre de quien recibe
                              TextFormField(
                                controller: _nombreRecibeController,
                                decoration: InputDecoration(
                                  labelText: 'Nombre de quien recibe',
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF606060),
                                    fontSize: 14,
                                  ),
                                  hintText: 'Nombre completo',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9A9A9A),
                                    fontSize: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1490EE),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: screenHeight * 0.02),
                              
                              // Área de firma
                              GestureDetector(
                                onTap: _showSignatureDialog,
                                child: Container(
                                  width: double.infinity,
                                  height: screenHeight * 0.15,
                                  decoration: BoxDecoration(
                                    color: _hasSignature ? Colors.white : const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _hasSignature 
                                          ? const Color(0xFF4CAF50) 
                                          : const Color(0xFFE0E0E0),
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
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF4CAF50),
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
                                              Icons.edit,
                                              size: screenWidth * 0.1,
                                              color: const Color(0xFF9A9A9A),
                                            ),
                                            SizedBox(height: screenHeight * 0.01),
                                            Text(
                                              'Toque para firmar',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.04,
                                                color: const Color(0xFF9A9A9A),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Comentarios
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.comment,
                                    color: const Color(0xFF1490EE),
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Text(
                                    'Comentarios',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              
                              TextFormField(
                                key: const Key('input_comentarios'),
                                controller: _comentariosController,
                                maxLines: 3,
                                maxLength: 150,
                                decoration: InputDecoration(
                                  hintText: 'Observaciones adicionales (opcional)',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9A9A9A),
                                    fontSize: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1490EE),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.04),
                        
                        // Botón Completar Entrega
                        SizedBox(
                          key: const Key('btn_completar_entrega'),
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _completarEntrega,
                            icon: const Icon(Icons.check_circle),
                            label: const Text(
                              'Completar Entrega',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1490EE),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}