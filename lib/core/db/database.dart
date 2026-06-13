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

  /// English quote text — the base/fallback. Translations live in
  /// [QuoteTranslations]; display resolution happens in the DAO.
  TextColumn get body => text()();
  TextColumn get author => text().nullable()();
  TextColumn get categoryId => text().references(Categories, #id)();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get favoritedAt => dateTime().nullable()();
  IntColumn get shownCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Per-language quote text. A quote with no row for a given locale falls back
/// to the English [Quotes.body]. Purely content — never holds user state, so
/// it is safe to upsert on every content import.
class QuoteTranslations extends Table {
  IntColumn get quoteId => integer().references(Quotes, #id)();

  /// Language code, e.g. 'de'. (Language only — no region in this phase.)
  TextColumn get locale => text()();
  TextColumn get body => text()();

  @override
  Set<Column> get primaryKey => {quoteId, locale};
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

  /// Optional daily reminder, in minutes from local midnight.
  /// `null` = no reminder (the default).
  IntColumn get reminderMinutes => integer().nullable()();
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
  tables: [Categories, Quotes, Habits, HabitCompletions, QuoteTranslations],
  daos: [QuoteDao, HabitDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'veggie'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // v1 → v2: add quote translations (content only, no user data).
          if (from < 2) {
            await m.createTable(quoteTranslations);
          }
          // v2 → v3: add the optional per-habit reminder column (additive,
          // never touches existing user data).
          if (from < 3) {
            await m.addColumn(habits, habits.reminderMinutes);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);
