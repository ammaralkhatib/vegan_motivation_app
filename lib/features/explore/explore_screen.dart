import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/purchases/premium_gate.dart';
import '../../l10n/app_localizations.dart';
import '../quotes/category_display.dart';
import '../quotes/providers.dart';

/// Browse categories, toggle which ones feed the daily mix, jump to
/// favorites.
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final categories = ref.watch(categoriesProvider);
    final counts = ref.watch(quoteCountsProvider).valueOrNull ?? const {};

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l.exploreTitle),
        actions: [
          IconButton(
            onPressed: () => context.go('/explore/favorites'),
            icon: const Icon(Icons.favorite_outline),
            tooltip: l.exploreFavoritesTooltip,
          ),
        ],
      ),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(l.exploreCategoriesError(e.toString()))),
        data: (list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: list.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  l.exploreMixHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }
            final category = list[index - 1];
            return _CategoryCard(
              category: category,
              quoteCount: counts[category.id] ?? 0,
            );
          },
        ),
      ),
    );
  }
}

final quoteCountsProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(databaseProvider).quoteDao.watchQuoteCountsByCategory();
});

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({required this.category, required this.quoteCount});

  final Category category;
  final int quoteCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final locked = !ref.watch(unlockedCategoryIdsProvider).contains(category.id);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        // Locked → show the premium prompt instead of opening the category.
        onTap: locked
            ? () => showPremiumPaywall(context)
            : () => context.go('/explore/category/${category.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          child: Row(
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryDisplayName(l, category.id, category.name),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.exploreQuoteCount(quoteCount),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (locked)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: theme.colorScheme.outline,
                  ),
                )
              else
                Switch(
                  value: category.inMix,
                  onChanged: (value) async {
                    final applied = await ref
                        .read(databaseProvider)
                        .quoteDao
                        .setCategoryInMix(category.id, value);
                    if (!applied && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l.exploreKeepOne),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
