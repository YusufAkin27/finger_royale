import 'dart:math';
import 'package:flutter/material.dart';
import 'package:finger_selection_game/models/game_settings.dart';
import 'package:finger_selection_game/models/light_state.dart' as light_models;

class EnhancedLightEffects extends StatelessWidget {
  final light_models.LightState lightState;
  final List<Offset> fingerPositions;
  final Set<int> winnerIds;
  final Map<int, Offset> fingerPositionsById;
  final Animation<double> rotationAnimation;
  final Animation<double> targetingAnimation;
  final Animation<double> highlightAnimation;
  final LightEffectStyle style;
  final GameThemeMode themeMode;

  const EnhancedLightEffects({
    super.key,
    required this.lightState,
    required this.fingerPositions,
    required this.winnerIds,
    required this.fingerPositionsById,
    required this.rotationAnimation,
    required this.targetingAnimation,
    required this.highlightAnimation,
    this.style = LightEffectStyle.standard,
    this.themeMode = GameThemeMode.light,
  });

  @override
  Widget build(BuildContext context) {
    if (fingerPositions.isEmpty) {
      return const SizedBox.shrink();
    }

    switch (style) {
      case LightEffectStyle.pulse:
        return _buildPulseLight();
      case LightEffectStyle.stars:
        return _buildStarsLight();
      case LightEffectStyle.standard:
      default:
        return _buildStandardLight();
    }
  }

  Widget _buildStandardLight() {
    Color lightColor = _getLightColorForTheme();

    return CustomPaint(
      size: Size.infinite,
      painter: StandardLightPainter(
        lightState: lightState,
        fingerPositions: fingerPositions,
        winnerIds: winnerIds,
        fingerPositionsById: fingerPositionsById,
        rotationAnimation: rotationAnimation,
        targetingAnimation: targetingAnimation,
        highlightAnimation: highlightAnimation,
        lightColor: lightColor,
      ),
    );
  }

  Widget _buildPulseLight() {
    Color lightColor = _getLightColorForTheme();

    return CustomPaint(
      size: Size.infinite,
      painter: PulseLightPainter(
        lightState: lightState,
        fingerPositions: fingerPositions,
        winnerIds: winnerIds,
        fingerPositionsById: fingerPositionsById,
        rotationAnimation: rotationAnimation,
        targetingAnimation: targetingAnimation,
        highlightAnimation: highlightAnimation,
        lightColor: lightColor,
      ),
    );
  }

  Widget _buildStarsLight() {
    return CustomPaint(
      size: Size.infinite,
      painter: StarsLightPainter(
        lightState: lightState,
        fingerPositions: fingerPositions,
        winnerIds: winnerIds,
        fingerPositionsById: fingerPositionsById,
        rotationAnimation: rotationAnimation,
        targetingAnimation: targetingAnimation,
        highlightAnimation: highlightAnimation,
      ),
    );
  }

  Color _getLightColorForTheme() {
    switch (themeMode) {
      case GameThemeMode.light:
        return Colors.blue.withOpacity(0.7);
      case GameThemeMode.dark:
        return Colors.cyanAccent.withOpacity(0.7);
      case GameThemeMode.neon:
        return Colors.greenAccent.withOpacity(0.8);
      default:
        return Colors.blue.withOpacity(0.7);
    }
  }
}

// Base light painter with common functionality
abstract class BaseLightPainter extends CustomPainter {
  final light_models.LightState lightState;
  final List<Offset> fingerPositions;
  final Set<int> winnerIds;
  final Map<int, Offset> fingerPositionsById;
  final Animation<double> rotationAnimation;
  final Animation<double> targetingAnimation;
  final Animation<double> highlightAnimation;

  BaseLightPainter({
    required this.lightState,
    required this.fingerPositions,
    required this.winnerIds,
    required this.fingerPositionsById,
    required this.rotationAnimation,
    required this.targetingAnimation,
    required this.highlightAnimation,
  });

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Standard light effect
class StandardLightPainter extends BaseLightPainter {
  final Color lightColor;

  StandardLightPainter({
    required super.lightState,
    required super.fingerPositions,
    required super.winnerIds,
    required super.fingerPositionsById,
    required super.rotationAnimation,
    required super.targetingAnimation,
    required super.highlightAnimation,
    this.lightColor = Colors.blue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fingerPositions.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);

    switch (lightState) {
      case light_models.LightState.rotating:
        _paintRotatingLight(canvas, size, center);
        break;
      case light_models.LightState.centered:
        _paintCenteredLight(canvas, size, center);
        break;
      case light_models.LightState.targeting:
        _paintTargetingLight(canvas, size, center);
        break;
      case light_models.LightState.highlighting:
        _paintHighlightingLight(canvas, size);
        break;
    }
  }

  void _paintRotatingLight(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    // Calculate light angle based on animation
    final angle = rotationAnimation.value * 2 * pi;

    // Rotating light around the screen edge
    final radius = max(size.width, size.height) * 0.8;
    final lightPosition = Offset(
      center.dx + cos(angle) * radius,
      center.dy + sin(angle) * radius,
    );

    canvas.drawCircle(lightPosition, 50, paint);
  }

  void _paintCenteredLight(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawCircle(center, 80, paint);
  }

  void _paintTargetingLight(Canvas canvas, Size size, Offset center) {
    // Light beams shooting from center to winners
    final paint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30 * targetingAnimation.value
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    for (final id in winnerIds) {
      if (fingerPositionsById.containsKey(id)) {
        final targetPos = fingerPositionsById[id]!;
        canvas.drawLine(center, targetPos, paint);
      }
    }
  }

  void _paintHighlightingLight(Canvas canvas, Size size) {
    // Highlight winners with pulsing glow
    final paint = Paint()
      ..color = lightColor.withOpacity(0.3 + 0.3 * highlightAnimation.value)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    for (final id in winnerIds) {
      if (fingerPositionsById.containsKey(id)) {
        final pos = fingerPositionsById[id]!;
        final radius = 60 + 20 * highlightAnimation.value;
        canvas.drawCircle(pos, radius, paint);
      }
    }
  }
}

// Pulse light effect
class PulseLightPainter extends BaseLightPainter {
  final Color lightColor;

  PulseLightPainter({
    required super.lightState,
    required super.fingerPositions,
    required super.winnerIds,
    required super.fingerPositionsById,
    required super.rotationAnimation,
    required super.targetingAnimation,
    required super.highlightAnimation,
    this.lightColor = Colors.blue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Simplified implementation
    final center = Offset(size.width / 2, size.height / 2);
    final pulseValue = highlightAnimation.value;

    final paint = Paint()
      ..color = lightColor.withOpacity(0.2 + 0.3 * pulseValue)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawCircle(center, 100 + 50 * pulseValue, paint);
  }
}

// Stars light effect
class StarsLightPainter extends BaseLightPainter {
  StarsLightPainter({
    required super.lightState,
    required super.fingerPositions,
    required super.winnerIds,
    required super.fingerPositionsById,
    required super.rotationAnimation,
    required super.targetingAnimation,
    required super.highlightAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Simplified stars implementation
    if (lightState == light_models.LightState.highlighting) {
      for (final id in winnerIds) {
        if (fingerPositionsById.containsKey(id)) {
          _drawStars(canvas, fingerPositionsById[id]!);
        }
      }
    }
  }

  void _drawStars(Canvas canvas, Offset center) {
    // Draw a simple star
    final paint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path();
    const starSize = 30.0;
    final outerRadius = starSize;
    final innerRadius = starSize * 0.4;

    for (int i = 0; i < 5; i++) {
      final outerAngle = 2 * pi * i / 5 - pi / 2;
      final innerAngle = 2 * pi * (i + 0.5) / 5 - pi / 2;

      final outerPoint = Offset(
        center.dx + cos(outerAngle) * outerRadius,
        center.dy + sin(outerAngle) * outerRadius,
      );

      final innerPoint = Offset(
        center.dx + cos(innerAngle) * innerRadius,
        center.dy + sin(innerAngle) * innerRadius,
      );

      if (i == 0) {
        path.moveTo(outerPoint.dx, outerPoint.dy);
      } else {
        path.lineTo(outerPoint.dx, outerPoint.dy);
      }

      path.lineTo(innerPoint.dx, innerPoint.dy);
    }

    path.close();
    canvas.drawPath(path, paint);
  }
}
