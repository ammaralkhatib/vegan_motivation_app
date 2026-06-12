import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/impact_estimates.dart';
import '../../l10n/app_localizations.dart';
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
      helpText: AppLocalizations.of(context).journeyDatePickerHelp,
    );
    if (picked != null) {
      await ref.read(journeyProvider.notifier).setVeganSince(picked);
    }
  }

  void _showEstimatesInfo(BuildContext context) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.journeyAboutNumbersTitle,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              l.journeyAboutNumbersBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final journey = ref.watch(journeyProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l.journeyTitle),
        actions: [
          IconButton(
            onPressed: () => context.go('/journey/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: l.journeySettingsTooltip,
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
    final l = AppLocalizations.of(context);
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
                    ? l.journeyHeroTitle
                    : l.journeyHeroTitleNamed(name),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                l.journeyDayCount(days),
                style: theme.textTheme.displayLarge
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => _pickDate(context, ref),
                icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                label: Text(
                  l.journeySince(
                    DateFormat('MMM d, y').format(journey.veganSince!),
                  ),
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
          Text(l.journeyEstimatedImpact, style: theme.textTheme.titleMedium),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => _showEstimatesInfo(context),
            icon: const Icon(Icons.info_outline, size: 18),
            visualDensity: VisualDensity.compact,
            tooltip: l.journeyAboutNumbersTitle,
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
    final l = AppLocalizations.of(context);
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(l.journeyCuriousTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                l.journeyCuriousSubtitle,
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
              l.journeyCuriousFootnote,
              style: theme.textTheme.bodySmall,
            ),
          ),
          IconButton(
            onPressed: () => _showEstimatesInfo(context),
            icon: const Icon(Icons.info_outline, size: 18),
            tooltip: l.journeyAboutNumbersTitle,
          ),
        ],
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () => _pickDate(context, ref),
        icon: const Icon(Icons.eco),
        label: Text(l.journeyHaveStartDate),
      ),
    ];
  }
}

class _MilestoneChips extends StatelessWidget {
  const _MilestoneChips({required this.days});

  final int days;

  static const _milestones = [
    (days: 7, emoji: '🌱'),
    (days: 30, emoji: '🌿'),
    (days: 100, emoji: '🌳'),
    (days: 365, emoji: '🏆'),
  ];

  String _label(AppLocalizations l, int milestoneDays) => switch (milestoneDays) {
        7 => l.journeyMilestone1Week,
        30 => l.journeyMilestone1Month,
        100 => l.journeyMilestone100Days,
        _ => l.journeyMilestone1Year,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in _milestones)
          Chip(
            avatar: Text(m.emoji),
            label: Text(_label(l, m.days)),
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
