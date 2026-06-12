import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/purchases/purchase_providers.dart';
import '../../core/purchases/purchase_service.dart';
import '../../core/purchases/restore_flow.dart';
import 'paywall_data.dart';
import 'paywall_providers.dart';

/// Pushes the paywall full-screen. 005 reuses this for the real triggers.
Future<void> showPaywall(BuildContext context, PaywallVariant variant) {
  return context.push('/paywall/${variant.name}');
}

/// The benefits every variant lists.
const _benefits = [
  'All 6 quote categories',
  'The full 508-quote library',
  'Support the mission 🌱',
  'Everything stays on your device',
];

/// Full paywall screen: loads the offering, renders [PaywallView], and runs
/// the purchase / restore flow. Degrades to a friendly retry state if the
/// offering can't load — and the close button always works.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, required this.variant});

  final PaywallVariant variant;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  final ConfettiController _confetti =
      ConfettiController(duration: const Duration(milliseconds: 1200));
  bool _busy = false;

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  Future<void> _buy(PaywallData data) async {
    if (_busy) return;
    setState(() => _busy = true);
    final outcome =
        await ref.read(purchaseServiceProvider).purchase(data.package);
    if (!mounted) return;
    switch (outcome) {
      case PurchaseOutcome.success:
        _confetti.play();
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        if (mounted) _close();
      case PurchaseOutcome.cancelled:
        setState(() => _busy = false); // stay open, no message
      case PurchaseOutcome.error:
        setState(() => _busy = false);
        _snack('Something went wrong — you were not charged.');
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result =
        await performRestore(ref.read(purchaseServiceProvider));
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(restoreMessage(result));
    if (result == RestoreResult.restored) _close();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(paywallDataProvider(widget.variant));

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => _OffersUnavailable(onRetry: _retry),
              data: (data) => data == null
                  ? _OffersUnavailable(onRetry: _retry)
                  : PaywallView(
                      data: data,
                      busy: _busy,
                      onPurchase: () => _buy(data),
                      onRestore: _restore,
                    ),
            ),
          ),
          // Confetti on success.
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 24,
              maxBlastForce: 18,
              minBlastForce: 6,
              gravity: 0.25,
            ),
          ),
          // Close (X) — always available.
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: IconButton(
                  onPressed: _close,
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _retry() => ref.invalidate(paywallDataProvider(widget.variant));
}

/// Pure, render-only paywall body — driven entirely by [PaywallData].
class PaywallView extends StatelessWidget {
  const PaywallView({
    super.key,
    required this.data,
    this.busy = false,
    this.onPurchase,
    this.onRestore,
  });

  final PaywallData data;
  final bool busy;
  final VoidCallback? onPurchase;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 56, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.eco, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 24),
            ..._benefits.map(
              (b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(b, style: theme.textTheme.bodyLarge)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _PriceBlock(data: data),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: busy ? null : onPurchase,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              child: busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(data.ctaLabel),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: busy ? null : onRestore,
              child: const Text('Restore purchases'),
            ),
            const SizedBox(height: 8),
            Text(
              'Cancel anytime in your store settings.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.data});

  final PaywallData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (data.badgeText != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data.badgeText!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (data.anchorPriceString != null)
          Text(
            data.anchorPriceString!,
            style: theme.textTheme.titleMedium?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        Text(
          // For the trial variant this carries the whole "X free, then …" line.
          data.trialText ?? data.priceString,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (data.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            data.subtitle!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _OffersUnavailable extends StatelessWidget {
  const _OffersUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              "Can't load offers right now — check your connection.",
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
