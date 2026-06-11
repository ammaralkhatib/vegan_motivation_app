import 'package:flutter/material.dart';

/// Type scale: Fraunces (serif display, quotes & numbers) + Inter (UI).
abstract final class VeggieType {
  static const serif = 'Fraunces';
  static const sans = 'Inter';

  static TextTheme textTheme(Color ink, Color inkMuted) {
    return TextTheme(
      // Fraunces — display / quotes / counters
      displayLarge: TextStyle(
        fontFamily: serif,
        fontSize: 34,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      displayMedium: TextStyle(
        fontFamily: serif,
        fontSize: 30,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      displaySmall: TextStyle(
        fontFamily: serif,
        fontSize: 26,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      headlineMedium: TextStyle(
        fontFamily: serif,
        fontSize: 22,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      headlineSmall: TextStyle(
        fontFamily: serif,
        fontSize: 19,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      // Inter — UI
      titleLarge: TextStyle(
        fontFamily: sans,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontFamily: sans,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleSmall: TextStyle(
        fontFamily: sans,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: TextStyle(
        fontFamily: sans,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: ink,
      ),
      bodyMedium: TextStyle(
        fontFamily: sans,
        fontSize: 15,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: ink,
      ),
      bodySmall: TextStyle(
        fontFamily: sans,
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: inkMuted,
      ),
      labelLarge: TextStyle(
        fontFamily: sans,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      labelMedium: TextStyle(
        fontFamily: sans,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      labelSmall: TextStyle(
        fontFamily: sans,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: inkMuted,
      ),
    );
  }
}
