import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_coordinator.dart'; // TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
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
          // TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
          const _DiagnosticsSection(),
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

// =============================================================================
// TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
// Throwaway "Diagnostics (temporary)" section: shows the real scheduling state
// and offers test buttons. NOT gated behind kDebugMode (must work in the
// TestFlight release build) but clearly labelled so it isn't a shipping
// feature. Delete this whole block + its <_DiagnosticsSection() usage above
// and the debug helpers in notification_service / notification_coordinator once
// the notification bug is found.
// =============================================================================

class _DiagnosticsSection extends ConsumerStatefulWidget {
  const _DiagnosticsSection();

  @override
  ConsumerState<_DiagnosticsSection> createState() =>
      _DiagnosticsSectionState();
}

class _DiagnosticsSectionState extends ConsumerState<_DiagnosticsSection> {
  bool _loading = true;
  NotifPlanDiagnostics? _plan;
  DebugPendingBreakdown? _pending;
  String _tzName = '';
  String _tzNow = '';
  String _perms = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final service = NotificationService.instance;
    try {
      final coordinator = ref.read(notificationCoordinatorProvider);
      final plan = await coordinator.debugComputePlan();
      final pending = await service.debugPendingBreakdown();
      final perms = await service.debugIosPermissions();
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _pending = pending;
        _tzName = service.debugTimezoneName;
        _tzNow = service.debugTzNow();
        _perms = perms;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  static String _hhmm(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _stamp(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.month)}-${p(d.day)} ${p(d.hour)}:${p(d.minute)}';
  }

  Future<void> _forceReschedule() async {
    await ref.read(notificationCoordinatorProvider).reschedule(force: true);
    await _load();
  }

  Future<void> _testOneShot() async {
    await NotificationService.instance.debugScheduleOneShot();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'TEST one-shot set for ~20s. Lock the phone / leave the app and wait.',
        ),
      ),
    );
  }

  Future<void> _testRepeating() async {
    await NotificationService.instance.debugScheduleRepeating();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'TEST repeating set for ~90s. Lock the phone / leave the app and wait.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(notifSettingsProvider);
    final mono = theme.textTheme.bodySmall
        ?.copyWith(fontFamily: 'monospace', height: 1.5);

    final lines = <String>[];
    lines.add('enabled: ${settings.enabled}');
    lines.add('mode: ${settings.mode.name}');
    if (settings.mode == NotifMode.spread) {
      lines.add('perDay: ${settings.perDay}');
      lines.add(
        'window: ${_hhmm(settings.windowStartMin)} – '
        '${_hhmm(settings.windowEndMin)}',
      );
    } else {
      for (final meal in Meal.values) {
        final m = settings.meal(meal);
        lines.add(
          '${meal.name}: on=${m.enabled} '
          'time=${_hhmm(m.timeMin)} count=${m.count}',
        );
      }
    }
    final plan = _plan;
    if (plan != null) {
      lines.add('locale: ${plan.locale}');
      lines.add(
        'unlocked (${plan.unlockedCategoryIds.length}): '
        '${plan.unlockedCategoryIds.join(", ")}',
      );
      lines.add('quotes in mix: ${plan.quotesInMix}');
      lines.add('plans now: ${plan.planCount}');
      if (plan.firstFireTimes.isEmpty) {
        lines.add('first fire times: (none)');
      } else {
        lines.add(
          'first fires: ${plan.firstFireTimes.map(_stamp).join(" · ")}',
        );
      }
    }
    lines.add('tz: $_tzName');
    lines.add('tz now: $_tzNow');
    lines.add('iOS perms: $_perms');
    if (_error != null) lines.add('ERROR: $_error');
    final pending = _pending;
    if (pending != null) {
      lines.add('pending total: ${pending.total}');
      lines.add(
        'pending: quote=${pending.quote} habit=${pending.habit} '
        'trial=${pending.trial} other=${pending.other}',
      );
      if (pending.first5.isEmpty) {
        lines.add('first 5: (none)');
      } else {
        for (final r in pending.first5) {
          lines.add('  #${r.id}  ${r.title}');
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Text(
            'Diagnostics (temporary)',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.error),
          ),
          Text(
            'Throwaway debug tools — removed once the notification bug is found.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _loading
                  ? Text('Loading…', style: mono)
                  : Text(lines.join('\n'), style: mono),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _forceReschedule,
                icon: const Icon(Icons.update, size: 18),
                label: const Text('Force reschedule now'),
              ),
              FilledButton.tonal(
                onPressed: _testOneShot,
                child: const Text('Test one-shot (+20s)'),
              ),
              FilledButton.tonal(
                onPressed: _testRepeating,
                child: const Text('Test repeating-time (+~90s)'),
              ),
            ],
          ),
        ],
      ),
    );
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
