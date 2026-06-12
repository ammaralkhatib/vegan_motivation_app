import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/notifications/trial_reminder.dart';
import '../../core/purchases/purchase_providers.dart';
import '../../core/purchases/purchase_service.dart';
import '../../core/purchases/restore_flow.dart';
import '../../l10n/app_localizations.dart';
import 'paywall_data.dart';
import 'paywall_providers.dart';

/// Pushes the paywall full-screen. 005 reuses this for the real triggers.
Future<void> showPaywall(BuildContext context, PaywallVariant variant) {
  return context.push('/paywall/${variant.name}');
}

/// The benefits every variant lists.
List<String> _benefits(AppLocalizations l) => [
      l.paywallBenefit1,
      l.paywallBenefit2,
      l.paywallBenefit3,
      l.paywallBenefit4,
    ];

/// Headline copy, by variant.
String _paywallTitle(AppLocalizations l, PaywallVariant v) => switch (v) {
      PaywallVariant.onboarding => l.paywallOnboardingTitle,
      PaywallVariant.defaultOffer => l.paywallDefaultTitle,
      PaywallVariant.discount => l.paywallDiscountTitle,
    };

/// Primary-button copy, by variant.
String _paywallCta(AppLocalizations l, PaywallVariant v) => switch (v) {
      PaywallVariant.onboarding => l.paywallOnboardingCta,
      PaywallVariant.defaultOffer => l.paywallDefaultCta,
      PaywallVariant.discount => l.paywallDiscountCta,
    };

/// Discount badge — only shown when a real anchor price is present.
String? _paywallBadge(AppLocalizations l, PaywallData d) {
  if (d.anchorPriceString == null) return null;
  return switch (d.variant) {
    PaywallVariant.defaultOffer => l.paywallBadge50,
    PaywallVariant.discount => l.paywallBadge80,
    PaywallVariant.onboarding => null,
  };
}

/// Localized free-trial duration, e.g. "7 days".
String _trialDuration(AppLocalizations l, int count, TrialPeriodUnit unit) =>
    switch (unit) {
      TrialPeriodUnit.day => l.paywallTrialDurationDays(count),
      TrialPeriodUnit.week => l.paywallTrialDurationWeeks(count),
      TrialPeriodUnit.month => l.paywallTrialDurationMonths(count),
      TrialPeriodUnit.year => l.paywallTrialDurationYears(count),
    };

/// The "{trial} free, then {price}/year" line, or null when there's no trial.
String? _trialText(AppLocalizations l, PaywallData d) {
  if (!d.hasTrial) return null;
  final duration =
      _trialDuration(l, d.trialPeriodCount!, d.trialPeriodUnit!);
  return l.paywallTrialText(duration, d.priceString);
}

/// Supporting line under the price, by variant.
String? _paywallSubtitle(AppLocalizations l, PaywallData d) => switch (d.variant) {
      PaywallVariant.onboarding =>
        d.hasTrial ? null : l.paywallPricePerYear(d.priceString),
      PaywallVariant.defaultOffer => l.paywallPricePerYear(d.priceString),
      PaywallVariant.discount => l.paywallDiscountUrgency,
    };

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

  // Close-button gating: the onboarding/discount offers fade their X in after
  // 2 s so the offer is actually seen, not reflex-dismissed.
  bool _closeReady = false;
  bool _closeScheduled = false;
  Timer? _closeTimer;

  bool get _delaysClose =>
      widget.variant == PaywallVariant.onboarding ||
      widget.variant == PaywallVariant.discount;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_closeScheduled) return;
    _closeScheduled = true;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!_delaysClose || reduceMotion) {
      _closeReady = true;
    } else {
      _closeTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _closeReady = true);
      });
    }
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
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
        // Trial purchases get a "your trial ends tomorrow" reminder; the 50%/
        // 80% products don't (no trial).
        final productId = data.package.storeProduct.identifier;
        if (shouldScheduleTrialReminder(productId)) {
          await NotificationService.instance.scheduleTrialEndReminder(
            trialReminderFireTime(DateTime.now()),
          );
        }
        if (!mounted) return;
        _confetti.play();
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        if (mounted) _close();
      case PurchaseOutcome.cancelled:
        setState(() => _busy = false); // stay open, no message
      case PurchaseOutcome.error:
        setState(() => _busy = false);
        _snack(AppLocalizations.of(context).paywallPurchaseError);
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
          // Close (X) — fades in after a beat on the onboarding/discount offers.
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: IgnorePointer(
                  ignoring: !_closeReady,
                  child: AnimatedOpacity(
                    opacity: _closeReady ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: IconButton(
                      onPressed: _close,
                      icon: const Icon(Icons.close),
                      tooltip: AppLocalizations.of(context).paywallClose,
                    ),
                  ),
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
    final l = AppLocalizations.of(context);
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
              _paywallTitle(l, data.variant),
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 24),
            ..._benefits(l).map(
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
                  : Text(_paywallCta(l, data.variant)),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: busy ? null : onRestore,
              child: Text(l.paywallRestore),
            ),
            const SizedBox(height: 8),
            Text(
              l.paywallCancelAnytime,
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
    final l = AppLocalizations.of(context);
    final badge = _paywallBadge(l, data);
    final subtitle = _paywallSubtitle(l, data);
    return Column(
      children: [
        if (badge != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
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
          _trialText(l, data) ?? data.priceString,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
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
    final l = AppLocalizations.of(context);
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
              l.paywallOffersUnavailable,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: Text(l.paywallRetry),
            ),
          ],
        ),
      ),
    );
  }
}
