import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/prefs/prefs_repository.dart';
import '../../core/purchases/purchase_providers.dart';
import '../../l10n/app_localizations.dart';
import 'paywall_data.dart';
import 'paywall_screen.dart';

/// The end-of-onboarding paywall funnel:
///   trial paywall → (if still free, once ever) 80% "last chance" paywall.
///
/// Premium users (e.g. restored earlier) get nothing. The discount flag is set
/// **before** the discount paywall is shown, so even a crash can't repeat the
/// one-time offer. Call this after `onboardingDone` is already persisted, then
/// navigate to `/today` — closing a paywall pops back here, never into
/// onboarding (see the router redirect note).
Future<void> runOnboardingPaywallFunnel(
  BuildContext context,
  WidgetRef ref,
) async {
  if (ref.read(isPremiumProvider)) return;

  await showPaywall(context, PaywallVariant.onboarding);
  if (!context.mounted) return;

  final prefs = ref.read(prefsProvider);
  final stillFree = !ref.read(isPremiumProvider);
  if (stillFree && !prefs.discountOfferShown) {
    // Persist first — once ever, even across a crash mid-show.
    await prefs.setDiscountOfferShown(true);
    if (!context.mounted) return;
    // Brief processing interstitial so the discount paywall reads as a new,
    // separate offer instead of the first paywall appearing to flicker.
    await _showInterstitial(context);
    if (!context.mounted) return;
    await showPaywall(context, PaywallVariant.discount);
  }
}

/// Shows the non-dismissible loading interstitial for ~1.2 s, then dismisses it.
/// A transient `Navigator` route on purpose — not a go_router destination.
Future<void> _showInterstitial(BuildContext context) async {
  unawaited(Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const _PaywallInterstitial()),
  ));
  await Future<void>.delayed(const Duration(milliseconds: 1200));
  if (!context.mounted) return;
  Navigator.of(context).pop();
}

/// Plain centered spinner shown between the two onboarding paywalls. Cannot be
/// dismissed by the user; it always auto-dismisses after its short delay.
class _PaywallInterstitial extends StatelessWidget {
  const _PaywallInterstitial();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                l.paywallInterstitialMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
