import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context);
    final date = DateFormat('MMMM d, y')
        .format(DateTime.now().add(const Duration(days: 30)));

    final bold = TextStyle(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
    );
    // The headline ends with an emphasized date, so the before-text is one ARB
    // key and the bold date is appended as its own span.
    final headline = Text.rich(
      TextSpan(children: [
        TextSpan(
          text: name.isEmpty
              ? l.onboardingPlanHeadlineBefore
              : l.onboardingPlanHeadlineNamedBefore(name),
        ),
        TextSpan(text: date, style: bold),
      ]),
      textAlign: TextAlign.center,
      style: theme.textTheme.headlineSmall,
    );

    return InputStep(
      onContinue: onContinue,
      cta: l.onboardingPlanCta,
      child: ListView(
        children: [
          const SizedBox(height: 8),
          headline,
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(l.onboardingPlanChip1),
              _Chip(l.onboardingPlanChip2),
              _Chip(l.onboardingPlanChip3),
            ],
          ),
          const SizedBox(height: 24),
          Text(l.onboardingPlanHow, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _PlanCard(
            emoji: '✨',
            title: l.onboardingPlanCard1Title,
            body: l.onboardingPlanCard1Body,
          ),
          const SizedBox(height: 12),
          _PlanCard(
            emoji: '📈',
            title: l.onboardingPlanCard2Title,
            body: l.onboardingPlanCard2Body,
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
