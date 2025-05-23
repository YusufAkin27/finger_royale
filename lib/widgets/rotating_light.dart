import 'dart:math';
import 'package:flutter/material.dart';
import 'package:finger_selection_game/models/finger_touch.dart';

enum LightState {
  rotating, // Light is rotating between all fingers
  centered, // Light is in the center of the screen (pause)
  targeting, // Light is moving to the winner(s)
  highlighting, // Light is highlighting the winner(s)
}

class RotatingLight extends StatefulWidget {
  final Map<int, FingerTouch> fingers;
  final Set<int> winnerIds;
  final AnimationController rotationController;
  final AnimationController targetingController;
  final VoidCallback onAnimationComplete;
  final LightState lightState;

  const RotatingLight({
    super.key,
    required this.fingers,
    required this.winnerIds,
    required this.rotationController,
    required this.targetingController,
    required this.onAnimationComplete,
    required this.lightState,
  });

  @override
  State<RotatingLight> createState() => _RotatingLightState();
}

class _RotatingLightState extends State<RotatingLight> {
  late int _currentFingerIndex;
  Offset _lightPosition = Offset.zero;
  List<int> _fingerIds = [];

  @override
  void initState() {
    super.initState();
    _updateFingerIds();
    _currentFingerIndex = 0;

    // Listen to rotation animation to update the current finger
    widget.rotationController.addListener(_updateRotatingPosition);

    // Listen to targeting animation to move towards winner
    widget.targetingController.addListener(_updateTargetingPosition);
  }

  @override
  void didUpdateWidget(RotatingLight oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateFingerIds();

    if (oldWidget.lightState != widget.lightState) {
      // If transitioning to targeting state, prepare the targeting animation
      if (widget.lightState == LightState.targeting) {
        widget.targetingController.reset();
        widget.targetingController.forward();
      }
    }
  }

  @override
  void dispose() {
    widget.rotationController.removeListener(_updateRotatingPosition);
    widget.targetingController.removeListener(_updateTargetingPosition);
    super.dispose();
  }

  void _updateFingerIds() {
    _fingerIds = widget.fingers.keys.toList();
  }

  void _updateRotatingPosition() {
    if (widget.lightState != LightState.rotating || _fingerIds.isEmpty) return;

    // Calculate the current finger index based on controller value
    // This creates a rotation effect through all fingers
    final totalRotations = 3; // Number of complete rotations
    final normalizedValue = widget.rotationController.value;
    final rotationProgress = normalizedValue * totalRotations;

    // The speed increases towards the end
    final adjustedProgress = pow(normalizedValue, 0.7) * totalRotations;

    if (_fingerIds.isNotEmpty) {
      final index =
          (adjustedProgress * _fingerIds.length).floor() % _fingerIds.length;
      if (index != _currentFingerIndex && index < _fingerIds.length) {
        setState(() {
          _currentFingerIndex = index;
          final currentFingerId = _fingerIds[_currentFingerIndex];
          if (widget.fingers.containsKey(currentFingerId)) {
            _lightPosition = widget.fingers[currentFingerId]!.position;
          }
        });
      }
    }

    // When animation completes, notify parent
    if (widget.rotationController.isCompleted) {
      // Make sure we end in the center position
      setState(() {
        _lightPosition = _getCenterPosition();
      });
      widget.onAnimationComplete();
    }
  }

  void _updateTargetingPosition() {
    if (widget.lightState != LightState.targeting &&
        widget.lightState != LightState.highlighting)
      return;

    if (widget.targetingController.isCompleted) {
      // When targeting completes, stay on winners
      setState(() {
        _lightPosition = _getWinnerPosition();
      });
      if (widget.lightState == LightState.targeting) {
        widget.onAnimationComplete();
      }
    } else {
      // During targeting, interpolate from center to winner
      final centerPos = _getCenterPosition();
      final winnerPos = _getWinnerPosition();

      setState(() {
        _lightPosition =
            Offset.lerp(
              centerPos,
              winnerPos,
              Curves.easeInOutBack.transform(widget.targetingController.value),
            )!;
      });
    }
  }

  Offset _getCenterPosition() {
    // Calculate screen center position
    final screenSize = MediaQuery.of(context).size;
    return Offset(screenSize.width / 2, screenSize.height / 2);
  }

  Offset _getWinnerPosition() {
    // If we have multiple winners, we'll target the first one for now
    if (widget.winnerIds.isNotEmpty) {
      final winnerId = widget.winnerIds.first;
      if (widget.fingers.containsKey(winnerId)) {
        return widget.fingers[winnerId]!.position;
      }
    }

    // Fallback to center if no winners
    return _getCenterPosition();
  }

  @override
  Widget build(BuildContext context) {
    if (_fingerIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final double lightSize =
        widget.lightState == LightState.highlighting ? 100.0 : 60.0;
    final double glowIntensity =
        widget.lightState == LightState.highlighting ? 0.8 : 0.5;

    return Positioned(
      left: _lightPosition.dx - (lightSize / 2),
      top: _lightPosition.dy - (lightSize / 2),
      child: Container(
        width: lightSize,
        height: lightSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.yellow.withOpacity(0.3),
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.withOpacity(glowIntensity),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: lightSize * 0.6,
            height: lightSize * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
