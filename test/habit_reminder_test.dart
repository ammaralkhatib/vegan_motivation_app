import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/notifications/habit_reminder.dart';

void main() {
  group('nextHabitFireTime', () {
    test('fires today when the time is still ahead', () {
      // now 08:00, reminder 09:00 → today 09:00.
      final now = DateTime(2026, 6, 13, 8, 0);
      expect(
        nextHabitFireTime(9 * 60, now),
        DateTime(2026, 6, 13, 9, 0),
      );
    });

    test('rolls to tomorrow when the time has already passed', () {
      // now 10:00, reminder 09:00 → tomorrow 09:00.
      final now = DateTime(2026, 6, 13, 10, 0);
      expect(
        nextHabitFireTime(9 * 60, now),
        DateTime(2026, 6, 14, 9, 0),
      );
    });

    test('an exactly-now time rolls to tomorrow (not strictly future)', () {
      final now = DateTime(2026, 6, 13, 9, 0);
      expect(
        nextHabitFireTime(9 * 60, now),
        DateTime(2026, 6, 14, 9, 0),
      );
    });
  });

  group('habitReminderNotificationId', () {
    test('sits clear of the quote, meal, and trial id bands', () {
      // Spread quotes < ~1.6M, meal quotes 100M–101.6M, trial 900000001.
      for (final habitId in [1, 50, 9999]) {
        final id = habitReminderNotificationId(habitId);
        expect(id, greaterThan(101_600_000)); // above meal band
        expect(id, lessThan(900_000_001)); // below trial id
        expect(isHabitReminderNotificationId(id), isTrue);
      }
    });

    test('ids are distinct per habit', () {
      expect(
        habitReminderNotificationId(1),
        isNot(habitReminderNotificationId(2)),
      );
    });

    test('does not claim ids outside its band', () {
      expect(isHabitReminderNotificationId(0), isFalse);
      expect(isHabitReminderNotificationId(1_600_000), isFalse);
      expect(isHabitReminderNotificationId(900_000_001), isFalse);
    });
  });
}
