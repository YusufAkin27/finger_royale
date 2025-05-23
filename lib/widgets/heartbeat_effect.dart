import 'dart:async';
import 'package:flutter/material.dart';

class HeartbeatEffect extends StatefulWidget {
  final double size;
  final Color color;
  final VoidCallback? onComplete;
  final int durationSeconds;

  const HeartbeatEffect({
    super.key,
    required this.size,
    required this.color,
    this.onComplete,
    this.durationSeconds = 3,
  });

  @override
  State<HeartbeatEffect> createState() => _HeartbeatEffectState();
}

class _HeartbeatEffectState extends State<HeartbeatEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  late Timer _beatTimer;
  late Timer _endTimer;

  double _beatInterval = 1.0; // Start with slow beats (1 second)
  final double _minBeatInterval = 0.2; // End with fast beats (0.2 seconds)

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sizeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Start the heartbeat
    _startHeartbeat();

    // Set the timer to end the effect after the specified duration
    _endTimer = Timer(Duration(seconds: widget.durationSeconds), () {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  void _startHeartbeat() {
    _beatTimer = Timer.periodic(
      Duration(milliseconds: (_beatInterval * 1000).toInt()),
      (timer) {
        _controller.forward().then((_) => _controller.reverse());

        // Gradually decrease the interval to increase the heartbeat rate
        setState(() {
          if (_beatInterval > _minBeatInterval) {
            _beatInterval -= 0.05;
            if (_beatInterval < _minBeatInterval) {
              _beatInterval = _minBeatInterval;
            }

            // Update the timer with the new interval
            _beatTimer.cancel();
            _startHeartbeat();
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _beatTimer.cancel();
    _endTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size * _sizeAnimation.value,
          height: widget.size * _sizeAnimation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.3),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5),
                blurRadius: 20 * _sizeAnimation.value,
                spreadRadius: 5 * _sizeAnimation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
