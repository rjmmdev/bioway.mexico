import 'package:flutter/material.dart';

/// Widget de indicador de carga reutilizable
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;
  
  const LoadingIndicator({
    super.key,
    this.message,
    this.color,
    this.size = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? Theme.of(context).primaryColor,
              ),
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 24),
            Text(
              message!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget de indicador de carga en línea (para botones, etc.)
class InlineLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;
  
  const InlineLoadingIndicator({
    super.key,
    this.color,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.white,
        ),
        strokeWidth: 2,
      ),
    );
  }
}

/// Overlay de carga para cubrir toda la pantalla
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;
  
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withOpacity(0.5),
            child: LoadingIndicator(
              message: message,
              color: Colors.white,
            ),
          ),
      ],
    );
  }
}