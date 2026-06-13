import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_data.dart';

/// Minimal real RevenueCat objects for tests. The `PaywallData` seam means we
/// only need these in the few places that exercise the mapper or pass a
/// package into `PurchaseService.purchase` (the fake ignores its contents).

const trial7Days = IntroductoryPrice(0, 'Free', 'P7D', 1, PeriodUnit.day, 7);

StoreProduct testStoreProduct({
  String priceString = r'$49.99',
  double price = 49.99,
  IntroductoryPrice? intro,
}) {
  return StoreProduct(
    'vegankit_yearly_full',
    'Full price yearly',
    'VeganKit Premium',
    price,
    priceString,
    'USD',
    introductoryPrice: intro,
  );
}

Package testPackage({StoreProduct? product}) {
  return Package(
    'annual',
    PackageType.annual,
    product ?? testStoreProduct(),
    const PresentedOfferingContext('onboarding', null, null),
  );
}

Offering testOffering(
  String id, {
  Package? package,
  bool empty = false,
}) {
  final pkg = package ?? testPackage();
  return Offering(
    id,
    'server description',
    const {},
    empty ? const [] : [pkg],
    annual: empty ? null : pkg,
  );
}

/// A ready-made [PaywallData] for view/screen tests. Display copy now lives in
/// the widget layer (resolved from [variant] via l10n), so this only carries
/// store facts: price, optional anchor, and an optional trial period.
PaywallData testPaywallData({
  PaywallVariant variant = PaywallVariant.defaultOffer,
  String priceString = r'$24.99',
  String? anchorPriceString,
  int? trialPeriodCount,
  TrialPeriodUnit? trialPeriodUnit,
}) {
  return PaywallData(
    variant: variant,
    priceString: priceString,
    package: testPackage(),
    anchorPriceString: anchorPriceString,
    trialPeriodCount: trialPeriodCount,
    trialPeriodUnit: trialPeriodUnit,
  );
}
