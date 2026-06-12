import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backgrounds/background_providers.dart';
import '../../core/critters/animated_critter.dart';
import '../../core/db/database.dart';
import '../../core/purchases/purchase_providers.dart';
import '../../core/theme/app_theme.dart';
import 'providers.dart';

/// Scrim over a photo background: ~25% black at the top → ~55% at the bottom,
/// so quote text keeps contrast in either theme.
const _photoScrim = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x40000000), Color(0x8C000000)],
  ),
);

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

    // Photo backgrounds: premium + toggle on + the category actually has images.
    final isPremium = ref.watch(isPremiumProvider);
    final photoOn = ref.watch(photoBackgroundsProvider);
    final manifest = ref.watch(backgroundManifestValueProvider);
    final imagePath = (isPremium && photoOn)
        ? manifest.pathForQuote(quote.categoryId, quote.id)
        : null;

    final gradient = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [tint, theme.scaffoldBackgroundColor],
      ),
    );

    final content = SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: _CardContent(
          quote: quote,
          category: category,
          onPhoto: imagePath != null,
          onShare: onShare,
        ),
      ),
    );

    if (imagePath == null) {
      return DecoratedBox(decoration: gradient, child: content);
    }

    // Premium: full-bleed photo + scrim + the usual content (light-on-dark).
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imagePath,
          key: const Key('quoteCardPhoto'),
          fit: BoxFit.cover,
          // Any decode/load failure → fall back to the gradient. The scrim
          // still sits on top, so light text stays readable either way.
          errorBuilder: (_, _, _) => DecoratedBox(decoration: gradient),
        ),
        const DecoratedBox(decoration: _photoScrim),
        content,
      ],
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.quote,
    required this.category,
    required this.onPhoto,
    required this.onShare,
  });

  final Quote quote;
  final Category? category;
  final bool onPhoto;
  final void Function(Quote quote)? onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLong = quote.body.length > 120;
    // On a photo the scrim guarantees a dark backdrop → force light text.
    final bodyColor = onPhoto ? Colors.white : null;
    final authorColor = onPhoto ? Colors.white70 : null;

    return Column(
      children: [
        const Spacer(flex: 2),
        if (category != null)
          Chip(label: Text('${category!.emoji}  ${category!.name}')),
        const SizedBox(height: 28),
        Text(
          quote.body,
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(
            fontSize: isLong ? 24 : 30,
            color: bodyColor,
          ),
        ),
        if (quote.author != null) ...[
          const SizedBox(height: 16),
          Text(
            '— ${quote.author}',
            style: theme.textTheme.bodyMedium?.copyWith(color: authorColor),
          ),
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
            _FavoriteButton(quote: quote, onPhoto: onPhoto),
            const SizedBox(width: 24),
            IconButton.filledTonal(
              onPressed: onShare == null ? null : () => onShare!(quote),
              iconSize: 26,
              padding: const EdgeInsets.all(14),
              style: onPhoto ? _onPhotoButtonStyle : null,
              icon: const Icon(Icons.ios_share),
              tooltip: 'Share',
            ),
          ],
        ),
        const SizedBox(height: 36),
      ],
    );
  }
}

/// Translucent light button treatment for the favorite/share icons when they
/// sit over a photo.
final ButtonStyle _onPhotoButtonStyle = IconButton.styleFrom(
  backgroundColor: Colors.white.withValues(alpha: 0.18),
  foregroundColor: Colors.white,
);

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.quote, this.onPhoto = false});

  final Quote quote;
  final bool onPhoto;

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
      style: onPhoto ? _onPhotoButtonStyle : null,
      selectedIcon: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 200),
        child: Icon(
          Icons.favorite,
          color: onPhoto ? Colors.white : theme.colorScheme.tertiary,
        ),
      ),
      icon: const Icon(Icons.favorite_outline),
      tooltip: quote.isFavorite ? 'Unfavorite' : 'Favorite',
    );
  }
}
