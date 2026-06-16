import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db/database.dart';
import '../../core/utils/date_utils.dart';
import '../../l10n/app_localizations.dart';
import 'habit_calendar.dart';
import 'providers.dart';
import 'streak_engine.dart';

/// One habit's detail screen: streak stats, a "mark today" toggle, and a
/// month-browsable calendar where today and past days can be backfilled. Edit
/// (name/emoji/reminder) reuses the existing [HabitEditScreen] via its route.
class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final int habitId;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  /// First-of-month for the calendar currently shown.
  late DateTime _visibleMonth;

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
          _calendarCard(theme, days, today),
        ],
      ),
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
