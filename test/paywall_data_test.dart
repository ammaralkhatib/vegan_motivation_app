import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_data.dart';

import 'support/paywall_fixtures.dart';

void main() {
  group('buildPaywallData — onboarding', () {
    test('uses the real free-trial period when present', () {
      final offering = testOffering(
        'onboarding',
        package: testPackage(product: testStoreProduct(intro: trial7Days)),
      );

      final data = buildPaywallData(PaywallVariant.onboarding, offering)!;

      expect(data.ctaLabel, 'Start free trial');
      expect(data.trialText, '7 days free, then \$49.99/year');
      expect(data.badgeText, isNull);
      expect(data.anchorPriceString, isNull);
    });

    test('falls back to plain price when the product has no trial', () {
      final offering = testOffering('onboarding'); // no intro price

      final data = buildPaywallData(PaywallVariant.onboarding, offering)!;

      expect(data.trialText, isNull);
      expect(data.subtitle, '\$49.99/year');
    });
  });

  group('buildPaywallData — discount variants', () {
    test('defaultOffer shows the 50% badge and the real crossed-out anchor', () {
      final offering = testOffering(
        'default',
        package: testPackage(
          product: testStoreProduct(priceString: r'$24.99', price: 24.99),
        ),
      );

      final data = buildPaywallData(
        PaywallVariant.defaultOffer,
        offering,
        anchorPriceString: r'$49.99',
      )!;

      expect(data.priceString, r'$24.99');
      expect(data.anchorPriceString, r'$49.99');
      expect(data.badgeText, '50% OFF');
      expect(data.ctaLabel, 'Unlock Veggie Premium');
    });

    test('discount shows the 80% one-time badge and urgency copy', () {
      final offering = testOffering(
        'discount',
        package: testPackage(
          product: testStoreProduct(priceString: r'$9.99', price: 9.99),
        ),
      );

      final data = buildPaywallData(
        PaywallVariant.discount,
        offering,
        anchorPriceString: r'$49.99',
      )!;

      expect(data.badgeText, '80% OFF — one-time offer');
      expect(data.subtitle, "This offer won't come back.");
      expect(data.ctaLabel, 'Claim my offer');
    });

    test('hides the badge and anchor when the full price is unavailable', () {
      final offering = testOffering('default');

      final data = buildPaywallData(
        PaywallVariant.defaultOffer,
        offering,
        anchorPriceString: null,
      )!;

      expect(data.anchorPriceString, isNull);
      expect(data.badgeText, isNull);
    });
  });

  group('buildPaywallData — no purchasable package', () {
    test('returns null so the screen shows its retry state', () {
      final offering = testOffering('default', empty: true);
      expect(buildPaywallData(PaywallVariant.defaultOffer, offering), isNull);
    });
  });

  group('anchorPriceFrom', () {
    test('reads the full price string, or null when missing', () {
      expect(anchorPriceFrom(testOffering('onboarding')), r'$49.99');
      expect(anchorPriceFrom(null), isNull);
      expect(anchorPriceFrom(testOffering('onboarding', empty: true)), isNull);
    });
  });
}
