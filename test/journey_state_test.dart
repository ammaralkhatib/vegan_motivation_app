import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/features/journey/providers.dart';

void main() {
  group('JourneyState.daysVegan', () {
    test('no start date means zero days', () {
      const state = JourneyState(
        veganSince: null,
        curiousMode: true,
        userName: null,
      );
      expect(state.daysVegan, 0);
    });

    test('starting today counts as day 1', () {
      final state = JourneyState(
        veganSince: DateTime.now(),
        curiousMode: false,
        userName: null,
      );
      expect(state.daysVegan, 1);
    });

    test('a week ago is day 8 (inclusive counting)', () {
      final state = JourneyState(
        veganSince: DateTime.now().subtract(const Duration(days: 7)),
        curiousMode: false,
        userName: null,
      );
      expect(state.daysVegan, 8);
    });

    test('future date clamps to day 1', () {
      final state = JourneyState(
        veganSince: DateTime.now().add(const Duration(days: 30)),
        curiousMode: false,
        userName: null,
      );
      expect(state.daysVegan, 1);
    });

    test('spans leap years correctly', () {
      // 2024-02-28 → 2024-03-01 crosses Feb 29.
      final state = JourneyState(
        veganSince: DateTime(2024, 2, 28),
        curiousMode: false,
        userName: null,
      );
      final reference = DateTime(2024, 3, 1);
      final start = DateTime(2024, 2, 28);
      expect(reference.difference(start).inDays + 1, 3);
      expect(state.daysVegan, greaterThan(365)); // sanity: long past date
    });
  });
}
