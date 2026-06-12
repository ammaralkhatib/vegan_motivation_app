import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_data.dart';

import 'support/paywall_fixtures.dart';

void main() {
  group('buildPaywallData — onboarding', () {
    test('captures the real free-trial period when present', () {
      final offering = testOffering(
        'onboarding',
        package: testPackage(product: testStoreProduct(intro: trial7Days)),
      );

      final data = buildPaywallData(PaywallVariant.onboarding, offering)!;

      expect(data.hasTrial, isTrue);
      expect(data.trialPeriodCount, 7);
      expect(data.trialPeriodUnit, TrialPeriodUnit.day);
      expect(data.anchorPriceString, isNull);
    });

    test('has no trial period when the product has no trial', () {
      final offering = testOffering('onboarding'); // no intro price

      final data = buildPaywallData(PaywallVariant.onboarding, offering)!;

      expect(data.hasTrial, isFalse);
      expect(data.trialPeriodCount, isNull);
      expect(data.priceString, r'$49.99');
    });
  });

  group('buildPaywallData — discount variants', () {
    test('defaultOffer keeps the discounted price and the real anchor', () {
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
      expect(data.hasTrial, isFalse);
    });

    test('discount keeps the discounted price and the real anchor', () {
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

      expect(data.priceString, r'$9.99');
      expect(data.anchorPriceString, r'$49.99');
    });

    test('drops the anchor when the full price is unavailable', () {
      final offering = testOffering('default');

      final data = buildPaywallData(
        PaywallVariant.defaultOffer,
        offering,
        anchorPriceString: null,
      )!;

      expect(data.anchorPriceString, isNull);
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
