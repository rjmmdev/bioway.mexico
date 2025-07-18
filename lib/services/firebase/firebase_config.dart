import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_manager.dart';

/// Configuraciones de Firebase para cada plataforma
class FirebaseConfig {
  /// Obtiene las opciones de Firebase para una plataforma específica
  static FirebaseOptions getOptionsForPlatform(FirebasePlatform platform) {
    switch (platform) {
      case FirebasePlatform.ecoce:
        return _getEcoceOptions();
      case FirebasePlatform.bioway:
        return _getBiowayOptions();
    }
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

  /// Configuración para BioWay según la plataforma actual
  static FirebaseOptions _getBiowayOptions() {
    if (kIsWeb) {
      return _biowayWebOptions;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _biowayIosOptions;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return _biowayAndroidOptions;
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
    iosBundleId: 'com.biowaymexico.app',
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

  /// Configuración Android para BioWay
  static const FirebaseOptions _biowayAndroidOptions = FirebaseOptions(
    apiKey: 'AIzaSyDWhBaGXpQjiFzkQ9XRuvGwEgKJrPWypNY',
    appId: '1:763751005076:android:d668a114c8753c2e56ed81',
    messagingSenderId: '763751005076',
    projectId: 'bioway-mexico',
    storageBucket: 'bioway-mexico.firebasestorage.app',
  );

  /// Configuración iOS para BioWay
  static const FirebaseOptions _biowayIosOptions = FirebaseOptions(
    apiKey: 'AIzaSyBeXT8JdQt-s5Ibi4cGto1OU1ZmZxvJsWw',
    appId: '1:763751005076:ios:c5fa7215e6ea4c4856ed81',
    messagingSenderId: '763751005076',
    projectId: 'bioway-mexico',
    storageBucket: 'bioway-mexico.firebasestorage.app',
    iosBundleId: 'com.biowaymexico.app',
  );

  /// Configuración Web para BioWay
  static const FirebaseOptions _biowayWebOptions = FirebaseOptions(
    apiKey: 'AIzaSyCGjPuE5BqzQx-FldRHr3kVeG0s361qSpo',
    appId: '1:763751005076:web:a0f4a39e1e9bf05b56ed81',
    messagingSenderId: '763751005076',
    projectId: 'bioway-mexico',
    authDomain: 'bioway-mexico.firebaseapp.com',
    storageBucket: 'bioway-mexico.firebasestorage.app',
  );
}