import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';

class QRService {
  static final ScreenshotController _screenshotController = ScreenshotController();

  // Generar imagen de código QR
  static Future<Uint8List?> generateQRImage({
    required String loteId,
    String? title,
    String? subtitle,
    Color? backgroundColor,
    Color? foregroundColor,
  }) async {
    try {
      final qrWidget = Container(
        color: backgroundColor ?? Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: foregroundColor ?? Colors.black,
                ),
              ),
              const SizedBox(height: 10),
            ],
            QrImageView(
              data: loteId,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: backgroundColor ?? Colors.white,
              foregroundColor: foregroundColor ?? Colors.black,
              errorStateBuilder: (cxt, err) {
                return Center(
                  child: Text(
                    'Error al generar QR',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: foregroundColor ?? Colors.black),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              'ID: $loteId',
              style: TextStyle(
                fontSize: 12,
                color: foregroundColor ?? Colors.black,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: foregroundColor ?? Colors.black,
                ),
              ),
            ],
          ],
        ),
      );

      // Capturar el widget como imagen
      final image = await _screenshotController.captureFromWidget(
        qrWidget,
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );

      return image;
    } catch (e) {
      print('Error al generar imagen QR: $e');
      return null;
    }
  }

  // Widget para mostrar código QR
  static Widget buildQRWidget({
    required String loteId,
    String? title,
    String? subtitle,
    double size = 200,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: foregroundColor ?? Colors.black,
              ),
            ),
            const SizedBox(height: 10),
          ],
          QrImageView(
            data: loteId,
            version: QrVersions.auto,
            size: size,
            backgroundColor: backgroundColor ?? Colors.white,
            foregroundColor: foregroundColor ?? Colors.black,
            errorStateBuilder: (cxt, err) {
              return Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                child: Text(
                  'Error al generar QR',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: foregroundColor ?? Colors.black),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (foregroundColor ?? Colors.black).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ID: ${_formatLoteId(loteId)}',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: foregroundColor ?? Colors.black,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: (foregroundColor ?? Colors.black).withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // Formato para mostrar ID del lote
  static String _formatLoteId(String loteId) {
    if (loteId.length > 20) {
      return '${loteId.substring(0, 8)}...${loteId.substring(loteId.length - 8)}';
    }
    return loteId;
  }

  // Generar datos del QR con metadatos adicionales
  static Map<String, dynamic> generateQRData({
    required String loteId,
    required String tipoLote,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'id': loteId,
      'tipo': tipoLote,
      'timestamp': DateTime.now().toIso8601String(),
      if (metadata != null) ...metadata,
    };
  }

  // Parsear datos del QR escaneado
  static Map<String, dynamic>? parseQRData(String qrData) {
    try {
      // Si es solo un ID simple, devolverlo como tal
      if (!qrData.contains('{') && !qrData.contains(':')) {
        return {'id': qrData, 'tipo': 'unknown'};
      }
      
      // Intentar parsear como JSON si tiene formato complejo
      // Por ahora solo manejamos IDs simples
      return {'id': qrData, 'tipo': 'unknown'};
    } catch (e) {
      print('Error al parsear QR: $e');
      return null;
    }
  }
}