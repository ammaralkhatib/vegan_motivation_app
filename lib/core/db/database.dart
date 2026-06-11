import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'daos/habit_dao.dart';
import 'daos/quote_dao.dart';

part 'database.g.dart';

class Categories extends Table {
  /// Slug, e.g. 'why_vegan'.
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get emoji => text()();
  IntColumn get sortOrder => integer()();

  /// Whether this category feeds the daily mix (feed + notifications).
  BoolColumn get inMix => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Quotes extends Table {
  /// Stable id from the bundled content file.
  IntColumn get id => integer()();
  TextColumn get body => text()();
  TextColumn get author => text().nullable()();
  TextColumn get categoryId => text().references(Categories, #id)();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get favoritedAt => dateTime().nullable()();
  IntColumn get shownCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get emoji => text()();

  /// Non-null for built-in presets (so we never duplicate them).
  TextColumn get presetKey => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  /// Soft delete — preserves completion history.
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

class HabitCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// Epoch-day (local calendar days since 1970-01-01).
  IntColumn get day => integer()();
  DateTimeColumn get completedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, day},
      ];
}

@DriftDatabase(
  tables: [Categories, Quotes, Habits, HabitCompletions],
  daos: [QuoteDao, HabitDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'veggie'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);
