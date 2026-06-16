import 'package:flutter/material.dart';

/// Text color for a day-number drawn on top of a heatmap/calendar cell of
/// [background]. Only light-background cells get a stronger, higher-contrast
/// color ([ColorScheme.onSurface]); every other cell (the green/filled and
/// transparent ones) keeps the original muted [ColorScheme.onSurfaceVariant] —
/// the look before the auto-contrast change. Theme-aware in both light and dark;
/// callers handle transparent cells (no text) themselves.
Color cellTextColor(Color background, ColorScheme scheme) {
  final isLight =
      ThemeData.estimateBrightnessForColor(background) == Brightness.light;
  // Only light cells get the stronger number color; everything else keeps the
  // original muted onSurfaceVariant.
  return isLight ? scheme.onSurface : scheme.onSurfaceVariant;
}
