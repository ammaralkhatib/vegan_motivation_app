import 'dart:math';

import '../utils/date_utils.dart';
import '../utils/seeded_shuffle.dart';

/// Minimal quote view the scheduler needs (no drift imports — pure & testable).
class SchedulableQuote {
  const SchedulableQuote({
    required this.id,
    required this.body,
    this.shownCount = 0,
  });

  final int id;
  final String body;
  final int shownCount;
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
/// least 3 days of runway even at 10/day:
///   daysAhead = clamp(60 ~/ perDay, 3, 14)  →  perDay*daysAhead ≤ 60
/// (except perDay ≥ 10 where 3 days × 10 = 30, still well under).
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
  assert(perDay >= 1 && perDay <= 10);
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
