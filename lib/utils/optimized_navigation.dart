import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import screens for route mapping
import '../screens/ecoce/origen/origen_inicio_screen.dart';
import '../screens/ecoce/origen/origen_lotes_screen.dart';
import '../screens/ecoce/origen/origen_ayuda.dart';
import '../screens/ecoce/origen/origen_perfil.dart';
import '../screens/ecoce/origen/origen_crear_lote_screen.dart';
import '../screens/ecoce/reciclador/reciclador_inicio.dart';
import '../screens/ecoce/reciclador/reciclador_administracion_lotes.dart';
import '../screens/ecoce/reciclador/reciclador_ayuda.dart';
import '../screens/ecoce/reciclador/reciclador_perfil.dart';
import '../screens/ecoce/reciclador/reciclador_escaneo.dart';
import '../screens/ecoce/transporte/transporte_inicio_screen.dart';
import '../screens/ecoce/transporte/transporte_entregar_screen.dart';
import '../screens/ecoce/transporte/transporte_ayuda_screen.dart';
import '../screens/ecoce/transporte/transporte_perfil_screen.dart';

class OptimizedNavigation {
  // Cache for transition animations to improve performance
  static final Map<String, Route> _transitionCache = {};
  
  // Preload commonly used images for better performance
  static void preloadImages(BuildContext context) {
    // Preload app images that are used frequently
    precacheImage(const AssetImage('assets/logos/ecoce_logo.svg'), context);
    precacheImage(const AssetImage('assets/logos/bioway_logo.svg'), context);
  }
  
  // Clear transition cache when memory is low
  static void clearCache() {
    _transitionCache.clear();
  }
  
  // Optimized page route with custom transition
  static Route<T> customPageRoute<T>({
    required Widget Function(BuildContext) builder,
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeOutCubic,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Haptic feedback for better UX
        if (animation.status == AnimationStatus.forward) {
          HapticFeedback.lightImpact();
        }
        
        // Combined fade and slide transition for smoothness
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(0.0, 0.5, curve: curve),
        ));
        
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.3, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));
        
        // Apply reverse animation for secondary
        final reverseSlideAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.3, 0.0),
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: curve,
        ));
        
        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: reverseSlideAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }
  
  // Navigate with optimized transition
  static Future<T?> navigateTo<T>(
    BuildContext context,
    Widget destination, {
    bool replacement = false,
    Duration duration = const Duration(milliseconds: 250),
  }) {
    final route = customPageRoute<T>(
      builder: (_) => destination,
      duration: duration,
    );
    
    if (replacement) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }
  
  // Navigate to named route with optimized transition
  static Future<T?> navigateToNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replacement = false,
    Duration duration = const Duration(milliseconds: 250),
  }) {
    // Use PageRouteBuilder for named routes
    final route = PageRouteBuilder<T>(
      settings: RouteSettings(name: routeName, arguments: arguments),
      pageBuilder: (context, animation, secondaryAnimation) {
        // Get the widget builder from the app's routes
        final routes = {
          '/origen_inicio': (context) => const OrigenInicioScreen(),
          '/origen_lotes': (context) => const OrigenLotesScreen(),
          '/origen_ayuda': (context) => const OrigenAyudaScreen(),
          '/origen_perfil': (context) => const OrigenPerfilScreen(),
          '/origen_crear_lote': (context) => const OrigenCrearLoteScreen(),
          '/reciclador_inicio': (context) => const RecicladorHomeScreen(),
          '/reciclador_lotes': (context) => const RecicladorAdministracionLotes(),
          '/reciclador_ayuda': (context) => const RecicladorAyudaScreen(),
          '/reciclador_perfil': (context) => const RecicladorPerfilScreen(),
          '/reciclador_escaneo': (context) => const QRScannerScreen(),
          '/transporte_inicio': (context) => const TransporteInicioScreen(),
          '/transporte_entregar': (context) => const TransporteEntregarScreen(),
          '/transporte_ayuda': (context) => const TransporteAyudaScreen(),
          '/transporte_perfil': (context) => const TransportePerfilScreen(),
        };
        
        final builder = routes[routeName];
        if (builder != null) {
          return builder(context);
        }
        
        // Fallback
        return const SizedBox();
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Haptic feedback
        if (animation.status == AnimationStatus.forward) {
          HapticFeedback.lightImpact();
        }
        
        // Smooth fade and scale transition
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        
        final scaleAnimation = Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ));
        
        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
    
    if (replacement) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }
  
  // Hero animation wrapper for smoother transitions
  static Widget heroWrapper({
    required String tag,
    required Widget child,
  }) {
    return Hero(
      tag: tag,
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
  
  // Preload images for faster rendering
  static void precacheImages(BuildContext context, List<String> imagePaths) {
    for (final path in imagePaths) {
      precacheImage(AssetImage(path), context);
    }
  }
}