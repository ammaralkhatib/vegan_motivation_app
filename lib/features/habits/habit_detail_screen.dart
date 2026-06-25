import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db/database.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/utils/date_utils.dart';
import '../../l10n/app_localizations.dart';
import 'habit_calendar.dart';
import 'providers.dart';
import 'streak_engine.dart';

/// One habit's detail screen: streak stats, a "mark today" toggle, a daily
/// reminder control, and a month-browsable calendar where today and past days
/// can be backfilled. Edit (name/emoji) reuses [HabitEditScreen] via its route.
class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final int habitId;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  /// First-of-month for the calendar currently shown.
  late DateTime _visibleMonth;

  /// Reminder time used when the switch is turned on (9:00 AM).
  static const int _defaultReminderMinutes = 9 * 60;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _visibleMonth.year == now.year && _visibleMonth.month == now.month;
  }

  void _leave() =>
      context.canPop() ? context.pop() : context.go('/habits');

  @override
  Widget build(BuildContext context) {
    final habitAsync = ref.watch(habitProvider(widget.habitId));

    return habitAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Text(AppLocalizations.of(context).habitsError(e.toString())),
        ),
      ),
      data: (habit) {
        if (habit == null) {
          // Archived or deleted while open — leave the dead screen.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _leave();
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _content(context, habit);
      },
    );
  }

  Widget _content(BuildContext context, Habit habit) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final today = todayEpochDay();
    final days =
        ref.watch(completionDaysProvider(widget.habitId)).valueOrNull ??
            const <int>[];
    final doneToday = days.contains(today);

    return Scaffold(
      appBar: AppBar(
        title: Text('${habit.emoji}  ${habit.name}'),
        actions: [
          IconButton(
            onPressed: () => context.push('/habits/edit/${widget.habitId}'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: l.habitsDetailEditTooltip,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _statsCard(theme, l, days, today),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _toggleToday(today),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            icon: Icon(
              doneToday ? Icons.check_circle : Icons.radio_button_unchecked,
            ),
            label: Text(
              doneToday ? l.habitsDetailDoneToday : l.habitsDetailMarkToday,
            ),
          ),
          const SizedBox(height: 16),
          _reminderCard(theme, l, habit),
          const SizedBox(height: 16),
          _calendarCard(theme, days, today),
        ],
      ),
    );
  }

  /// "Daily reminder" card. Reads its state straight from [habit] (the screen
  /// watches the row), so it stays in sync with the DB instead of holding local
  /// state that could drift.
  Widget _reminderCard(ThemeData theme, AppLocalizations l, Habit habit) {
    final minutes = habit.reminderMinutes;
    final on = minutes != null;
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: Text(l.habitsReminderSectionTitle),
            subtitle: Text(l.habitsReminderSubtitle),
            value: on,
            onChanged: (value) =>
                value ? _enableReminder(habit) : _disableReminder(habit),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          if (on)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _pickReminderTime(habit, minutes),
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    '${l.habitsReminderSetTime} · '
                    '${TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context)}',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Turns the reminder on at the default time, asks for permission the first
  /// time (off → on), and schedules it. Best-effort: never throws to the UI.
  Future<void> _enableReminder(Habit habit) async {
    final dao = ref.read(databaseProvider).habitDao;
    final service = NotificationService.instance;
    await dao.setHabitReminder(habit.id, _defaultReminderMinutes);
    await service.requestPermission();
    await service.scheduleHabitReminder(
      habitId: habit.id,
      name: habit.name,
      emoji: habit.emoji,
      reminderMinutes: _defaultReminderMinutes,
    );
  }

  Future<void> _disableReminder(Habit habit) async {
    final dao = ref.read(databaseProvider).habitDao;
    await dao.setHabitReminder(habit.id, null);
    await NotificationService.instance.cancelHabitReminder(habit.id);
  }

  Future<void> _pickReminderTime(Habit habit, int current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    final dao = ref.read(databaseProvider).habitDao;
    await dao.setHabitReminder(habit.id, minutes);
    await NotificationService.instance.scheduleHabitReminder(
      habitId: habit.id,
      name: habit.name,
      emoji: habit.emoji,
      reminderMinutes: minutes,
    );
  }

  Widget _statsCard(
    ThemeData theme,
    AppLocalizations l,
    List<int> days,
    int today,
  ) {
    final current = currentStreak(days, today);
    final best = bestStreak(days);
    final total = days.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '$current',
              style: theme.textTheme.displayMedium
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
            Text(
              l.habitsDetailCurrentStreak,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat(theme, '$best', l.habitsDetailBestStreak),
                _stat(theme, '$total', l.habitsDetailTotalDays),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _calendarCard(ThemeData theme, List<int> days, int today) {
    final dao = ref.read(databaseProvider).habitDao;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month - 1,
                      1,
                    );
                  }),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(_visibleMonth),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  // Never browse into the future.
                  onPressed: _isCurrentMonth
                      ? null
                      : () => setState(() {
                            _visibleMonth = DateTime(
                              _visibleMonth.year,
                              _visibleMonth.month + 1,
                              1,
                            );
                          }),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            HabitCalendar(
              completedDays: days.toSet(),
              month: _visibleMonth,
              today: today,
              onToggleDay: (day) =>
                  dao.toggleCompletion(widget.habitId, day),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleToday(int today) async {
    HapticFeedback.mediumImpact();
    await ref
        .read(databaseProvider)
        .habitDao
        .toggleCompletion(widget.habitId, today);
  }
}
