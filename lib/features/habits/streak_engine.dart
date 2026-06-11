/// Pure streak math over sorted epoch-day lists.
library;

/// Current streak ending today (or yesterday — an unchecked today doesn't
/// break the streak, it's just still pending).
int currentStreak(List<int> sortedDays, int today) {
  if (sortedDays.isEmpty) return 0;
  final days = sortedDays.toSet();
  var anchor = today;
  if (!days.contains(anchor)) {
    anchor = today - 1;
    if (!days.contains(anchor)) return 0;
  }
  var streak = 0;
  while (days.contains(anchor - streak)) {
    streak++;
  }
  return streak;
}

/// Longest run of consecutive days anywhere in history.
int bestStreak(List<int> sortedDays) {
  if (sortedDays.isEmpty) return 0;
  var best = 1;
  var run = 1;
  for (var i = 1; i < sortedDays.length; i++) {
    final gap = sortedDays[i] - sortedDays[i - 1];
    if (gap == 0) continue; // defensive: duplicate days
    if (gap == 1) {
      run++;
      if (run > best) best = run;
    } else {
      run = 1;
    }
  }
  return best;
}

/// Completion days that fall inside the given month, as day-of-month numbers.
Set<int> completionDaysInMonth(
  List<int> sortedDays,
  int year,
  int month, {
  required DateTime Function(int epochDay) toDate,
}) {
  final result = <int>{};
  for (final day in sortedDays) {
    final date = toDate(day);
    if (date.year == year && date.month == month) {
      result.add(date.day);
    }
  }
  return result;
}
