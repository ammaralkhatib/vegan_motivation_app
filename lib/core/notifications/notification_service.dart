import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';
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
        appName: 'Veggie',
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
        'Veggie 🌱',
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

  /// Cancels every pending notification except the reserved trial reminder.
  Future<void> _cancelDailyNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id != trialReminderNotificationId) {
        await _plugin.cancel(p.id);
      }
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
}
