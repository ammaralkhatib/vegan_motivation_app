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

/// Everything the paywall *screen* needs to render — already resolved from the
/// store. The screen renders only this, so widget tests build it by hand and
/// never touch real SDK types (002 showed those are painful to fake).
///
/// Prices and trial text always come from the store ([priceString],
/// [anchorPriceString], [trialText]); only copy is hard-coded.
class PaywallData {
  const PaywallData({
    required this.variant,
    required this.title,
    required this.ctaLabel,
    required this.priceString,
    required this.package,
    this.subtitle,
    this.anchorPriceString,
    this.trialText,
    this.badgeText,
  });

  final PaywallVariant variant;

  /// Headline copy.
  final String title;

  /// Primary button label.
  final String ctaLabel;

  /// Real, localized price of the product being sold (e.g. "$24.99").
  final String priceString;

  /// The package the CTA buys.
  final Package package;

  /// Optional supporting line (e.g. discount urgency, or plain "$X/year").
  final String? subtitle;

  /// Optional crossed-out anchor price — only ever the real full price.
  final String? anchorPriceString;

  /// Optional trial line, e.g. "7 days free, then $49.99/year".
  final String? trialText;

  /// Optional badge, e.g. "50% OFF".
  final String? badgeText;
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
      final trial = _freeTrialText(package.storeProduct);
      return PaywallData(
        variant: variant,
        title: 'Start your Veggie journey',
        ctaLabel: 'Start free trial',
        priceString: price,
        package: package,
        trialText: trial != null ? '$trial free, then $price/year' : null,
        subtitle: trial == null ? '$price/year' : null,
      );
    case PaywallVariant.defaultOffer:
      return PaywallData(
        variant: variant,
        title: 'Unlock Veggie Premium',
        ctaLabel: 'Unlock Veggie Premium',
        priceString: price,
        package: package,
        subtitle: '$price/year',
        anchorPriceString: anchorPriceString,
        badgeText: anchorPriceString != null ? '50% OFF' : null,
      );
    case PaywallVariant.discount:
      return PaywallData(
        variant: variant,
        title: 'A one-time gift for you',
        ctaLabel: 'Claim my offer',
        priceString: price,
        package: package,
        subtitle: "This offer won't come back.",
        anchorPriceString: anchorPriceString,
        badgeText: anchorPriceString != null ? '80% OFF — one-time offer' : null,
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

/// Returns trial duration text ("7 days") when the product has a *free*
/// introductory phase, else null — so we never promise a trial the store
/// won't honor.
String? _freeTrialText(StoreProduct product) {
  final intro = product.introductoryPrice;
  if (intro == null || intro.price != 0) return null;
  final n = intro.periodNumberOfUnits;
  final unit = switch (intro.periodUnit) {
    PeriodUnit.day => n == 1 ? 'day' : 'days',
    PeriodUnit.week => n == 1 ? 'week' : 'weeks',
    PeriodUnit.month => n == 1 ? 'month' : 'months',
    PeriodUnit.year => n == 1 ? 'year' : 'years',
    PeriodUnit.unknown => 'days',
  };
  return '$n $unit';
}
