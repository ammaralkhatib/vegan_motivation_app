import 'dart:math';

import '../utils/date_utils.dart';
import '../utils/seeded_shuffle.dart';

/// Minimal quote view the scheduler needs (no drift imports — pure & testable).
class SchedulableQuote {
  const SchedulableQuote({
    required this.id,
    required this.body,
    this.shownCount = 0,
    this.categoryId = '',
  });

  final int id;
  final String body;
  final int shownCount;

  /// Content category id (e.g. `why_vegan`). Used by meal mode to prefer
  /// moment-fitting quotes; ignored by spread mode.
  final String categoryId;
}

/// Before a meal we want encouragement; after a meal we want praise.
/// Real content ids (assets/content/quotes_v1.json).
const Set<String> beforeMealCategoryIds = {'staying_strong', 'why_vegan'};
const Set<String> afterMealCategoryIds = {'youre_awesome'};

/// One enabled meal for [planMealSlots]. [index] (0 breakfast, 1 lunch,
/// 2 dinner) drives the stable notification id, so changing one meal's count
/// never shifts another meal's ids.
class MealConfig {
  const MealConfig({
    required this.index,
    required this.timeMin,
    required this.count,
  });

  final int index;
  final int timeMin;
  final int count;
}

class SlotPlan {
  const SlotPlan({
    required this.notificationId,
    required this.fireAt,
    required this.quoteId,
    required this.body,
  });

  /// Stable 32-bit id: (epochDay % 100000) * 16 + slotIndex.
  final int notificationId;
  final DateTime fireAt;
  final int quoteId;
  final String body;
}

/// Plans the rolling batch of notification slots.
///
/// iOS caps pending local notifications at 64 — we budget ≤ 60 and keep at
/// least 3 days of runway even at 12/day:
///   daysAhead = clamp(60 ~/ perDay, 3, 14)  →  perDay*daysAhead ≤ 60
/// (except perDay ≥ 12 where 5 days × 12 = 60, still within the 64 cap).
///
/// Fire times: the daily window is split into [perDay] equal segments, each
/// slot fires at a deterministic jittered point inside its segment
/// (seeded by epochDay*31+slot), so refreshing the schedule never moves
/// already-planned times.
List<SlotPlan> planSlots({
  required int perDay,
  required int windowStartMin,
  required int windowEndMin,
  required DateTime now,
  required List<SchedulableQuote> quotes,
}) {
  assert(perDay >= 1 && perDay <= 12);
  if (quotes.isEmpty) return const [];
  final windowLen = windowEndMin - windowStartMin;
  if (windowLen <= 0) return const [];

  final daysAhead = (60 ~/ perDay).clamp(3, 14);
  final today = epochDay(now);
  final plans = <SlotPlan>[];

  for (var offset = 0; offset < daysAhead; offset++) {
    final day = today + offset;
    final date = dateFromEpochDay(day);

    // Day-seeded quote order, gently weighted away from often-seen quotes.
    final shuffled = seededShuffle(quotes, day);
    final indexed = shuffled.asMap().entries.toList();
    indexed.sort((a, b) {
      final bucketA = a.value.shownCount > 3 ? 3 : a.value.shownCount;
      final bucketB = b.value.shownCount > 3 ? 3 : b.value.shownCount;
      final byBucket = bucketA.compareTo(bucketB);
      return byBucket != 0 ? byBucket : a.key.compareTo(b.key);
    });
    final dayQuotes = [for (final e in indexed) e.value];

    final segment = windowLen / perDay;
    for (var slot = 0; slot < perDay; slot++) {
      // Deterministic jitter in the middle 80% of the segment.
      final jitter = Random(day * 31 + slot).nextDouble();
      final fireMin =
          windowStartMin + segment * slot + segment * (0.1 + 0.8 * jitter);
      final fireAt = DateTime(
        date.year,
        date.month,
        date.day,
      ).add(Duration(minutes: fireMin.round()));

      if (!fireAt.isAfter(now)) continue; // skip already-passed slots today

      final quote = dayQuotes[slot % dayQuotes.length];
      plans.add(SlotPlan(
        notificationId: (day % 100000) * 16 + slot,
        fireAt: fireAt,
        quoteId: quote.id,
        body: quote.body,
      ));
    }
  }
  return plans;
}

/// Meal-mode ids live in a high, separate band so they can never collide with
/// spread-mode ids (which are < ~1.6M). `100M + (day%100000)*16 + slotIndex`,
/// slotIndex = mealIndex*3 + j (0–8).
const int _mealIdBase = 100000000;

/// Offsets (minutes from meal time) and whether each is an after-meal slot:
///   count 1 → [T−20]
///   count 2 → [T−60, T−15]
///   count 3 → [T−60, T−15, T+30]   (the +30 is the only "after" slot)
List<({int offset, bool after})> _mealOffsets(int count) => switch (count) {
      <= 1 => const [(offset: -20, after: false)],
      2 => const [(offset: -60, after: false), (offset: -15, after: false)],
      _ => const [
          (offset: -60, after: false),
          (offset: -15, after: false),
          (offset: 30, after: true),
        ],
    };

/// Plans notification slots anchored to meals. Pure & deterministic, mirroring
/// [planSlots]: same day-seeded quote ordering, same iOS-64 budgeting, same
/// "skip already-passed slots" rule. Each slot gets ±7 min deterministic jitter
/// seeded by `day*31 + slotIndex` so a reschedule never moves planned times.
///
/// Quote choice prefers [beforeMealCategoryIds] before a meal and
/// [afterMealCategoryIds] after — but only when the mix actually contains an
/// unused quote there; otherwise it falls back to the normal day ordering.
List<SlotPlan> planMealSlots({
  required List<MealConfig> meals,
  required DateTime now,
  required List<SchedulableQuote> quotes,
}) {
  if (quotes.isEmpty || meals.isEmpty) return const [];
  final totalPerDay = meals.fold<int>(0, (sum, m) => sum + m.count);
  if (totalPerDay <= 0) return const [];

  final daysAhead = (60 ~/ totalPerDay).clamp(3, 14);
  final today = epochDay(now);
  final plans = <SlotPlan>[];

  for (var offset = 0; offset < daysAhead; offset++) {
    final day = today + offset;
    final date = dateFromEpochDay(day);
    final dayQuotes = _orderedForDay(quotes, day);

    final used = <int>{};
    var fallback = 0;

    for (final meal in meals) {
      final offsets = _mealOffsets(meal.count);
      for (var j = 0; j < offsets.length; j++) {
        final spec = offsets[j];
        final slotIndex = meal.index * 3 + j;
        // ±7 min deterministic jitter, same seeding style as spread mode.
        final jitter = (Random(day * 31 + slotIndex).nextDouble() * 14 - 7)
            .round();
        final fireMin = meal.timeMin + spec.offset + jitter;
        final fireAt = DateTime(date.year, date.month, date.day)
            .add(Duration(minutes: fireMin));

        if (!fireAt.isAfter(now)) continue; // skip already-passed slots

        final preferred =
            spec.after ? afterMealCategoryIds : beforeMealCategoryIds;
        final quote = _pickQuote(dayQuotes, preferred, used, fallback++);

        plans.add(SlotPlan(
          notificationId: _mealIdBase + (day % 100000) * 16 + slotIndex,
          fireAt: fireAt,
          quoteId: quote.id,
          body: quote.body,
        ));
      }
    }
  }
  return plans;
}

/// Day-seeded quote order, gently weighted away from often-seen quotes —
/// identical ordering to [planSlots].
List<SchedulableQuote> _orderedForDay(List<SchedulableQuote> quotes, int day) {
  final shuffled = seededShuffle(quotes, day);
  final indexed = shuffled.asMap().entries.toList();
  indexed.sort((a, b) {
    final bucketA = a.value.shownCount > 3 ? 3 : a.value.shownCount;
    final bucketB = b.value.shownCount > 3 ? 3 : b.value.shownCount;
    final byBucket = bucketA.compareTo(bucketB);
    return byBucket != 0 ? byBucket : a.key.compareTo(b.key);
  });
  return [for (final e in indexed) e.value];
}

/// Picks a moment-fitting quote: first unused one in a [preferred] category,
/// else the next unused quote, else a deterministic cyclic fallback.
SchedulableQuote _pickQuote(
  List<SchedulableQuote> dayQuotes,
  Set<String> preferred,
  Set<int> used,
  int fallbackIndex,
) {
  for (final q in dayQuotes) {
    if (preferred.contains(q.categoryId) && !used.contains(q.id)) {
      used.add(q.id);
      return q;
    }
  }
  for (final q in dayQuotes) {
    if (!used.contains(q.id)) {
      used.add(q.id);
      return q;
    }
  }
  return dayQuotes[fallbackIndex % dayQuotes.length];
}
