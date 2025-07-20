import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';
import 'loading_indicator.dart';

/// Wrapper widget that handles loading and error states consistently
class LoadingWrapper extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onRetry;
  final Widget child;
  final String? errorMessage;
  final Color? primaryColor;

  const LoadingWrapper({
    super.key,
    required this.isLoading,
    required this.child,
    this.hasError = false,
    this.onRetry,
    this.errorMessage,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: LoadingIndicator(
            color: primaryColor ?? BioWayColors.ecoceGreen,
          ),
        ),
      );
    }

    if (hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: BioWayColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage ?? 'Error al cargar datos',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor ?? BioWayColors.ecoceGreen,
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return child;
  }
}