import 'package:flutter/services.dart';

/// Formateadores de entrada personalizados para campos de formulario
class EcoceInputFormatters {
  EcoceInputFormatters._();

  /// Formateador para números de teléfono mexicanos (###-###-####)
  static TextInputFormatter phoneNumber() => _PhoneNumberFormatter();

  /// Formateador para RFC (convierte a mayúsculas)
  static TextInputFormatter rfc() => _UpperCaseFormatter();

  /// Formateador para código postal (solo 5 dígitos)
  static TextInputFormatter postalCode() => _PostalCodeFormatter();

  /// Formateador para moneda mexicana
  static TextInputFormatter currency() => _CurrencyFormatter();

  /// Formateador para peso con decimales (###.##)
  static TextInputFormatter weight() => _WeightFormatter();

  /// Formateador para dimensiones (##.## x ##.##)
  static TextInputFormatter dimensions() => _DimensionsFormatter();

  /// Formateador genérico para mayúsculas
  static TextInputFormatter upperCase() => _UpperCaseFormatter();

  /// Formateador para porcentajes (0-100)
  static TextInputFormatter percentage() => _PercentageFormatter();
}

/// Formateador de números de teléfono
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Eliminar todos los caracteres no numéricos
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    // Limitar a 10 dígitos
    final truncated = digitsOnly.length > 10 ? digitsOnly.substring(0, 10) : digitsOnly;
    
    // Aplicar formato ###-###-####
    String formatted = '';
    for (int i = 0; i < truncated.length; i++) {
      if (i == 3 || i == 6) {
        formatted += '-';
      }
      formatted += truncated[i];
    }
    
    // Calcular la nueva posición del cursor
    int selectionIndex = formatted.length;
    
    // Si estamos borrando y el último caracter es un guión, retroceder uno más
    if (oldValue.text.length > newValue.text.length && 
        formatted.isNotEmpty && 
        formatted[formatted.length - 1] == '-') {
      formatted = formatted.substring(0, formatted.length - 1);
      selectionIndex = formatted.length;
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

/// Formateador para convertir texto a mayúsculas
class _UpperCaseFormatter extends TextInputFormatter {
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

/// Formateador para código postal
class _PostalCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Solo permitir dígitos
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    // Limitar a 5 dígitos
    final truncated = digitsOnly.length > 5 ? digitsOnly.substring(0, 5) : digitsOnly;
    
    return TextEditingValue(
      text: truncated,
      selection: TextSelection.collapsed(offset: truncated.length),
    );
  }
}

/// Formateador para moneda
class _CurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Eliminar todo excepto dígitos y punto decimal
    String value = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    
    // Asegurar solo un punto decimal
    final parts = value.split('.');
    if (parts.length > 2) {
      value = '${parts[0]}.${parts.sublist(1).join('')}';
    }
    
    // Limitar a 2 decimales
    if (parts.length == 2 && parts[1].length > 2) {
      value = '${parts[0]}.${parts[1].substring(0, 2)}';
    }
    
    // Agregar comas para miles
    if (parts.isNotEmpty) {
      String integerPart = parts[0];
      String formattedInteger = '';
      
      for (int i = integerPart.length - 1; i >= 0; i--) {
        if ((integerPart.length - i - 1) % 3 == 0 && i != integerPart.length - 1) {
          formattedInteger = ',$formattedInteger';
        }
        formattedInteger = integerPart[i] + formattedInteger;
      }
      
      value = parts.length == 2 ? '$formattedInteger.${parts[1]}' : formattedInteger;
    }
    
    // Agregar símbolo de peso
    if (value.isNotEmpty) {
      value = '\$ $value';
    }
    
    return TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

/// Formateador para peso con decimales
class _WeightFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Permitir solo dígitos y un punto decimal
    if (!RegExp(r'^\d*\.?\d{0,3}$').hasMatch(newValue.text)) {
      return oldValue;
    }
    
    return newValue;
  }
}

/// Formateador para dimensiones (ancho x largo)
class _DimensionsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Eliminar espacios
    String text = newValue.text.replaceAll(' ', '');
    
    // Permitir solo dígitos, punto decimal y 'x'
    text = text.replaceAll(RegExp(r'[^\d.x]'), '');
    
    // Asegurar solo una 'x'
    final parts = text.split('x');
    if (parts.length > 2) {
      text = '${parts[0]}x${parts[1]}';
    }
    
    // Limitar decimales en cada parte
    if (parts.isNotEmpty) {
      for (int i = 0; i < parts.length && i < 2; i++) {
        final numberParts = parts[i].split('.');
        if (numberParts.length > 1 && numberParts[1].length > 2) {
          parts[i] = '${numberParts[0]}.${numberParts[1].substring(0, 2)}';
        }
      }
      text = parts.join(' x ');
    }
    
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Formateador para porcentajes
class _PercentageFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Eliminar todo excepto dígitos
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }
    
    // Convertir a número
    final number = int.tryParse(digitsOnly) ?? 0;
    
    // Limitar a 100
    final limited = number > 100 ? 100 : number;
    
    // Formatear con símbolo de porcentaje
    final formatted = '$limited%';
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length - 1),
    );
  }
}