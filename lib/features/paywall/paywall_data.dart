import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/purchases/purchase_config.dart';

/// The three paywall variants, each backed by one RevenueCat offering
/// (CLAUDE.md §3).
enum PaywallVariant {
  /// End of onboarding — 7-day free trial on the full-price product.
  onboarding,

  /// 50% off, shown on locked content / settings.
  defaultOffer,

  /// 80% off "last chance", shown once after onboarding.
  discount;

  String get offeringId => switch (this) {
        PaywallVariant.onboarding => PurchaseConfig.onboardingOfferingId,
        PaywallVariant.defaultOffer => PurchaseConfig.defaultOfferingId,
        PaywallVariant.discount => PurchaseConfig.discountOfferingId,
      };

  /// Parse from a router path segment; unknown values fall back to the 50%-off
  /// paywall (the safest default — no invented discounts, no false trial).
  static PaywallVariant fromName(String? name) =>
      PaywallVariant.values.firstWhere(
        (v) => v.name == name,
        orElse: () => PaywallVariant.defaultOffer,
      );
}

/// Free-trial period unit, decoupled from the RevenueCat SDK enum so the
/// widget layer can localize it without importing the store SDK.
enum TrialPeriodUnit { day, week, month, year }

/// Everything the paywall *screen* needs to render — resolved from the store,
/// but **string-free of copy**. Prices come straight from the store
/// ([priceString], [anchorPriceString]); the trial is kept as a raw
/// count + unit. All display copy (title, CTA, badge, subtitle, trial line) is
/// resolved from [variant] in the widget layer via AppLocalizations, so no
/// English lives in the data layer (UI-strings-only l10n, CLAUDE.md §1).
///
/// The screen renders only this, so widget tests build it by hand and never
/// touch real SDK types (002 showed those are painful to fake).
class PaywallData {
  const PaywallData({
    required this.variant,
    required this.priceString,
    required this.package,
    this.anchorPriceString,
    this.trialPeriodCount,
    this.trialPeriodUnit,
  });

  final PaywallVariant variant;

  /// Real, localized price of the product being sold (e.g. "$24.99").
  final String priceString;

  /// The package the CTA buys.
  final Package package;

  /// Optional crossed-out anchor price — only ever the real full price.
  final String? anchorPriceString;

  /// Free-trial length, or null when the product has no free trial. The pair is
  /// formatted (and pluralized) in the widget layer.
  final int? trialPeriodCount;
  final TrialPeriodUnit? trialPeriodUnit;

  bool get hasTrial => trialPeriodCount != null && trialPeriodUnit != null;
}

/// Builds [PaywallData] from a RevenueCat [offering]. Returns null if the
/// offering has no purchasable package (treated as a load failure by the
/// screen). [anchorPriceString] is the real full price for discount variants;
/// when null the crossed-out anchor and the "% OFF" badge are both omitted
/// (CLAUDE.md §3 — never invent an anchor).
PaywallData? buildPaywallData(
  PaywallVariant variant,
  Offering offering, {
  String? anchorPriceString,
}) {
  final package = _annualOrFirst(offering);
  if (package == null) return null;
  final price = package.storeProduct.priceString;

  switch (variant) {
    case PaywallVariant.onboarding:
      final trial = _freeTrialPeriod(package.storeProduct);
      return PaywallData(
        variant: variant,
        priceString: price,
        package: package,
        trialPeriodCount: trial?.$1,
        trialPeriodUnit: trial?.$2,
      );
    case PaywallVariant.defaultOffer:
    case PaywallVariant.discount:
      return PaywallData(
        variant: variant,
        priceString: price,
        package: package,
        anchorPriceString: anchorPriceString,
      );
  }
}

/// The full price string for the anchor, read from a full-price [offering]
/// (the `onboarding` offering sells the $49.99 product). Null if unavailable.
String? anchorPriceFrom(Offering? offering) {
  if (offering == null) return null;
  return _annualOrFirst(offering)?.storeProduct.priceString;
}

Package? _annualOrFirst(Offering offering) =>
    offering.annual ??
    (offering.availablePackages.isNotEmpty
        ? offering.availablePackages.first
        : null);

/// Returns the trial duration as a (count, unit) pair when the product has a
/// *free* introductory phase, else null — so we never promise a trial the
/// store won't honor. The pair is localized in the widget layer.
(int, TrialPeriodUnit)? _freeTrialPeriod(StoreProduct product) {
  final intro = product.introductoryPrice;
  if (intro == null || intro.price != 0) return null;
  final unit = switch (intro.periodUnit) {
    PeriodUnit.day => TrialPeriodUnit.day,
    PeriodUnit.week => TrialPeriodUnit.week,
    PeriodUnit.month => TrialPeriodUnit.month,
    PeriodUnit.year => TrialPeriodUnit.year,
    PeriodUnit.unknown => TrialPeriodUnit.day,
  };
  return (intro.periodNumberOfUnits, unit);
}
