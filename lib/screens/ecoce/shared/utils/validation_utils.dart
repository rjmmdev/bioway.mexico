/// Utilidades de validación compartidas para formularios ECOCE
class ValidationUtils {
  /// Valida campo requerido
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null 
          ? '$fieldName es obligatorio' 
          : 'Este campo es obligatorio';
    }
    return null;
  }

  /// Valida longitud mínima
  static String? validateMinLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null 
          ? '$fieldName es obligatorio' 
          : 'Este campo es obligatorio';
    }
    if (value.trim().length < minLength) {
      return 'Debe tener al menos $minLength caracteres';
    }
    return null;
  }

  /// Valida peso/número con rango
  static String? validateWeight(String? value, {
    double? min, 
    double? max,
    String fieldName = 'El peso',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Ingrese un número válido';
    }
    
    if (min != null && weight < min) {
      return '$fieldName debe ser mayor a $min';
    }
    
    if (max != null && weight > max) {
      return '$fieldName debe ser menor a $max';
    }
    
    if (weight <= 0) {
      return '$fieldName debe ser mayor a 0';
    }
    
    return null;
  }

  /// Valida número entero
  static String? validateInteger(String? value, {
    int? min,
    int? max,
    String fieldName = 'El valor',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    
    final number = int.tryParse(value);
    if (number == null) {
      return 'Ingrese un número entero válido';
    }
    
    if (min != null && number < min) {
      return '$fieldName debe ser mayor o igual a $min';
    }
    
    if (max != null && number > max) {
      return '$fieldName debe ser menor o igual a $max';
    }
    
    return null;
  }

  /// Valida email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es obligatorio';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingrese un correo válido';
    }
    
    return null;
  }

  /// Valida teléfono mexicano
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es obligatorio';
    }
    
    // Eliminar espacios y caracteres especiales
    final cleanPhone = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Validar formato mexicano (10 dígitos o con código de país)
    if (!RegExp(r'^(\+52)?[1-9]\d{9}$').hasMatch(cleanPhone)) {
      return 'Ingrese un teléfono válido (10 dígitos)';
    }
    
    return null;
  }

  /// Valida RFC mexicano
  static String? validateRFC(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El RFC es obligatorio';
    }
    
    // RFC pattern para personas morales (12 caracteres) y físicas (13 caracteres)
    final rfcRegex = RegExp(r'^[A-ZÑ&]{3,4}\d{6}[A-Z\d]{3}$');
    if (!rfcRegex.hasMatch(value.toUpperCase())) {
      return 'Ingrese un RFC válido';
    }
    
    return null;
  }

  /// Valida código postal mexicano
  static String? validatePostalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El código postal es obligatorio';
    }
    
    if (!RegExp(r'^\d{5}$').hasMatch(value)) {
      return 'Ingrese un código postal válido (5 dígitos)';
    }
    
    return null;
  }

  /// Valida selección de dropdown
  static String? validateSelection(dynamic value, {String? fieldName}) {
    if (value == null) {
      return fieldName != null 
          ? 'Seleccione $fieldName' 
          : 'Seleccione una opción';
    }
    return null;
  }

  /// Valida fecha no futura
  static String? validateNotFutureDate(DateTime? date, {String? fieldName}) {
    if (date == null) {
      return fieldName != null 
          ? '$fieldName es obligatoria' 
          : 'La fecha es obligatoria';
    }
    
    if (date.isAfter(DateTime.now())) {
      return 'La fecha no puede ser futura';
    }
    
    return null;
  }
}