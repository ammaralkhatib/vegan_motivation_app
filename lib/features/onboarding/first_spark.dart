import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';

/// Maps the user's chosen motivation to the content category their first
/// onboarding quote ("spark") is drawn from.
String sparkCategoryFor(String? motivationPick) => switch (motivationPick) {
      'animals' => 'why_vegan',
      'planet' => 'facts',
      'health' => 'quick_tips',
      _ => 'why_vegan', // curious / unset
    };

/// The id of the first quote (lowest id, deterministic) in [categoryId], or
/// null if the category has none. Reads the local DB via the existing DAO.
final firstSparkQuoteIdProvider =
    FutureProvider.family<int?, String>((ref, categoryId) async {
  final db = ref.watch(databaseProvider);
  final quotes = await db.quoteDao.watchQuotesByCategory(categoryId).first;
  if (quotes.isEmpty) return null;
  final sorted = [...quotes]..sort((a, b) => a.id.compareTo(b.id));
  return sorted.first.id;
});
