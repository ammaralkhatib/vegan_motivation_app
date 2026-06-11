import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/prefs/prefs_repository.dart';

/// Notification configuration (reactive over prefs).
/// Phase 8 listens to this to (re)schedule actual notifications.
class NotifSettings {
  const NotifSettings({
    required this.enabled,
    required this.perDay,
    required this.windowStartMin,
    required this.windowEndMin,
  });

  final bool enabled;
  final int perDay;

  /// Minutes from midnight.
  final int windowStartMin;
  final int windowEndMin;
}

class NotifSettingsNotifier extends Notifier<NotifSettings> {
  @override
  NotifSettings build() {
    final prefs = ref.read(prefsProvider);
    return NotifSettings(
      enabled: prefs.notifEnabled,
      perDay: prefs.notifPerDay,
      windowStartMin: prefs.notifWindowStart,
      windowEndMin: prefs.notifWindowEnd,
    );
  }

  Future<void> setEnabled(bool value) async {
    await ref.read(prefsProvider).setNotifEnabled(value);
    ref.invalidateSelf();
  }

  Future<void> setPerDay(int value) async {
    await ref.read(prefsProvider).setNotifPerDay(value.clamp(1, 10));
    ref.invalidateSelf();
  }

  Future<void> setWindow(int startMin, int endMin) async {
    final prefs = ref.read(prefsProvider);
    await prefs.setNotifWindowStart(startMin);
    await prefs.setNotifWindowEnd(endMin);
    ref.invalidateSelf();
  }
}

final notifSettingsProvider =
    NotifierProvider<NotifSettingsNotifier, NotifSettings>(
        NotifSettingsNotifier.new);
