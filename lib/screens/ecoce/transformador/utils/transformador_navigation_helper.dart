import 'package:flutter/material.dart';

/// Helper class for consistent navigation between transformer screens
class TransformadorNavigationHelper {
  TransformadorNavigationHelper._();
  
  /// Navigate to production screen with specific tab
  static void navigateToProduction(
    BuildContext context, {
    int initialTab = 0,
    bool replacement = false,
  }) {
    final args = {'initialTab': initialTab};
    
    if (replacement) {
      Navigator.pushReplacementNamed(
        context,
        '/transformador_produccion',
        arguments: args,
      );
    } else {
      Navigator.pushNamed(
        context,
        '/transformador_produccion',
        arguments: args,
      );
    }
  }
  
  /// Navigate to production screen showing pending/salida tab
  static void navigateToPendingSalida(BuildContext context, {bool replacement = false}) {
    navigateToProduction(context, initialTab: 0, replacement: replacement);
  }
  
  /// Navigate to production screen showing documentation tab
  static void navigateToDocumentation(BuildContext context, {bool replacement = false}) {
    navigateToProduction(context, initialTab: 1, replacement: replacement);
  }
  
  /// Navigate to production screen showing completed tab
  static void navigateToCompleted(BuildContext context, {bool replacement = false}) {
    navigateToProduction(context, initialTab: 2, replacement: replacement);
  }
  
  /// Navigate to home screen
  static void navigateToHome(BuildContext context, {bool clearStack = false}) {
    if (clearStack) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/transformador_inicio',
        (route) => false,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/transformador_inicio');
    }
  }
  
  /// Navigate after successful reception
  static void navigateAfterReception(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/transformador_produccion',
      (route) => false,
      arguments: {'initialTab': 0}, // Go to Salida tab for processing
    );
  }
  
  /// Navigate after successful documentation upload
  static void navigateAfterDocumentation(BuildContext context, {bool allCompleted = false}) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/transformador_produccion',
      (route) => false,
      arguments: {'initialTab': allCompleted ? 2 : 1}, // Go to Completados if all done, else stay in Docs
    );
  }
  
  /// Navigate after completing a lot processing
  static void navigateAfterProcessing(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/transformador_produccion',
      (route) => false,
      arguments: {'initialTab': 1}, // Go to Documentation tab
    );
  }
}