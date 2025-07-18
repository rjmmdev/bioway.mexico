import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../utils/colors.dart';
import '../../../../widgets/common/simple_map_widget.dart';
import '../../../ecoce/shared/widgets/form_widgets.dart';
import '../../../ecoce/shared/utils/design_system.dart';
import '../../../ecoce/shared/utils/validation_utils.dart';

/// Header del registro con información del proveedor
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
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(context.responsiveRadius * 2),
          bottomRight: Radius.circular(context.responsiveRadius * 2),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(EcoceDesignSystem.spacing20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: onBackPressed,
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: EcoceDesignSystem.spacing12,
                      vertical: EcoceDesignSystem.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: EcoceDesignSystem.opacityStrong),
                      borderRadius: BorderRadius.circular(EcoceDesignSystem.radiusCircular),
                    ),
                    child: Text(
                      'Paso $currentStep de $totalSteps',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: EcoceDesignSystem.fontSizeSmall,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: EcoceDesignSystem.spacing20),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(EcoceDesignSystem.spacing12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: EcoceDesignSystem.opacityStrong),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  SizedBox(width: EcoceDesignSystem.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: EcoceDesignSystem.fontSizeXXLarge,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: EcoceDesignSystem.spacing4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: EcoceDesignSystem.fontSizeBase,
                            color: Colors.white.withValues(alpha: EcoceDesignSystem.opacityDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: EcoceDesignSystem.spacing24),
              // Progress bar
              LinearProgressIndicator(
                value: currentStep / totalSteps,
                backgroundColor: Colors.white.withValues(alpha: EcoceDesignSystem.opacityStrong),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Título de paso con número y descripción
Widget buildStepTitle({
  required String number,
  required String title,
  required String subtitle,
  IconData? icon,
}) {
  return Container(
    margin: EdgeInsets.only(bottom: EcoceDesignSystem.spacing32),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: BioWayColors.petBlue,
            borderRadius: BorderRadius.circular(EcoceDesignSystem.radiusMedium),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, color: Colors.white, size: 24)
                : Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: EcoceDesignSystem.fontSizeXLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(width: EcoceDesignSystem.spacing16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: EcoceDesignSystem.fontSizeXLarge,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
              ),
              SizedBox(height: EcoceDesignSystem.spacing4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: EcoceDesignSystem.fontSizeBase,
                  color: BioWayColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Paso 1: Información básica
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildStepTitle(
          number: '1',
          title: 'Información Básica',
          subtitle: 'Datos principales de tu empresa',
        ),
        
        StandardTextField(
          controller: controllers['nombreComercial']!,
          label: 'Nombre Comercial',
          hint: 'Ej: Centro de Acopio San Juan',
          icon: Icons.business,
          required: true,
        ),
        SizedBox(height: EcoceDesignSystem.spacing16),
        
        RFCField(controller: controllers['rfc']!),
        SizedBox(height: EcoceDesignSystem.spacing24),
        
        GradientContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.contact_phone,
                title: 'Información de Contacto',
              ),
              SizedBox(height: EcoceDesignSystem.spacing16),
              
              StandardTextField(
                controller: controllers['nombreContacto']!,
                label: 'Nombre del Contacto',
                hint: 'Nombre completo',
                icon: Icons.person,
                required: true,
              ),
              SizedBox(height: EcoceDesignSystem.spacing12),
              
              Row(
                children: [
                  Expanded(
                    child: PhoneNumberField(
                      controller: controllers['telefono']!,
                      label: 'Teléfono Móvil',
                    ),
                  ),
                  SizedBox(width: EcoceDesignSystem.spacing12),
                  Expanded(
                    child: PhoneNumberField(
                      controller: controllers['telefonoOficina']!,
                      label: 'Teléfono Oficina',
                      required: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: EcoceDesignSystem.spacing40),

        StepNavigationButtons(onNext: onNext),
      ],
    );
  }
}

/// Paso 2: Ubicación (simplificado usando componentes compartidos)
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
  }

  bool _canContinue() {
    final hasRequiredFields = widget.controllers['estado']!.text.isNotEmpty &&
        widget.controllers['municipio']!.text.isNotEmpty &&
        widget.controllers['colonia']!.text.isNotEmpty &&
        widget.controllers['cp']!.text.isNotEmpty &&
        widget.controllers['direccion']!.text.isNotEmpty &&
        widget.controllers['numExt']!.text.isNotEmpty &&
        widget.controllers['referencias']!.text.isNotEmpty;
    
    return hasRequiredFields && _selectedLocation != null && _locationConfirmed;
  }

  void _handleLocationSelected(LatLng location, Map<String, String>? addressComponents) {
    setState(() {
      _selectedLocation = location;
      _locationConfirmed = false;
      
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
        if (addressComponents['calle']?.isNotEmpty ?? false) {
          if (widget.controllers['direccion']!.text.isEmpty) {
            widget.controllers['direccion']!.text = addressComponents['calle']!;
          }
        }
      }
    });
    widget.onLocationSelected?.call(location, '${location.latitude}, ${location.longitude}');
  }

  void _showConfirmationDialog() {
    if (!_canContinue()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LocationConfirmationDialog(
          controllers: widget.controllers,
          selectedLocation: _selectedLocation,
          onConfirm: () {
            Navigator.of(context).pop();
            widget.onNext();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildStepTitle(
          number: '2',
          title: 'Ubicación del negocio',
          subtitle: 'Datos de la dirección física',
        ),

        // Dirección de entrega
        GradientContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.location_on,
                title: 'Dirección de entrega',
                subtitle: 'Esta será la dirección para recolección y entrega',
              ),
              SizedBox(height: EcoceDesignSystem.spacing16),

              StandardTextField(
                controller: widget.controllers['estado']!,
                label: 'Estado',
                hint: 'Selecciona tu estado',
                icon: Icons.map,
                required: true,
              ),
              SizedBox(height: EcoceDesignSystem.spacing12),

              StandardTextField(
                controller: widget.controllers['municipio']!,
                label: 'Municipio',
                hint: 'Selecciona tu municipio',
                icon: Icons.location_city,
                required: true,
              ),
              SizedBox(height: EcoceDesignSystem.spacing12),

              StandardTextField(
                controller: widget.controllers['colonia']!,
                label: 'Colonia',
                hint: 'Selecciona tu colonia',
                icon: Icons.holiday_village,
                required: true,
              ),
              SizedBox(height: EcoceDesignSystem.spacing12),

              PostalCodeField(controller: widget.controllers['cp']!),
              SizedBox(height: EcoceDesignSystem.spacing12),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: StandardTextField(
                      controller: widget.controllers['direccion']!,
                      label: 'Nombre de calle',
                      hint: 'Ej: Av. Universidad',
                      icon: Icons.home,
                      required: true,
                    ),
                  ),
                  SizedBox(width: EcoceDesignSystem.spacing12),
                  Expanded(
                    child: StandardTextField(
                      controller: widget.controllers['numExt']!,
                      label: 'Núm. Exterior',
                      hint: '123',
                      icon: Icons.numbers,
                      required: true,
                      inputFormatters: [LengthLimitingTextInputFormatter(10)],
                    ),
                  ),
                ],
              ),
              SizedBox(height: EcoceDesignSystem.spacing12),

              StandardTextField(
                controller: widget.controllers['referencias']!,
                label: 'Referencias de ubicación',
                hint: 'Ej: Frente a la iglesia, entrada lateral',
                icon: Icons.near_me,
                required: true,
                maxLines: 3,
              ),
            ],
          ),
        ),
        
        SizedBox(height: EcoceDesignSystem.spacing24),

        // Búsqueda por dirección
        GradientContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.search_rounded,
                title: 'Búsqueda por dirección',
                subtitle: 'Ingresa los datos de tu ubicación para generar el mapa',
              ),
              SizedBox(height: EcoceDesignSystem.spacing16),

              SimpleMapWidget(
                estado: widget.controllers['estado']!.text,
                municipio: widget.controllers['municipio']!.text,
                colonia: widget.controllers['colonia']!.text,
                codigoPostal: widget.controllers['cp']!.text,
                initialLocation: _selectedLocation,
                onLocationSelected: _handleLocationSelected,
              ),
            ],
          ),
        ),
        
        // Checkbox de confirmación
        if (_selectedLocation != null) ...[
          SizedBox(height: EcoceDesignSystem.spacing20),
          LocationConfirmationCheckbox(
            selectedLocation: _selectedLocation!,
            locationConfirmed: _locationConfirmed,
            onChanged: (value) {
              setState(() {
                _locationConfirmed = value ?? false;
              });
            },
          ),
        ],
        
        SizedBox(height: EcoceDesignSystem.spacing40),

        StepNavigationButtons(
          onNext: _showConfirmationDialog,
          onPrevious: widget.onPrevious,
          enableNext: _canContinue(),
        ),
      ],
    );
  }
}

/// Widget de confirmación de ubicación
class LocationConfirmationCheckbox extends StatelessWidget {
  final LatLng selectedLocation;
  final bool locationConfirmed;
  final Function(bool?) onChanged;

  const LocationConfirmationCheckbox({
    super.key,
    required this.selectedLocation,
    required this.locationConfirmed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(EcoceDesignSystem.spacing16),
      decoration: BoxDecoration(
        color: BioWayColors.lightGreen.withValues(alpha: EcoceDesignSystem.opacityMedium),
        borderRadius: BorderRadius.circular(EcoceDesignSystem.radiusMedium),
        border: Border.all(
          color: BioWayColors.primaryGreen.withValues(alpha: EcoceDesignSystem.opacityIntense),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: BioWayColors.primaryGreen,
                size: 20,
              ),
              SizedBox(width: EcoceDesignSystem.spacing8),
              const Text(
                'Coordenadas guardadas:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                  fontSize: EcoceDesignSystem.fontSizeBase,
                ),
              ),
            ],
          ),
          SizedBox(height: EcoceDesignSystem.spacing8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: EcoceDesignSystem.spacing12,
              vertical: EcoceDesignSystem.spacing8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(EcoceDesignSystem.radiusSmall),
              border: Border.all(color: BioWayColors.lightGrey),
            ),
            child: Text(
              'Latitud: ${selectedLocation.latitude.toStringAsFixed(6)}\nLongitud: ${selectedLocation.longitude.toStringAsFixed(6)}',
              style: const TextStyle(
                fontSize: EcoceDesignSystem.fontSizeMedium,
                color: BioWayColors.darkGreen,
                fontFamily: 'monospace',
                height: EcoceDesignSystem.lineHeightBase,
              ),
            ),
          ),
          SizedBox(height: EcoceDesignSystem.spacing12),
          CheckboxListTile(
            value: locationConfirmed,
            onChanged: onChanged,
            title: const Text(
              'Confirmo que esta es mi ubicación exacta',
              style: TextStyle(
                fontSize: EcoceDesignSystem.fontSizeBase,
                color: BioWayColors.darkGreen,
              ),
            ),
            subtitle: const Text(
              'Debes confirmar tu ubicación para continuar',
              style: TextStyle(
                fontSize: EcoceDesignSystem.fontSizeSmall,
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
    );
  }
}

/// Diálogo de confirmación de ubicación
class LocationConfirmationDialog extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final LatLng? selectedLocation;
  final VoidCallback onConfirm;

  const LocationConfirmationDialog({
    super.key,
    required this.controllers,
    required this.selectedLocation,
    required this.onConfirm,
  });

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: EcoceDesignSystem.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: EcoceDesignSystem.fontSizeMedium,
                color: BioWayColors.textGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '(No especificado)' : value,
              style: TextStyle(
                fontSize: EcoceDesignSystem.fontSizeMedium,
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EcoceDesignSystem.radiusXLarge),
      ),
      child: Container(
        padding: EdgeInsets.all(EcoceDesignSystem.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: BioWayColors.primaryGreen.withValues(alpha: EcoceDesignSystem.opacityMedium),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                size: 40,
                color: BioWayColors.primaryGreen,
              ),
            ),
            SizedBox(height: EcoceDesignSystem.spacing20),
            
            // Título
            const Text(
              'Confirmar información de ubicación',
              style: TextStyle(
                fontSize: EcoceDesignSystem.fontSizeXLarge,
                fontWeight: FontWeight.bold,
                color: BioWayColors.darkGreen,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: EcoceDesignSystem.spacing20),
            
            // Información a confirmar
            Container(
              padding: EdgeInsets.all(EcoceDesignSystem.spacing16),
              decoration: BoxDecoration(
                color: BioWayColors.backgroundGrey,
                borderRadius: BorderRadius.circular(EcoceDesignSystem.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Estado', controllers['estado']!.text),
                  _buildInfoRow('Municipio', controllers['municipio']!.text),
                  _buildInfoRow('Colonia', controllers['colonia']!.text),
                  _buildInfoRow('C.P.', controllers['cp']!.text),
                  _buildInfoRow('Calle', controllers['direccion']!.text),
                  _buildInfoRow('Núm. Ext.', controllers['numExt']!.text),
                  _buildInfoRow('Referencias', controllers['referencias']!.text),
                  const Divider(height: 24, color: BioWayColors.lightGrey),
                  if (selectedLocation != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.gps_fixed, size: 16, color: BioWayColors.primaryGreen),
                        SizedBox(width: EcoceDesignSystem.spacing8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Coordenadas GPS',
                                style: TextStyle(
                                  fontSize: EcoceDesignSystem.fontSizeSmall,
                                  color: BioWayColors.textGrey,
                                ),
                              ),
                              Text(
                                'Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontSize: EcoceDesignSystem.fontSizeMedium,
                                  fontWeight: FontWeight.w500,
                                  color: BioWayColors.darkGreen,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                'Lng: ${selectedLocation!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontSize: EcoceDesignSystem.fontSizeMedium,
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
            SizedBox(height: EcoceDesignSystem.spacing16),
            
            // Mensaje de confirmación
            const Text(
              '¿Toda la información es correcta?',
              style: TextStyle(
                fontSize: EcoceDesignSystem.fontSizeLarge,
                color: BioWayColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: EcoceDesignSystem.spacing24),
            
            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: EcoceDesignSystem.spacing12),
                      side: const BorderSide(color: BioWayColors.textGrey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(EcoceDesignSystem.radiusMedium),
                      ),
                    ),
                    child: const Text(
                      'Revisar',
                      style: TextStyle(
                        fontSize: EcoceDesignSystem.fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.textGrey,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: EcoceDesignSystem.spacing12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BioWayColors.primaryGreen,
                      padding: EdgeInsets.symmetric(vertical: EcoceDesignSystem.spacing12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(EcoceDesignSystem.radiusMedium),
                      ),
                    ),
                    child: const Text(
                      'Confirmar',
                      style: TextStyle(
                        fontSize: EcoceDesignSystem.fontSizeLarge,
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
  }
}

// Los demás pasos seguirían el mismo patrón de refactorización...