import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import 'quote_card.dart';

/// Full-screen single quote — the landing target when a notification is
/// tapped.
class QuoteDetailScreen extends StatelessWidget {
  const QuoteDetailScreen({super.key, required this.quoteId});

  final int quoteId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          QuoteCard(quoteId: quoteId),
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton.filledTonal(
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/today'),
                  icon: const Icon(Icons.close),
                  tooltip: l.quotesCloseTooltip,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
