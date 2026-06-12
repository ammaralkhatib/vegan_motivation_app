import 'package:flutter/material.dart';

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
    final style = theme.textTheme.titleLarge;

    final goalPhrase = goals.isEmpty
        ? 'to keep your motivation strong'
        : goalPlainWords[goals.first] ?? 'to keep your motivation strong';
    final obstaclePhrase = obstacles.isEmpty
        ? 'old habits'
        : obstaclePlainWords[obstacles.first] ?? 'old habits';
    final dipsLine = dipsPerWeek < 0
        ? 'and some weeks test your motivation'
        : 'your motivation dips $dipsPerWeek '
            '${dipsPerWeek == 1 ? 'day' : 'days'} a week';

    final lines = <String>[
      'you want $goalPhrase',
      'but $obstaclePhrase keeps getting in the way',
      dipsLine,
      'veggie was made for exactly this moment.',
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
