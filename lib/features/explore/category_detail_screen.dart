import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/locale/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../quotes/category_display.dart';
import '../quotes/providers.dart';

final _categoryQuotesProvider =
    StreamProvider.family<List<Quote>, String>((ref, categoryId) {
  final locale = ref.watch(localeCodeProvider);
  return ref
      .watch(databaseProvider)
      .quoteDao
      .watchQuotesByCategory(categoryId, locale: locale);
});

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final category = ref.watch(categoryByIdProvider(categoryId));
    final quotes = ref.watch(_categoryQuotesProvider(categoryId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          category == null
              ? ''
              : '${category.emoji}  '
                  '${categoryDisplayName(l, category.id, category.name)}',
        ),
      ),
      body: quotes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.exploreQuotesError(e.toString()))),
        data: (list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => QuoteListTile(quote: list[index]),
        ),
      ),
    );
  }
}

/// Shared list tile for category detail + favorites lists.
class QuoteListTile extends ConsumerWidget {
  const QuoteListTile({super.key, required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                quote.body,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(toggleFavoriteProvider)(quote);
              },
              isSelected: quote.isFavorite,
              selectedIcon:
                  Icon(Icons.favorite, color: theme.colorScheme.tertiary),
              icon: const Icon(Icons.favorite_outline),
              tooltip: quote.isFavorite ? l.quotesUnfavorite : l.quotesFavorite,
            ),
          ],
        ),
      ),
    );
  }
}
