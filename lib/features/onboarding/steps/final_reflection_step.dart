import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../onboarding_copy.dart';
import '../onboarding_widgets.dart';

/// S15 — a short reflection assembled from the user's own answers, with
/// graceful fallbacks. Lines fade in one by one.
class FinalReflectionStep extends StatelessWidget {
  const FinalReflectionStep({
    super.key,
    required this.goals,
    required this.obstacles,
    required this.dipsPerWeek,
    required this.onContinue,
  });

  final List<String> goals;
  final List<String> obstacles;
  final int dipsPerWeek;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final style = theme.textTheme.titleLarge;

    final goalPhrase = goals.isEmpty
        ? l.onboardingReflectionGoalFallback
        : goalPlainWords(l, goals.first);
    final obstaclePhrase = obstacles.isEmpty
        ? l.onboardingReflectionObstacleFallback
        : obstaclePlainWords(l, obstacles.first);
    final dipsLine = dipsPerWeek < 0
        ? l.onboardingReflectionDipsUnknown
        : l.onboardingReflectionDips(dipsPerWeek);

    final lines = <String>[
      l.onboardingReflectionGoalLine(goalPhrase),
      l.onboardingReflectionObstacleLine(obstaclePhrase),
      dipsLine,
      l.onboardingReflectionClose,
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
              child: Text(lines[i], textAlign: TextAlign.center, style: style),
            ),
            if (i != lines.length - 1) const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }
}
