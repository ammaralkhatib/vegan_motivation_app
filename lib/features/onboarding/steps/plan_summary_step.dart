import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../onboarding_widgets.dart';

/// S22 — the personalized 30-day plan summary.
class PlanSummaryStep extends StatelessWidget {
  const PlanSummaryStep({
    super.key,
    required this.name,
    required this.onContinue,
  });

  final String name;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateFormat('MMMM d, y')
        .format(DateTime.now().add(const Duration(days: 30)));

    final bold = TextStyle(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
    );
    final headline = name.isEmpty
        ? Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'your unshakable habit arrives by '),
              TextSpan(text: date, style: bold),
            ]),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          )
        : Text.rich(
            TextSpan(children: [
              TextSpan(text: '$name, you\'ll have an unshakable habit by '),
              TextSpan(text: date, style: bold),
            ]),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          );

    return InputStep(
      onContinue: onContinue,
      cta: 'begin my journey',
      child: ListView(
        children: [
          const SizedBox(height: 8),
          headline,
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              _Chip('daily spark'),
              _Chip('streaks that stick'),
              _Chip('impact you can see'),
            ],
          ),
          const SizedBox(height: 24),
          Text('how we\'ll get you there:',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          const _PlanCard(
            emoji: '✨',
            title: 'a personal spark, daily',
            body: 'no more hunting for motivation. quotes picked for your why, '
                'every morning.',
          ),
          const SizedBox(height: 12),
          const _PlanCard(
            emoji: '📈',
            title: 'proof of the good you do',
            body: 'watch your animal, CO₂ and water impact grow, day by day.',
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(label),
      backgroundColor: theme.colorScheme.primaryContainer,
      side: BorderSide.none,
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.emoji,
    required this.title,
    required this.body,
  });

  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
