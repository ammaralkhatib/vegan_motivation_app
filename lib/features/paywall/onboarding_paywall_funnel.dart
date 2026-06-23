import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/purchases/purchase_providers.dart';
import 'paywall_data.dart';
import 'paywall_presenter.dart';

/// The end-of-onboarding paywall: presents the RevenueCat `onboarding` hosted
/// paywall (the 7-day free trial).
///
/// Premium users (e.g. restored earlier) get nothing. There is **no**
/// exit-intent discount any more (App Review 5.6). The 80%-off offer lives in
/// an opt-in home banner (`DiscountBanner`). Call this after `onboardingDone`
/// is persisted, then navigate to `/today`.
Future<void> runOnboardingPaywallFunnel(WidgetRef ref) async {
  if (ref.read(isPremiumProvider)) return;
  await ref.read(paywallPresenterProvider).present(PaywallVariant.onboarding);
}
