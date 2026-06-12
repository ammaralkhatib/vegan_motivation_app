import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_providers.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_service.dart';

import 'support/fake_purchase_service.dart';

ProviderContainer containerWith(FakePurchaseService fake) {
  final container = ProviderContainer(
    overrides: [purchaseServiceProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  // Keep the provider alive so its stream subscription stays active.
  container.listen(isPremiumProvider, (_, _) {});
  return container;
}

void main() {
  test('isPremiumProvider seeds from the service cached value', () {
    final fake = FakePurchaseService(initialPremium: true);
    final container = containerWith(fake);

    expect(container.read(isPremiumProvider), isTrue);
  });

  test('isPremiumProvider starts false for a free user', () {
    final fake = FakePurchaseService(initialPremium: false);
    final container = containerWith(fake);

    expect(container.read(isPremiumProvider), isFalse);
  });

  // Guards the FORCE_PREMIUM wiring. Tests compile without the dart-define, so
  // `PurchaseConfig.forcePremium` is the default `false` here — this confirms
  // the flag's guard doesn't leak premium when it's off, i.e. real gating still
  // drives `isPremiumProvider`. The `true` branch is fixed at compile time by
  // the define, so it can't be exercised from a normal `flutter test` run.
  test('FORCE_PREMIUM off: a free user is not forced premium', () {
    final fake = FakePurchaseService(initialPremium: false);
    final container = containerWith(fake);

    expect(container.read(isPremiumProvider), isFalse);
  });

  test('isPremiumProvider updates when the store reports a change', () async {
    final fake = FakePurchaseService(initialPremium: false);
    final container = containerWith(fake);
    expect(container.read(isPremiumProvider), isFalse);

    fake.emitPremium(true);
    await Future<void>.delayed(Duration.zero); // let the stream deliver

    expect(container.read(isPremiumProvider), isTrue);
  });

  test('a successful restore flips premium and the provider updates',
      () async {
    final fake = FakePurchaseService(initialPremium: false);
    final container = containerWith(fake);

    final outcome = await fake.restorePurchases();
    await Future<void>.delayed(Duration.zero);

    expect(outcome, PurchaseOutcome.success);
    expect(container.read(isPremiumProvider), isTrue);
  });

  test('a failed restore leaves premium untouched', () async {
    final fake = FakePurchaseService(
      initialPremium: false,
      restoreResult: PurchaseOutcome.error,
    );
    final container = containerWith(fake);

    final outcome = await fake.restorePurchases();
    await Future<void>.delayed(Duration.zero);

    expect(outcome, PurchaseOutcome.error);
    expect(container.read(isPremiumProvider), isFalse);
  });
}
