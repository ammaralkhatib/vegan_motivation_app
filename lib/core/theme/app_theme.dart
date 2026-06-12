import 'package:flutter/material.dart';

import 'palette.dart';
import 'typography.dart';

/// Extra design tokens that don't fit ColorScheme: heatmap ramp, celebration
/// accents, per-category feed tints.
@immutable
class VeggieAccents extends ThemeExtension<VeggieAccents> {
  const VeggieAccents({
    required this.heatmapRamp,
    required this.celebration,
    required this.categoryTints,
  });

  /// 5 steps: empty → fully complete (heatmap cells).
  final List<Color> heatmapRamp;

  /// Confetti / milestone highlight color.
  final Color celebration;

  /// Subtle background tints keyed by category slug, layered on the canvas.
  final Map<String, Color> categoryTints;

  static const light = VeggieAccents(
    heatmapRamp: [
      Color(0xFFEFEDE4),
      Color(0xFFD3E2D0),
      Color(0xFFA8C7AC),
      Color(0xFF6E9C7C),
      Color(0xFF1F4D36),
    ],
    celebration: VeggiePalette.coral,
    categoryTints: {
      'why_vegan': Color(0xFFCBE6C2), // green
      'quick_tips': Color(0xFFE9E2A6), // yellow-olive
      'youre_awesome': Color(0xFFF8CFC6), // warm pink/coral
      'facts': Color(0xFFBFE2E6), // teal/blue
      'staying_strong': Color(0xFFEBCFAF), // earthy orange/brown
      'milestones': Color(0xFFF6DCA0), // golden amber
    },
  );

  static const dark = VeggieAccents(
    heatmapRamp: [
      Color(0xFF1C2620),
      Color(0xFF27402F),
      Color(0xFF3A5C44),
      Color(0xFF5E8A6B),
      Color(0xFF9FC2A8),
    ],
    celebration: VeggiePalette.coralDark,
    categoryTints: {
      'why_vegan': Color(0xFF1C3A28), // green
      'quick_tips': Color(0xFF34330F), // yellow-olive
      'youre_awesome': Color(0xFF3F231D), // warm pink/coral
      'facts': Color(0xFF123537), // teal/blue
      'staying_strong': Color(0xFF3A280F), // earthy orange/brown
      'milestones': Color(0xFF3E2E0B), // golden amber
    },
  );

  @override
  VeggieAccents copyWith({
    List<Color>? heatmapRamp,
    Color? celebration,
    Map<String, Color>? categoryTints,
  }) {
    return VeggieAccents(
      heatmapRamp: heatmapRamp ?? this.heatmapRamp,
      celebration: celebration ?? this.celebration,
      categoryTints: categoryTints ?? this.categoryTints,
    );
  }

  @override
  VeggieAccents lerp(VeggieAccents? other, double t) {
    if (other == null) return this;
    return VeggieAccents(
      heatmapRamp: [
        for (var i = 0; i < heatmapRamp.length; i++)
          Color.lerp(heatmapRamp[i], other.heatmapRamp[i], t)!,
      ],
      celebration: Color.lerp(celebration, other.celebration, t)!,
      categoryTints: {
        for (final entry in categoryTints.entries)
          entry.key:
              Color.lerp(entry.value, other.categoryTints[entry.key], t)!,
      },
    );
  }
}

abstract final class VeggieTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: VeggiePalette.forest,
      onPrimary: Colors.white,
      primaryContainer: VeggiePalette.forestContainer,
      onPrimaryContainer: VeggiePalette.forest,
      secondary: VeggiePalette.sage,
      onSecondary: Colors.white,
      secondaryContainer: VeggiePalette.sageContainer,
      onSecondaryContainer: VeggiePalette.forest,
      tertiary: VeggiePalette.coral,
      onTertiary: Colors.white,
      tertiaryContainer: VeggiePalette.coralContainer,
      onTertiaryContainer: Color(0xFF6B3526),
      error: Color(0xFFB3403A),
      onError: Colors.white,
      surface: VeggiePalette.surfaceLight,
      onSurface: VeggiePalette.inkLight,
      onSurfaceVariant: VeggiePalette.inkMutedLight,
      surfaceContainerHighest: Color(0xFFF0EBE0),
      surfaceContainerHigh: Color(0xFFF4F0E6),
      surfaceContainer: Color(0xFFF7F3EA),
      surfaceContainerLow: Color(0xFFFAF6EF),
      surfaceContainerLowest: Colors.white,
      outline: VeggiePalette.outlineLight,
      outlineVariant: Color(0xFFE0E5DB),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: VeggiePalette.inkLight,
      onInverseSurface: VeggiePalette.cream,
      inversePrimary: VeggiePalette.mint,
    );
    return _base(scheme, VeggiePalette.cream, VeggieAccents.light);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: VeggiePalette.mint,
      onPrimary: Color(0xFF0C2417),
      primaryContainer: VeggiePalette.mintContainer,
      onPrimaryContainer: VeggiePalette.mint,
      secondary: VeggiePalette.sageDark,
      onSecondary: Color(0xFF0C2417),
      secondaryContainer: Color(0xFF324A3A),
      onSecondaryContainer: Color(0xFFD3E2D0),
      tertiary: VeggiePalette.coralDark,
      onTertiary: Color(0xFF3A1D14),
      tertiaryContainer: VeggiePalette.coralContainerDark,
      onTertiaryContainer: Color(0xFFF8CDBE),
      error: Color(0xFFE99490),
      onError: Color(0xFF3F1413),
      surface: VeggiePalette.surfaceDark,
      onSurface: VeggiePalette.inkDark,
      onSurfaceVariant: VeggiePalette.inkMutedDark,
      surfaceContainerHighest: Color(0xFF2C3A30),
      surfaceContainerHigh: VeggiePalette.surfaceDarkHigh,
      surfaceContainer: Color(0xFF1F2A22),
      surfaceContainerLow: Color(0xFF18211A),
      surfaceContainerLowest: Color(0xFF0C120E),
      outline: VeggiePalette.outlineDark,
      outlineVariant: Color(0xFF2C362F),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: VeggiePalette.inkDark,
      onInverseSurface: VeggiePalette.charcoal,
      inversePrimary: VeggiePalette.forest,
    );
    return _base(scheme, VeggiePalette.charcoal, VeggieAccents.dark);
  }

  static ThemeData _base(
    ColorScheme scheme,
    Color scaffold,
    VeggieAccents accents,
  ) {
    final textTheme =
        VeggieType.textTheme(scheme.onSurface, scheme.onSurfaceVariant);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      fontFamily: VeggieType.sans,
      splashFactory: InkSparkle.splashFactory,
      extensions: [accents],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.displaySmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.secondaryContainer,
        labelStyle: textTheme.labelMedium,
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          textStyle: textTheme.titleMedium,
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          textStyle: textTheme.titleMedium,
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.headlineMedium,
        contentTextStyle: textTheme.bodyMedium,
      ),
    );
  }
}
