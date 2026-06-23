import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/purchases/purchase_providers.dart';
import 'paywall_data.dart';
import 'paywall_screen.dart';

/// The end-of-onboarding paywall: a single 7-day free-trial offer.
///
/// Premium users (e.g. restored earlier) get nothing. There is **no**
/// exit-intent discount any more (App Review 5.6 — showing a second "last
/// chance" paywall when the user tries to leave was treated as pressuring an
/// unwanted purchase). Closing this paywall lands the user straight in the app.
/// The 80%-off offer now lives in an opt-in home banner (`DiscountBanner`),
/// which sets `discountOfferShown` itself, so this funnel no longer touches that
/// flag. Call this after `onboardingDone` is persisted, then navigate to
/// `/today` — closing the paywall pops back here, never into onboarding.
Future<void> runOnboardingPaywallFunnel(
  BuildContext context,
  WidgetRef ref,
) async {
  if (ref.read(isPremiumProvider)) return;
  await showPaywall(context, PaywallVariant.onboarding);
}
