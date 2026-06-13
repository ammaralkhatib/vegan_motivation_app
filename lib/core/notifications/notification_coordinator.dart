import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/notification_prefs.dart';
import '../db/database.dart';
import '../locale/locale_provider.dart';
import '../prefs/prefs_repository.dart';
import '../purchases/premium_gate.dart';
import '../utils/date_utils.dart';
import 'notification_scheduler.dart';
import 'notification_service.dart';

/// Connects prefs + content to the notification plugin.
///
/// Reschedules:
///  - on app resume, at most once per day (debounced via lastNotifScheduleDay)
///  - immediately (force) when notification settings change
class NotificationCoordinator {
  NotificationCoordinator(this._ref);

  final Ref _ref;

  /// iOS caps pending local notifications at 64. We truncate the quote schedule
  /// to this many so trial (1) + per-habit reminders (the rest) still fit.
  static const int maxQuotePending = 50;

  Future<void> reschedule({bool force = false}) async {
    final service = NotificationService.instance;
    if (!service.isSupportedPlatform) return;

    final prefs = _ref.read(prefsProvider);
    final settings = _ref.read(notifSettingsProvider);
    final today = todayEpochDay();

    // Meal mode with every meal switched off schedules nothing — same end
    // state as the master switch being off.
    final mealsOffEntirely =
        settings.mode == NotifMode.meals && !settings.anyMealEnabled;
    if (!settings.enabled || mealsOffEntirely) {
      await service.cancelAll();
      await prefs.setLastNotifScheduleDay(-1);
      return;
    }
    if (!force && prefs.lastNotifScheduleDay == today) return;

    final unlocked = _ref.read(unlockedCategoryIdsProvider);
    // Notifications have no BuildContext; resolve quote text against the user's
    // language override (or the device locale when unset) so notification
    // bodies match the feed.
    final locale = resolveLanguageCode(prefs.languageOverride);
    final quotes = await _ref
        .read(databaseProvider)
        .quoteDao
        .getQuotesInMix(unlockedCategoryIds: unlocked, locale: locale);
    final schedulable = [
      for (final q in quotes)
        SchedulableQuote(
          id: q.id,
          body: q.body,
          shownCount: q.shownCount,
          categoryId: q.categoryId,
        ),
    ];

    final plans = switch (settings.mode) {
      NotifMode.spread => planSlots(
          perDay: settings.perDay,
          windowStartMin: settings.windowStartMin,
          windowEndMin: settings.windowEndMin,
          now: DateTime.now(),
          quotes: schedulable,
        ),
      NotifMode.meals => planMealSlots(
          meals: _enabledMeals(settings),
          now: DateTime.now(),
          quotes: schedulable,
        ),
    };
    // Keep quotes + trial + habit reminders under the iOS 64 pending cap by
    // sending the soonest [maxQuotePending] quote slots only.
    final capped = [...plans]..sort((a, b) => a.fireAt.compareTo(b.fireAt));
    final limited =
        capped.length > maxQuotePending ? capped.sublist(0, maxQuotePending) : capped;
    await service.scheduleAll(limited, languageCode: locale);
    await prefs.setLastNotifScheduleDay(today);
  }

  /// Rebuilds every active habit's daily reminder. Runs alongside the quote
  /// reschedule (app launch + resume). Cheap and idempotent.
  Future<void> rescheduleHabits() async {
    final service = NotificationService.instance;
    if (!service.isSupportedPlatform) return;
    final habits = await _ref.read(databaseProvider).habitDao.getActiveHabits();
    final reminders = [
      for (final h in habits)
        if (h.reminderMinutes != null)
          (
            id: h.id,
            name: h.name,
            emoji: h.emoji,
            reminderMinutes: h.reminderMinutes!,
          ),
    ];
    await service.rescheduleAllHabitReminders(reminders);
  }

  List<MealConfig> _enabledMeals(NotifSettings s) => [
        for (final meal in Meal.values)
          if (s.meal(meal).enabled)
            MealConfig(
              index: meal.index,
              timeMin: s.meal(meal).timeMin,
              count: s.meal(meal).count,
            ),
      ];
}

final notificationCoordinatorProvider = Provider<NotificationCoordinator>(
  (ref) {
    final coordinator = NotificationCoordinator(ref);
    // Any settings change → immediate replan (also covers onboarding opt-in).
    ref.listen(notifSettingsProvider, (previous, next) {
      coordinator.reschedule(force: true);
    });
    return coordinator;
  },
);
