import 'dart:math';
import 'package:flutter/material.dart';
import 'package:finger_selection_game/models/game_settings.dart';

class EnhancedParticleEffects extends StatelessWidget {
  final Offset position;
  final bool isActive;
  final ParticleEffectType effectType;
  final Color baseColor;
  final double size;

  const EnhancedParticleEffects({
    super.key,
    required this.position,
    required this.isActive,
    this.effectType = ParticleEffectType.confetti,
    this.baseColor = Colors.blue,
    this.size = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive || effectType == ParticleEffectType.none) {
      return const SizedBox.shrink();
    }

    switch (effectType) {
      case ParticleEffectType.confetti:
        return _ConfettiEffect(
          position: position,
          baseColor: baseColor,
          size: size,
        );
      case ParticleEffectType.fireworks:
        return _FireworksEffect(
          position: position,
          baseColor: baseColor,
          size: size,
        );
      case ParticleEffectType.sparkle:
        return _SparkleEffect(
          position: position,
          baseColor: baseColor,
          size: size,
        );
      default:
        return _ConfettiEffect(
          position: position,
          baseColor: baseColor,
          size: size,
        );
    }
  }
}

class _SimpleParticleEffect extends StatefulWidget {
  final Offset position;
  final Color baseColor;
  final double size;

  const _SimpleParticleEffect({
    required this.position,
    required this.baseColor,
    required this.size,
  });

  @override
  State<_SimpleParticleEffect> createState() => _SimpleParticleEffectState();
}

class _SimpleParticleEffectState extends State<_SimpleParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _generateParticles();
  }

  void _generateParticles() {
    const int particleCount = 20;
    _particles.clear();

    for (int i = 0; i < particleCount; i++) {
      final speed = 2.0 + _random.nextDouble() * 3.0;
      final direction = _random.nextDouble() * 2 * pi;
      final size = 3.0 + _random.nextDouble() * 5.0;
      final opacity = 0.5 + _random.nextDouble() * 0.5;

      _particles.add(
        _Particle(
          speed: speed,
          direction: direction,
          size: size,
          color: widget.baseColor.withOpacity(opacity),
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
          painter: _SimpleParticlePainter(
            position: widget.position,
            progress: _controller.value,
            particles: _particles,
          ),
          size: Size(widget.size * 3, widget.size * 3),
        );
      },
    );
  }
}

class _SimpleParticlePainter extends CustomPainter {
  final Offset position;
  final double progress;
  final List<_Particle> particles;

  _SimpleParticlePainter({
    required this.position,
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(1.0 - progress)
        ..style = PaintingStyle.fill;

      final distance = particle.speed * progress * 100;
      final dx = cos(particle.direction) * distance;
      final dy = sin(particle.direction) * distance;

      final particlePosition = center.translate(dx, dy);
      final particleSize = particle.size * (1.0 - progress * 0.5);

      canvas.drawCircle(particlePosition, particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Particle {
  final double speed;
  final double direction;
  final double size;
  final Color color;

  _Particle({
    required this.speed,
    required this.direction,
    required this.size,
    required this.color,
  });
}

// Confetti effect implementation
class _ConfettiEffect extends StatefulWidget {
  final Offset position;
  final Color baseColor;
  final double size;

  const _ConfettiEffect({
    required this.position,
    required this.baseColor,
    required this.size,
  });

  @override
  State<_ConfettiEffect> createState() => _ConfettiEffectState();
}

class _ConfettiEffectState extends State<_ConfettiEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiPiece> _pieces = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _generateConfetti();
  }

  void _generateConfetti() {
    const int confettiCount = 50;
    _pieces.clear();

    // Generate confetti pieces with various colors
    for (int i = 0; i < confettiCount; i++) {
      // Random velocity components
      final vx = -2.0 + _random.nextDouble() * 4.0;
      final vy = -5.0 + _random.nextDouble() * 2.0; // Initial upward velocity

      // Random size
      final width = 3.0 + _random.nextDouble() * 7.0;
      final height = 2.0 + _random.nextDouble() * 6.0;

      // Random rotation
      final rotationSpeed = -0.1 + _random.nextDouble() * 0.2;

      // Random color (either from base color or rainbow colors)
      final useRainbow = _random.nextBool();
      final Color color = useRainbow
          ? HSVColor.fromAHSV(
              1.0,
              _random.nextDouble() * 360,
              0.8,
              0.8,
            ).toColor()
          : Color.fromARGB(
              255,
              widget.baseColor.red + _random.nextInt(80) - 40,
              widget.baseColor.green + _random.nextInt(80) - 40,
              widget.baseColor.blue + _random.nextInt(80) - 40,
            );

      _pieces.add(
        _ConfettiPiece(
          velocityX: vx,
          velocityY: vy,
          width: width,
          height: height,
          rotationSpeed: rotationSpeed,
          color: color,
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
          painter: _ConfettiPainter(
            position: widget.position,
            progress: _controller.value,
            pieces: _pieces,
          ),
          size: Size(widget.size * 4, widget.size * 5),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final Offset position;
  final double progress;
  final List<_ConfettiPiece> pieces;

  _ConfettiPainter({
    required this.position,
    required this.progress,
    required this.pieces,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final gravity = 9.8 * 2; // Gravity effect (simplified)

    for (final piece in pieces) {
      // Skip if piece would be invisible
      if (progress > 0.95) continue;

      final paint = Paint()
        ..color = piece.color.withOpacity(1.0 - progress * 0.8)
        ..style = PaintingStyle.fill;

      // Calculate position with gravity
      final time = progress * 2; // Scale the time for effect
      final dx = piece.velocityX * time * 50;
      final dy = (piece.velocityY * time + 0.5 * gravity * time * time) * 30;

      final rotation = piece.rotationSpeed * time * 10;

      final particlePosition = center.translate(dx, dy);

      // Draw rotated rectangle
      canvas.save();
      canvas.translate(particlePosition.dx, particlePosition.dy);
      canvas.rotate(rotation);

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.width,
          height: piece.height,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ConfettiPiece {
  final double velocityX;
  final double velocityY;
  final double width;
  final double height;
  final double rotationSpeed;
  final Color color;

  _ConfettiPiece({
    required this.velocityX,
    required this.velocityY,
    required this.width,
    required this.height,
    required this.rotationSpeed,
    required this.color,
  });
}

// Simplified implementations for other effects
class _FireworksEffect extends StatefulWidget {
  final Offset position;
  final Color baseColor;
  final double size;

  const _FireworksEffect({
    required this.position,
    required this.baseColor,
    required this.size,
  });

  @override
  State<_FireworksEffect> createState() => _FireworksEffectState();
}

class _FireworksEffectState extends State<_FireworksEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Simplified fireworks implementation
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _FireworksPainter(
            position: widget.position,
            progress: _controller.value,
            baseColor: widget.baseColor,
          ),
          size: Size(widget.size * 4, widget.size * 4),
        );
      },
    );
  }
}

class _FireworksPainter extends CustomPainter {
  final Offset position;
  final double progress;
  final Color baseColor;
  final Random _random = Random();

  _FireworksPainter({
    required this.position,
    required this.progress,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Early stage - rocket trail
    if (progress < 0.3) {
      _drawRocket(canvas, center, progress);
    }
    // Explosion stage
    else {
      _drawExplosion(canvas, center, progress);
    }
  }

  void _drawRocket(Canvas canvas, Offset center, double progress) {
    final rocketProgress = progress / 0.3; // Normalize to 0-1 for rocket phase
    final rocketPath = Path();

    // Rocket trail
    final trailPaint = Paint()
      ..color = Colors.orange.withOpacity(0.7 - rocketProgress * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw trail from bottom to current position
    final startY = center.dy + 100;
    final currentY = center.dy + 100 - 200 * rocketProgress;

    rocketPath.moveTo(center.dx, startY);
    rocketPath.lineTo(center.dx, currentY);

    canvas.drawPath(rocketPath, trailPaint);

    // Rocket head
    final headPaint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(center.dx, currentY), 4, headPaint);
  }

  void _drawExplosion(Canvas canvas, Offset center, double progress) {
    // Normalized explosion progress (0-1)
    final explosionProgress = (progress - 0.3) / 0.7;

    // Number of explosion rays increases with progress
    final rayCount = 20;
    final rayLength = 100 * min(explosionProgress * 1.5, 1.0);

    for (int i = 0; i < rayCount; i++) {
      final angle = i * (2 * pi / rayCount);
      final hue = (i * 360 / rayCount) % 360;

      // Color fades out over time
      final rayPaint = Paint()
        ..color = HSVColor.fromAHSV(
          1.0 - explosionProgress * 0.8,
          hue,
          0.8,
          1.0,
        ).toColor()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * (1.0 - explosionProgress * 0.5);

      final endPoint = Offset(
        center.dx + cos(angle) * rayLength,
        center.dy + sin(angle) * rayLength,
      );

      canvas.drawLine(center, endPoint, rayPaint);

      // Add some sparks at the end of each ray
      if (explosionProgress > 0.2 && explosionProgress < 0.8) {
        final sparkPaint = Paint()
          ..color = HSVColor.fromAHSV(
            0.7 - explosionProgress * 0.6,
            hue,
            0.9,
            1.0,
          ).toColor()
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          endPoint,
          2 * (1.0 - explosionProgress * 0.8),
          sparkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Other effect implementations would follow similar patterns
// Simple placeholders for remaining effects:

class _SparkleEffect extends StatelessWidget {
  final Offset position;
  final Color baseColor;
  final double size;

  const _SparkleEffect({
    required this.position,
    required this.baseColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Simplified placeholder
    return SizedBox(
      width: size * 3,
      height: size * 3,
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: baseColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: baseColor.withOpacity(0.6),
                blurRadius: 15,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmokeEffect extends StatelessWidget {
  final Offset position;
  final Color baseColor;
  final double size;

  const _SmokeEffect({
    required this.position,
    required this.baseColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Simplified placeholder
    return SizedBox(
      width: size * 3,
      height: size * 3,
      child: Center(
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: baseColor.withOpacity(0.3),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: baseColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleEffect extends StatelessWidget {
  final Offset position;
  final Color baseColor;
  final double size;

  const _BubbleEffect({
    required this.position,
    required this.baseColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Simplified placeholder
    return SizedBox(
      width: size * 3,
      height: size * 3,
      child: Center(
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: baseColor.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: baseColor.withOpacity(0.8), width: 2),
          ),
        ),
      ),
    );
  }
}
