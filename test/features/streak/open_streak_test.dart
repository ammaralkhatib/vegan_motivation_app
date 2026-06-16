import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/features/streak/open_streak.dart';

void main() {
  group('computeOpenStreak', () {
    test('first ever open: count 1, banner shows, day added', () {
      final r = computeOpenStreak(const [], 100);
      expect(r.count, 1);
      expect(r.showBanner, isTrue);
      expect(r.savedDays, [100]);
      expect(r.openedDays, {100});
    });

    test('open again same day: no banner, count and list unchanged', () {
      final r = computeOpenStreak(const [98, 99, 100], 100);
      expect(r.showBanner, isFalse);
      expect(r.count, 3);
      expect(r.savedDays, [98, 99, 100]);
    });

    test('next day in a row: count increments, banner shows', () {
      final r = computeOpenStreak(const [98, 99, 100], 101);
      expect(r.showBanner, isTrue);
      expect(r.count, 4);
      expect(r.savedDays, [98, 99, 100, 101]);
    });

    test('open after a gap: streak resets to 1, banner shows', () {
      final r = computeOpenStreak(const [98, 99, 100], 105);
      expect(r.showBanner, isTrue);
      expect(r.count, 1);
      expect(r.savedDays, [98, 99, 100, 105]);
    });

    test('pruning: days older than today - 30 are dropped on record', () {
      // 60 is older than 100 - 30 = 70, so it must be pruned. 99 stays.
      final r = computeOpenStreak(const [60, 99], 100);
      expect(r.showBanner, isTrue);
      expect(r.savedDays, [99, 100]);
      expect(r.savedDays, isNot(contains(60)));
    });
  });
}
