import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/utils/date_utils.dart';
import 'package:vegan_motivation_app/features/habits/streak_engine.dart';

void main() {
  group('currentStreak', () {
    test('empty history is zero', () {
      expect(currentStreak([], 100), 0);
    });

    test('single completion today', () {
      expect(currentStreak([100], 100), 1);
    });

    test('today still pending does not break the streak', () {
      expect(currentStreak([97, 98, 99], 100), 3);
    });

    test('gap of more than one day resets to zero', () {
      expect(currentStreak([96, 97, 98], 100), 0);
    });

    test('counts back through consecutive days including today', () {
      expect(currentStreak([95, 98, 99, 100], 100), 3);
    });

    test('old completions do not extend the current run', () {
      expect(currentStreak([1, 2, 3, 99, 100], 100), 2);
    });
  });

  group('bestStreak', () {
    test('empty history is zero', () {
      expect(bestStreak([]), 0);
    });

    test('single day', () {
      expect(bestStreak([42]), 1);
    });

    test('finds the longest historical run', () {
      expect(bestStreak([1, 2, 3, 4, 10, 11, 20]), 4);
    });

    test('run at the end wins when longest', () {
      expect(bestStreak([1, 2, 10, 11, 12, 13]), 4);
    });

    test('tolerates duplicate days', () {
      expect(bestStreak([5, 5, 6, 7]), 3);
    });
  });

  group('completionDaysInMonth', () {
    test('filters to year/month and maps to day-of-month', () {
      final jan15 = epochDay(DateTime(2026, 1, 15));
      final jan31 = epochDay(DateTime(2026, 1, 31));
      final feb1 = epochDay(DateTime(2026, 2, 1));

      final result = completionDaysInMonth(
        [jan15, jan31, feb1],
        2026,
        1,
        toDate: dateFromEpochDay,
      );
      expect(result, {15, 31});
    });

    test('month boundaries respect local dates across year end', () {
      final dec31 = epochDay(DateTime(2025, 12, 31));
      final jan1 = epochDay(DateTime(2026, 1, 1));

      expect(
        completionDaysInMonth([dec31, jan1], 2025, 12,
            toDate: dateFromEpochDay),
        {31},
      );
      expect(
        completionDaysInMonth([dec31, jan1], 2026, 1,
            toDate: dateFromEpochDay),
        {1},
      );
    });
  });

  group('epoch-day helpers', () {
    test('round trips through leap day', () {
      final leap = DateTime(2024, 2, 29);
      expect(dateFromEpochDay(epochDay(leap)), DateTime(2024, 2, 29));
    });

    test('consecutive local dates are consecutive epoch days', () {
      final a = epochDay(DateTime(2026, 3, 28));
      final b = epochDay(DateTime(2026, 3, 29)); // DST shift in many zones
      final c = epochDay(DateTime(2026, 3, 30));
      expect(b - a, 1);
      expect(c - b, 1);
    });
  });
}
