import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/purchases/purchase_config.dart';
import '../../core/purchases/purchase_providers.dart';
import 'paywall_data.dart';

/// Loads the [PaywallData] for a variant from the store. Null means the
/// offering couldn't be fetched (offline, placeholder keys, missing dashboard
/// setup) — the screen shows its friendly retry state. Override this in tests
/// to render any state without real SDK calls.
final paywallDataProvider =
    FutureProvider.family<PaywallData?, PaywallVariant>((ref, variant) async {
  final service = ref.watch(purchaseServiceProvider);

  final offering = await service.getOffering(variant.offeringId);
  if (offering == null) return null;

  // Discount variants cross out the *real* full price from the onboarding
  // offering — never an invented number (CLAUDE.md §3).
  String? anchor;
  if (variant != PaywallVariant.onboarding) {
    final fullPrice =
        await service.getOffering(PurchaseConfig.onboardingOfferingId);
    anchor = anchorPriceFrom(fullPrice);
  }

  return buildPaywallData(variant, offering, anchorPriceString: anchor);
});
