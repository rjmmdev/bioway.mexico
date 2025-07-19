// Archivo: widgets/step_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../utils/colors.dart';
import '../../../../widgets/common/simple_map_widget.dart';
import 'material_selector.dart';
import 'document_uploader.dart';

/// Header reutilizable para pantallas de registro con indicador de progreso
class RegisterHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBackPressed;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const RegisterHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onBackPressed,
    this.title = 'Registro Acopiador',
    this.subtitle = 'Centro de acopio de materiales',
    this.icon = Icons.warehouse,
    this.color = BioWayColors.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBackPressed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.arrow_back, color: color),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.darkGreen,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: BioWayColors.textGrey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StepProgressIndicator(
            currentStep: currentStep,
            totalSteps: totalSteps,
            color: color,
          ),
        ],
      ),
    );
  }
}

/// Indicador de progreso personalizado para evitar conflictos
class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color color;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.color = BioWayColors.petBlue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index % 2 == 0) {
            final stepNumber = (index ~/ 2) + 1;
            final isActive = stepNumber == currentStep;
            final isCompleted = stepNumber < currentStep;

            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive || isCompleted ? color : BioWayColors.lightGrey,
                border: Border.all(
                  color: isActive ? color : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                  stepNumber.toString(),
                  style: TextStyle(
                    color: isActive ? Colors.white : BioWayColors.textGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          } else {
            final lineIndex = index ~/ 2;
            final isCompleted = lineIndex < currentStep - 1;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: isCompleted ? color : BioWayColors.lightGrey,
              ),
            );
          }
        }),
      ),
    );
  }
}

/// Construye el título de un paso con numeración
Widget buildStepTitle(int currentStep, int totalSteps, String title, String subtitle, {Color? color}) {
  final themeColor = color ?? BioWayColors.petBlue;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Paso $currentStep de $totalSteps',
        style: TextStyle(
          fontSize: 14,
          color: themeColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: BioWayColors.darkGreen,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: BioWayColors.textGrey,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    ],
  );
}

/// Construye un TextFormField estándar
Widget buildTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  String? helperText,
  String? Function(String?)? validator,
  List<TextInputFormatter>? inputFormatters,
  TextInputType? keyboardType,
  int maxLines = 1,
  int? maxLength,
  bool obscureText = false,
  Widget? suffixIcon,
  Function(String)? onChanged,
}) {
  return TextFormField(
    controller: controller,
    validator: validator,
    inputFormatters: inputFormatters,
    keyboardType: keyboardType,
    maxLines: maxLines,
    maxLength: maxLength,
    obscureText: obscureText,
    onChanged: onChanged,
    textCapitalization: maxLines == 1
        ? TextCapitalization.words
        : TextCapitalization.sentences,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      prefixIcon: Icon(icon, color: BioWayColors.petBlue),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: BioWayColors.lightGrey.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BioWayColors.lightGrey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BioWayColors.petBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BioWayColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BioWayColors.error, width: 2),
      ),
      counterText: maxLength != null ? '' : null,
    ),
  );
}

/// Construye botones de navegación estándar
Widget buildNavigationButtons({
  required VoidCallback onNext,
  VoidCallback? onPrevious,
  String nextLabel = 'Continuar',
  Color nextColor = BioWayColors.petBlue,
  IconData nextIcon = Icons.arrow_forward,
  bool isLoading = false,
}) {
  return Row(
    children: [
      if (onPrevious != null) ...[
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : onPrevious,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isLoading ? BioWayColors.lightGrey : BioWayColors.petBlue,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: isLoading ? BioWayColors.lightGrey : BioWayColors.petBlue,
            ),
            child: const Text(
              'Anterior',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
      Expanded(
        child: ElevatedButton(
          onPressed: isLoading ? null : onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: isLoading ? BioWayColors.lightGrey : nextColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (nextIcon == Icons.check) Icon(nextIcon, color: Colors.white),
              if (nextIcon == Icons.check) const SizedBox(width: 8),
              Text(
                nextLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (nextIcon != Icons.check) const SizedBox(width: 8),
              if (nextIcon != Icons.check) Icon(nextIcon, color: Colors.white),
            ],
          ),
        ),
      ),
    ],
  );
}

/// Paso 1: Información Básica
class BasicInfoStep extends StatefulWidget {
  final Map<String, TextEditingController> controllers;
  final VoidCallback onNext;

  const BasicInfoStep({
    super.key,
    required this.controllers,
    required this.onNext,
  });

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  String? _errorMessage;
  
  bool _validateFields() {
    setState(() {
      _errorMessage = null;
    });
    
    if (widget.controllers['nombreComercial']!.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'El nombre comercial es obligatorio';
      });
      return false;
    }
    
    if (widget.controllers['rfc']!.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'El RFC es obligatorio';
      });
      return false;
    }
    
    // Validar formato de RFC (básico)
    final rfc = widget.controllers['rfc']!.text.trim();
    if (rfc.length != 12 && rfc.length != 13) {
      setState(() {
        _errorMessage = 'El RFC debe tener 12 o 13 caracteres';
      });
      return false;
    }
    
    if (widget.controllers['nombreContacto']!.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'El nombre del contacto es obligatorio';
      });
      return false;
    }
    
    if (widget.controllers['telefono']!.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'El teléfono móvil es obligatorio';
      });
      return false;
    }
    
    // Validar formato de teléfono básico (al menos 10 dígitos)
    final telefono = widget.controllers['telefono']!.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (telefono.length < 10) {
      setState(() {
        _errorMessage = 'El teléfono debe tener al menos 10 dígitos';
      });
      return false;
    }
    
    return true;
  }
  
  void _handleNext() {
    if (_validateFields()) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildStepTitle(1, 5, 'Información Básica', 'Datos principales de tu centro'),
        const SizedBox(height: 32),

        buildTextField(
          controller: widget.controllers['nombreComercial']!,
          label: 'Nombre Comercial *',
          hint: 'Ej: Centro de Acopio San Juan',
          icon: Icons.business,
        ),
        const SizedBox(height: 20),

        buildTextField(
          controller: widget.controllers['rfc']!,
          label: 'RFC *',
          hint: 'XXXX000000XXX',
          icon: Icons.article,
          inputFormatters: [
            LengthLimitingTextInputFormatter(13),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              return newValue.copyWith(text: newValue.text.toUpperCase());
            }),
          ],
        ),
        const SizedBox(height: 20),

        buildTextField(
          controller: widget.controllers['nombreContacto']!,
          label: 'Nombre del Contacto *',
          hint: 'Nombre completo',
          icon: Icons.person,
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: buildTextField(
                controller: widget.controllers['telefono']!,
                label: 'Teléfono Móvil *',
                hint: '10 dígitos',
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(15),
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildTextField(
                controller: widget.controllers['telefonoOficina']!,
                label: 'Teléfono Oficina',
                hint: 'Opcional',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(15),
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
                ],
              ),
            ),
          ],
        ),
        
        if (_errorMessage != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 40),

        buildNavigationButtons(onNext: _handleNext),
      ],
    );
  }
}

/// Paso 2: Ubicación
class LocationStep extends StatefulWidget {
  final Map<String, TextEditingController> controllers;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final Function(LatLng, String)? onLocationSelected;
  final LatLng? selectedLocation;
  final String? selectedAddress;

  const LocationStep({
    super.key,
    required this.controllers,
    required this.onNext,
    required this.onPrevious,
    this.onLocationSelected,
    this.selectedLocation,
    this.selectedAddress,
  });

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  LatLng? _selectedLocation;
  bool _locationConfirmed = false;
  bool _hasAttemptedToContinue = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.selectedLocation;
    // Si ya hay una ubicación guardada, considerarla confirmada
    if (_selectedLocation != null) {
      _locationConfirmed = true;
    }
  }
  
  bool _hasTriedToContinue() {
    // Simple check para ver si han llenado algún campo
    return widget.controllers['estado']!.text.isNotEmpty ||
           widget.controllers['municipio']!.text.isNotEmpty ||
           widget.controllers['colonia']!.text.isNotEmpty ||
           widget.controllers['cp']!.text.isNotEmpty;
  }

  void _showConfirmationDialog() {
    if (!_canContinue()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: BioWayColors.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    size: 40,
                    color: BioWayColors.primaryGreen,
                  ),
                ),
                SizedBox(height: 20),
                
                // Título
                Text(
                  'Confirmar información de ubicación',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                
                // Información a confirmar
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BioWayColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Estado', widget.controllers['estado']!.text),
                      _buildInfoRow('Municipio', widget.controllers['municipio']!.text),
                      _buildInfoRow('Colonia', widget.controllers['colonia']!.text),
                      _buildInfoRow('C.P.', widget.controllers['cp']!.text),
                      _buildInfoRow('Calle', widget.controllers['direccion']!.text),
                      _buildInfoRow('Núm. Ext.', widget.controllers['numExt']!.text),
                      _buildInfoRow('Referencias', widget.controllers['referencias']!.text),
                      Divider(height: 24, color: BioWayColors.lightGrey),
                      if (_selectedLocation != null) ...[
                        Row(
                          children: [
                            Icon(Icons.gps_fixed, size: 16, color: BioWayColors.primaryGreen),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Coordenadas GPS',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: BioWayColors.textGrey,
                                    ),
                                  ),
                                  Text(
                                    'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: BioWayColors.darkGreen,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  Text(
                                    'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: BioWayColors.darkGreen,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // Mensaje de confirmación
                Text(
                  '¿Toda la información es correcta?',
                  style: TextStyle(
                    fontSize: 16,
                    color: BioWayColors.textGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                
                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: BioWayColors.textGrey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Revisar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.textGrey,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onNext();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BioWayColors.primaryGreen,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Confirmar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: BioWayColors.textGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '(No especificado)' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: value.isEmpty ? BioWayColors.textGrey : BioWayColors.darkGreen,
                fontStyle: value.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLocationSelected(LatLng location, Map<String, String>? addressComponents) {
    setState(() {
      _selectedLocation = location;
      _locationConfirmed = false; // Resetear confirmación cuando se cambia la ubicación
      
      // Auto-llenar campos con los componentes de dirección si están disponibles
      if (addressComponents != null) {
        if (addressComponents['estado']?.isNotEmpty ?? false) {
          widget.controllers['estado']!.text = addressComponents['estado']!;
        }
        if (addressComponents['municipio']?.isNotEmpty ?? false) {
          widget.controllers['municipio']!.text = addressComponents['municipio']!;
        }
        if (addressComponents['colonia']?.isNotEmpty ?? false) {
          widget.controllers['colonia']!.text = addressComponents['colonia']!;
        }
        if (addressComponents['cp']?.isNotEmpty ?? false) {
          widget.controllers['cp']!.text = addressComponents['cp']!;
        }
        // Si viene la calle, actualizar el campo de dirección
        if (addressComponents['calle']?.isNotEmpty ?? false) {
          // Solo actualizar si el campo está vacío para no sobrescribir entrada manual
          if (widget.controllers['direccion']!.text.isEmpty) {
            widget.controllers['direccion']!.text = addressComponents['calle']!;
          }
        }
      }
    });
    // Notificar al padre
    widget.onLocationSelected?.call(location, '${location.latitude}, ${location.longitude}');
  }

  String _getValidationMessage() {
    if (_selectedLocation == null) {
      return 'Debes generar tu ubicación en el mapa';
    }
    
    if (!_locationConfirmed) {
      return 'Debes confirmar tu ubicación para continuar';
    }
    
    final missingFields = <String>[];
    
    if (widget.controllers['direccion']!.text.trim().isEmpty) {
      missingFields.add('Dirección/Calle');
    }
    if (widget.controllers['numExt']!.text.trim().isEmpty) {
      missingFields.add('Número exterior');
    }
    if (widget.controllers['cp']!.text.trim().isEmpty) {
      missingFields.add('Código postal');
    }
    if (widget.controllers['estado']!.text.trim().isEmpty) {
      missingFields.add('Estado');
    }
    if (widget.controllers['municipio']!.text.trim().isEmpty) {
      missingFields.add('Municipio');
    }
    if (widget.controllers['colonia']!.text.trim().isEmpty) {
      missingFields.add('Colonia');
    }
    if (widget.controllers['referencias']!.text.trim().isEmpty) {
      missingFields.add('Referencias');
    }
    
    if (missingFields.isNotEmpty) {
      if (missingFields.length == 1) {
        return 'Campo requerido: ${missingFields.first}';
      } else {
        return 'Faltan ${missingFields.length} campos requeridos';
      }
    }
    
    return 'Completa todos los campos para continuar';
  }

  bool _canContinue() {
    // Validar todos los campos requeridos
    final hasRequiredFields = widget.controllers['estado']!.text.trim().isNotEmpty &&
        widget.controllers['municipio']!.text.trim().isNotEmpty &&
        widget.controllers['colonia']!.text.trim().isNotEmpty &&
        widget.controllers['cp']!.text.trim().isNotEmpty &&
        widget.controllers['direccion']!.text.trim().isNotEmpty &&
        widget.controllers['numExt']!.text.trim().isNotEmpty &&
        widget.controllers['referencias']!.text.trim().isNotEmpty;
    
    // También debe tener ubicación confirmada
    return hasRequiredFields && _selectedLocation != null && _locationConfirmed;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildStepTitle(2, 5, 'Ubicación', 'Dirección de tu centro de acopio'),
        const SizedBox(height: 32),

        // Sección de búsqueda por dirección
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                BioWayColors.petBlue.withValues(alpha: 0.05),
                BioWayColors.petBlue.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BioWayColors.petBlue.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.search_rounded, color: BioWayColors.petBlue, size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Búsqueda por dirección',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa los datos de tu ubicación para generar el mapa',
                style: TextStyle(fontSize: 14, color: BioWayColors.textGrey),
              ),
              const SizedBox(height: 16),

              // Estado
              buildTextField(
                controller: widget.controllers['estado']!,
                label: 'Estado *',
                hint: 'Selecciona tu estado',
                icon: Icons.map,
              ),
              const SizedBox(height: 16),

              // Municipio
              buildTextField(
                controller: widget.controllers['municipio']!,
                label: 'Municipio *',
                hint: 'Selecciona tu municipio',
                icon: Icons.location_city,
              ),
              const SizedBox(height: 16),

              // Colonia
              buildTextField(
                controller: widget.controllers['colonia']!,
                label: 'Colonia *',
                hint: 'Selecciona tu colonia',
                icon: Icons.holiday_village,
              ),
              const SizedBox(height: 16),
              
              // Código Postal
              buildTextField(
                controller: widget.controllers['cp']!,
                label: 'Código Postal *',
                hint: '00000',
                icon: Icons.location_on,
                keyboardType: TextInputType.number,
                maxLength: 5,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Dirección completa
        Row(
          children: [
            Expanded(
              flex: 2,
              child: buildTextField(
                controller: widget.controllers['direccion']!,
                label: 'Nombre de calle *',
                hint: 'Ej: Av. Universidad',
                icon: Icons.home,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildTextField(
                controller: widget.controllers['numExt']!,
                label: 'Núm. Exterior *',
                hint: '123',
                icon: Icons.numbers,
                inputFormatters: [LengthLimitingTextInputFormatter(10)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        buildTextField(
          controller: widget.controllers['referencias']!,
          label: 'Referencias de ubicación *',
          hint: 'Ej: Frente a la iglesia, entrada lateral',
          icon: Icons.near_me,
          maxLines: 3,
          maxLength: 150,
        ),
        const SizedBox(height: 24),

        // Mapa con marcador arrastrable
        SimpleMapWidget(
          estado: widget.controllers['estado']!.text,
          municipio: widget.controllers['municipio']!.text,
          colonia: widget.controllers['colonia']!.text,
          codigoPostal: widget.controllers['cp']!.text,
          initialLocation: _selectedLocation,
          onLocationSelected: _handleLocationSelected,
        ),
        
        // Checkbox de confirmación si hay ubicación seleccionada
        if (_selectedLocation != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BioWayColors.lightGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: BioWayColors.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: BioWayColors.primaryGreen,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Coordenadas guardadas:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: BioWayColors.lightGrey),
                  ),
                  child: Text(
                    'Latitud: ${_selectedLocation!.latitude.toStringAsFixed(6)}\nLongitud: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: BioWayColors.darkGreen,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                CheckboxListTile(
                  value: _locationConfirmed,
                  onChanged: (value) {
                    setState(() {
                      _locationConfirmed = value ?? false;
                    });
                  },
                  title: Text(
                    'Confirmo que esta es mi ubicación exacta',
                    style: TextStyle(
                      fontSize: 14,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                  subtitle: Text(
                    'Debes confirmar tu ubicación para continuar',
                    style: TextStyle(
                      fontSize: 12,
                      color: BioWayColors.textGrey,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: BioWayColors.primaryGreen,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
            ),
          ),
        ],
        
        // Mensaje de validación si falta algo
        if (!_canContinue()) ...[
          const SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getValidationMessage(),
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 40),

        buildNavigationButtons(
          onNext: _canContinue() ? _showConfirmationDialog : () {},
          onPrevious: widget.onPrevious,
        ),
      ],
    );
  }
}

/// Sección de código postal con búsqueda
class PostalCodeSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final Function(String) onChanged;

  const PostalCodeSection({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BioWayColors.petBlue.withValues(alpha: 0.05),
            BioWayColors.petBlue.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BioWayColors.petBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pin_drop, color: BioWayColors.petBlue, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Código Postal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa tu código postal para facilitar la búsqueda',
            style: TextStyle(fontSize: 14, color: BioWayColors.textGrey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  onChanged: onChanged,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  decoration: InputDecoration(
                    hintText: '00000',
                    counterText: '',
                    prefixIcon: const Icon(Icons.location_searching, color: BioWayColors.petBlue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: BioWayColors.lightGrey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: BioWayColors.petBlue, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isSearching ? 40 : 0,
                child: isSearching
                    ? const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(BioWayColors.petBlue),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Vista previa del mapa
class MapPreview extends StatelessWidget {
  final String estado;
  final String municipio;
  final String colonia;

  const MapPreview({
    super.key,
    required this.estado,
    required this.municipio,
    required this.colonia,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: BioWayColors.lightGrey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BioWayColors.lightGrey, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey.shade200, Colors.grey.shade300],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      estado.isNotEmpty && municipio.isNotEmpty && colonia.isNotEmpty
                          ? 'Mapa de $colonia, $municipio'
                          : 'El mapa se mostrará al seleccionar la ubicación',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    if (estado.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        estado,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (estado.isNotEmpty && municipio.isNotEmpty && colonia.isNotEmpty)
              Positioned(
                bottom: 16,
                right: 16,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Ubicación exacta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.petBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Paso 3: Información Operativa
class OperationsStep extends StatefulWidget {
  final Map<String, TextEditingController> controllers;
  final Set<String> selectedMaterials;
  final bool hasTransport;
  final Function(String) onMaterialToggle;
  final Function(bool) onTransportChanged;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool isTransportLocked;
  final bool showCapacitySection;
  final List<Map<String, String>>? customMaterials;

  const OperationsStep({
    super.key,
    required this.controllers,
    required this.selectedMaterials,
    required this.hasTransport,
    required this.onMaterialToggle,
    required this.onTransportChanged,
    required this.onNext,
    required this.onPrevious,
    this.isTransportLocked = false,
    this.showCapacitySection = true,
    this.customMaterials,
  });

  @override
  State<OperationsStep> createState() => _OperationsStepState();
}

class _OperationsStepState extends State<OperationsStep> {
  String? _errorMessage;
  
  bool _validateFields() {
    setState(() {
      _errorMessage = null;
    });
    
    // Validar que haya al menos un material seleccionado
    if (widget.selectedMaterials.isEmpty) {
      setState(() {
        _errorMessage = 'Debes seleccionar al menos un tipo de material';
      });
      return false;
    }
    
    // Validar capacidad si se muestra esa sección
    if (widget.showCapacitySection) {
      final largo = widget.controllers['largo']!.text.trim();
      final ancho = widget.controllers['ancho']!.text.trim();
      final peso = widget.controllers['peso']!.text.trim();
      
      if (largo.isEmpty || ancho.isEmpty || peso.isEmpty) {
        setState(() {
          _errorMessage = 'Debes completar todas las dimensiones de capacidad';
        });
        return false;
      }
      
      // Validar que sean números válidos
      if (double.tryParse(largo) == null || double.tryParse(ancho) == null || double.tryParse(peso) == null) {
        setState(() {
          _errorMessage = 'Las dimensiones deben ser números válidos';
        });
        return false;
      }
      
      // Validar que sean valores positivos
      if (double.parse(largo) <= 0 || double.parse(ancho) <= 0 || double.parse(peso) <= 0) {
        setState(() {
          _errorMessage = 'Las dimensiones deben ser mayores a cero';
        });
        return false;
      }
    }
    
    return true;
  }
  
  void _handleNext() {
    if (_validateFields()) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildStepTitle(3, 5, 'Información Operativa', 'Materiales EPF\'s y capacidad de tu centro'),
        const SizedBox(height: 32),

        MaterialSelector(
          selectedMaterials: widget.selectedMaterials,
          onMaterialToggle: widget.onMaterialToggle,
          customMaterials: widget.customMaterials,
        ),
        const SizedBox(height: 24),

        // Toggle de transporte
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BioWayColors.lightGrey, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_shipping, color: BioWayColors.petBlue, size: 24),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '¿Cuentas con transporte propio?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.darkGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Para recolección de materiales',
                      style: TextStyle(
                        fontSize: 14,
                        color: BioWayColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.hasTransport,
                onChanged: widget.isTransportLocked ? null : widget.onTransportChanged,
                activeColor: BioWayColors.petBlue,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (widget.showCapacitySection) ...[
          CapacitySection(
            largoController: widget.controllers['largo']!,
            anchoController: widget.controllers['ancho']!,
            weightController: widget.controllers['peso']!,
          ),
          const SizedBox(height: 24),
        ],

        buildTextField(
          controller: widget.controllers['linkRedSocial']!,
          label: 'Página web o red social (opcional)',
          hint: 'https://www.ejemplo.com',
          icon: Icons.language,
          keyboardType: TextInputType.url,
        ),
        
        if (_errorMessage != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 40),

        buildNavigationButtons(
          onNext: _handleNext,
          onPrevious: widget.onPrevious,
        ),
      ],
    );
  }
}

/// Widget personalizado para input de dimensiones con formato X
class DimensionsInput extends StatefulWidget {
  final TextEditingController largoController;
  final TextEditingController anchoController;
  final String label;
  final String? helperText;
  final IconData icon;

  const DimensionsInput({
    super.key,
    required this.largoController,
    required this.anchoController,
    this.label = 'Dimensiones (metros) *',
    this.helperText = 'Formato: largo X ancho',
    this.icon = Icons.straighten,
  });

  @override
  State<DimensionsInput> createState() => _DimensionsInputState();
}

class _DimensionsInputState extends State<DimensionsInput> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, color: BioWayColors.petBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: BioWayColors.darkGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BioWayColors.lightGrey, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.largoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: '15.25',
                    hintStyle: TextStyle(color: BioWayColors.textGrey.withValues(alpha: 0.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                  inputFormatters: [
                    DecimalTextInputFormatter(),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  'X',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.petBlue,
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: widget.anchoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: '15.20',
                    hintStyle: TextStyle(color: BioWayColors.textGrey.withValues(alpha: 0.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                  inputFormatters: [
                    DecimalTextInputFormatter(),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              widget.helperText!,
              style: const TextStyle(
                fontSize: 12,
                color: BioWayColors.textGrey,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Sección de capacidad de prensado específica para Acopiador
class CapacitySection extends StatelessWidget {
  final TextEditingController largoController;
  final TextEditingController anchoController;
  final TextEditingController weightController;

  const CapacitySection({
    super.key,
    required this.largoController,
    required this.anchoController,
    required this.weightController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BioWayColors.petBlue.withValues(alpha: 0.05),
            BioWayColors.petBlue.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BioWayColors.petBlue.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compress, color: BioWayColors.petBlue, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Capacidad de Prensado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: BioWayColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'OBLIGATORIO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Información importante para coordinar la logística',
            style: TextStyle(fontSize: 14, color: BioWayColors.textGrey),
          ),
          const SizedBox(height: 16),

          DimensionsInput(
            largoController: largoController,
            anchoController: anchoController,
          ),
          const SizedBox(height: 16),

          buildTextField(
            controller: weightController,
            label: 'Peso máximo (kg) *',
            hint: 'Ej: 500.5',
            icon: Icons.scale,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paso 4: Datos Fiscales y Documentos
class FiscalDataStep extends StatefulWidget {
  final Map<String, String?> selectedFiles;
  final Map<String, PlatformFile?> platformFiles;
  final Function(String, PlatformFile?, String?) onFileSelected;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool isUploading;

  const FiscalDataStep({
    super.key,
    required this.selectedFiles,
    required this.platformFiles,
    required this.onFileSelected,
    required this.onNext,
    required this.onPrevious,
    this.isUploading = false,
  });
  
  @override
  State<FiscalDataStep> createState() => _FiscalDataStepState();
}

class _FiscalDataStepState extends State<FiscalDataStep> {
  String? _errorMessage;
  
  bool _validateDocuments() {
    setState(() {
      _errorMessage = null;
    });
    
    // Verificar que todos los documentos estén seleccionados
    final missingDocs = <String>[];
    
    if (widget.selectedFiles['const_sit_fis'] == null) {
      missingDocs.add('Constancia de Situación Fiscal');
    }
    if (widget.selectedFiles['comp_domicilio'] == null) {
      missingDocs.add('Comprobante de Domicilio');
    }
    if (widget.selectedFiles['banco_caratula'] == null) {
      missingDocs.add('Carátula de Estado de Cuenta');
    }
    if (widget.selectedFiles['ine'] == null) {
      missingDocs.add('INE');
    }
    
    if (missingDocs.isNotEmpty) {
      setState(() {
        if (missingDocs.length == 1) {
          _errorMessage = 'Falta subir: ${missingDocs.first}';
        } else {
          _errorMessage = 'Faltan ${missingDocs.length} documentos por subir';
        }
      });
      return false;
    }
    
    return true;
  }
  
  void _handleNext() {
    if (_validateDocuments()) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildStepTitle(4, 5, 'Datos Fiscales', 'Documentación fiscal requerida'),
        const SizedBox(height: 32),

        // Información sobre documentos requeridos
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BioWayColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BioWayColors.info.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: BioWayColors.info, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Documentos Fiscales Requeridos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sube los documentos en formato PDF o imagen. Máximo 5MB por archivo.\nTodos los documentos son obligatorios para continuar.',
                      style: TextStyle(
                        fontSize: 12,
                        color: BioWayColors.textGrey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        DocumentUploader(
          selectedFiles: widget.selectedFiles,
          onFileSelected: widget.onFileSelected,
          platformFiles: widget.platformFiles,
          isUploading: widget.isUploading,
        ),
        
        if (_errorMessage != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 40),

        buildNavigationButtons(
          onNext: _handleNext,
          onPrevious: widget.onPrevious,
          nextLabel: 'Siguiente',
        ),
      ],
    );
  }
}

/// Paso 5: Credenciales de Acceso
class CredentialsStep extends StatefulWidget {
  final Map<String, TextEditingController> controllers;
  final bool acceptTerms;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final Function(bool) onTermsChanged;
  final VoidCallback onPasswordVisibilityToggle;
  final VoidCallback onConfirmPasswordVisibilityToggle;
  final VoidCallback onComplete;
  final VoidCallback onPrevious;
  final bool isLoading;

  const CredentialsStep({
    super.key,
    required this.controllers,
    required this.acceptTerms,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTermsChanged,
    required this.onPasswordVisibilityToggle,
    required this.onConfirmPasswordVisibilityToggle,
    required this.onComplete,
    required this.onPrevious,
    this.isLoading = false,
  });

  @override
  State<CredentialsStep> createState() => _CredentialsStepState();
}

class _CredentialsStepState extends State<CredentialsStep> {
  String? _errorMessage;
  
  bool _validateFields() {
    setState(() {
      _errorMessage = null;
    });
    
    final email = widget.controllers['email']!.text.trim();
    final password = widget.controllers['password']!.text;
    final confirmPassword = widget.controllers['confirmPassword']!.text;
    
    // Validar email
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'El correo electrónico es obligatorio';
      });
      return false;
    }
    
    // Validar formato de email
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = 'Ingresa un correo electrónico válido';
      });
      return false;
    }
    
    // Validar contraseña
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'La contraseña es obligatoria';
      });
      return false;
    }
    
    if (password.length < 6) {
      setState(() {
        _errorMessage = 'La contraseña debe tener al menos 6 caracteres';
      });
      return false;
    }
    
    // Validar confirmación de contraseña
    if (confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Debes confirmar tu contraseña';
      });
      return false;
    }
    
    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Las contraseñas no coinciden';
      });
      return false;
    }
    
    // Validar términos
    if (!widget.acceptTerms) {
      setState(() {
        _errorMessage = 'Debes aceptar los términos y condiciones';
      });
      return false;
    }
    
    return true;
  }
  
  void _handleComplete() {
    if (_validateFields()) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildStepTitle(5, 5, 'Credenciales de Acceso', 'Correo, contraseña y términos'),
        const SizedBox(height: 32),

        CredentialsSection(
          emailController: widget.controllers['email']!,
          passwordController: widget.controllers['password']!,
          confirmPasswordController: widget.controllers['confirmPassword']!,
          obscurePassword: widget.obscurePassword,
          obscureConfirmPassword: widget.obscureConfirmPassword,
          onPasswordVisibilityToggle: widget.onPasswordVisibilityToggle,
          onConfirmPasswordVisibilityToggle: widget.onConfirmPasswordVisibilityToggle,
        ),
        const SizedBox(height: 24),

        TermsSection(
          acceptTerms: widget.acceptTerms,
          onTermsChanged: widget.onTermsChanged,
        ),
        
        if (_errorMessage != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 40),

        buildNavigationButtons(
          onNext: _handleComplete,
          onPrevious: widget.onPrevious,
          nextLabel: 'Completar Registro',
          nextColor: BioWayColors.success,
          nextIcon: Icons.check,
          isLoading: widget.isLoading,
        ),
      ],
    );
  }
}

/// Sección de credenciales de acceso
class CredentialsSection extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onPasswordVisibilityToggle;
  final VoidCallback onConfirmPasswordVisibilityToggle;

  const CredentialsSection({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onPasswordVisibilityToggle,
    required this.onConfirmPasswordVisibilityToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BioWayColors.lightGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle, color: BioWayColors.petBlue, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Datos de Acceso',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          buildTextField(
            controller: emailController,
            label: 'Correo electrónico *',
            hint: 'ejemplo@correo.com',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          buildTextField(
            controller: passwordController,
            label: 'Contraseña *',
            hint: 'Mínimo 6 caracteres',
            icon: Icons.lock,
            obscureText: obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: BioWayColors.textGrey,
              ),
              onPressed: onPasswordVisibilityToggle,
            ),
          ),
          const SizedBox(height: 16),

          buildTextField(
            controller: confirmPasswordController,
            label: 'Confirmar contraseña *',
            hint: 'Repite tu contraseña',
            icon: Icons.lock_outline,
            obscureText: obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                color: BioWayColors.textGrey,
              ),
              onPressed: onConfirmPasswordVisibilityToggle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección de términos y condiciones
class TermsSection extends StatelessWidget {
  final bool acceptTerms;
  final Function(bool) onTermsChanged;

  const TermsSection({
    super.key,
    required this.acceptTerms,
    required this.onTermsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BioWayColors.petBlue.withValues(alpha: 0.05),
            BioWayColors.petBlue.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BioWayColors.petBlue.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel, color: BioWayColors.petBlue, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Términos y Condiciones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: acceptTerms,
                onChanged: (value) => onTermsChanged(value ?? false),
                activeColor: BioWayColors.petBlue,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'He leído y acepto los términos y condiciones de uso y el aviso de privacidad de ECOCE.',
                        style: TextStyle(fontSize: 14, color: BioWayColors.darkGreen),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        children: [
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Ver términos y condiciones',
                              style: TextStyle(
                                color: BioWayColors.petBlue,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Ver aviso de privacidad',
                              style: TextStyle(
                                color: BioWayColors.petBlue,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Diálogo de éxito reutilizable
class SuccessDialog extends StatelessWidget {
  final String folio;
  final VoidCallback onContinue;
  final String title;
  final String message;

  const SuccessDialog({
    super.key,
    required this.folio,
    required this.onContinue,
    this.title = '¡Registro exitoso!',
    this.message = 'Tu cuenta ha sido creada correctamente',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: BioWayColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 40, color: BioWayColors.success),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: BioWayColors.darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: BioWayColors.textGrey),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BioWayColors.petBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BioWayColors.petBlue.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Tu folio de registro es:',
                    style: TextStyle(fontSize: 14, color: BioWayColors.darkGreen),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    folio,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGreen,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BioWayColors.petBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formatter personalizado para agregar punto decimal automáticamente después de 2 dígitos
class DecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remover cualquier carácter no numérico excepto el punto
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    
    // Si el texto está vacío, permitir
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Remover puntos existentes para reformatear
    String numbersOnly = newText.replaceAll('.', '');
    
    // Limitar a 4 dígitos máximo
    if (numbersOnly.length > 4) {
      numbersOnly = numbersOnly.substring(0, 4);
    }
    
    // Si hay más de 2 dígitos, insertar el punto después del segundo dígito
    if (numbersOnly.length > 2) {
      newText = numbersOnly.substring(0, 2) + '.' + numbersOnly.substring(2);
    } else {
      newText = numbersOnly;
    }
    
    // Calcular la nueva posición del cursor
    int selectionIndex = newText.length;
    
    // Si estamos borrando y el cursor estaba después del punto, ajustar
    if (oldValue.text.length > newValue.text.length && 
        oldValue.selection.baseOffset == 3 && 
        newText.length == 2) {
      selectionIndex = 2;
    }
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
