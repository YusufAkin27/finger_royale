import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finger_selection_game/models/game_settings.dart';

class ThemeBackground extends StatefulWidget {
  final GameThemeMode themeMode;
  final Widget child;

  const ThemeBackground({
    super.key,
    required this.themeMode,
    required this.child,
  });

  @override
  State<ThemeBackground> createState() => _ThemeBackgroundState();
}

class _ThemeBackgroundState extends State<ThemeBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tema seçimine göre status bar rengini güncelle
    _updateStatusBarColor(widget.themeMode);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        return Container(
          decoration: _getBackgroundDecoration(),
          child: widget.child,
        );
      },
    );
  }

  void _updateStatusBarColor(GameThemeMode themeMode) {
    switch (themeMode) {
      case GameThemeMode.light:
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
          ),
        );
        break;
      case GameThemeMode.dark:
      case GameThemeMode.neon:
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          ),
        );
        break;
      default:
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          ),
        );
    }
  }

  BoxDecoration _getBackgroundDecoration() {
    switch (widget.themeMode) {
      case GameThemeMode.dark:
        return BoxDecoration(
          color: Colors.black,
          backgroundBlendMode: BlendMode.darken,
        );
      case GameThemeMode.neon:
        return BoxDecoration(
          color: Colors.black,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.withOpacity(0.3),
              Colors.blue.withOpacity(0.3),
            ],
          ),
        );
      case GameThemeMode.light:
      default:
        return const BoxDecoration(
          color: Colors.white,
        );
    }
  }
}

// Decorator elements for additional visual effects
class ThemeDecoration extends StatelessWidget {
  final GameThemeMode themeMode;

  const ThemeDecoration({
    super.key,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    switch (themeMode) {
      case GameThemeMode.neon:
        return const NeonGridLines();
      default:
        return const SizedBox.shrink();
    }
  }
}

class NeonGridLines extends StatelessWidget {
  const NeonGridLines({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Placeholder
  }
}
