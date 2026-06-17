import 'package:flutter/foundation.dart'; // TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
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
    // TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
    // Wrap the whole body so a thrown error surfaces in the device log instead
    // of vanishing silently. Behavior is unchanged: we log and swallow.
    try {
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
      // Notifications have no BuildContext; resolve quote text against the
      // user's language override (or the device locale when unset) so
      // notification bodies match the feed.
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
      final limited = capped.length > maxQuotePending
          ? capped.sublist(0, maxQuotePending)
          : capped;
      await service.scheduleAll(limited, languageCode: locale);
      await prefs.setLastNotifScheduleDay(today);
    } catch (e, st) {
      // TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
      debugPrint('RESCHEDULE ERROR: $e\n$st');
    }
  }

  /// Rebuilds every active habit's daily reminder. Runs alongside the quote
  /// reschedule (app launch + resume). Cheap and idempotent.
  Future<void> rescheduleHabits() async {
    // TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
    try {
      final service = NotificationService.instance;
      if (!service.isSupportedPlatform) return;
      final habits =
          await _ref.read(databaseProvider).habitDao.getActiveHabits();
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
    } catch (e, st) {
      // TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
      debugPrint('RESCHEDULE HABITS ERROR: $e\n$st');
    }
  }

  // TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
  /// Computes exactly what [reschedule] would schedule right now, WITHOUT
  /// touching the plugin. Feeds the diagnostics card so we can see whether the
  /// data path produces an empty plan / zero quotes.
  Future<NotifPlanDiagnostics> debugComputePlan() async {
    final prefs = _ref.read(prefsProvider);
    final settings = _ref.read(notifSettingsProvider);
    final unlocked = _ref.read(unlockedCategoryIdsProvider);
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
    final now = DateTime.now();
    final plans = switch (settings.mode) {
      NotifMode.spread => planSlots(
          perDay: settings.perDay,
          windowStartMin: settings.windowStartMin,
          windowEndMin: settings.windowEndMin,
          now: now,
          quotes: schedulable,
        ),
      NotifMode.meals => planMealSlots(
          meals: _enabledMeals(settings),
          now: now,
          quotes: schedulable,
        ),
    };
    final sorted = [...plans]..sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return NotifPlanDiagnostics(
      locale: locale,
      unlockedCategoryIds: unlocked,
      quotesInMix: quotes.length,
      planCount: plans.length,
      firstFireTimes: [for (final p in sorted.take(3)) p.fireAt],
    );
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

/// TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
/// What the coordinator would schedule right now (no plugin calls).
class NotifPlanDiagnostics {
  const NotifPlanDiagnostics({
    required this.locale,
    required this.unlockedCategoryIds,
    required this.quotesInMix,
    required this.planCount,
    required this.firstFireTimes,
  });

  final String locale;
  final Set<String> unlockedCategoryIds;
  final int quotesInMix;
  final int planCount;
  final List<DateTime> firstFireTimes;
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
