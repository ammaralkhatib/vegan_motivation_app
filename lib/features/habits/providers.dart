import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/utils/date_utils.dart';

final activeHabitsProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(databaseProvider).habitDao.watchActiveHabits();
});

/// Completions for the trailing 7 days (today inclusive), as
/// habitId → set of epoch-days.
final weekCompletionsProvider =
    StreamProvider<Map<int, Set<int>>>((ref) {
  final db = ref.watch(databaseProvider);
  final today = todayEpochDay();
  return db.habitDao.watchCompletionsInRange(today - 6, today).map((rows) {
    final map = <int, Set<int>>{};
    for (final row in rows) {
      map.putIfAbsent(row.habitId, () => <int>{}).add(row.day);
    }
    return map;
  });
});

/// All completion days for one habit, ascending (streak math input).
final completionDaysProvider =
    StreamProvider.family<List<int>, int>((ref, habitId) {
  return ref.watch(databaseProvider).habitDao.watchCompletionDays(habitId);
});

/// Heatmap input for the current month: epoch-day → number of habits
/// completed that day.
final monthCompletionsProvider = StreamProvider<Map<int, int>>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final first = epochDay(DateTime(now.year, now.month, 1));
  final last = epochDay(DateTime(now.year, now.month + 1, 0));
  return db.habitDao.watchCompletionsInRange(first, last).map((rows) {
    final map = <int, int>{};
    for (final row in rows) {
      map[row.day] = (map[row.day] ?? 0) + 1;
    }
    return map;
  });
});
