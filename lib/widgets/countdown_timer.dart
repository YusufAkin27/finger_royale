import 'package:flutter/material.dart';

class CountdownTimer extends StatelessWidget {
  final int countdown;

  const CountdownTimer({super.key, required this.countdown});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            countdown.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
