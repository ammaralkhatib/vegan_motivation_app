import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/db/database.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/core/utils/date_utils.dart';
import 'package:vegan_motivation_app/features/habits/habits_screen.dart';

import 'helpers.dart';

Widget app(AppDatabase db) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      theme: VeggieTheme.light(),
      home: const HabitsScreen(),
    ),
  );
}

void main() {
  testWidgets('empty state shows preset picker and adds selected habits',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(app(db));
    await tester.pumpAndSettle();

    expect(find.textContaining('Build your plant-powered'), findsOneWidget);

    // The button sits below the fold of the lazy ListView in the test
    // viewport — scroll it into existence first.
    await tester.scrollUntilVisible(
      find.textContaining('Start tracking'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.textContaining('Start tracking'));
    await tester.pumpAndSettle();

    final habits = await db.habitDao.getActiveHabits();
    expect(habits.length, 3); // the three suggested presets
    expect(find.textContaining('Ate fully plant-based'), findsOneWidget);

    await unmountAndFlush(tester);
  });

  testWidgets('tapping the check button records a completion for today',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final habitId = await db.habitDao.insertHabit(
      name: 'Took B12',
      emoji: '💊',
    );

    await tester.pumpWidget(app(db));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Mark complete'));
    await tester.pumpAndSettle();

    final days = await db.habitDao.getCompletionDays(habitId);
    expect(days, [todayEpochDay()]);

    // Toggle off again.
    await tester.tap(find.bySemanticsLabel('Completed today'));
    await tester.pumpAndSettle();
    expect(await db.habitDao.getCompletionDays(habitId), isEmpty);

    await unmountAndFlush(tester);
  });
}
