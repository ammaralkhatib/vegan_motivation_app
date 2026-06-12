import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../quotes/quote_card.dart';
import '../first_spark.dart';
import '../onboarding_widgets.dart';

/// S18 — the user's first personalized quote, the core feature shown live.
/// The quote is drawn from the category their motivation maps to. It may be a
/// premium category (a taste); it unlocks nothing.
class FirstSparkStep extends ConsumerWidget {
  const FirstSparkStep({
    super.key,
    required this.name,
    required this.motivationPick,
    required this.onContinue,
  });

  final String name;
  final String? motivationPick;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category = sparkCategoryFor(motivationPick);
    final quoteId = ref.watch(firstSparkQuoteIdProvider(category)).valueOrNull;
    final headline =
        name.isEmpty ? 'here\'s your first spark' : 'here\'s your first spark, $name';

    return InputStep(
      onContinue: onContinue,
      child: ListView(
        children: [
          const SizedBox(height: 8),
          _eyebrow(theme, 'built from your answers'),
          Text(headline, style: theme.textTheme.displaySmall),
          const SizedBox(height: 20),
          SizedBox(
            height: 380,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: quoteId == null
                  ? Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'your sparks are getting ready…',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : QuoteCard(quoteId: quoteId, onShare: null),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'your quotes are saved for you — to keep your why strong.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _eyebrow(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: theme.textTheme.labelLarge
              ?.copyWith(color: theme.colorScheme.primary),
        ),
      );
}
