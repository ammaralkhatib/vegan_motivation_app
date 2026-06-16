import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/utils/date_utils.dart';
import 'package:vegan_motivation_app/features/habits/habit_calendar.dart';
import 'package:vegan_motivation_app/l10n/app_localizations.dart';

void main() {
  group('isToggleable', () {
    test('past and today are toggleable, the future is not', () {
      const today = 20000;
      expect(isToggleable(today - 1, today), isTrue); // past
      expect(isToggleable(today, today), isTrue); // today
      expect(isToggleable(today + 1, today), isFalse); // future
    });
  });

  testWidgets('future days draw no number and are not tappable', (tester) async {
    final today = epochDay(DateTime(2026, 6, 16));
    final month = DateTime(2026, 6, 1);
    final toggled = <int>[];

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: HabitCalendar(
          completedDays: const {},
          month: month,
          today: today,
          onToggleDay: toggled.add,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // A future day (June 20) renders no number, so it can't be tapped.
    expect(find.text('20'), findsNothing);

    // A past day (June 10) is present and toggles with its epoch-day.
    expect(find.text('10'), findsOneWidget);
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(toggled, [epochDay(DateTime(2026, 6, 10))]);
  });
}
