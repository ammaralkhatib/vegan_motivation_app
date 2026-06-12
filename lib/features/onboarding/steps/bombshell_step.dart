import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/impact_estimates.dart';
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
              before: '${namePrefix}by staying on this path you\'ll save ~',
              value: ImpactEstimates.animalsPerDay * 365 * yearsLeft,
              after: ' animals',
              body: body,
              bold: bold,
            ),
            _numberLine(
              context,
              before: 'that\'s ',
              value: ImpactEstimates.co2KgPerDay * 365 * yearsLeft / 1000,
              after: ' tonnes of CO₂',
              body: body,
              bold: bold,
            ),
            _numberLine(
              context,
              before: 'and ',
              value: ImpactEstimates.waterLitresPerDay * 365 * yearsLeft,
              after: ' litres of water over your lifetime...',
              body: body,
              bold: bold,
            ),
            Text('what could matter more than protecting that?',
                textAlign: TextAlign.center, style: body),
          ]
        : <Widget>[
            _numberLine(
              context,
              before: '${namePrefix}the average diet takes ~',
              value: ImpactEstimates.animalsPerDay * 365,
              after: ' animal lives every year',
              body: body,
              bold: bold,
            ),
            _numberLine(
              context,
              before: 'that\'s ~',
              value: ImpactEstimates.animalsPerDay * 365 * yearsLeft,
              after: ' animals over a lifetime',
              body: body,
              bold: bold,
            ),
            _numberLine(
              context,
              before: 'and ',
              value: ImpactEstimates.co2KgPerDay * 365 * yearsLeft / 1000,
              after: ' tonnes of CO₂...',
              body: body,
              bold: bold,
            ),
            Text('how many of them could you spare?',
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
