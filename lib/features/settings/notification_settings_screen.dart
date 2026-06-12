import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_service.dart';
import '../../l10n/app_localizations.dart';
import 'notification_prefs.dart';

String _formatMinutes(BuildContext context, int minutes) =>
    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context);

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _pickWindow(
    BuildContext context,
    WidgetRef ref, {
    required bool isStart,
  }) async {
    final settings = ref.read(notifSettingsProvider);
    final current = isStart ? settings.windowStartMin : settings.windowEndMin;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;

    var start = isStart ? minutes : settings.windowStartMin;
    var end = isStart ? settings.windowEndMin : minutes;
    // Keep at least a 2-hour window, in order.
    if (end - start < 120) {
      if (isStart) {
        end = (start + 120).clamp(0, 24 * 60 - 1);
      } else {
        start = (end - 120).clamp(0, end);
      }
    }
    await ref.read(notifSettingsProvider.notifier).setWindow(start, end);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(notifSettingsProvider);
    final notifier = ref.read(notifSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          SwitchListTile(
            value: settings.enabled,
            onChanged: (enabled) async {
              if (enabled) {
                await NotificationService.instance.requestPermission();
              }
              await notifier.setEnabled(enabled);
            },
            title: Text(l10n.notificationsDailyMotivation),
            subtitle: Text(l10n.notificationsDailyMotivationSubtitle),
            contentPadding: EdgeInsets.zero,
          ),
          if (settings.enabled) ...[
            const SizedBox(height: 16),
            SegmentedButton<NotifMode>(
              segments: [
                ButtonSegment(
                  value: NotifMode.spread,
                  label: Text(l10n.notificationsModeSpread),
                  icon: const Icon(Icons.schedule_outlined),
                ),
                ButtonSegment(
                  value: NotifMode.meals,
                  label: Text(l10n.notificationsModeMeals),
                  icon: const Icon(Icons.restaurant_outlined),
                ),
              ],
              selected: {settings.mode},
              onSelectionChanged: (s) => notifier.setMode(s.first),
            ),
            const SizedBox(height: 20),
            if (settings.mode == NotifMode.spread)
              ..._spreadControls(context, ref, theme, settings, notifier)
            else
              ..._mealControls(l10n, theme, settings),
          ],
        ],
      ),
    );
  }

  List<Widget> _spreadControls(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    NotifSettings settings,
    NotifSettingsNotifier notifier,
  ) {
    final l10n = AppLocalizations.of(context);
    return [
      Text(l10n.notificationsPerDayLabel, style: theme.textTheme.titleMedium),
      Row(
        children: [
          Expanded(
            child: Slider(
              value: settings.perDay.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: l10n.notificationsPerDayCount(settings.perDay),
              onChanged: (v) => notifier.setPerDay(v.round()),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(l10n.notificationsPerDayCount(settings.perDay),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(l10n.notificationsBetween, style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickWindow(context, ref, isStart: true),
              icon: const Icon(Icons.wb_sunny_outlined, size: 18),
              label: Text(_formatMinutes(context, settings.windowStartMin)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(l10n.notificationsWindowTo),
          ),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickWindow(context, ref, isStart: false),
              icon: const Icon(Icons.nights_stay_outlined, size: 18),
              label: Text(_formatMinutes(context, settings.windowEndMin)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Text(
        l10n.notificationsSpreadHint,
        style: theme.textTheme.bodySmall,
      ),
    ];
  }

  List<Widget> _mealControls(
    AppLocalizations l10n,
    ThemeData theme,
    NotifSettings settings,
  ) {
    return [
      for (final meal in Meal.values) ...[
        _MealCard(meal: meal),
        const SizedBox(height: 12),
      ],
      Text(
        settings.anyMealEnabled
            ? l10n.notificationsMealHintOn
            : l10n.notificationsMealHintOff,
        style: theme.textTheme.bodySmall,
      ),
    ];
  }
}

class _MealCard extends ConsumerWidget {
  const _MealCard({required this.meal});

  final Meal meal;

  String _label(AppLocalizations l10n) => switch (meal) {
        Meal.breakfast => l10n.notificationsMealBreakfast,
        Meal.lunch => l10n.notificationsMealLunch,
        Meal.dinner => l10n.notificationsMealDinner,
      };

  IconData get _icon => switch (meal) {
        Meal.breakfast => Icons.bakery_dining_outlined,
        Meal.lunch => Icons.lunch_dining_outlined,
        Meal.dinner => Icons.dinner_dining_outlined,
      };

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(notifSettingsProvider);
    final current = settings.meal(meal).timeMin;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;

    // Keep enabled meals at least 2 hours apart; otherwise block with a hint
    // (simpler than cascading adjustments across three independent times).
    for (final other in Meal.values) {
      if (other == meal) continue;
      final om = settings.meal(other);
      if (om.enabled && (minutes - om.timeMin).abs() < 120) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).notificationsMealsApart,
              ),
            ),
          );
        }
        return;
      }
    }
    await ref.read(notifSettingsProvider.notifier).setMealTime(meal, minutes);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final m = ref.watch(notifSettingsProvider).meal(meal);
    final notifier = ref.read(notifSettingsProvider.notifier);

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            value: m.enabled,
            onChanged: (v) => notifier.setMealEnabled(meal, v),
            secondary: Icon(_icon),
            title: Text(_label(l10n), style: theme.textTheme.titleMedium),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          if (m.enabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickTime(context, ref),
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(_formatMinutes(context, m.timeMin)),
                  ),
                  const Spacer(),
                  SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1')),
                      ButtonSegment(value: 2, label: Text('2')),
                      ButtonSegment(value: 3, label: Text('3')),
                    ],
                    selected: {m.count},
                    onSelectionChanged: (s) =>
                        notifier.setMealCount(meal, s.first),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
