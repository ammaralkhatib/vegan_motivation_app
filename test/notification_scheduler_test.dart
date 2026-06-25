import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/notifications/notification_scheduler.dart';

List<SchedulableQuote> quotes(int n) => [
      for (var i = 1; i <= n; i++)
        SchedulableQuote(id: i, body: 'Quote $i'),
    ];

void main() {
  final now = DateTime(2026, 6, 11, 8, 0); // before the default window

  group('planSlots', () {
    test('stays within the iOS-64 cap for every perDay 1–12', () {
      for (var perDay = 1; perDay <= 12; perDay++) {
        final plans = planSlots(
          perDay: perDay,
          windowStartMin: 9 * 60,
          windowEndMin: 21 * 60,
          now: now,
          quotes: quotes(100),
        );
        expect(plans.length, lessThanOrEqualTo(64),
            reason: 'perDay=$perDay produced ${plans.length}');
        expect(plans.length, greaterThanOrEqualTo(3 * perDay - perDay),
            reason: 'at least ~3 days of runway for perDay=$perDay');
      }
    });

    test('perDay 12 stays at or under 64 pending', () {
      // daysAhead = clamp(60 ~/ 12, 3, 14) = 5, so 12 × 5 = 60 ≤ 64.
      final plans = planSlots(
        perDay: 12,
        windowStartMin: 9 * 60,
        windowEndMin: 21 * 60,
        now: now,
        quotes: quotes(100),
      );
      expect(plans.length, lessThanOrEqualTo(64));
      expect(plans.length, 60);
    });

    test('every fire time falls inside the configured window', () {
      final plans = planSlots(
        perDay: 5,
        windowStartMin: 9 * 60,
        windowEndMin: 21 * 60,
        now: now,
        quotes: quotes(50),
      );
      for (final plan in plans) {
        final minutes = plan.fireAt.hour * 60 + plan.fireAt.minute;
        expect(minutes, greaterThanOrEqualTo(9 * 60));
        expect(minutes, lessThanOrEqualTo(21 * 60));
      }
    });

    test('is deterministic for identical inputs', () {
      final a = planSlots(
        perDay: 4,
        windowStartMin: 8 * 60,
        windowEndMin: 22 * 60,
        now: now,
        quotes: quotes(40),
      );
      final b = planSlots(
        perDay: 4,
        windowStartMin: 8 * 60,
        windowEndMin: 22 * 60,
        now: now,
        quotes: quotes(40),
      );
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].fireAt, b[i].fireAt);
        expect(a[i].quoteId, b[i].quoteId);
        expect(a[i].notificationId, b[i].notificationId);
      }
    });

    test('never schedules in the past', () {
      final midday = DateTime(2026, 6, 11, 14, 30); // mid-window
      final plans = planSlots(
        perDay: 6,
        windowStartMin: 9 * 60,
        windowEndMin: 21 * 60,
        now: midday,
        quotes: quotes(30),
      );
      for (final plan in plans) {
        expect(plan.fireAt.isAfter(midday), isTrue);
      }
    });

    test('notification ids are unique', () {
      final plans = planSlots(
        perDay: 10,
        windowStartMin: 9 * 60,
        windowEndMin: 21 * 60,
        now: now,
        quotes: quotes(30),
      );
      final ids = plans.map((p) => p.notificationId).toSet();
      expect(ids.length, plans.length);
    });

    test('empty mix or empty window yields no slots', () {
      expect(
        planSlots(
          perDay: 3,
          windowStartMin: 540,
          windowEndMin: 1260,
          now: now,
          quotes: const [],
        ),
        isEmpty,
      );
      expect(
        planSlots(
          perDay: 3,
          windowStartMin: 1260,
          windowEndMin: 540,
          now: now,
          quotes: quotes(10),
        ),
        isEmpty,
      );
    });

    test('quote bodies ride along for watch mirroring', () {
      final plans = planSlots(
        perDay: 2,
        windowStartMin: 9 * 60,
        windowEndMin: 21 * 60,
        now: now,
        quotes: quotes(5),
      );
      for (final plan in plans) {
        expect(plan.body, startsWith('Quote '));
      }
    });
  });
}
