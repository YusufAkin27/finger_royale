import 'package:flutter/material.dart';
import 'package:finger_selection_game/models/finger_touch.dart';

class FingerIndicator extends StatelessWidget {
  final FingerTouch fingerTouch;
  final AnimationController? animationController;
  final double size;

  const FingerIndicator({
    super.key,
    required this.fingerTouch,
    this.animationController,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final position = fingerTouch.position;
    final isWinner = fingerTouch.isWinner;
    final isLoser = fingerTouch.isLoser;
    final isDisqualified = fingerTouch.isDisqualified;
    final uniqueColor = fingerTouch.uniqueColor;

    final actualSize = size;
    final halfSize = actualSize / 2;

    return Positioned(
      left: position.dx - halfSize,
      top: position.dy - halfSize,
      child: AnimatedBuilder(
        animation: animationController ?? const AlwaysStoppedAnimation(0),
        builder: (context, child) {
          final scale = animationController != null
              ? 1.0 +
                  animationController!.value * 0.5 // More dramatic animation
              : isWinner
                  ? 1.2 // Always scaled up for winners
                  : isLoser
                      ? 0.85 // Scaled down for losers
                      : 1.0;

          final baseColor = isDisqualified
              ? Colors.red
              : isWinner
                  ? Colors.green
                  : isLoser
                      ? Colors.grey.withOpacity(0.3) // Very dim for losers
                      : uniqueColor;

          final glowColor = isDisqualified
              ? Colors.red.withOpacity(0.7)
              : isWinner
                  ? Colors.green.withOpacity(0.8)
                  : isLoser
                      ? Colors.grey.withOpacity(0.1) // Minimal glow for losers
                      : uniqueColor.withOpacity(0.5);

          return Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Extra glow effect for winners
                if (isWinner)
                  Container(
                    width: actualSize * 1.5,
                    height: actualSize * 1.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 25,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),

                // Main circle
                Container(
                  width: actualSize,
                  height: actualSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: baseColor,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor,
                        blurRadius: isWinner
                            ? 20
                            : isLoser
                                ? 3
                                : 8,
                        spreadRadius: isWinner
                            ? 8
                            : isLoser
                                ? 1
                                : 3,
                      ),
                    ],
                    border: Border.all(
                      color: isWinner
                          ? Colors.white
                          : isLoser
                              ? Colors.grey.withOpacity(0.3)
                              : Colors.white.withOpacity(0.5),
                      width: isWinner ? 4 : 2,
                    ),
                  ),
                  child: Center(
                    child: isDisqualified
                        ? const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 36,
                          )
                        : isWinner
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    color: Colors.white,
                                    size: actualSize / 2,
                                  ),
                                  Text(
                                    "KAZANAN!",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : isLoser
                                ? Icon(
                                    Icons.remove_circle,
                                    color: Colors.white.withOpacity(0.5),
                                    size: actualSize / 3,
                                  )
                                : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
