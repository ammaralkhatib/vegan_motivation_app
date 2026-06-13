import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/notifications/trial_reminder.dart';

void main() {
  group('shouldScheduleTrialReminder', () {
    test('schedules for the trial product only', () {
      expect(shouldScheduleTrialReminder('vegankit_yearly_full'), isTrue);
    });

    test('does not schedule for the 50% / 80% discount products', () {
      expect(shouldScheduleTrialReminder('vegankit_yearly_50'), isFalse);
      expect(shouldScheduleTrialReminder('vegankit_yearly_80'), isFalse);
      expect(shouldScheduleTrialReminder('anything_else'), isFalse);
    });
  });

  test('reminder fires 6 days after purchase (a day before the trial ends)', () {
    final bought = DateTime(2026, 6, 12, 9, 0);
    expect(trialReminderFireTime(bought), DateTime(2026, 6, 18, 9, 0));
  });

  test('reserved id is clear of the daily/meal notification ranges', () {
    // Spread ids < ~1.6M, meal ids 100M–101.6M.
    expect(trialReminderNotificationId, greaterThan(101_600_000));
  });
}
