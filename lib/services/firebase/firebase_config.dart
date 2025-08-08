import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_manager.dart';

/// Configuraciones de Firebase para ECOCE
class FirebaseConfig {
  /// Obtiene las opciones de Firebase para una plataforma específica
  static FirebaseOptions getOptionsForPlatform(FirebasePlatform platform) {
    // Solo ECOCE está soportado
    return _getEcoceOptions();
  }

  /// Configuración para ECOCE según la plataforma actual
  static FirebaseOptions _getEcoceOptions() {
    if (kIsWeb) {
      return _ecoceWebOptions;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _ecoceIosOptions;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return _ecoceAndroidOptions;
    }
    throw UnsupportedError('Plataforma no soportada');
  }

  /// Configuración Android para ECOCE
  static const FirebaseOptions _ecoceAndroidOptions = FirebaseOptions(
    apiKey: 'AIzaSyDgKMZL6trJuXIt-gkKTn5RDzfrg_1aEyU',
    appId: '1:1098503063628:android:5d4a3e73323f7a31414ce9',
    messagingSenderId: '1098503063628',
    projectId: 'trazabilidad-ecoce',
    storageBucket: 'trazabilidad-ecoce.firebasestorage.app',
  );

  /// Configuración iOS para ECOCE
  static const FirebaseOptions _ecoceIosOptions = FirebaseOptions(
    apiKey: 'AIzaSyA4227y8ecjrDlhgRtmzo0OeTrLTmDD9mg',
    appId: '1:1098503063628:ios:8b0ee3809eef41da414ce9',
    messagingSenderId: '1098503063628',
    projectId: 'trazabilidad-ecoce',
    storageBucket: 'trazabilidad-ecoce.firebasestorage.app',
    iosBundleId: 'com.ecoce.app',
  );

  /// Configuración Web para ECOCE
  static const FirebaseOptions _ecoceWebOptions = FirebaseOptions(
    apiKey: 'AIzaSyCGF-eZR686HDEZlbAhEpMv282S4BFklzY',
    appId: '1:1098503063628:web:dc7be1b94edba0bf414ce9',
    messagingSenderId: '1098503063628',
    projectId: 'trazabilidad-ecoce',
    authDomain: 'trazabilidad-ecoce.firebaseapp.com',
    storageBucket: 'trazabilidad-ecoce.firebasestorage.app',
    measurementId: 'G-3RCPGFJS0M',
  );
}