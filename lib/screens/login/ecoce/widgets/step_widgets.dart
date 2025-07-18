// Archivo: widgets/step_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
class BasicInfoStep extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final VoidCallback onNext;

  const BasicInfoStep({
    super.key,
    required this.controllers,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildStepTitle(1, 5, 'Información Básica', 'Datos principales de tu centro de acopio'),
        const SizedBox(height: 32),

        buildTextField(
          controller: controllers['nombreComercial']!,
          label: 'Nombre Comercial *',
          hint: 'Ej: Centro de Acopio San Juan',
          icon: Icons.business,
        ),
        const SizedBox(height: 20),

        buildTextField(
          controller: controllers['rfc']!,
          label: 'RFC (Opcional)',
          hint: 'XXXX000000XXX',
          icon: Icons.article,
          helperText: 'Tienes 2 semanas para proporcionarlo',
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
          controller: controllers['nombreContacto']!,
          label: 'Nombre del Contacto *',
          hint: 'Nombre completo',
          icon: Icons.person,
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: buildTextField(
                controller: controllers['telefono']!,
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
                controller: controllers['telefonoOficina']!,
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
        const SizedBox(height: 40),

        buildNavigationButtons(onNext: onNext),
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

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.selectedLocation;
    // Si ya hay una ubicación guardada, considerarla confirmada
    if (_selectedLocation != null) {
      _locationConfirmed = true;
    }
  }

  void _handleLocationSelected(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _locationConfirmed = false; // Resetear confirmación cuando se cambia la ubicación
    });
    // Notificar al padre
    widget.onLocationSelected?.call(location, '${location.latitude}, ${location.longitude}');
  }

  bool _canContinue() {
    // Validar todos los campos requeridos
    final hasRequiredFields = widget.controllers['estado']!.text.isNotEmpty &&
        widget.controllers['municipio']!.text.isNotEmpty &&
        widget.controllers['colonia']!.text.isNotEmpty &&
        widget.controllers['cp']!.text.isNotEmpty &&
        widget.controllers['direccion']!.text.isNotEmpty &&
        widget.controllers['numExt']!.text.isNotEmpty &&
        widget.controllers['referencias']!.text.isNotEmpty;
    
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
        
        const SizedBox(height: 40),

        buildNavigationButtons(
          onNext: widget.onNext,
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
class OperationsStep extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildStepTitle(3, 5, 'Información Operativa', 'Materiales EPF\'s y capacidad de tu centro'),
        const SizedBox(height: 32),

        MaterialSelector(
          selectedMaterials: selectedMaterials,
          onMaterialToggle: onMaterialToggle,
          customMaterials: customMaterials,
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
                value: hasTransport,
                onChanged: isTransportLocked ? null : onTransportChanged,
                activeColor: BioWayColors.petBlue,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (showCapacitySection) ...[
          CapacitySection(
            largoController: controllers['largo']!,
            anchoController: controllers['ancho']!,
            weightController: controllers['peso']!,
          ),
          const SizedBox(height: 24),
        ],

        buildTextField(
          controller: controllers['linkRedSocial']!,
          label: 'Página web o red social (opcional)',
          hint: 'https://www.ejemplo.com',
          icon: Icons.language,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 40),

        buildNavigationButtons(
          onNext: onNext,
          onPrevious: onPrevious,
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
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
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
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
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
class FiscalDataStep extends StatelessWidget {
  final Map<String, String?> selectedFiles;
  final Function(String) onFileToggle;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const FiscalDataStep({
    super.key,
    required this.selectedFiles,
    required this.onFileToggle,
    required this.onNext,
    required this.onPrevious,
  });

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
            color: BioWayColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BioWayColors.info.withOpacity(0.3)),
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
                      'Sube los documentos en formato PDF o imagen. Máximo 5MB por archivo.\nTienes 2 semanas para completar esta documentación.',
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
          selectedFiles: selectedFiles,
          onFileToggle: onFileToggle,
        ),
        const SizedBox(height: 40),

        buildNavigationButtons(
          onNext: onNext,
          onPrevious: onPrevious,
          nextLabel: 'Siguiente',
        ),
      ],
    );
  }
}

/// Paso 5: Credenciales de Acceso
class CredentialsStep extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildStepTitle(5, 5, 'Credenciales de Acceso', 'Correo, contraseña y términos'),
        const SizedBox(height: 32),

        CredentialsSection(
          emailController: controllers['email']!,
          passwordController: controllers['password']!,
          confirmPasswordController: controllers['confirmPassword']!,
          obscurePassword: obscurePassword,
          obscureConfirmPassword: obscureConfirmPassword,
          onPasswordVisibilityToggle: onPasswordVisibilityToggle,
          onConfirmPasswordVisibilityToggle: onConfirmPasswordVisibilityToggle,
        ),
        const SizedBox(height: 24),

        TermsSection(
          acceptTerms: acceptTerms,
          onTermsChanged: onTermsChanged,
        ),
        const SizedBox(height: 40),

        buildNavigationButtons(
          onNext: onComplete,
          onPrevious: onPrevious,
          nextLabel: 'Completar Registro',
          nextColor: BioWayColors.success,
          nextIcon: Icons.check,
          isLoading: isLoading,
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