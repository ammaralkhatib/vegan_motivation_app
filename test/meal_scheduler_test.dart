import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/notifications/notification_scheduler.dart';

List<SchedulableQuote> plainQuotes(int n) => [
      for (var i = 1; i <= n; i++) SchedulableQuote(id: i, body: 'Quote $i'),
    ];

int minutesOf(DateTime dt) => dt.hour * 60 + dt.minute;

/// Plans for the first (today) day only, in slot order.
List<SlotPlan> firstDay(List<SlotPlan> plans, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return plans
      .where((p) =>
          p.fireAt.year == today.year &&
          p.fireAt.month == today.month &&
          p.fireAt.day == today.day)
      .toList();
}

void main() {
  // Midnight, so no meal slot is ever in the past on day 0.
  final now = DateTime(2026, 6, 12, 0, 0);

  group('planMealSlots — slot pattern', () {
    test('count 1 places one slot at T-20 (±7)', () {
      final plans = planMealSlots(
        meals: const [MealConfig(index: 1, timeMin: 13 * 60, count: 1)],
        now: now,
        quotes: plainQuotes(10),
      );
      final day0 = firstDay(plans, now);
      expect(day0.length, 1);
      expect((minutesOf(day0[0].fireAt) - (13 * 60 - 20)).abs(),
          lessThanOrEqualTo(7));
    });

    test('count 2 places T-60 and T-15 (±7)', () {
      final plans = planMealSlots(
        meals: const [MealConfig(index: 1, timeMin: 13 * 60, count: 2)],
        now: now,
        quotes: plainQuotes(10),
      );
      final day0 = firstDay(plans, now);
      expect(day0.length, 2);
      expect((minutesOf(day0[0].fireAt) - (13 * 60 - 60)).abs(),
          lessThanOrEqualTo(7));
      expect((minutesOf(day0[1].fireAt) - (13 * 60 - 15)).abs(),
          lessThanOrEqualTo(7));
    });

    test('count 3 adds the only after-meal slot at T+30 (±7)', () {
      final plans = planMealSlots(
        meals: const [MealConfig(index: 2, timeMin: 19 * 60, count: 3)],
        now: now,
        quotes: plainQuotes(10),
      );
      final day0 = firstDay(plans, now);
      expect(day0.length, 3);
      final bases = [19 * 60 - 60, 19 * 60 - 15, 19 * 60 + 30];
      for (var i = 0; i < 3; i++) {
        expect((minutesOf(day0[i].fireAt) - bases[i]).abs(),
            lessThanOrEqualTo(7));
      }
    });
  });

  test('jitter is deterministic across calls', () {
    List<SlotPlan> run() => planMealSlots(
          meals: const [
            MealConfig(index: 0, timeMin: 8 * 60, count: 3),
            MealConfig(index: 2, timeMin: 19 * 60, count: 2),
          ],
          now: now,
          quotes: plainQuotes(20),
        );
    final a = run();
    final b = run();
    expect(a.length, b.length);
    for (var i = 0; i < a.length; i++) {
      expect(a[i].fireAt, b[i].fireAt);
      expect(a[i].notificationId, b[i].notificationId);
      expect(a[i].quoteId, b[i].quoteId);
    }
  });

  test('skips meal slots already past on the first day', () {
    // Breakfast slots land ~07:00 / 07:45; "now" at noon makes them past.
    final noon = DateTime(2026, 6, 12, 12, 0);
    final plans = planMealSlots(
      meals: const [MealConfig(index: 0, timeMin: 8 * 60, count: 2)],
      now: noon,
      quotes: plainQuotes(10),
    );
    expect(firstDay(plans, noon), isEmpty);
    expect(plans.every((p) => p.fireAt.isAfter(noon)), isTrue);
  });

  group('budget', () {
    test('max load (3 meals × 3) stays under 60 pending', () {
      final plans = planMealSlots(
        meals: const [
          MealConfig(index: 0, timeMin: 8 * 60, count: 3),
          MealConfig(index: 1, timeMin: 13 * 60, count: 3),
          MealConfig(index: 2, timeMin: 19 * 60, count: 3),
        ],
        now: now,
        quotes: plainQuotes(30),
      );
      // totalPerDay 9 → daysAhead clamp(60~/9,3,14)=6 → 6×9 = 54.
      expect(plans.length, 54);
      expect(plans.length, lessThanOrEqualTo(60));
    });

    test('single light meal keeps ~14 days of runway', () {
      final plans = planMealSlots(
        meals: const [MealConfig(index: 0, timeMin: 8 * 60, count: 1)],
        now: now,
        quotes: plainQuotes(10),
      );
      expect(plans.length, 14); // daysAhead clamp(60,3,14)=14, 1/day
    });
  });

  group('ids', () {
    test('meal ids are unique and never collide with spread ids', () {
      final mealPlans = planMealSlots(
        meals: const [
          MealConfig(index: 0, timeMin: 8 * 60, count: 3),
          MealConfig(index: 1, timeMin: 13 * 60, count: 3),
          MealConfig(index: 2, timeMin: 19 * 60, count: 3),
        ],
        now: now,
        quotes: plainQuotes(30),
      );
      final ids = mealPlans.map((p) => p.notificationId).toSet();
      expect(ids.length, mealPlans.length);
      // Spread ids are < ~1.6M; meal ids live in a 100M+ band.
      expect(mealPlans.every((p) => p.notificationId >= 100000000), isTrue);

      final spreadPlans = planSlots(
        perDay: 10,
        windowStartMin: 9 * 60,
        windowEndMin: 21 * 60,
        now: now,
        quotes: plainQuotes(30),
      );
      final spreadIds = spreadPlans.map((p) => p.notificationId).toSet();
      expect(ids.intersection(spreadIds), isEmpty);
    });

    test("changing one meal's count does not shift another meal's ids", () {
      List<int> breakfastIds(int dinnerCount) => planMealSlots(
            meals: [
              const MealConfig(index: 0, timeMin: 8 * 60, count: 2),
              MealConfig(index: 2, timeMin: 19 * 60, count: dinnerCount),
            ],
            now: now,
            quotes: plainQuotes(20),
          )
              // breakfast = index 0 → slotIndex 0,1 → low ids
              .where((p) => p.notificationId % 16 < 3)
              .map((p) => p.notificationId)
              .toList();
      // The scheduling horizon (daysAhead) legitimately changes with the total
      // budget, but the per-day breakfast ids must be identical over the days
      // both schedules cover.
      final a = breakfastIds(1);
      final b = breakfastIds(3);
      final k = a.length < b.length ? a.length : b.length;
      expect(a.take(k), b.take(k));
    });
  });

  group('meal-aware quote choice', () {
    final mixed = [
      SchedulableQuote(id: 1, body: 'a', categoryId: 'facts'),
      SchedulableQuote(id: 2, body: 'b', categoryId: 'staying_strong'),
      SchedulableQuote(id: 3, body: 'c', categoryId: 'youre_awesome'),
      SchedulableQuote(id: 4, body: 'd', categoryId: 'why_vegan'),
      SchedulableQuote(id: 5, body: 'e', categoryId: 'milestones'),
    ];

    test('before slots prefer encouragement, the after slot prefers praise',
        () {
      final plans = planMealSlots(
        meals: const [MealConfig(index: 1, timeMin: 13 * 60, count: 3)],
        now: now,
        quotes: mixed,
      );
      final day0 = firstDay(plans, now);
      final byId = {for (final q in mixed) q.id: q.categoryId};

      // Slots 0 and 1 are before-meal → staying_strong / why_vegan.
      expect(beforeMealCategoryIds.contains(byId[day0[0].quoteId]), isTrue);
      expect(beforeMealCategoryIds.contains(byId[day0[1].quoteId]), isTrue);
      // Slot 2 is the after-meal slot → youre_awesome.
      expect(afterMealCategoryIds.contains(byId[day0[2].quoteId]), isTrue);
    });

    test('falls back to the normal mix when preferred categories are absent',
        () {
      final noPreferred = [
        SchedulableQuote(id: 10, body: 'a', categoryId: 'facts'),
        SchedulableQuote(id: 11, body: 'b', categoryId: 'milestones'),
        SchedulableQuote(id: 12, body: 'c', categoryId: 'quick_tips'),
      ];
      final plans = planMealSlots(
        meals: const [MealConfig(index: 1, timeMin: 13 * 60, count: 2)],
        now: now,
        quotes: noPreferred,
      );
      final day0 = firstDay(plans, now);
      expect(day0.length, 2);
      // Still scheduled, just from the regular mix.
      final ids = {10, 11, 12};
      expect(ids.contains(day0[0].quoteId), isTrue);
      expect(ids.contains(day0[1].quoteId), isTrue);
    });
  });
}
