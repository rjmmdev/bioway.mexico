import 'package:intl/intl.dart';

/// Utilidades centralizadas para formateo de datos
class FormatUtils {
  FormatUtils._();
  
  /// Formatea una fecha en formato dd/MM/yyyy
  static String formatDate(DateTime? date) {
    if (date == null) return 'Sin fecha';
    
    try {
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'Fecha inválida';
    }
  }
  
  /// Formatea una fecha y hora en formato dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Sin fecha';
    
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return 'Fecha inválida';
    }
  }
  
  /// Formatea una hora en formato HH:mm
  static String formatTime(DateTime? time) {
    if (time == null) return 'Sin hora';
    
    try {
      return DateFormat('HH:mm').format(time);
    } catch (e) {
      return 'Hora inválida';
    }
  }
  
  /// Formatea un peso con unidad kg
  static String formatWeight(double? weight, {int decimals = 1}) {
    if (weight == null) return '0 kg';
    
    if (decimals == 0) {
      return '${weight.toStringAsFixed(0)} kg';
    }
    
    return '${weight.toStringAsFixed(decimals)} kg';
  }
  
  /// Formatea un número de teléfono en formato (xxx) xxx-xxxx
  static String formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    
    // Remover cualquier carácter no numérico
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length != 10) return phone;
    
    // Formatear como (xxx) xxx-xxxx
    return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
  }
  
  /// Formatea un código postal
  static String formatPostalCode(String? postalCode) {
    if (postalCode == null || postalCode.isEmpty) return '';
    
    // Asegurar que tenga 5 dígitos
    final digitsOnly = postalCode.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length > 5) {
      return digitsOnly.substring(0, 5);
    }
    
    return digitsOnly.padLeft(5, '0');
  }
  
  /// Formatea un RFC a mayúsculas
  static String formatRFC(String? rfc) {
    if (rfc == null || rfc.isEmpty) return '';
    
    return rfc.toUpperCase().trim();
  }
  
  /// Formatea dimensiones en formato "largo x ancho"
  static String formatDimensions(double? largo, double? ancho, {String unit = 'm'}) {
    if (largo == null || ancho == null) return 'Sin dimensiones';
    
    return '${largo.toStringAsFixed(2)} x ${ancho.toStringAsFixed(2)} $unit';
  }
  
  /// Formatea un porcentaje
  static String formatPercentage(double? value, {int decimals = 1}) {
    if (value == null) return '0%';
    
    return '${value.toStringAsFixed(decimals)}%';
  }
  
  /// Formatea moneda en pesos mexicanos
  static String formatCurrency(double? amount) {
    if (amount == null) return '\$0.00';
    
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );
    
    return formatter.format(amount);
  }
  
  /// Formatea un número con separadores de miles
  static String formatNumber(num? number, {int decimals = 0}) {
    if (number == null) return '0';
    
    final formatter = NumberFormat.decimalPattern('es_MX');
    formatter.minimumFractionDigits = decimals;
    formatter.maximumFractionDigits = decimals;
    
    return formatter.format(number);
  }
  
  /// Capitaliza la primera letra de cada palabra
  static String capitalize(String? text) {
    if (text == null || text.isEmpty) return '';
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  /// Trunca un texto si excede la longitud máxima
  static String truncate(String? text, int maxLength, {String suffix = '...'}) {
    if (text == null || text.isEmpty) return '';
    
    if (text.length <= maxLength) return text;
    
    return '${text.substring(0, maxLength)}$suffix';
  }
}