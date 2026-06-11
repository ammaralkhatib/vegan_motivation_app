import 'package:flutter/material.dart';

/// Veggie color palette — "fresh & organic".
///
/// Light-first: warm cream canvas, deep forest green, sage, soft coral.
/// Coral is reserved for fills/accents, never body text (contrast).
abstract final class VeggiePalette {
  // Light
  static const cream = Color(0xFFFAF6EF);
  static const surfaceLight = Color(0xFFFFFDF7);
  static const forest = Color(0xFF1F4D36);
  static const forestContainer = Color(0xFFDCE8DA);
  static const sage = Color(0xFF7FA08A);
  static const sageContainer = Color(0xFFE4EDE2);
  static const coral = Color(0xFFE88A70);
  static const coralContainer = Color(0xFFFBE3DA);
  static const inkLight = Color(0xFF26302A);
  static const inkMutedLight = Color(0xFF5C6B60);
  static const outlineLight = Color(0xFFC9D2C5);

  // Dark
  static const charcoal = Color(0xFF101712);
  static const surfaceDark = Color(0xFF1A231C);
  static const surfaceDarkHigh = Color(0xFF243029);
  static const mint = Color(0xFF9FC2A8);
  static const mintContainer = Color(0xFF2C4434);
  static const sageDark = Color(0xFF7FA08A);
  static const coralDark = Color(0xFFF09D85);
  static const coralContainerDark = Color(0xFF4A2E25);
  static const inkDark = Color(0xFFE8EDE6);
  static const inkMutedDark = Color(0xFFA3B0A6);
  static const outlineDark = Color(0xFF3A463D);
}
