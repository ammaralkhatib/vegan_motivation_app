import 'package:drift/drift.dart';

import '../database.dart';

part 'quote_dao.g.dart';

@DriftAccessor(tables: [Quotes, Categories, QuoteTranslations])
class QuoteDao extends DatabaseAccessor<AppDatabase> with _$QuoteDaoMixin {
  QuoteDao(super.db);

  // --- Locale-aware display resolution (the single translation seam) ---------
  //
  // Quote text shown anywhere resolves as: the translation for [locale]'s
  // language code if one exists, else the English `body`. This is done here at
  // the DAO so every read path (feed, lists, favorites, widget, notifications)
  // gets the same resolved text — no per-widget string juggling. Favorites,
  // shownCount, ids and category logic all keep operating on the quote row;
  // translation affects display text only.

  /// The translation LEFT JOIN for [locale], or an empty list for English /
  /// no locale — keeping the English query path identical to before (we never
  /// store an 'en' translation, so English always reads `quotes.body`).
  List<Join> _translationJoin(String? locale) {
    if (locale == null || locale == 'en') return const [];
    return [
      leftOuterJoin(
        quoteTranslations,
        quoteTranslations.quoteId.equalsExp(quotes.id) &
            quoteTranslations.locale.equals(locale),
      ),
    ];
  }

  /// Reads a joined row's quote, swapping in the locale translation `body` when
  /// one was joined and present.
  Quote _resolve(TypedResult row, {required bool joined}) {
    final quote = row.readTable(quotes);
    if (!joined) return quote;
    final translated = row.readTableOrNull(quoteTranslations)?.body;
    return translated == null ? quote : quote.copyWith(body: translated);
  }

  Stream<List<Category>> watchCategories() {
    return (select(categories)
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  Stream<List<Quote>> watchQuotesInMix({String? locale}) {
    final joins = _translationJoin(locale);
    final query = select(quotes).join([
      innerJoin(categories, categories.id.equalsExp(quotes.categoryId)),
      ...joins,
    ])
      ..where(categories.inMix.equals(true));
    return query.map((r) => _resolve(r, joined: joins.isNotEmpty)).watch();
  }

  Stream<List<Quote>> watchQuotesByCategory(String categoryId,
      {String? locale}) {
    final joins = _translationJoin(locale);
    final query = select(quotes).join(joins)
      ..where(quotes.categoryId.equals(categoryId));
    return query.map((r) => _resolve(r, joined: joins.isNotEmpty)).watch();
  }

  Stream<List<Quote>> watchFavorites({String? locale}) {
    final joins = _translationJoin(locale);
    final query = select(quotes).join(joins)
      ..where(quotes.isFavorite.equals(true))
      ..orderBy([OrderingTerm.desc(quotes.favoritedAt)]);
    return query.map((r) => _resolve(r, joined: joins.isNotEmpty)).watch();
  }

  Future<Quote?> getQuoteById(int id, {String? locale}) {
    final joins = _translationJoin(locale);
    final query = select(quotes).join(joins)..where(quotes.id.equals(id));
    return query
        .map((r) => _resolve(r, joined: joins.isNotEmpty))
        .getSingleOrNull();
  }

  /// Live row for one quote, with locale-resolved text.
  Stream<Quote?> watchQuoteById(int id, {String? locale}) {
    final joins = _translationJoin(locale);
    final query = select(quotes).join(joins)..where(quotes.id.equals(id));
    return query
        .map((r) => _resolve(r, joined: joins.isNotEmpty))
        .watchSingleOrNull();
  }

  /// Quotes in the active mix. When [unlockedCategoryIds] is given, only quotes
  /// from those categories are returned — the premium gate (CLAUDE.md §3). The
  /// stored `inMix` flag is never touched, so a free user who had a premium
  /// category switched on keeps it; it's just filtered out until they upgrade.
  Future<List<Quote>> getQuotesInMix(
      {Set<String>? unlockedCategoryIds, String? locale}) {
    final joins = _translationJoin(locale);
    final query = select(quotes).join([
      innerJoin(categories, categories.id.equalsExp(quotes.categoryId)),
      ...joins,
    ])
      ..where(categories.inMix.equals(true));
    if (unlockedCategoryIds != null) {
      query.where(categories.id.isIn(unlockedCategoryIds.toList()));
    }
    return query.map((r) => _resolve(r, joined: joins.isNotEmpty)).get();
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
