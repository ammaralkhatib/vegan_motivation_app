import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_service.dart';
import 'package:vegan_motivation_app/core/purchases/restore_flow.dart';

import 'support/fake_purchase_service.dart';

void main() {
  group('performRestore', () {
    test('premium after restore → restored', () async {
      final fake = FakePurchaseService(initialPremium: false);
      expect(await performRestore(fake), RestoreResult.restored);
    });

    test('succeeded but no entitlement → noneFound', () async {
      final fake = FakePurchaseService(
        initialPremium: false,
        restoreGrantsPremium: false,
      );
      expect(await performRestore(fake), RestoreResult.noneFound);
    });

    test('store error → error', () async {
      final fake = FakePurchaseService(
        initialPremium: false,
        restoreResult: PurchaseOutcome.error,
        restoreGrantsPremium: false,
      );
      expect(await performRestore(fake), RestoreResult.error);
    });
  });

  test('restoreMessage maps each result', () {
    expect(restoreMessage(RestoreResult.restored), 'Welcome back!');
    expect(restoreMessage(RestoreResult.noneFound), 'No previous purchase found.');
    expect(
      restoreMessage(RestoreResult.error),
      'Something went wrong — please try again.',
    );
  });
}
