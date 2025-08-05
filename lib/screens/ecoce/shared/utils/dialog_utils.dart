import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/ui_constants.dart';
import '../widgets/signature_dialog.dart';

/// Utilidades para mostrar diálogos comunes en ECOCE
class DialogUtils {
  /// Muestra diálogo de éxito
  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Aceptar',
    VoidCallback? onPressed,
  }) async {
    HapticFeedback.lightImpact();
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusConstants.borderRadiusLarge,
          ),
          title: Column(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: UIConstants.iconSizeDialog,
              ),
              SizedBox(height: UIConstants.spacing16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: UIConstants.fontSizeXLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: UIConstants.fontSizeBody),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onPressed?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(
                    horizontal: UIConstants.spacing32,
                    vertical: UIConstants.spacing12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusConstants.borderRadiusSmall,
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: UIConstants.fontSizeBody,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Muestra diálogo de error
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Aceptar',
  }) async {
    HapticFeedback.mediumImpact();
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusConstants.borderRadiusLarge,
          ),
          title: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: UIConstants.iconSizeDialog,
              ),
              SizedBox(height: UIConstants.spacing16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: UIConstants.fontSizeXLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: UIConstants.fontSizeBody),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(
                    horizontal: UIConstants.spacing32,
                    vertical: UIConstants.spacing12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusConstants.borderRadiusSmall,
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: UIConstants.fontSizeBody,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Muestra diálogo de confirmación
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Color? confirmColor,
  }) async {
    HapticFeedback.lightImpact();
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusConstants.borderRadiusMedium,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: UIConstants.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: UIConstants.fontSizeBody),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                cancelText,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor ?? Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusConstants.borderRadiusSmall,
                ),
              ),
              child: Text(
                confirmText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }

  /// Muestra diálogo de firma
  static Future<List<Offset?>?> showSignatureDialog({
    required BuildContext context,
    required String title,
    List<Offset?>? initialSignature,
    Color? primaryColor,
  }) async {
    HapticFeedback.lightImpact();
    
    return showDialog<List<Offset?>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SignatureDialog(
          title: title,
          initialSignature: initialSignature ?? [],
          onSignatureSaved: (signatureData) {
            Navigator.of(context).pop(signatureData);
          },
          primaryColor: primaryColor ?? Theme.of(context).primaryColor,
        );
      },
    );
  }

  /// Muestra diálogo de carga
  static Future<void> showLoadingDialog({
    required BuildContext context,
    String message = 'Cargando...',
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusConstants.borderRadiusMedium,
              ),
              child: Padding(
                padding: EdgeInsetsConstants.paddingAll24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(fontSize: UIConstants.fontSizeBody),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Cierra el diálogo de carga
  static void hideLoadingDialog(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Muestra diálogo con información
  static Future<void> showInfoDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Entendido',
    IconData icon = Icons.info_outline,
    Color? iconColor,
  }) async {
    HapticFeedback.lightImpact();
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusConstants.borderRadiusMedium,
          ),
          title: Column(
            children: [
              Icon(
                icon,
                color: iconColor ?? Theme.of(context).primaryColor,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: UIConstants.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: UIConstants.fontSizeBody),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: UIConstants.spacing32,
                    vertical: UIConstants.spacing12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusConstants.borderRadiusSmall,
                  ),
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// Muestra diálogo de cerrar sesión
  static Future<bool> showLogoutDialog({
    required BuildContext context,
  }) async {
    return await showConfirmDialog(
      context: context,
      title: '¿Cerrar sesión?',
      message: '¿Estás seguro de que deseas cerrar sesión?',
      confirmText: 'Cerrar sesión',
      cancelText: 'Cancelar',
      confirmColor: Colors.red,
    );
  }
  
  /// Muestra diálogo de eliminar con confirmación de texto
  static Future<bool> showDeleteConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmationText,
    String? hint,
  }) async {
    HapticFeedback.mediumImpact();
    
    final TextEditingController controller = TextEditingController();
    bool isValid = false;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusConstants.borderRadiusMedium,
              ),
              title: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  const SizedBox(height: 16),
                  Text(
                    'Escribe "$confirmationText" para confirmar:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: hint ?? confirmationText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadiusConstants.borderRadiusSmall,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        isValid = value == confirmationText;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isValid ? () => Navigator.of(context).pop(true) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusSmall,
                    ),
                  ),
                  child: const Text(
                    'Eliminar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    
    controller.dispose();
    return result ?? false;
  }
  
  /// Muestra diálogo de función próximamente disponible
  static Future<void> showComingSoonDialog({
    required BuildContext context,
    String? feature,
  }) async {
    return showInfoDialog(
      context: context,
      title: 'Próximamente',
      message: feature != null 
        ? 'La función "$feature" estará disponible próximamente.'
        : 'Esta función estará disponible próximamente.',
      icon: Icons.access_time,
      iconColor: Colors.orange,
    );
  }
  
  /// Muestra diálogo simple con input de texto
  static Future<String?> showInputDialog({
    required BuildContext context,
    required String title,
    String? message,
    String? initialValue,
    String? hintText,
    String confirmText = 'Aceptar',
    String cancelText = 'Cancelar',
    TextInputType keyboardType = TextInputType.text,
    int? maxLines = 1,
  }) async {
    final TextEditingController controller = TextEditingController(text: initialValue);
    
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusConstants.borderRadiusMedium,
          ),
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message != null) ...[
                Text(message),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                maxLines: maxLines,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadiusConstants.borderRadiusSmall,
                  ),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusConstants.borderRadiusSmall,
                ),
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
    
    controller.dispose();
    return result;
  }
  
  /// Muestra diálogo con acciones personalizadas
  static Future<T?> showCustomActionDialog<T>({
    required BuildContext context,
    required String title,
    required String message,
    required List<DialogAction<T>> actions,
    IconData? icon,
    Color? iconColor,
    bool barrierDismissible = true,
  }) async {
    HapticFeedback.lightImpact();
    
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusConstants.borderRadiusMedium,
          ),
          title: Column(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: iconColor ?? Theme.of(context).primaryColor,
                  size: 60,
                ),
                const SizedBox(height: 16),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: UIConstants.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: UIConstants.fontSizeBody),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: actions.map((action) {
                if (action.isOutlined) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(action.value),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: action.color,
                        side: BorderSide(color: action.color ?? Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusConstants.borderRadiusSmall,
                        ),
                      ),
                      child: Text(action.label),
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(action.value),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: action.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusConstants.borderRadiusSmall,
                        ),
                      ),
                      child: Text(
                        action.label,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

/// Clase para definir acciones personalizadas en diálogos
class DialogAction<T> {
  final String label;
  final T value;
  final Color? color;
  final bool isOutlined;
  
  const DialogAction({
    required this.label,
    required this.value,
    this.color,
    this.isOutlined = false,
  });
}