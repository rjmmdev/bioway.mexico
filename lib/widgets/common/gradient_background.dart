import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/ui_constants.dart';

/// Widget reutilizable para crear fondos con gradiente
/// Usado en múltiples pantallas de la aplicación
class GradientBackground extends StatelessWidget {
  /// Widget hijo que se mostrará sobre el gradiente
  final Widget child;

  /// Colores del gradiente (opcional)
  final List<Color>? colors;

  /// Punto de inicio del gradiente (opcional)
  final AlignmentGeometry? begin;

  /// Punto final del gradiente (opcional)
  final AlignmentGeometry? end;

  /// Opacidad del gradiente (opcional)
  final double opacity;

  /// Si debe incluir un patrón decorativo
  final bool showPattern;

  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.begin,
    this.end,
    this.opacity = 1.0,
    this.showPattern = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo con gradiente
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin ?? Alignment.topCenter,
              end: end ?? Alignment.bottomCenter,
              colors: colors ?? BioWayColors.backgroundGradient,
            ),
          ),
        ),

        // Opacidad opcional
        if (opacity < 1.0)
          Container(
            color: Colors.white.withValues(alpha: 1.0 - opacity),
          ),

        // Patrón decorativo opcional
        if (showPattern) ...[
          // Círculo decorativo superior derecho
          Positioned(
            top: -UIConstants.iconContainerXLarge + UIConstants.spacing20,
            right: -UIConstants.iconContainerXLarge + UIConstants.spacing20,
            child: Container(
              width: UIConstants.signatureWidth,
              height: UIConstants.signatureWidth,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BioWayColors.primaryGreen.withValues(alpha: UIConstants.opacityVeryLow),
              ),
            ),
          ),

          // Círculo decorativo inferior izquierdo
          Positioned(
            bottom: -UIConstants.qrSizeSmall,
            left: -UIConstants.qrSizeSmall,
            child: Container(
              width: UIConstants.maxWidthDialog,
              height: UIConstants.maxWidthDialog,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BioWayColors.mediumGreen.withValues(alpha: UIConstants.opacityVeryLow),
              ),
            ),
          ),

          // Líneas decorativas
          ...List.generate(3, (index) {
            return Positioned(
              top: UIConstants.iconContainerXLarge - UIConstants.spacing20 + (index * UIConstants.qrSizeMedium).toDouble(),
              left: -UIConstants.buttonHeightMedium - UIConstants.spacing4 / 2,
              child: Transform.rotate(
                angle: 0.3,
                child: Container(
                  width: UIConstants.qrSizeMedium,
                  height: UIConstants.borderWidthThin,
                  color: Colors.white.withValues(alpha: UIConstants.opacityLow),
                ),
              ),
            );
          }),
        ],

        // Contenido principal
        child,
      ],
    );
  }
}

/// Variante del gradiente para fondos más suaves
class SoftGradientBackground extends StatelessWidget {
  final Widget child;
  final bool showWaves;

  const SoftGradientBackground({
    super.key,
    required this.child,
    this.showWaves = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo base
        Container(
          color: BioWayColors.backgroundGrey,
        ),

        // Gradiente suave
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                BioWayColors.lightGreen.withValues(alpha: 0.3),
                BioWayColors.mediumGreen.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.5),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Ondas decorativas opcionales
        if (showWaves)
          CustomPaint(
            size: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            ),
            painter: WavePainter(),
          ),

        // Contenido
        child,
      ],
    );
  }
}

/// Painter personalizado para dibujar ondas decorativas
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BioWayColors.primaryGreen.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Primera onda
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.25,
      size.width * 0.5,
      size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.35,
      size.width,
      size.height * 0.3,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Segunda onda
    paint.color = BioWayColors.mediumGreen.withValues(alpha: 0.03);
    final path2 = Path();

    path2.moveTo(0, size.height * 0.5);
    path2.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.45,
      size.width * 0.6,
      size.height * 0.5,
    );
    path2.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.55,
      size.width,
      size.height * 0.5,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}