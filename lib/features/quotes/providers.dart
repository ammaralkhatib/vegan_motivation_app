import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/locale/locale_provider.dart';
import '../../core/purchases/premium_gate.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/seeded_shuffle.dart';

/// Ordered quote ids for today's feed.
///
/// Reacts to category-mix changes (categories stream) but deliberately does
/// NOT react to quote-row changes — incrementing shownCount while the user
/// swipes must not reshuffle the queue under their thumb.
final feedQueueProvider = StreamProvider<List<int>>((ref) {
  final db = ref.watch(databaseProvider);
  // Reactive to premium: when the unlocked set changes, the feed rebuilds.
  final unlocked = ref.watch(unlockedCategoryIdsProvider);
  return db.quoteDao.watchCategories().asyncMap((categories) async {
    final quotes =
        await db.quoteDao.getQuotesInMix(unlockedCategoryIds: unlocked);
    final day = todayEpochDay();
    final shuffled = seededShuffle(quotes, day);
    // Light anti-repeat: quotes seen often sink. List.sort isn't stable, so
    // tie-break on the shuffled index to keep the daily order deterministic.
    final indexed = shuffled.asMap().entries.toList();
    indexed.sort((a, b) {
      final bucketA = a.value.shownCount > 3 ? 3 : a.value.shownCount;
      final bucketB = b.value.shownCount > 3 ? 3 : b.value.shownCount;
      final byBucket = bucketA.compareTo(bucketB);
      return byBucket != 0 ? byBucket : a.key.compareTo(b.key);
    });
    return [for (final e in indexed) e.value.id];
  });
});

/// Live row for one quote (heart state stays in sync everywhere), with text
/// resolved to the active locale.
final quoteByIdProvider = StreamProvider.family<Quote?, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  final locale = ref.watch(localeCodeProvider);
  return db.quoteDao.watchQuoteById(id, locale: locale);
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(databaseProvider).quoteDao.watchCategories();
});

/// Category lookup by id, derived from the categories stream.
final categoryByIdProvider = Provider.family<Category?, String>((ref, id) {
  final categories = ref.watch(categoriesProvider).valueOrNull;
  if (categories == null) return null;
  for (final c in categories) {
    if (c.id == id) return c;
  }
  return null;
});

final toggleFavoriteProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return (Quote quote) => db.quoteDao.setFavorite(quote.id, !quote.isFavorite);
});
