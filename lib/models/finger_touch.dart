import 'package:flutter/material.dart';
import 'dart:math';

class FingerTouch {
  final int id;
  final Offset position;
  final bool isWinner;
  final bool isLoser;
  final double size;
  final DateTime touchStartTime;
  final Color uniqueColor;
  final bool isDisqualified;

  FingerTouch({
    required this.id,
    required this.position,
    this.isWinner = false,
    this.isLoser = false,
    this.size = 60.0,
    DateTime? touchStartTime,
    Color? uniqueColor,
    this.isDisqualified = false,
  })  : touchStartTime = touchStartTime ?? DateTime.now(),
        uniqueColor = uniqueColor ?? _generateRandomColor();

  static Color _generateRandomColor() {
    final random = Random();
    return Color.fromRGBO(
      50 + random.nextInt(150), // Not too dark, not too bright
      50 + random.nextInt(150),
      50 + random.nextInt(150),
      1.0,
    );
  }

  FingerTouch copyWith({
    int? id,
    Offset? position,
    bool? isWinner,
    bool? isLoser,
    double? size,
    DateTime? touchStartTime,
    Color? uniqueColor,
    bool? isDisqualified,
  }) {
    return FingerTouch(
      id: id ?? this.id,
      position: position ?? this.position,
      isWinner: isWinner ?? this.isWinner,
      isLoser: isLoser ?? this.isLoser,
      size: size ?? this.size,
      touchStartTime: touchStartTime ?? this.touchStartTime,
      uniqueColor: uniqueColor ?? this.uniqueColor,
      isDisqualified: isDisqualified ?? this.isDisqualified,
    );
  }

  Duration getDuration() {
    return DateTime.now().difference(touchStartTime);
  }
}
