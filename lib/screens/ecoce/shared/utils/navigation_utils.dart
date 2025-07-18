import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utilidades de navegación compartidas para ECOCE
class NavigationUtils {
  /// Duración estándar para transiciones
  static const Duration transitionDuration = Duration(milliseconds: 300);
  
  /// Navega con fade transition
  static Future<T?> navigateWithFade<T>(
    BuildContext context,
    Widget destination, {
    bool replacement = false,
  }) {
    HapticFeedback.lightImpact();
    
    final route = PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: transitionDuration,
    );
    
    if (replacement) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }
  
  /// Navega con slide transition
  static Future<T?> navigateWithSlide<T>(
    BuildContext context,
    Widget destination, {
    bool replacement = false,
    Offset beginOffset = const Offset(1.0, 0.0),
  }) {
    HapticFeedback.lightImpact();
    
    final route = PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(
          begin: beginOffset,
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: transitionDuration,
    );
    
    if (replacement) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }
  
  /// Navega con scale transition
  static Future<T?> navigateWithScale<T>(
    BuildContext context,
    Widget destination, {
    bool replacement = false,
  }) {
    HapticFeedback.lightImpact();
    
    final route = PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(
            Tween(begin: 0.9, end: 1.0).chain(
              CurveTween(curve: Curves.easeOutCubic),
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: transitionDuration,
    );
    
    if (replacement) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }
  
  /// Muestra un modal bottom sheet con animación estándar
  static Future<T?> showCustomBottomSheet<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool isScrollControlled = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      shape: shape,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: builder(context),
      ),
    );
  }
  
  /// Navega hacia atrás con haptic feedback
  static void navigateBack<T>(BuildContext context, [T? result]) {
    HapticFeedback.lightImpact();
    Navigator.pop(context, result);
  }
  
  /// Helper para navegación entre tabs del bottom navigation
  static void handleBottomNavigation({
    required BuildContext context,
    required int currentIndex,
    required int targetIndex,
    required Map<int, Widget> destinations,
  }) {
    if (currentIndex == targetIndex) return;
    
    final destination = destinations[targetIndex];
    if (destination != null) {
      navigateWithFade(context, destination, replacement: true);
    }
  }
}

