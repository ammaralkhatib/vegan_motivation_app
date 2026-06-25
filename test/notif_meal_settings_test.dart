import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegan_motivation_app/core/prefs/prefs_repository.dart';
import 'package:vegan_motivation_app/features/settings/notification_prefs.dart';

Future<ProviderContainer> containerWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = PrefsRepository(await SharedPreferences.getInstance());
  final container = ProviderContainer(
    overrides: [prefsProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults: spread mode and 08:00/13:00/19:00 meals, count 2', () async {
    final container = await containerWith({});
    final s = container.read(notifSettingsProvider);

    expect(s.mode, NotifMode.spread);
    // Spread defaults: 6/day across a 7:30 AM–9:30 PM window.
    expect(s.perDay, 6);
    expect(s.windowStartMin, 7 * 60 + 30);
    expect(s.windowEndMin, 21 * 60 + 30);
    expect(s.breakfast.enabled, isTrue);
    expect(s.breakfast.timeMin, 8 * 60);
    expect(s.lunch.timeMin, 13 * 60);
    expect(s.dinner.timeMin, 19 * 60);
    expect(s.breakfast.count, 2);
    expect(s.anyMealEnabled, isTrue);
  });

  test('legacy users (old keys only) resolve to spread mode', () async {
    final container = await containerWith({
      'notifEnabled': true,
      'notifPerDay': 5,
      'notifWindowStart': 9 * 60,
      'notifWindowEnd': 21 * 60,
    });
    final s = container.read(notifSettingsProvider);

    expect(s.mode, NotifMode.spread);
    expect(s.perDay, 5);
    // Meal settings fall back to defaults without touching anything.
    expect(s.breakfast.timeMin, 8 * 60);
  });

  test('round-trips new settings through prefs', () async {
    final container = await containerWith({});
    final notifier = container.read(notifSettingsProvider.notifier);

    await notifier.setMode(NotifMode.meals);
    await notifier.setMealCount(Meal.breakfast, 3);
    await notifier.setMealEnabled(Meal.lunch, false);
    await notifier.setMealTime(Meal.dinner, 20 * 60);

    final s = container.read(notifSettingsProvider);
    expect(s.mode, NotifMode.meals);
    expect(s.breakfast.count, 3);
    expect(s.lunch.enabled, isFalse);
    expect(s.dinner.timeMin, 20 * 60);
  });

  test('meal count is clamped to 1–3', () async {
    final container = await containerWith({});
    final notifier = container.read(notifSettingsProvider.notifier);

    await notifier.setMealCount(Meal.breakfast, 9);
    expect(container.read(notifSettingsProvider).breakfast.count, 3);

    await notifier.setMealCount(Meal.breakfast, 0);
    expect(container.read(notifSettingsProvider).breakfast.count, 1);
  });
}
