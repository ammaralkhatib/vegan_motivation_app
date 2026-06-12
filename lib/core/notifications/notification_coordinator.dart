import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/notification_prefs.dart';
import '../db/database.dart';
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

  Future<void> reschedule({bool force = false}) async {
    final service = NotificationService.instance;
    if (!service.isSupportedPlatform) return;

    final prefs = _ref.read(prefsProvider);
    final settings = _ref.read(notifSettingsProvider);
    final today = todayEpochDay();

    if (!settings.enabled) {
      await service.cancelAll();
      await prefs.setLastNotifScheduleDay(-1);
      return;
    }
    if (!force && prefs.lastNotifScheduleDay == today) return;

    final unlocked = _ref.read(unlockedCategoryIdsProvider);
    final quotes = await _ref
        .read(databaseProvider)
        .quoteDao
        .getQuotesInMix(unlockedCategoryIds: unlocked);
    final plans = planSlots(
      perDay: settings.perDay,
      windowStartMin: settings.windowStartMin,
      windowEndMin: settings.windowEndMin,
      now: DateTime.now(),
      quotes: [
        for (final q in quotes)
          SchedulableQuote(id: q.id, body: q.body, shownCount: q.shownCount),
      ],
    );
    await service.scheduleAll(plans);
    await prefs.setLastNotifScheduleDay(today);
  }
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
