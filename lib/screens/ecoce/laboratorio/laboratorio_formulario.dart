import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../services/lote_service.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/user_session_service.dart';
import 'laboratorio_documentacion.dart';
import 'laboratorio_gestion_muestras.dart';

class LaboratorioFormulario extends StatefulWidget {
  final String muestraId;
  final String transformacionId; // Para el sistema de megalotes
  final Map<String, dynamic> datosMuestra;

  const LaboratorioFormulario({
    super.key,
    required this.muestraId,
    required this.transformacionId,
    required this.datosMuestra,
  });

  @override
  State<LaboratorioFormulario> createState() => _LaboratorioFormularioState();
}

class _LaboratorioFormularioState extends State<LaboratorioFormulario> {
  final _formKey = GlobalKey<FormState>();
  
  // Servicios
  final LoteService _loteService = LoteService();
  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  final UserSessionService _userSession = UserSessionService();
  
  // Controladores para los campos
  final _humedadController = TextEditingController();
  final _pelletsController = TextEditingController();
  final _tipoPolimeroController = TextEditingController();
  final _temperaturaUnicaController = TextEditingController();
  final _temperaturaRangoMinController = TextEditingController();
  final _temperaturaRangoMaxController = TextEditingController();
  final _contenidoOrganicoController = TextEditingController();
  final _contenidoInorganicoController = TextEditingController();
  final _oitController = TextEditingController();
  final _mfiController = TextEditingController();
  final _densidadController = TextEditingController();
  final _normaController = TextEditingController();
  final _observacionesController = TextEditingController();
  
  // Estados para el formulario
  bool _isTemperaturaUnica = true; // true = única, false = rango
  String _unidadTemperatura = 'C°'; // C°, K°, F°
  bool? _cumpleRequisitos; // null = no seleccionado, true = Sí, false = No
  bool _isLoading = false;
  
  @override
  void dispose() {
    _humedadController.dispose();
    _pelletsController.dispose();
    _tipoPolimeroController.dispose();
    _temperaturaUnicaController.dispose();
    _temperaturaRangoMinController.dispose();
    _temperaturaRangoMaxController.dispose();
    _contenidoOrganicoController.dispose();
    _contenidoInorganicoController.dispose();
    _oitController.dispose();
    _mfiController.dispose();
    _densidadController.dispose();
    _normaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  void _handleFormSubmit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor completa todos los campos obligatorios'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (_cumpleRequisitos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor indica si la muestra cumple con los requisitos'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Preparar datos de temperatura
      Map<String, dynamic> temperaturaData = {
        'unidad': _unidadTemperatura,
      };
      
      if (_isTemperaturaUnica) {
        temperaturaData['tipo'] = 'unica';
        temperaturaData['valor'] = double.parse(_temperaturaUnicaController.text);
      } else {
        temperaturaData['tipo'] = 'rango';
        temperaturaData['minima'] = double.parse(_temperaturaRangoMinController.text);
        temperaturaData['maxima'] = double.parse(_temperaturaRangoMaxController.text);
      }

      // Obtener datos del usuario
      final userProfile = await _userSession.getUserProfile();
      
      // Preparar datos del análisis
      final datosAnalisis = {
        'humedad': double.parse(_humedadController.text),
        'pellets_gramo': double.parse(_pelletsController.text),
        'tipo_polimero': _tipoPolimeroController.text.trim(),
        'temperatura_fusion': temperaturaData,
        'contenido_organico': double.parse(_contenidoOrganicoController.text),
        'contenido_inorganico': double.parse(_contenidoInorganicoController.text),
        'oit': _oitController.text.trim(),
        'mfi': _mfiController.text.trim(),
        'densidad': _densidadController.text.trim(),
        'norma': _normaController.text.trim(),
        'observaciones': _observacionesController.text.trim(),
        'cumple_requisitos': _cumpleRequisitos,
        'analista': userProfile?['ecoceNombre'] ?? 'Sin nombre',
      };
      
      // Si hay transformacionId, es un megalote
      if (widget.transformacionId != null) {
        await _loteUnificadoService.actualizarAnalisisMuestraMegalote(
          transformacionId: widget.transformacionId!,
          muestraId: widget.muestraId,
          datosAnalisis: datosAnalisis,
        );
      } else {
        // Sistema antiguo (por compatibilidad)
        await _loteService.actualizarLoteLaboratorio(
          widget.muestraId,
          {
            ...datosAnalisis.map((key, value) => MapEntry('ecoce_laboratorio_$key', value)),
            'ecoce_laboratorio_fecha_analisis': Timestamp.fromDate(DateTime.now()),
            'estado': 'documentacion',
          },
        );
      }

      if (mounted) {
        // Mostrar diálogo de confirmación
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: BioWayColors.success,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text('Análisis Registrado'),
              ],
            ),
            content: const Text(
              '¿Deseas proceder a cargar la documentación del análisis?',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navegar a gestión de muestras
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LaboratorioGestionMuestras(
                        initialTab: 1, // Tab de documentación
                      ),
                    ),
                    (route) => route.isFirst,
                  );
                },
                child: const Text('Más tarde'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navegar a documentación
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LaboratorioDocumentacion(
                        muestraId: widget.muestraId,
                        transformacionId: widget.transformacionId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BioWayColors.ecoceGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cargar Documentos'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar análisis: ${e.toString()}'),
            backgroundColor: BioWayColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildNumericField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? suffix,
    required String pattern, // e.g., "100.00" for percentage, "10.2" for pellets
  }) {
    List<TextInputFormatter> formatters = [];
    TextInputType keyboardType = const TextInputType.numberWithOptions(decimal: true);
    
    if (pattern == "100.00") {
      // Porcentaje - máximo 100.00
      formatters = [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?$')),
      ];
    } else if (pattern == "10.2") {
      // Pellets por gramo - XXXXXXXXXX.XX
      formatters = [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,10}(\.\d{0,2})?$')),
      ];
    } else if (pattern == "5.5") {
      // Temperatura - XXXXX.XXXXX
      formatters = [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,5}(\.\d{0,5})?$')),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BioWayColors.textGrey,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BioWayColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            suffixText: suffix,
            suffixStyle: const TextStyle(
              color: BioWayColors.darkGreen,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: BioWayColors.backgroundGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: BioWayColors.ecoceGreen.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: BioWayColors.ecoceGreen,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: BioWayColors.error,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: BioWayColors.error,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es obligatorio';
            }
            
            if (pattern == "100.00") {
              final numValue = double.tryParse(value);
              if (numValue == null || numValue > 100 || numValue < 0) {
                return 'Debe ser un porcentaje entre 0 y 100';
              }
            }
            
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStringField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLength = 50,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BioWayColors.textGrey,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BioWayColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            filled: true,
            fillColor: BioWayColors.backgroundGrey,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: BioWayColors.ecoceGreen.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: BioWayColors.ecoceGreen,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: BioWayColors.error,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: BioWayColors.error,
                width: 2,
              ),
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
    );
  }

  Widget _buildTemperatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Temperatura de Fusión*',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: BioWayColors.darkGreen,
          ),
        ),
        const SizedBox(height: 12),
        
        // Radio buttons para tipo de temperatura
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Única'),
                value: true,
                groupValue: _isTemperaturaUnica,
                onChanged: (value) {
                  setState(() {
                    _isTemperaturaUnica = value!;
                    _temperaturaRangoMinController.clear();
                    _temperaturaRangoMaxController.clear();
                  });
                },
                activeColor: BioWayColors.ecoceGreen,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Rango'),
                value: false,
                groupValue: _isTemperaturaUnica,
                onChanged: (value) {
                  setState(() {
                    _isTemperaturaUnica = value!;
                    _temperaturaUnicaController.clear();
                  });
                },
                activeColor: BioWayColors.ecoceGreen,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Selector de unidad
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _unidadTemperatura,
              items: ['C°', 'K°', 'F°'].map((unidad) {
                return DropdownMenuItem(
                  value: unidad,
                  child: Text(
                    'Unidad: $unidad',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _unidadTemperatura = value!;
                });
              },
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Campos de temperatura según la selección
        if (_isTemperaturaUnica)
          _buildNumericField(
            label: 'Temperatura $_unidadTemperatura',
            controller: _temperaturaUnicaController,
            hint: 'Ej: 165.5',
            suffix: _unidadTemperatura,
            pattern: '5.5',
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildNumericField(
                  label: 'Mínima $_unidadTemperatura',
                  controller: _temperaturaRangoMinController,
                  hint: 'Ej: 160.0',
                  suffix: _unidadTemperatura,
                  pattern: '5.5',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumericField(
                  label: 'Máxima $_unidadTemperatura',
                  controller: _temperaturaRangoMaxController,
                  hint: 'Ej: 170.0',
                  suffix: _unidadTemperatura,
                  pattern: '5.5',
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: BioWayColors.darkGreen),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Formulario de Muestra',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
              // Header con información de la muestra
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Muestra ID',
                              style: TextStyle(
                                fontSize: 12,
                                color: BioWayColors.textGrey,
                              ),
                            ),
                            Text(
                              widget.muestraId,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: BioWayColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(widget.datosMuestra['peso_muestra'] ?? 0.0).toStringAsFixed(2)} kg',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tarjeta de Características de la Muestra
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: BioWayColors.ecoceGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.science,
                            color: BioWayColors.ecoceGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Características de la Muestra',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    _buildNumericField(
                      label: 'Humedad',
                      controller: _humedadController,
                      hint: 'Ej: 2.45',
                      suffix: '%',
                      pattern: '100.00',
                    ),
                    const SizedBox(height: 16),
                    
                    _buildNumericField(
                      label: 'Pellets por Gramo',
                      controller: _pelletsController,
                      hint: 'Ej: 25.50',
                      pattern: '10.2',
                    ),
                    const SizedBox(height: 16),
                    
                    _buildStringField(
                      label: 'Tipo de Polímero (FTIR)',
                      controller: _tipoPolimeroController,
                      hint: 'Ej: Polietileno de baja densidad',
                      maxLength: 30,
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTemperatureSection(),
                    const SizedBox(height: 16),
                    
                    _buildNumericField(
                      label: 'Contenido Orgánico',
                      controller: _contenidoOrganicoController,
                      hint: 'Ej: 98.50',
                      suffix: '%',
                      pattern: '100.00',
                    ),
                    const SizedBox(height: 16),
                    
                    _buildNumericField(
                      label: 'Contenido Inorgánico',
                      controller: _contenidoInorganicoController,
                      hint: 'Ej: 1.50',
                      suffix: '%',
                      pattern: '100.00',
                    ),
                    const SizedBox(height: 16),
                    
                    _buildStringField(
                      label: 'Tiempo de Inducción de Oxidación (OIT)',
                      controller: _oitController,
                      hint: 'Ej: 45',
                      maxLength: 6,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildStringField(
                      label: 'Índice de fluidez (MFI)',
                      controller: _mfiController,
                      hint: 'Ej: 2.16',
                      maxLength: 10,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildStringField(
                      label: 'Densidad',
                      controller: _densidadController,
                      hint: 'Ej: 0.918',
                      maxLength: 10,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tarjeta de Análisis
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: BioWayColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.analytics,
                            color: BioWayColors.info,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Análisis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    _buildStringField(
                      label: 'Norma o Método de Referencia',
                      controller: _normaController,
                      hint: 'Ej: ASTM D5511-18',
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildStringField(
                      label: 'Observaciones / Interpretación Técnica',
                      controller: _observacionesController,
                      hint: 'Describe las observaciones técnicas del análisis...',
                      maxLength: 200,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),
                    
                    // Checkbox de cumplimiento
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¿La muestra cumple con los requisitos de transformación?*',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: BioWayColors.darkGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Opción Sí
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _cumpleRequisitos = true;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _cumpleRequisitos == true 
                                                ? BioWayColors.success 
                                                : Colors.grey[400]!,
                                            width: 2,
                                          ),
                                          color: _cumpleRequisitos == true 
                                              ? BioWayColors.success 
                                              : Colors.transparent,
                                        ),
                                        child: _cumpleRequisitos == true
                                            ? const Icon(
                                                Icons.check,
                                                size: 14,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Sí',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: _cumpleRequisitos == true 
                                              ? FontWeight.w600 
                                              : FontWeight.normal,
                                          color: _cumpleRequisitos == true 
                                              ? BioWayColors.success 
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 32),
                              // Opción No
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _cumpleRequisitos = false;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _cumpleRequisitos == false 
                                                ? BioWayColors.error 
                                                : Colors.grey[400]!,
                                            width: 2,
                                          ),
                                          color: _cumpleRequisitos == false 
                                              ? BioWayColors.error 
                                              : Colors.transparent,
                                        ),
                                        child: _cumpleRequisitos == false
                                            ? const Icon(
                                                Icons.check,
                                                size: 14,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'No',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: _cumpleRequisitos == false 
                                              ? FontWeight.w600 
                                              : FontWeight.normal,
                                          color: _cumpleRequisitos == false 
                                              ? BioWayColors.error 
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Botón de confirmación
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleFormSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.ecoceGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Confirmar Análisis de la Muestra',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF9333EA), // Purple for laboratorio
                ),
              ),
            ),
        ],
      ),
    );
  }
}