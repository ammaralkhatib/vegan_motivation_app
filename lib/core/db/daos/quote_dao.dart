import 'package:drift/drift.dart';

import '../database.dart';

part 'quote_dao.g.dart';

@DriftAccessor(tables: [Quotes, Categories])
class QuoteDao extends DatabaseAccessor<AppDatabase> with _$QuoteDaoMixin {
  QuoteDao(super.db);

  Stream<List<Category>> watchCategories() {
    return (select(categories)
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  Stream<List<Quote>> watchQuotesInMix() {
    final query = select(quotes).join([
      innerJoin(categories, categories.id.equalsExp(quotes.categoryId)),
    ])
      ..where(categories.inMix.equals(true));
    return query.map((row) => row.readTable(quotes)).watch();
  }

  Stream<List<Quote>> watchQuotesByCategory(String categoryId) {
    return (select(quotes)..where((q) => q.categoryId.equals(categoryId)))
        .watch();
  }

  Stream<List<Quote>> watchFavorites() {
    return (select(quotes)
          ..where((q) => q.isFavorite.equals(true))
          ..orderBy([(q) => OrderingTerm.desc(q.favoritedAt)]))
        .watch();
  }

  Future<Quote?> getQuoteById(int id) {
    return (select(quotes)..where((q) => q.id.equals(id))).getSingleOrNull();
  }

  /// Quotes in the active mix. When [unlockedCategoryIds] is given, only quotes
  /// from those categories are returned — the premium gate (CLAUDE.md §3). The
  /// stored `inMix` flag is never touched, so a free user who had a premium
  /// category switched on keeps it; it's just filtered out until they upgrade.
  Future<List<Quote>> getQuotesInMix({Set<String>? unlockedCategoryIds}) {
    final query = select(quotes).join([
      innerJoin(categories, categories.id.equalsExp(quotes.categoryId)),
    ])
      ..where(categories.inMix.equals(true));
    if (unlockedCategoryIds != null) {
      query.where(categories.id.isIn(unlockedCategoryIds.toList()));
    }
    return query.map((row) => row.readTable(quotes)).get();
  }

  Future<void> setFavorite(int id, bool favorite) {
    return (update(quotes)..where((q) => q.id.equals(id))).write(
      QuotesCompanion(
        isFavorite: Value(favorite),
        favoritedAt: Value(favorite ? DateTime.now() : null),
      ),
    );
  }

  Future<void> incrementShownCount(int id) {
    return (update(quotes)..where((q) => q.id.equals(id))).write(
      QuotesCompanion.custom(shownCount: quotes.shownCount + const Constant(1)),
    );
  }

  /// Sets a category's mix membership. Refuses to remove the last category
  /// from the mix; returns whether the change was applied.
  Future<bool> setCategoryInMix(String id, bool include) async {
    if (!include) {
      final inMixCount = await (selectOnly(categories)
            ..addColumns([categories.id.count()])
            ..where(categories.inMix.equals(true)))
          .map((row) => row.read(categories.id.count())!)
          .getSingle();
      final current = await (select(categories)
            ..where((c) => c.id.equals(id)))
          .getSingle();
      if (current.inMix && inMixCount <= 1) return false;
    }
    await (update(categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(inMix: Value(include)));
    return true;
  }

  Stream<Map<String, int>> watchQuoteCountsByCategory() {
    final count = quotes.id.count();
    final query = selectOnly(quotes)
      ..addColumns([quotes.categoryId, count])
      ..groupBy([quotes.categoryId]);
    return query.watch().map((rows) => {
          for (final row in rows)
            row.read(quotes.categoryId)!: row.read(count)!,
        });
  }
}
