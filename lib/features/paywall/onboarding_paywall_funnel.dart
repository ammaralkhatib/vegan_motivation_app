import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/prefs/prefs_repository.dart';
import '../../core/purchases/purchase_providers.dart';
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
    await showPaywall(context, PaywallVariant.discount);
  }
}
