import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/database.dart';
import '../../l10n/app_localizations.dart';
import 'providers.dart';
import 'quote_card.dart';
import 'share_service.dart';

/// The signature interaction: full-screen vertical swipe feed of quotes.
/// Tap anywhere (outside the action buttons) also advances.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _advance() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _share(Quote quote) {
    showShareSheet(context, quote);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final queue = ref.watch(feedQueueProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: queue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.feedError(e.toString()))),
        data: (ids) {
          if (ids.isEmpty) {
            return Center(child: Text(l.feedEmpty));
          }
          return Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _advance,
                child: PageView.builder(
                  controller: _controller,
                  scrollDirection: Axis.vertical,
                  onPageChanged: (page) {
                    final id = ids[page % ids.length];
                    ref
                        .read(databaseProvider)
                        .quoteDao
                        .incrementShownCount(id);
                  },
                  itemBuilder: (context, index) {
                    final id = ids[index % ids.length];
                    return QuoteCard(quoteId: id, onShare: _share);
                  },
                ),
              ),
              // Date header overlay.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d').format(DateTime.now()),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const Spacer(),
                        Icon(
                          Icons.eco,
                          size: 18,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
