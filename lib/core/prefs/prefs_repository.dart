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
  static const _kNotifMode = 'notifMode';
  static const _kBreakfastEnabled = 'notifBreakfastEnabled';
  static const _kBreakfastTime = 'notifBreakfastTime';
  static const _kBreakfastCount = 'notifBreakfastCount';
  static const _kLunchEnabled = 'notifLunchEnabled';
  static const _kLunchTime = 'notifLunchTime';
  static const _kLunchCount = 'notifLunchCount';
  static const _kDinnerEnabled = 'notifDinnerEnabled';
  static const _kDinnerTime = 'notifDinnerTime';
  static const _kDinnerCount = 'notifDinnerCount';
  static const _kContentVersion = 'contentVersion';
  static const _kLastNotifScheduleDay = 'lastNotifScheduleDay';
  static const _kPremiumCached = 'premiumCached';
  static const _kDiscountOfferShown = 'discountOfferShown';
  static const _kPhotoBackgrounds = 'photoBackgrounds';
  // Onboarding story answers.
  static const _kAgeRange = 'ageRange';
  static const _kDietStatus = 'dietStatus';
  static const _kGoalsPick = 'goalsPick';
  static const _kMotivationDips = 'motivationDipsPerWeek';
  static const _kObstacles = 'obstacles';
  static const _kWhyRelationship = 'whyRelationship';
  static const _kReviewPromptShown = 'reviewPromptShown';

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

  // --- Onboarding story answers -------------------------------------------
  String? get ageRange => _prefs.getString(_kAgeRange);
  Future<void> setAgeRange(String? value) => value == null
      ? _prefs.remove(_kAgeRange)
      : _prefs.setString(_kAgeRange, value);

  String? get dietStatus => _prefs.getString(_kDietStatus);
  Future<void> setDietStatus(String? value) => value == null
      ? _prefs.remove(_kDietStatus)
      : _prefs.setString(_kDietStatus, value);

  List<String> get goalsPick => _prefs.getStringList(_kGoalsPick) ?? const [];
  Future<void> setGoalsPick(List<String> value) =>
      _prefs.setStringList(_kGoalsPick, value);

  /// Days/week the user's motivation dips. -1 means unanswered.
  int get motivationDipsPerWeek => _prefs.getInt(_kMotivationDips) ?? -1;
  Future<void> setMotivationDipsPerWeek(int value) =>
      _prefs.setInt(_kMotivationDips, value);

  List<String> get obstacles => _prefs.getStringList(_kObstacles) ?? const [];
  Future<void> setObstacles(List<String> value) =>
      _prefs.setStringList(_kObstacles, value);

  String? get whyRelationship => _prefs.getString(_kWhyRelationship);
  Future<void> setWhyRelationship(String? value) => value == null
      ? _prefs.remove(_kWhyRelationship)
      : _prefs.setString(_kWhyRelationship, value);

  /// Whether the OS review prompt has been requested (at the onboarding streak
  /// peak). Once true it never fires again.
  bool get reviewPromptShown => _prefs.getBool(_kReviewPromptShown) ?? false;
  Future<void> setReviewPromptShown(bool value) =>
      _prefs.setBool(_kReviewPromptShown, value);

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

  /// Notification scheduling mode: 'spread' (default) or 'meals'. Stored as a
  /// string so the core layer stays free of the feature enum. Legacy users have
  /// no value → 'spread', i.e. exactly their old window/perDay behavior.
  String get notifMode => _prefs.getString(_kNotifMode) ?? 'spread';
  Future<void> setNotifMode(String value) =>
      _prefs.setString(_kNotifMode, value);

  // Per-meal settings (minutes-from-midnight times). Defaults: 08:00 / 13:00 /
  // 19:00, all enabled, count 2.
  bool get breakfastEnabled => _prefs.getBool(_kBreakfastEnabled) ?? true;
  Future<void> setBreakfastEnabled(bool v) =>
      _prefs.setBool(_kBreakfastEnabled, v);
  int get breakfastTime => _prefs.getInt(_kBreakfastTime) ?? 8 * 60;
  Future<void> setBreakfastTime(int v) => _prefs.setInt(_kBreakfastTime, v);
  int get breakfastCount => _prefs.getInt(_kBreakfastCount) ?? 2;
  Future<void> setBreakfastCount(int v) => _prefs.setInt(_kBreakfastCount, v);

  bool get lunchEnabled => _prefs.getBool(_kLunchEnabled) ?? true;
  Future<void> setLunchEnabled(bool v) => _prefs.setBool(_kLunchEnabled, v);
  int get lunchTime => _prefs.getInt(_kLunchTime) ?? 13 * 60;
  Future<void> setLunchTime(int v) => _prefs.setInt(_kLunchTime, v);
  int get lunchCount => _prefs.getInt(_kLunchCount) ?? 2;
  Future<void> setLunchCount(int v) => _prefs.setInt(_kLunchCount, v);

  bool get dinnerEnabled => _prefs.getBool(_kDinnerEnabled) ?? true;
  Future<void> setDinnerEnabled(bool v) => _prefs.setBool(_kDinnerEnabled, v);
  int get dinnerTime => _prefs.getInt(_kDinnerTime) ?? 19 * 60;
  Future<void> setDinnerTime(int v) => _prefs.setInt(_kDinnerTime, v);
  int get dinnerCount => _prefs.getInt(_kDinnerCount) ?? 2;
  Future<void> setDinnerCount(int v) => _prefs.setInt(_kDinnerCount, v);

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

  /// Whether the one-time 80%-off "last chance" offer has ever been shown.
  /// Once true it stays true forever — the discount paywall never repeats.
  bool get discountOfferShown => _prefs.getBool(_kDiscountOfferShown) ?? false;
  Future<void> setDiscountOfferShown(bool value) =>
      _prefs.setBool(_kDiscountOfferShown, value);

  /// Premium photo backgrounds on feed cards. Default on; only consulted for
  /// premium users.
  bool get photoBackgrounds => _prefs.getBool(_kPhotoBackgrounds) ?? true;
  Future<void> setPhotoBackgrounds(bool value) =>
      _prefs.setBool(_kPhotoBackgrounds, value);

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
