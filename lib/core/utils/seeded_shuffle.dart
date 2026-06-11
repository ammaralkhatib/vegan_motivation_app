import 'dart:math';

/// Deterministic Fisher–Yates shuffle. The same [seed] always produces the
/// same order — used to keep the daily feed stable within a day.
List<T> seededShuffle<T>(Iterable<T> items, int seed) {
  final list = List<T>.of(items);
  final random = Random(seed);
  for (var i = list.length - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
  }
  return list;
}
