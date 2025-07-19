import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';
import '../utils/input_decorations.dart';
import '../utils/input_formatters.dart';
import '../utils/validation_utils.dart';

/// Widget de campo de texto estándar reutilizable
class StandardTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? helperText;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool required;

  const StandardTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.helperText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
    this.suffixIcon,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      textCapitalization: keyboardType == TextInputType.name
          ? TextCapitalization.words
          : TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
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
          borderSide: BorderSide(
            color: BioWayColors.lightGrey,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: BioWayColors.petBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: BioWayColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: BioWayColors.error,
            width: 2,
          ),
        ),
      ),
      validator: validator ?? (required ? (value) => ValidationUtils.validateRequired(value, fieldName: label) : null),
    );
  }
}

/// Campo de teléfono con formato y validación
class PhoneNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;

  const PhoneNumberField({
    super.key,
    required this.controller,
    this.label = 'Teléfono',
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return StandardTextField(
      controller: controller,
      label: label,
      hint: '10 dígitos',
      icon: Icons.phone_android,
      keyboardType: TextInputType.phone,
      required: required,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
        EcoceInputFormatters.phoneNumber(),
      ],
      validator: required ? ValidationUtils.validatePhoneNumber : null,
    );
  }
}

/// Campo RFC con formato y validación
class RFCField extends StatelessWidget {
  final TextEditingController controller;
  final bool required;

  const RFCField({
    super.key,
    required this.controller,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return StandardTextField(
      controller: controller,
      label: 'RFC',
      hint: 'XXXX000000XXX',
      icon: Icons.article,
      required: required,
      helperText: required ? null : 'Tienes 2 semanas para proporcionarlo',
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9Ñ&]')),
        LengthLimitingTextInputFormatter(13),
        _UpperCaseTextFormatter(),
      ],
      validator: required ? ValidationUtils.validateRFC : null,
    );
  }
}

/// Campo de código postal con validación
class PostalCodeField extends StatelessWidget {
  final TextEditingController controller;
  final bool required;

  const PostalCodeField({
    super.key,
    required this.controller,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return StandardTextField(
      controller: controller,
      label: 'Código Postal',
      hint: '00000',
      icon: Icons.location_on,
      keyboardType: TextInputType.number,
      required: required,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5),
      ],
      validator: required ? ValidationUtils.validatePostalCode : null,
    );
  }
}

/// Campo de correo electrónico con validación
class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final bool required;

  const EmailField({
    super.key,
    required this.controller,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return StandardTextField(
      controller: controller,
      label: 'Correo electrónico',
      hint: 'ejemplo@correo.com',
      icon: Icons.email,
      keyboardType: TextInputType.emailAddress,
      required: required,
      validator: required ? ValidationUtils.validateEmail : null,
    );
  }
}

/// Campo de contraseña con toggle de visibilidad
class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final bool required;

  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Contraseña',
    this.hint = 'Mínimo 6 caracteres',
    this.icon = Icons.lock,
    required this.obscureText,
    required this.onToggleVisibility,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return StandardTextField(
      controller: controller,
      label: label,
      hint: hint,
      icon: icon,
      obscureText: obscureText,
      required: required,
      suffixIcon: IconButton(
        icon: Icon(
          obscureText ? Icons.visibility : Icons.visibility_off,
          color: BioWayColors.textGrey,
        ),
        onPressed: onToggleVisibility,
      ),
      validator: required ? (value) => ValidationUtils.validateMinLength(value, 6, fieldName: label) : null,
    );
  }
}

/// Contenedor con gradiente estándar
class GradientContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? primaryColor;
  final double? borderRadius;

  const GradientContainer({
    super.key,
    required this.child,
    this.padding,
    this.primaryColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? BioWayColors.petBlue;
    final radius = borderRadius ?? 16;

    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.05),
            color.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: child,
    );
  }
}

/// Título de sección estándar
class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;

  const SectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor ?? BioWayColors.petBlue, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 14, color: BioWayColors.textGrey),
          ),
        ],
      ],
    );
  }
}

/// Mensaje de validación estándar
class ValidationMessage extends StatelessWidget {
  final String message;
  final MessageType type;

  const ValidationMessage({
    super.key,
    required this.message,
    this.type = MessageType.warning,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (type) {
      case MessageType.error:
        color = BioWayColors.error;
        icon = Icons.error_outline;
        break;
      case MessageType.warning:
        color = BioWayColors.warning;
        icon = Icons.warning_amber_rounded;
        break;
      case MessageType.info:
        color = BioWayColors.petBlue;
        icon = Icons.info_outline;
        break;
      case MessageType.success:
        color = BioWayColors.success;
        icon = Icons.check_circle_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botones de navegación estándar
class StepNavigationButtons extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onPrevious;
  final String nextLabel;
  final Color nextColor;
  final IconData nextIcon;
  final bool isLoading;
  final bool enableNext;

  const StepNavigationButtons({
    super.key,
    required this.onNext,
    this.onPrevious,
    this.nextLabel = 'Continuar',
    this.nextColor = BioWayColors.petBlue,
    this.nextIcon = Icons.arrow_forward,
    this.isLoading = false,
    this.enableNext = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onPrevious != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onPrevious,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Anterior'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: BioWayColors.textGrey),
                foregroundColor: BioWayColors.textGrey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (isLoading || !enableNext) ? null : onNext,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(nextIcon),
            label: Text(isLoading ? 'Procesando...' : nextLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: nextColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tipos de mensaje para ValidationMessage
enum MessageType {
  error,
  warning,
  info,
  success,
}

/// Formateador para convertir texto a mayúsculas
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}