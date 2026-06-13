/// Pure helpers for per-habit daily reminders. No drift or plugin imports, so
/// this stays cheap to unit-test.
library;

/// Base for the reserved habit-reminder notification id band. Habit reminders
/// use `_habitReminderIdBase + habitId`. Habit ids are small autoincrement
/// ints, so this band (800M+) sits clear of every other band in use:
/// spread quotes < ~1.6M, meal quotes 100M–101.6M, trial 900000001.
const int _habitReminderIdBase = 800000000;

/// Stable notification id for a habit's daily reminder.
int habitReminderNotificationId(int habitId) => _habitReminderIdBase + habitId;

/// Whether [id] belongs to the reserved habit-reminder band.
bool isHabitReminderNotificationId(int id) =>
    id >= _habitReminderIdBase && id < _habitReminderIdBase + 100000000;

/// When a habit reminder should next fire: today at [reminderMinutes] minutes
/// past local midnight if that moment is still in the future, otherwise the
/// same time tomorrow. Used as the anchor for a daily-repeating schedule.
DateTime nextHabitFireTime(int reminderMinutes, DateTime now) {
  final todayMidnight = DateTime(now.year, now.month, now.day);
  final todayFire = todayMidnight.add(Duration(minutes: reminderMinutes));
  if (todayFire.isAfter(now)) return todayFire;
  return todayFire.add(const Duration(days: 1));
}
