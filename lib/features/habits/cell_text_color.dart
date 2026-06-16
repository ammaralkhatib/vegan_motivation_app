import 'package:flutter/material.dart';

/// Readable text color for a day-number drawn on top of a heatmap/calendar
/// cell of [background]. Light text on dark cells, muted-dark on light cells.
/// Theme-aware; callers handle transparent cells (no text) themselves.
Color cellTextColor(Color background, ColorScheme scheme) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? scheme.onInverseSurface // near-white in light theme
      : scheme.onSurfaceVariant; // muted dark
}
