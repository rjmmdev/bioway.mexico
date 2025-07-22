import 'package:flutter/material.dart';
import 'dart:math' as math;

class BioMotivationalPopup extends StatefulWidget {
  final String message;
  final String emoji;
  final Color color;
  final VoidCallback? onClose;

  const BioMotivationalPopup({
    Key? key,
    required this.message,
    this.emoji = '🌟',
    this.color = Colors.green,
    this.onClose,
  }) : super(key: key);

  static void show(BuildContext context, {
    required String message,
    String icon = '🌟',
    Color color = Colors.green,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BioMotivationalPopup(
        message: message,
        emoji: icon,
        color: color,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<BioMotivationalPopup> createState() => _BioMotivationalPopupState();
}

class _BioMotivationalPopupState extends State<BioMotivationalPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && widget.onClose != null) {
        widget.onClose!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha:0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.emoji,
                      style: const TextStyle(fontSize: 60),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MotivationalMessages {
  static final List<Map<String, dynamic>> _messages = [
    {'message': '¡Excelente trabajo!', 'icon': '🌟'},
    {'message': '¡Sigue así, lo estás haciendo genial!', 'icon': '💪'},
    {'message': '¡Cada acción cuenta!', 'icon': '🌱'},
    {'message': '¡Eres un héroe del planeta!', 'icon': '🌍'},
    {'message': '¡Tu esfuerzo marca la diferencia!', 'icon': '✨'},
    {'message': '¡Juntos podemos más!', 'icon': '🤝'},
    {'message': '¡Un paso más cerca del cambio!', 'icon': '🚶‍♂️'},
    {'message': '¡Tu compromiso es inspirador!', 'icon': '💚'},
    {'message': '¡Gracias por cuidar el planeta!', 'icon': '🌳'},
    {'message': '¡Cada día es una nueva oportunidad!', 'icon': '☀️'},
  ];

  static Map<String, dynamic> getRandomMessage() {
    final random = math.Random();
    return _messages[random.nextInt(_messages.length)];
  }
}