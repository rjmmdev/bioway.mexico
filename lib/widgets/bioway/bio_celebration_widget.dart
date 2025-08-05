import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/ui_constants.dart';

class BioCelebrationWidget extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onComplete;

  const BioCelebrationWidget({
    Key? key,
    required this.title,
    required this.message,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<BioCelebrationWidget> createState() => _BioCelebrationWidgetState();
}

class _BioCelebrationWidgetState extends State<BioCelebrationWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  final List<ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: UIConstants.animationDurationLong * 3),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _generateConfetti();
    _controller.forward();
    _confettiController.repeat();

    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  void _generateConfetti() {
    final random = math.Random();
    for (int i = 0; i < 50; i++) {
      _particles.add(ConfettiParticle(
        x: random.nextDouble() * 400 - 200,
        y: random.nextDouble() * -100 - 50,
        vx: random.nextDouble() * 4 - 2,
        vy: random.nextDouble() * 5 + 2,
        color: Colors.primaries[random.nextInt(Colors.primaries.length)],
        size: random.nextDouble() * 10 + 5,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: UIConstants.opacityVeryHigh),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                painter: ConfettiPainter(
                  particles: _particles,
                  progress: _confettiController.value,
                ),
                size: Size.infinite,
              );
            },
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Container(
                      padding: EdgeInsetsConstants.paddingAll32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadiusConstants.borderRadiusXLarge,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: UIConstants.opacityMedium),
                            blurRadius: UIConstants.blurRadiusXLarge - 5,
                            spreadRadius: UIConstants.spacing4 + 1,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            size: UIConstants.iconSizeDialog + UIConstants.spacing20,
                            color: Colors.amber,
                          ),
                          SizedBox(height: UIConstants.spacing20),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: UIConstants.fontSizeXXLarge,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: UIConstants.spacing10),
                          Text(
                            widget.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: UIConstants.fontSizeLarge,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiParticle {
  double x;
  double y;
  final double vx;
  final double vy;
  final Color color;
  final double size;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });

  void update() {
    x += vx;
    y += vy + 9.8 * 0.1; // Gravity effect
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2);

    for (var particle in particles) {
      particle.update();
      
      paint.color = particle.color.withValues(alpha:0.8);
      canvas.drawCircle(
        Offset(center.dx + particle.x, center.dy + particle.y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}