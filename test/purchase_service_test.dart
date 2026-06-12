import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegan_motivation_app/core/prefs/prefs_repository.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_service.dart';

Future<PrefsRepository> prefsWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return PrefsRepository(await SharedPreferences.getInstance());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RevenueCatPurchaseService cache seeding', () {
    test('seeds isPremium from the cache before any network call', () async {
      final prefs = await prefsWith({'premiumCached': true});
      final service = RevenueCatPurchaseService(prefs, supported: true);

      // No init() / SDK call — the value comes straight from the cache.
      expect(service.isPremium, isTrue);
      service.dispose();
    });

    test('defaults to free when nothing is cached', () async {
      final prefs = await prefsWith({});
      final service = RevenueCatPurchaseService(prefs, supported: true);

      expect(service.isPremium, isFalse);
      service.dispose();
    });

    test('unsupported platforms are premium and never touch the SDK',
        () async {
      final prefs = await prefsWith({});
      final service = RevenueCatPurchaseService(prefs, supported: false);

      expect(service.isPremium, isTrue);
      expect(service.isPremiumStream, emits(true));
      await service.init(); // no-op for the SDK on unsupported platforms
      expect(service.isPremium, isTrue);
      service.dispose();
    });

    test('restore on an unsupported platform reports success', () async {
      final prefs = await prefsWith({});
      final service = RevenueCatPurchaseService(prefs, supported: false);

      expect(await service.restorePurchases(), PurchaseOutcome.success);
      service.dispose();
    });
  });

  group('PrefsRepository premium cache', () {
    test('round-trips the cached premium flag', () async {
      final prefs = await prefsWith({});
      expect(prefs.premiumCached, isFalse);
      await prefs.setPremiumCached(true);
      expect(prefs.premiumCached, isTrue);
    });
  });
}
