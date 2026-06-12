import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/utils/date_utils.dart';
import '../../l10n/app_localizations.dart';
import 'providers.dart';
import 'streak_engine.dart';
import 'week_strip.dart';

class HabitTile extends ConsumerWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.weekDays,
    this.onToggled,
  });

  final Habit habit;
  final Set<int> weekDays;

  /// Called with (nowCompleted, currentStreakAfterToggle).
  final void Function(bool nowCompleted, int streak)? onToggled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final today = todayEpochDay();
    final doneToday = weekDays.contains(today);
    final allDays =
        ref.watch(completionDaysProvider(habit.id)).valueOrNull ?? const [];
    final streak = currentStreak(allDays, today);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onLongPress: () => context.go('/habits/edit/${habit.id}'),
        onTap: () => _toggle(ref, today),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
          child: Row(
            children: [
              Text(habit.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.name, style: theme.textTheme.titleMedium),
                    if (streak > 1) ...[
                      const SizedBox(height: 2),
                      Text(
                        l.habitsStreak(streak),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 10),
                    WeekStrip(completedDays: weekDays, today: today),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CheckButton(
                done: doneToday,
                onPressed: () => _toggle(ref, today),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(WidgetRef ref, int today) async {
    HapticFeedback.mediumImpact();
    final dao = ref.read(databaseProvider).habitDao;
    final nowCompleted = await dao.toggleCompletion(habit.id, today);
    if (onToggled != null) {
      final days = await dao.getCompletionDays(habit.id);
      onToggled!(nowCompleted, currentStreak(days, today));
    }
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.done, required this.onPressed});

  final bool done;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: done ? l.habitsCompletedSemantics : l.habitsMarkCompleteSemantics,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? scheme.primary : Colors.transparent,
            border: Border.all(
              color: done ? scheme.primary : scheme.outline,
              width: 2,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: done
                ? Icon(Icons.check, key: const ValueKey('done'),
                    color: scheme.onPrimary)
                : const SizedBox(key: ValueKey('todo')),
          ),
        ),
      ),
    );
  }
}
