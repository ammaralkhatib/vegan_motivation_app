import 'package:drift/drift.dart';

import '../database.dart';

part 'habit_dao.g.dart';

@DriftAccessor(tables: [Habits, HabitCompletions])
class HabitDao extends DatabaseAccessor<AppDatabase> with _$HabitDaoMixin {
  HabitDao(super.db);

  Stream<List<Habit>> watchActiveHabits() {
    return (select(habits)
          ..where((h) => h.archivedAt.isNull())
          ..orderBy([(h) => OrderingTerm.asc(h.sortOrder)]))
        .watch();
  }

  Future<List<Habit>> getActiveHabits() {
    return (select(habits)..where((h) => h.archivedAt.isNull())).get();
  }

  /// All completions for active habits within [fromDay, toDay] inclusive.
  Stream<List<HabitCompletion>> watchCompletionsInRange(
    int fromDay,
    int toDay,
  ) {
    return (select(habitCompletions)
          ..where((c) => c.day.isBetweenValues(fromDay, toDay)))
        .watch();
  }

  /// One-shot variant of [watchCompletionDays] (safe to await anywhere).
  Future<List<int>> getCompletionDays(int habitId) {
    final query = selectOnly(habitCompletions)
      ..addColumns([habitCompletions.day])
      ..where(habitCompletions.habitId.equals(habitId))
      ..orderBy([OrderingTerm.asc(habitCompletions.day)]);
    return query
        .get()
        .then((rows) => [for (final r in rows) r.read(habitCompletions.day)!]);
  }

  /// Every completion day for one habit (for streak math), ascending.
  Stream<List<int>> watchCompletionDays(int habitId) {
    final query = selectOnly(habitCompletions)
      ..addColumns([habitCompletions.day])
      ..where(habitCompletions.habitId.equals(habitId))
      ..orderBy([OrderingTerm.asc(habitCompletions.day)]);
    return query
        .watch()
        .map((rows) => [for (final r in rows) r.read(habitCompletions.day)!]);
  }

  Future<int> insertHabit({
    required String name,
    required String emoji,
    String? presetKey,
    int sortOrder = 0,
  }) {
    return into(habits).insert(
      HabitsCompanion.insert(
        name: name,
        emoji: emoji,
        presetKey: Value(presetKey),
        sortOrder: Value(sortOrder),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> renameHabit(int id, String name, String emoji) {
    return (update(habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(name: Value(name), emoji: Value(emoji)),
    );
  }

  /// Sets (or clears, with null) the habit's daily reminder time, in minutes
  /// from local midnight.
  Future<void> setHabitReminder(int id, int? minutes) {
    return (update(habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(reminderMinutes: Value(minutes)),
    );
  }

  Future<void> archiveHabit(int id) {
    return (update(habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(archivedAt: Value(DateTime.now())),
    );
  }

  /// Toggles a completion; returns true if the habit is now completed.
  Future<bool> toggleCompletion(int habitId, int day) async {
    final deleted = await (delete(habitCompletions)
          ..where((c) => c.habitId.equals(habitId) & c.day.equals(day)))
        .go();
    if (deleted > 0) return false;
    await into(habitCompletions).insert(
      HabitCompletionsCompanion.insert(
        habitId: habitId,
        day: day,
        completedAt: DateTime.now(),
      ),
    );
    return true;
  }
}
