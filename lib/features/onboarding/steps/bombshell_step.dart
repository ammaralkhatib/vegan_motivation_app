import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/impact_estimates.dart';
import '../../../l10n/app_localizations.dart';
import '../onboarding_widgets.dart';

/// S7 — the personalized "bombshell" impact stat. Lines fade in one by one;
/// numbers count up. Positive framing for vegan/mostly, negative for
/// cutting_down/curious.
class BombshellStep extends StatelessWidget {
  const BombshellStep({
    super.key,
    required this.name,
    required this.dietStatus,
    required this.ageRange,
    required this.onContinue,
  });

  final String name;
  final String? dietStatus;
  final String? ageRange;
  final VoidCallback onContinue;

  static int ageMidpoint(String? range) => switch (range) {
        '14–24' => 19,
        '25–34' => 30,
        '35–44' => 40,
        '45–54' => 50,
        '55+' => 60,
        _ => 40,
      };

  bool get _positive => dietStatus == 'vegan' || dietStatus == 'mostly';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final yearsLeft = math.max(5, 80 - ageMidpoint(ageRange)).toDouble();
    final namePrefix = name.isEmpty ? '' : '$name, ';

    final bold = theme.textTheme.headlineSmall?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
    );
    final body = theme.textTheme.titleLarge;

    final lines = _positive
        ? <Widget>[
            _numberLine(
              context,
              before: l.onboardingBombshellSavedBefore(namePrefix),
              value: ImpactEstimates.animalsPerDay * 365 * yearsLeft,
              after: l.onboardingBombshellSavedAfter,
              body: body,
              bold: bold,
            ),
            _numberLine(
              context,
              before: l.onboardingBombshellCo2Before,
              value: ImpactEstimates.co2KgPerDay * 365 * yearsLeft / 1000,
              after: l.onboardingBombshellCo2After,
              body: body,
              bold: bold,
            ),
            _numberLine(
              context,
              before: l.onboardingBombshellWaterBefore,
              value: ImpactEstimates.waterLitresPerDay * 365 * yearsLeft,
              after: l.onboardingBombshellWaterAfter,
              body: body,
              bold: bold,
            ),
            Text(l.onboardingBombshellPositiveClose,
                textAlign: TextAlign.center, style: body),
          ]
        : <Widget>[
            _numberLine(
              context,
              before: l.onboardingBombshellTakesBefore(namePrefix),
              value: ImpactEstimates.animalsPerDay * 365,
              after: l.onboardingBombshellTakesAfter,
              body: body,
              bold: bold,
            ),
            _numberLine(
              context,
              before: l.onboardingBombshellLifetimeBefore,
              value: ImpactEstimates.animalsPerDay * 365 * yearsLeft,
              after: l.onboardingBombshellLifetimeAfter,
              body: body,
              bold: bold,
            ),
            _numberLine(
              context,
              before: l.onboardingBombshellNegCo2Before,
              value: ImpactEstimates.co2KgPerDay * 365 * yearsLeft / 1000,
              after: l.onboardingBombshellNegCo2After,
              body: body,
              bold: bold,
            ),
            Text(l.onboardingBombshellNegativeClose,
                textAlign: TextAlign.center, style: body),
          ];

    return TapStep(
      onContinue: onContinue,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            FadeInLine(
              delay: Duration(milliseconds: 500 * i),
              child: lines[i],
            ),
            if (i != lines.length - 1) const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _numberLine(
    BuildContext context, {
    required String before,
    required double value,
    required String after,
    required TextStyle? body,
    required TextStyle? bold,
  }) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: before),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: CountUpNumber(value: value, style: bold),
          ),
          TextSpan(text: after),
        ],
      ),
      textAlign: TextAlign.center,
      style: body,
    );
  }
}
