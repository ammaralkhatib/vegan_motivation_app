import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_service.dart';
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
    final settings = ref.watch(notifSettingsProvider);
    final notifier = ref.read(notifSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Notifications')),
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
            title: const Text('Daily motivation'),
            subtitle: const Text(
              'Full quotes in every notification — they show on your watch too.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          if (settings.enabled) ...[
            const SizedBox(height: 16),
            SegmentedButton<NotifMode>(
              segments: const [
                ButtonSegment(
                  value: NotifMode.spread,
                  label: Text('Through the day'),
                  icon: Icon(Icons.schedule_outlined),
                ),
                ButtonSegment(
                  value: NotifMode.meals,
                  label: Text('Around meals'),
                  icon: Icon(Icons.restaurant_outlined),
                ),
              ],
              selected: {settings.mode},
              onSelectionChanged: (s) => notifier.setMode(s.first),
            ),
            const SizedBox(height: 20),
            if (settings.mode == NotifMode.spread)
              ..._spreadControls(context, ref, theme, settings, notifier)
            else
              ..._mealControls(theme, settings),
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
    return [
      Text('How many per day', style: theme.textTheme.titleMedium),
      Row(
        children: [
          Expanded(
            child: Slider(
              value: settings.perDay.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '${settings.perDay}×',
              onChanged: (v) => notifier.setPerDay(v.round()),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text('${settings.perDay}×',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text('Between', style: theme.textTheme.titleMedium),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('to'),
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
        'Quotes come from the categories in your mix. '
        'Times vary a little day to day, on purpose — surprise is part '
        'of the charm.',
        style: theme.textTheme.bodySmall,
      ),
    ];
  }

  List<Widget> _mealControls(ThemeData theme, NotifSettings settings) {
    return [
      for (final meal in Meal.values) ...[
        _MealCard(meal: meal),
        const SizedBox(height: 12),
      ],
      Text(
        settings.anyMealEnabled
            ? 'A gentle nudge before each meal, and a kind word after dinner. '
                'Times wiggle a few minutes day to day.'
            : 'Turn on at least one meal to get reminders.',
        style: theme.textTheme.bodySmall,
      ),
    ];
  }
}

class _MealCard extends ConsumerWidget {
  const _MealCard({required this.meal});

  final Meal meal;

  String get _label => switch (meal) {
        Meal.breakfast => 'Breakfast',
        Meal.lunch => 'Lunch',
        Meal.dinner => 'Dinner',
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
            const SnackBar(
              content: Text('Keep meals at least 2 hours apart 🌱'),
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
    final m = ref.watch(notifSettingsProvider).meal(meal);
    final notifier = ref.read(notifSettingsProvider.notifier);

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            value: m.enabled,
            onChanged: (v) => notifier.setMealEnabled(meal, v),
            secondary: Icon(_icon),
            title: Text(_label, style: theme.textTheme.titleMedium),
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
