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
    'veggie_yearly_full',
    'Full price yearly',
    'Veggie Premium',
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

/// A ready-made [PaywallData] for view/screen tests.
PaywallData testPaywallData({
  PaywallVariant variant = PaywallVariant.defaultOffer,
  String title = 'Unlock Veggie Premium',
  String ctaLabel = 'Unlock Veggie Premium',
  String priceString = r'$24.99',
  String? subtitle = r'$24.99/year',
  String? anchorPriceString,
  String? trialText,
  String? badgeText,
}) {
  return PaywallData(
    variant: variant,
    title: title,
    ctaLabel: ctaLabel,
    priceString: priceString,
    package: testPackage(),
    subtitle: subtitle,
    anchorPriceString: anchorPriceString,
    trialText: trialText,
    badgeText: badgeText,
  );
}
