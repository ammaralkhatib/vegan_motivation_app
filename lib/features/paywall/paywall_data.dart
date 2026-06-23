import '../../core/purchases/purchase_config.dart';

/// The three paywall variants, each backed by one RevenueCat offering
/// (CLAUDE.md §3). The hosted RevenueCat paywall for the offering is what the
/// user actually sees — this enum just names which offering to present.
enum PaywallVariant {
  /// End of onboarding — 7-day free trial on the full-price product.
  onboarding,

  /// 50% off, shown on locked content / settings.
  defaultOffer,

  /// 80% off "last chance", shown from the opt-in home discount banner.
  discount;

  String get offeringId => switch (this) {
        PaywallVariant.onboarding => PurchaseConfig.onboardingOfferingId,
        PaywallVariant.defaultOffer => PurchaseConfig.defaultOfferingId,
        PaywallVariant.discount => PurchaseConfig.discountOfferingId,
      };
}
