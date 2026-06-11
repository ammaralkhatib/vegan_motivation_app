/// Epoch-day helpers: a date is stored as the number of calendar days since
/// 1970-01-01 *in local time*. Pure integer math — DST and timezone proof.
library;

/// Days since 1970-01-01 for the local calendar date of [dt].
int epochDay(DateTime dt) {
  final utcMidnight = DateTime.utc(dt.year, dt.month, dt.day);
  return utcMidnight.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
}

/// Today's epoch-day in local time.
int todayEpochDay({DateTime Function() now = DateTime.now}) => epochDay(now());

/// Local [DateTime] (midnight) for an epoch-day.
DateTime dateFromEpochDay(int day) {
  final utc = DateTime.fromMillisecondsSinceEpoch(
    day * Duration.millisecondsPerDay,
    isUtc: true,
  );
  return DateTime(utc.year, utc.month, utc.day);
}
