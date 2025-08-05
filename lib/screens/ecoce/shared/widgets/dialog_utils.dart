import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/ui_constants.dart';

/// Utilidades para mostrar diálogos comunes en ECOCE
class DialogUtils {
  /// Muestra diálogo de éxito con un callback onAccept
  static Future<void> showSuccessDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onAccept,
  }) async {
    HapticFeedback.lightImpact();
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusConstants.borderRadiusMedium,
          ),
          title: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: UIConstants.iconSizeDialog,
              ),
              SizedBox(height: UIConstants.spacing16),
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
            style: TextStyle(fontSize: UIConstants.fontSizeBody),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onAccept?.call();
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
                child: const Text(
                  'Aceptar',
                  style: TextStyle(
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
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    HapticFeedback.mediumImpact();
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusConstants.borderRadiusMedium,
          ),
          title: Column(
            children: [
              const Icon(
                Icons.error,
                color: Colors.red,
                size: UIConstants.iconSizeDialog,
              ),
              SizedBox(height: UIConstants.spacing16),
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
            style: TextStyle(fontSize: UIConstants.fontSizeBody),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
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
                child: const Text(
                  'Aceptar',
                  style: TextStyle(
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

  /// Muestra diálogo de información
  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    HapticFeedback.lightImpact();
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusConstants.borderRadiusMedium,
          ),
          title: Column(
            children: [
              const Icon(
                Icons.info,
                color: Colors.blue,
                size: UIConstants.iconSizeDialog,
              ),
              SizedBox(height: UIConstants.spacing16),
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
            style: TextStyle(fontSize: UIConstants.fontSizeBody),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(
                    horizontal: UIConstants.spacing32,
                    vertical: UIConstants.spacing12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusConstants.borderRadiusSmall,
                  ),
                ),
                child: const Text(
                  'Aceptar',
                  style: TextStyle(
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
}