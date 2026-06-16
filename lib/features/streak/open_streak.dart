import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/prefs/prefs_repository.dart';
import '../../core/utils/date_utils.dart';
import '../habits/streak_engine.dart';

/// How many trailing days of open history we keep. Anything older than
/// `today - _retentionDays` is pruned so the saved list never grows unbounded.
const int _retentionDays = 30;

/// Result of computing the app-open streak for the current launch.
class OpenStreakResult {
  const OpenStreakResult({
    required this.count,
    required this.openedDays,
    required this.today,
    required this.showBanner,
    required this.savedDays,
  });

  /// Consecutive-day streak ending today.
  final int count;

  /// All open-days we still track (for the WeekStrip dots).
  final Set<int> openedDays;

  /// Today's epoch-day.
  final int today;

  /// True only on the first launch of a new calendar day.
  final bool showBanner;

  /// The pruned, sorted day list to persist. Equal to the existing list when
  /// [showBanner] is false (today was already recorded).
  final List<int> savedDays;
}

/// Pure decision: given the existing open-day list and today, work out the new
/// list, the streak count, and whether the banner should show. Does **not**
/// touch prefs — the provider persists [OpenStreakResult.savedDays] after.
OpenStreakResult computeOpenStreak(List<int> existingDays, int today) {
  final alreadyOpenedToday = existingDays.contains(today);

  final List<int> savedDays;
  if (alreadyOpenedToday) {
    savedDays = List<int>.from(existingDays)..sort();
  } else {
    final cutoff = today - _retentionDays;
    savedDays = <int>[
      for (final d in existingDays)
        if (d >= cutoff) d,
      today,
    ]..sort();
  }

  return OpenStreakResult(
    count: currentStreak(savedDays, today),
    openedDays: savedDays.toSet(),
    today: today,
    showBanner: !alreadyOpenedToday,
    savedDays: savedDays,
  );
}

/// Computed once per app process (plain [Provider]), which is what gives the
/// banner its "once per calendar day" behaviour on a cold launch. Reading it
/// records today (if not already recorded) as a side effect.
final appOpenStreakProvider = Provider<OpenStreakResult>((ref) {
  final prefs = ref.read(prefsProvider);
  final today = todayEpochDay();
  final result = computeOpenStreak(prefs.openDays, today);
  if (result.showBanner) {
    prefs.setOpenDays(result.savedDays);
  }
  return result;
});
