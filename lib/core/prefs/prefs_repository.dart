import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Typed wrapper over SharedPreferences for all scalar app settings.
/// The instance is loaded once in main() before runApp and provided
/// via [prefsProvider].
class PrefsRepository {
  PrefsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kOnboardingDone = 'onboardingDone';
  static const _kUserName = 'userName';
  static const _kMotivationPick = 'motivationPick';
  static const _kVeganSince = 'veganSince';
  static const _kCuriousMode = 'curiousMode';
  static const _kThemeMode = 'themeMode';
  static const _kNotifEnabled = 'notifEnabled';
  static const _kNotifPerDay = 'notifPerDay';
  static const _kNotifWindowStart = 'notifWindowStart';
  static const _kNotifWindowEnd = 'notifWindowEnd';
  static const _kContentVersion = 'contentVersion';
  static const _kLastNotifScheduleDay = 'lastNotifScheduleDay';
  static const _kPremiumCached = 'premiumCached';

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool value) =>
      _prefs.setBool(_kOnboardingDone, value);

  String? get userName => _prefs.getString(_kUserName);
  Future<void> setUserName(String? value) => value == null || value.isEmpty
      ? _prefs.remove(_kUserName)
      : _prefs.setString(_kUserName, value);

  String? get motivationPick => _prefs.getString(_kMotivationPick);
  Future<void> setMotivationPick(String value) =>
      _prefs.setString(_kMotivationPick, value);

  /// Date the user went vegan (date-only precision), null if unset.
  DateTime? get veganSince {
    final raw = _prefs.getString(_kVeganSince);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setVeganSince(DateTime? value) => value == null
      ? _prefs.remove(_kVeganSince)
      : _prefs.setString(
          _kVeganSince,
          value.toIso8601String().substring(0, 10),
        );

  bool get curiousMode => _prefs.getBool(_kCuriousMode) ?? false;
  Future<void> setCuriousMode(bool value) =>
      _prefs.setBool(_kCuriousMode, value);

  ThemeMode get themeMode => switch (_prefs.getString(_kThemeMode)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> setThemeMode(ThemeMode value) =>
      _prefs.setString(_kThemeMode, value.name);

  bool get notifEnabled => _prefs.getBool(_kNotifEnabled) ?? false;
  Future<void> setNotifEnabled(bool value) =>
      _prefs.setBool(_kNotifEnabled, value);

  int get notifPerDay => _prefs.getInt(_kNotifPerDay) ?? 3;
  Future<void> setNotifPerDay(int value) =>
      _prefs.setInt(_kNotifPerDay, value);

  /// Notification window, minutes from midnight. Default 9:00–21:00.
  int get notifWindowStart => _prefs.getInt(_kNotifWindowStart) ?? 9 * 60;
  Future<void> setNotifWindowStart(int value) =>
      _prefs.setInt(_kNotifWindowStart, value);

  int get notifWindowEnd => _prefs.getInt(_kNotifWindowEnd) ?? 21 * 60;
  Future<void> setNotifWindowEnd(int value) =>
      _prefs.setInt(_kNotifWindowEnd, value);

  int get contentVersion => _prefs.getInt(_kContentVersion) ?? 0;
  Future<void> setContentVersion(int value) =>
      _prefs.setInt(_kContentVersion, value);

  int get lastNotifScheduleDay => _prefs.getInt(_kLastNotifScheduleDay) ?? -1;
  Future<void> setLastNotifScheduleDay(int value) =>
      _prefs.setInt(_kLastNotifScheduleDay, value);

  /// Last-known premium status, cached on-device so the app knows the answer
  /// instantly and offline, before RevenueCat is reached. Defaults to false
  /// (free) on a fresh install.
  bool get premiumCached => _prefs.getBool(_kPremiumCached) ?? false;
  Future<void> setPremiumCached(bool value) =>
      _prefs.setBool(_kPremiumCached, value);

  /// Wipes everything (used by "reset all data").
  Future<void> clear() => _prefs.clear();
}

/// Overridden in main() with the loaded instance.
final prefsProvider = Provider<PrefsRepository>(
  (ref) => throw UnimplementedError('prefsProvider must be overridden'),
);

/// App-wide theme mode, persisted.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(prefsProvider).themeMode;

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(prefsProvider).setThemeMode(mode);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
