import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  late Offset position;
  late double size;
  late Color color;
  late double speed;
  late double theta;
  late double age;
  late double maxAge;

  Particle({
    required this.position,
    required this.color,
    this.size = 4.0,
    this.maxAge = 2.0,
  }) {
    final random = Random();
    speed = 20 + random.nextDouble() * 30; // Speed between 20-50
    theta = random.nextDouble() * 2 * pi; // Random direction
    age = 0.0;
  }

  bool update(double dt) {
    age += dt;
    if (age >= maxAge) return false;

    // Calculate new position
    position = Offset(
      position.dx + cos(theta) * speed * dt,
      position.dy + sin(theta) * speed * dt,
    );

    // Reduce size as it ages
    size = size * (1 - age / maxAge);

    return true;
  }
}

class WinnerParticleEffect extends StatefulWidget {
  final Offset position;
  final Color color;
  final int particleCount;

  const WinnerParticleEffect({
    super.key,
    required this.position,
    this.color = Colors.yellow,
    this.particleCount = 30,
  });

  @override
  State<WinnerParticleEffect> createState() => _WinnerParticleEffectState();
}

class _WinnerParticleEffectState extends State<WinnerParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _initParticles();

    _controller.forward();
  }

  void _initParticles() {
    final random = Random();

    for (int i = 0; i < widget.particleCount; i++) {
      final hue =
          (widget.color.red + widget.color.green + widget.color.blue) / 3;
      final randomColor =
          HSLColor.fromAHSL(
            1.0,
            random.nextDouble() * 360,
            0.8,
            0.5 + random.nextDouble() * 0.5,
          ).toColor();

      _particles.add(
        Particle(
          position: widget.position,
          color: Color.lerp(widget.color, randomColor, 0.3)!,
          size: 2 + random.nextDouble() * 6,
          maxAge: 1.0 + random.nextDouble(),
        ),
      );
    }
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
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Update particles based on progress
    for (var particle in particles) {
      // Update particle position
      particle.update(0.016); // assume 60fps

      // Draw particle
      final opacity = 1.0 - (particle.age / particle.maxAge);
      final paint =
          Paint()
            ..color = particle.color.withOpacity(opacity)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
