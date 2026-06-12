import 'package:flutter/material.dart';

import '../onboarding_copy.dart';
import '../onboarding_widgets.dart';

/// S25 — a "motivation snapshot" assembled from the user's own answers, with
/// sensible fallbacks when something wasn't set.
class SnapshotStep extends StatelessWidget {
  const SnapshotStep({
    super.key,
    required this.whyRelationship,
    required this.dipsPerWeek,
    required this.commitmentLevel,
    required this.firstGoal,
    required this.onContinue,
  });

  final String? whyRelationship;
  final int dipsPerWeek;
  final String? commitmentLevel;
  final String? firstGoal;
  final VoidCallback onContinue;

  double get _motivationFill => switch (whyRelationship) {
        'fading' => 0.25,
        'ups_downs' || 'starting' => 0.5,
        'strong' => 0.9,
        _ => 0.5,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dips = dipsPerWeek < 0 ? 0 : dipsPerWeek;
    final commitmentFill = commitmentBarFill[commitmentLevel] ?? 0.5;
    final strength = firstGoal == null
        ? 'showing up every day'
        : goalPlainWords[firstGoal] ?? 'showing up every day';

    return InputStep(
      onContinue: onContinue,
      child: ListView(
        children: [
          const SizedBox(height: 8),
          Text('✨ your motivation snapshot',
              style: theme.textTheme.displaySmall),
          const SizedBox(height: 20),
          _BarCard(
            label: 'current motivation',
            fill: _motivationFill,
            trailing: 'low → high',
          ),
          const SizedBox(height: 12),
          _ValueCard(
            label: 'weekly dips',
            value: '$dips days/week',
          ),
          const SizedBox(height: 12),
          _BarCard(
            label: 'commitment level',
            fill: commitmentFill,
          ),
          const SizedBox(height: 12),
          _ValueCard(
            label: 'strengths',
            value: strength,
          ),
        ],
      ),
    );
  }
}

class _BarCard extends StatelessWidget {
  const _BarCard({required this.label, required this.fill, this.trailing});

  final String label;
  final double fill;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child:
                        Text(label, style: theme.textTheme.titleMedium)),
                if (trailing != null)
                  Text(trailing!, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: fill,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
            Text(value,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}
