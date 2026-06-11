import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/impact_estimates.dart';
import 'impact_counter.dart';
import 'providers.dart';

class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final journey = ref.read(journeyProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: journey.veganSince ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      helpText: 'When did your vegan journey begin?',
    );
    if (picked != null) {
      await ref.read(journeyProvider.notifier).setVeganSince(picked);
    }
  }

  void _showEstimatesInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About these numbers',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              'These are rough estimates of what one fully plant-based day '
              'saves, based on commonly cited figures (the Cowspiracy fact '
              'sheet, Water Footprint Network data, and similar aggregations '
              'popularized by The Vegan Calculator).\n\n'
              'Real-world impact varies by diet, region, and season — treat '
              'them as a motivating sketch, not an exact audit. The direction '
              'is what matters, and the direction is wonderful.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = ref.watch(journeyProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Journey'),
        actions: [
          IconButton(
            onPressed: () => context.go('/journey/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (journey.veganSince != null)
            ..._veganJourney(context, ref, journey)
          else
            ..._curiousJourney(context, ref, journey),
        ],
      ),
    );
  }

  List<Widget> _veganJourney(
    BuildContext context,
    WidgetRef ref,
    JourneyState journey,
  ) {
    final theme = Theme.of(context);
    final days = journey.daysVegan;
    final name = journey.userName;

    return [
      // Hero
      Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                name == null || name.isEmpty
                    ? 'Your vegan journey'
                    : '$name, your vegan journey',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                'Day $days 🌱',
                style: theme.textTheme.displayLarge
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => _pickDate(context, ref),
                icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                label: Text(
                  'since ${DateFormat('MMM d, y').format(journey.veganSince!)}',
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      _MilestoneChips(days: days),
      const SizedBox(height: 20),
      Row(
        children: [
          Text('Your estimated impact', style: theme.textTheme.titleMedium),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => _showEstimatesInfo(context),
            icon: const Icon(Icons.info_outline, size: 18),
            visualDensity: VisualDensity.compact,
            tooltip: 'About these numbers',
          ),
        ],
      ),
      const SizedBox(height: 8),
      for (final stat in impactStats) ...[
        ImpactCounter(stat: stat, days: days),
        const SizedBox(height: 10),
      ],
    ];
  }

  List<Widget> _curiousJourney(
    BuildContext context,
    WidgetRef ref,
    JourneyState journey,
  ) {
    final theme = Theme.of(context);
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text('Curious about the difference\none month could make?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                'Here is what 30 plant-based days are estimated to save:',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      for (final stat in impactStats) ...[
        ImpactCounter(stat: stat, days: 30),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: Text(
              'Estimates, not audits — tap for sources.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          IconButton(
            onPressed: () => _showEstimatesInfo(context),
            icon: const Icon(Icons.info_outline, size: 18),
            tooltip: 'About these numbers',
          ),
        ],
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () => _pickDate(context, ref),
        icon: const Icon(Icons.eco),
        label: const Text('I have a start date!'),
      ),
    ];
  }
}

class _MilestoneChips extends StatelessWidget {
  const _MilestoneChips({required this.days});

  final int days;

  static const _milestones = [
    (days: 7, label: '1 week', emoji: '🌱'),
    (days: 30, label: '1 month', emoji: '🌿'),
    (days: 100, label: '100 days', emoji: '🌳'),
    (days: 365, label: '1 year', emoji: '🏆'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in _milestones)
          Chip(
            avatar: Text(m.emoji),
            label: Text(m.label),
            backgroundColor: days >= m.days
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            labelStyle: TextStyle(
              color: days >= m.days
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
