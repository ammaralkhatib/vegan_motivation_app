import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vegan_motivation_app/core/db/database.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/features/habits/habit_detail_screen.dart';
import 'package:vegan_motivation_app/features/habits/habit_edit_screen.dart';
import 'package:vegan_motivation_app/l10n/app_localizations.dart';

import 'helpers.dart';

/// Reads one habit row directly (post-action assertions).
Future<Habit> _readHabit(AppDatabase db, int id) =>
    (db.select(db.habits)..where((h) => h.id.equals(id))).getSingle();

Widget _editApp(AppDatabase db, GoRouter router) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp.router(
      theme: VeggieTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

Widget _detailApp(AppDatabase db, int habitId) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      theme: VeggieTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HabitDetailScreen(habitId: habitId),
    ),
  );
}

void main() {
  testWidgets('creating a new habit turns the daily reminder on by default',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: SizedBox())),
        GoRoute(
          path: '/edit',
          builder: (_, _) => const HabitEditScreen(habitId: 'new'),
        ),
      ],
    );

    await tester.pumpWidget(_editApp(db, router));
    router.push('/edit');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Drink water');
    await tester.tap(find.text('Add habit'));
    await tester.pumpAndSettle();

    final habits = await db.habitDao.getActiveHabits();
    expect(habits.length, 1);
    // Default-on at 9:00 AM (540 minutes from midnight).
    expect(habits.single.reminderMinutes, 9 * 60);

    await unmountAndFlush(tester);
  });

  testWidgets('detail screen reminder switch toggles the stored reminder',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    // Start with no reminder so the switch begins in the off position.
    final habitId = await db.habitDao.insertHabit(name: 'Walk', emoji: '🏃');

    await tester.pumpWidget(_detailApp(db, habitId));
    await tester.pumpAndSettle();

    expect(find.text('Daily reminder'), findsOneWidget);

    // Turn it on → reminder set to the 9:00 AM default and scheduled.
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect((await _readHabit(db, habitId)).reminderMinutes, 9 * 60);

    // Turn it off → reminder cleared.
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect((await _readHabit(db, habitId)).reminderMinutes, isNull);

    await unmountAndFlush(tester);
  });
}
