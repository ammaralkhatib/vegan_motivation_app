import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';
import 'habit_reminder.dart';
import 'notification_scheduler.dart';
import 'trial_reminder.dart';

/// Notification text has no BuildContext, so we resolve [AppLocalizations] from
/// the given [languageCode] (the user's override, threaded in from the
/// coordinator) or the device locale when null, falling back to English for any
/// unsupported locale. Daily notifications are rescheduled whenever the language
/// changes and on every app launch, so the language flips promptly; the
/// one-shot trial reminder keeps the language it was scheduled in.
AppLocalizations _notificationL10n([String? languageCode]) {
  try {
    final locale = languageCode != null
        ? Locale(languageCode)
        : PlatformDispatcher.instance.locale;
    return lookupAppLocalizations(locale);
  } catch (_) {
    return lookupAppLocalizations(const Locale('en'));
  }
}

/// Thin wrapper around flutter_local_notifications.
/// Pure planning lives in notification_scheduler.dart; this class only talks
/// to the plugin (init, permissions, schedule, cancel).
class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Set by the app layer; receives the quote-id payload on tap.
  void Function(String payload)? onTap;

  static const _channelId = 'daily_motivation';

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows);

  Future<void> init() async {
    if (_initialized || !isSupportedPlatform) return;

    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fall back to the bundled default (UTC) — times will still fire,
      // just resolved against the device clock by the OS.
    }

    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      windows: WindowsInitializationSettings(
        appName: 'VeganKit',
        appUserModelId: 'io.develooper.vegankit',
        guid: 'a3a1cb53-7a51-4d70-9b35-2a72b1b0c8e1',
      ),
    );
    await _plugin.initialize(
      init,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) onTap?.call(payload);
      },
    );
    _initialized = true;
  }

  /// Payload of the notification that launched the app, if any.
  Future<String?> launchPayload() async {
    if (!_initialized) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details!.notificationResponse?.payload;
    }
    return null;
  }

  Future<bool> requestPermission() async {
    if (!_initialized) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission() ?? false;
      case TargetPlatform.iOS:
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        return await ios?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      case TargetPlatform.macOS:
        final macos = _plugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
        return await macos?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      default:
        return true; // Windows needs no runtime permission
    }
  }

  /// Replaces all pending *daily* notifications with the given plan. The
  /// reserved trial-end reminder is left intact (cancelAll would wipe it).
  Future<void> scheduleAll(List<SlotPlan> plans, {String? languageCode}) async {
    if (!_initialized) return;
    await _cancelDailyNotifications();

    final l = _notificationL10n(languageCode);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l.notificationChannelName,
        channelDescription: l.notificationChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );

    for (final plan in plans) {
      await _plugin.zonedSchedule(
        plan.notificationId,
        'VeganKit 🌱',
        // Full quote in the plain body — Apple Watch / Wear OS mirror it.
        plan.body,
        tz.TZDateTime.from(plan.fireAt, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '${plan.quoteId}',
      );
    }
  }

  Future<int> pendingCount() async {
    if (!_initialized) return 0;
    return (await _plugin.pendingNotificationRequests()).length;
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  /// Cancels every pending *quote* notification, leaving the reserved trial
  /// reminder and all per-habit reminders intact (a quote reschedule must never
  /// wipe them).
  Future<void> _cancelDailyNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id == trialReminderNotificationId ||
          isHabitReminderNotificationId(p.id)) {
        continue;
      }
      await _plugin.cancel(p.id);
    }
  }

  /// Schedules the one-shot trial-end reminder at [fireAt]. No-op when the
  /// plugin isn't ready; the OS silently drops it if permission is denied.
  Future<void> scheduleTrialEndReminder(DateTime fireAt) async {
    if (!_initialized || !isSupportedPlatform) return;
    final l = _notificationL10n();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l.notificationChannelName,
        channelDescription: l.notificationChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
    try {
      await _plugin.zonedSchedule(
        trialReminderNotificationId,
        l.notificationTrialTitle,
        l.notificationTrialBody,
        tz.TZDateTime.from(fireAt, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Best-effort — never let a reminder failure surface to the user.
    }
  }

  /// Schedules one daily-repeating reminder for a habit at [reminderMinutes]
  /// minutes past local midnight. Uses a single pending slot (the OS repeats it
  /// every day via [DateTimeComponents.time]). Best-effort: never throws to UI,
  /// no-op when the plugin isn't ready / unsupported platform.
  Future<void> scheduleHabitReminder({
    required int habitId,
    required String name,
    required String emoji,
    required int reminderMinutes,
  }) async {
    if (!_initialized || !isSupportedPlatform) return;
    final l = _notificationL10n();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l.notificationChannelName,
        channelDescription: l.notificationChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
    try {
      await _plugin.zonedSchedule(
        habitReminderNotificationId(habitId),
        '$emoji $name',
        l.notificationHabitBody,
        tz.TZDateTime.from(
          nextHabitFireTime(reminderMinutes, DateTime.now()),
          tz.local,
        ),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'habit:$habitId',
      );
    } catch (_) {
      // Best-effort — never let a reminder failure surface to the user.
    }
  }

  /// Cancels a habit's daily reminder (if any).
  Future<void> cancelHabitReminder(int habitId) async {
    if (!_initialized) return;
    await _plugin.cancel(habitReminderNotificationId(habitId));
  }

  /// Rebuilds every habit reminder: cancels each habit's slot first, then
  /// re-schedules the ones that have a reminder. Idempotent.
  Future<void> rescheduleAllHabitReminders(
    List<({int id, String name, String emoji, int reminderMinutes})> habits,
  ) async {
    if (!_initialized || !isSupportedPlatform) return;
    for (final h in habits) {
      await cancelHabitReminder(h.id);
    }
    for (final h in habits) {
      await scheduleHabitReminder(
        habitId: h.id,
        name: h.name,
        emoji: h.emoji,
        reminderMinutes: h.reminderMinutes,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
  // Throwaway helpers that expose the real runtime scheduling state to the
  // settings "Diagnostics (temporary)" section. None of these change scheduling
  // behavior. Delete this whole block (and its callers) once the bug is found.
  // ---------------------------------------------------------------------------

  /// TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
  /// The active timezone name (catches a wrong / UTC timezone).
  String get debugTimezoneName => tz.local.name;

  /// TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
  /// "Now" as the plugin sees it, in the active timezone.
  String debugTzNow() => tz.TZDateTime.now(tz.local).toString();

  /// TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
  /// iOS alert/badge/sound permission status, or a short note off iOS.
  Future<String> debugIosPermissions() async {
    if (!_initialized) return 'plugin not initialized';
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return 'n/a (not iOS)';
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final p = await ios?.checkPermissions();
    if (p == null) return 'unavailable';
    return 'alert=${p.isAlertEnabled} '
        'badge=${p.isBadgeEnabled} '
        'sound=${p.isSoundEnabled} '
        '(enabled=${p.isEnabled})';
  }

  /// TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
  /// Pending notifications, counted and split into quote / habit / trial /
  /// other using the same id bands the app schedules into.
  Future<DebugPendingBreakdown> debugPendingBreakdown() async {
    if (!_initialized) {
      return const DebugPendingBreakdown(
        total: 0, quote: 0, habit: 0, trial: 0, other: 0, first5: [],
      );
    }
    final pending = await _plugin.pendingNotificationRequests();
    // Meal-mode quote ids live in a high band starting here (see scheduler).
    const mealIdBase = 100000000;
    var quote = 0, habit = 0, trial = 0, other = 0;
    for (final p in pending) {
      if (p.id == trialReminderNotificationId) {
        trial++;
      } else if (isHabitReminderNotificationId(p.id)) {
        habit++;
      } else if (p.id < 1600000 ||
          (p.id >= mealIdBase && p.id < mealIdBase + 1600000)) {
        // Spread quotes sit below ~1.6M; meal quotes in the 100M band.
        quote++;
      } else {
        other++;
      }
    }
    return DebugPendingBreakdown(
      total: pending.length,
      quote: quote,
      habit: habit,
      trial: trial,
      other: other,
      first5: [
        for (final p in pending.take(5)) (id: p.id, title: p.title ?? ''),
      ],
    );
  }

  /// TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
  /// The exact NotificationDetails the app already uses, for the test buttons.
  NotificationDetails _debugDetails() {
    final l = _notificationL10n();
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l.notificationChannelName,
        channelDescription: l.notificationChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
  }

  /// TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
  /// Fires ONE notification ~[seconds]s out the way QUOTE notifications are
  /// scheduled: plain zonedSchedule, no matchDateTimeComponents.
  Future<void> debugScheduleOneShot({int seconds = 20}) async {
    if (!_initialized) return;
    await _plugin.zonedSchedule(
      2000000001,
      'TEST one-shot',
      'Scheduled the QUOTE way (no repeat match), +${seconds}s.',
      tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
      _debugDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
  /// Fires ONE notification ~[seconds]s out the way HABIT reminders are
  /// scheduled: matchDateTimeComponents: DateTimeComponents.time.
  Future<void> debugScheduleRepeating({int seconds = 90}) async {
    if (!_initialized) return;
    await _plugin.zonedSchedule(
      2000000002,
      'TEST repeating',
      'Scheduled the HABIT way (matchDateTimeComponents.time), +${seconds}s.',
      tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
      _debugDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

/// TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)
/// Counted pending-notification breakdown for the diagnostics card.
class DebugPendingBreakdown {
  const DebugPendingBreakdown({
    required this.total,
    required this.quote,
    required this.habit,
    required this.trial,
    required this.other,
    required this.first5,
  });

  final int total;
  final int quote;
  final int habit;
  final int trial;
  final int other;

  /// First few pending requests (id + title) for eyeballing.
  final List<({int id, String title})> first5;
}
