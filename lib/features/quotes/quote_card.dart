import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/critters/animated_critter.dart';
import '../../core/db/database.dart';
import '../../core/theme/app_theme.dart';
import 'providers.dart';

/// One full-screen quote in the feed.
class QuoteCard extends ConsumerWidget {
  const QuoteCard({super.key, required this.quoteId, this.onShare});

  final int quoteId;
  final void Function(Quote quote)? onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quote = ref.watch(quoteByIdProvider(quoteId)).valueOrNull;
    if (quote == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final accents = theme.extension<VeggieAccents>()!;
    final category = ref.watch(categoryByIdProvider(quote.categoryId));
    final tint = accents.categoryTints[quote.categoryId] ??
        theme.scaffoldBackgroundColor;
    final isLong = quote.body.length > 120;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tint, theme.scaffoldBackgroundColor],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              if (category != null)
                Chip(label: Text('${category.emoji}  ${category.name}')),
              const SizedBox(height: 28),
              Text(
                quote.body,
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: isLong ? 24 : 30,
                ),
              ),
              if (quote.author != null) ...[
                const SizedBox(height: 16),
                Text('— ${quote.author}', style: theme.textTheme.bodyMedium),
              ],
              const Spacer(flex: 2),
              AnimatedCritter(
                critter: Critter.forCategory(quote.categoryId),
                size: 96,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FavoriteButton(quote: quote),
                  const SizedBox(width: 24),
                  IconButton.filledTonal(
                    onPressed:
                        onShare == null ? null : () => onShare!(quote),
                    iconSize: 26,
                    padding: const EdgeInsets.all(14),
                    icon: const Icon(Icons.ios_share),
                    tooltip: 'Share',
                  ),
                ],
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return IconButton.filledTonal(
      onPressed: () {
        HapticFeedback.lightImpact();
        ref.read(toggleFavoriteProvider)(quote);
      },
      iconSize: 26,
      padding: const EdgeInsets.all(14),
      isSelected: quote.isFavorite,
      selectedIcon: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 200),
        child: Icon(Icons.favorite, color: theme.colorScheme.tertiary),
      ),
      icon: const Icon(Icons.favorite_outline),
      tooltip: quote.isFavorite ? 'Unfavorite' : 'Favorite',
    );
  }
}
