// Archivo: widgets/form_field_builder.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';

class FormFieldBuilder {
  /// Construye un TextFormField estándar con el diseño del proyecto
  static Widget buildTextField({
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

  /// Construye el título de un paso con numeración
  static Widget buildStepTitle(int currentStep, int totalSteps, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paso $currentStep de $totalSteps',
          style: const TextStyle(
            fontSize: 14,
            color: BioWayColors.petBlue,
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
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: BioWayColors.textGrey,
          ),
        ),
      ],
    );
  }

  /// Construye botones de navegación estándar
  static Widget buildNavigationButtons({
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

  /// Construye un contenedor con diseño estándar del proyecto
  static Widget buildContainer({
    required Widget child,
    EdgeInsets? padding,
    Color? backgroundColor,
    Color? borderColor,
    bool hasGradient = false,
    bool hasBorder = true,
    double borderRadius = 16,
    double borderWidth = 1,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasGradient ? null : (backgroundColor ?? Colors.white),
        gradient: hasGradient
            ? LinearGradient(
          colors: [
            BioWayColors.petBlue.withValues(alpha: 0.05),
            BioWayColors.petBlue.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder
            ? Border.all(
          color: borderColor ?? BioWayColors.lightGrey,
          width: borderWidth,
        )
            : null,
      ),
      child: child,
    );
  }

  /// Construye una sección con título e ícono
  static Widget buildSectionHeader({
    required String title,
    required IconData icon,
    String? subtitle,
    Widget? trailing,
    Color iconColor = BioWayColors.petBlue,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: BioWayColors.textGrey,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  /// Construye un campo de teléfono específico
  static Widget buildPhoneField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return buildTextField(
      controller: controller,
      label: '$label${isRequired ? ' *' : ''}',
      hint: hint,
      icon: isRequired ? Icons.phone_android : Icons.phone,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        LengthLimitingTextInputFormatter(15),
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
      ],
      validator: validator,
    );
  }

  /// Construye un campo de email específico
  static Widget buildEmailField({
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return buildTextField(
      controller: controller,
      label: 'Correo electrónico *',
      hint: 'ejemplo@correo.com',
      icon: Icons.email,
      keyboardType: TextInputType.emailAddress,
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'El correo es obligatorio';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Ingresa un correo válido';
        }
        return null;
      },
    );
  }

  /// Construye un campo de contraseña con toggle de visibilidad
  static Widget buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return buildTextField(
      controller: controller,
      label: label,
      hint: hint,
      icon: Icons.lock,
      obscureText: obscureText,
      suffixIcon: IconButton(
        icon: Icon(
          obscureText ? Icons.visibility : Icons.visibility_off,
          color: BioWayColors.textGrey,
        ),
        onPressed: onToggleVisibility,
      ),
      validator: validator,
    );
  }

  /// Construye un toggle switch con título y descripción
  static Widget buildToggleSection({
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    Color iconColor = BioWayColors.petBlue,
  }) {
    return buildContainer(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: BioWayColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: BioWayColors.petBlue,
          ),
        ],
      ),
    );
  }
}