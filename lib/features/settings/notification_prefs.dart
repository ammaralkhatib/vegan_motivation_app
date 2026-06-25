import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/prefs/prefs_repository.dart';

/// How notifications are scheduled.
enum NotifMode { spread, meals }

/// One meal's settings (breakfast / lunch / dinner).
class MealSetting {
  const MealSetting({
    required this.enabled,
    required this.timeMin,
    required this.count,
  });

  final bool enabled;

  /// Minutes from midnight.
  final int timeMin;

  /// Notifications around this meal, 1–3.
  final int count;

  MealSetting copyWith({bool? enabled, int? timeMin, int? count}) => MealSetting(
        enabled: enabled ?? this.enabled,
        timeMin: timeMin ?? this.timeMin,
        count: count ?? this.count,
      );
}

/// The three meals, in order. [index] drives stable notification ids.
enum Meal { breakfast, lunch, dinner }

/// Notification configuration (reactive over prefs).
/// Phase 8 listens to this to (re)schedule actual notifications.
class NotifSettings {
  const NotifSettings({
    required this.enabled,
    required this.perDay,
    required this.windowStartMin,
    required this.windowEndMin,
    required this.mode,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  final bool enabled;
  final int perDay;

  /// Minutes from midnight.
  final int windowStartMin;
  final int windowEndMin;

  final NotifMode mode;
  final MealSetting breakfast;
  final MealSetting lunch;
  final MealSetting dinner;

  MealSetting meal(Meal m) => switch (m) {
        Meal.breakfast => breakfast,
        Meal.lunch => lunch,
        Meal.dinner => dinner,
      };

  /// Whether at least one meal is enabled (meal mode schedules nothing if not).
  bool get anyMealEnabled =>
      breakfast.enabled || lunch.enabled || dinner.enabled;
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
      mode: prefs.notifMode == 'meals' ? NotifMode.meals : NotifMode.spread,
      breakfast: MealSetting(
        enabled: prefs.breakfastEnabled,
        timeMin: prefs.breakfastTime,
        count: prefs.breakfastCount,
      ),
      lunch: MealSetting(
        enabled: prefs.lunchEnabled,
        timeMin: prefs.lunchTime,
        count: prefs.lunchCount,
      ),
      dinner: MealSetting(
        enabled: prefs.dinnerEnabled,
        timeMin: prefs.dinnerTime,
        count: prefs.dinnerCount,
      ),
    );
  }

  Future<void> setEnabled(bool value) async {
    await ref.read(prefsProvider).setNotifEnabled(value);
    ref.invalidateSelf();
  }

  Future<void> setPerDay(int value) async {
    await ref.read(prefsProvider).setNotifPerDay(value.clamp(1, 12));
    ref.invalidateSelf();
  }

  Future<void> setWindow(int startMin, int endMin) async {
    final prefs = ref.read(prefsProvider);
    await prefs.setNotifWindowStart(startMin);
    await prefs.setNotifWindowEnd(endMin);
    ref.invalidateSelf();
  }

  Future<void> setMode(NotifMode mode) async {
    await ref.read(prefsProvider).setNotifMode(mode.name);
    ref.invalidateSelf();
  }

  Future<void> setMealEnabled(Meal meal, bool value) async {
    final prefs = ref.read(prefsProvider);
    switch (meal) {
      case Meal.breakfast:
        await prefs.setBreakfastEnabled(value);
      case Meal.lunch:
        await prefs.setLunchEnabled(value);
      case Meal.dinner:
        await prefs.setDinnerEnabled(value);
    }
    ref.invalidateSelf();
  }

  Future<void> setMealTime(Meal meal, int timeMin) async {
    final prefs = ref.read(prefsProvider);
    switch (meal) {
      case Meal.breakfast:
        await prefs.setBreakfastTime(timeMin);
      case Meal.lunch:
        await prefs.setLunchTime(timeMin);
      case Meal.dinner:
        await prefs.setDinnerTime(timeMin);
    }
    ref.invalidateSelf();
  }

  Future<void> setMealCount(Meal meal, int count) async {
    final value = count.clamp(1, 3);
    final prefs = ref.read(prefsProvider);
    switch (meal) {
      case Meal.breakfast:
        await prefs.setBreakfastCount(value);
      case Meal.lunch:
        await prefs.setLunchCount(value);
      case Meal.dinner:
        await prefs.setDinnerCount(value);
    }
    ref.invalidateSelf();
  }
}

final notifSettingsProvider =
    NotifierProvider<NotifSettingsNotifier, NotifSettings>(
        NotifSettingsNotifier.new);
