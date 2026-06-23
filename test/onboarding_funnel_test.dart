import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegan_motivation_app/core/prefs/prefs_repository.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_providers.dart';
import 'package:vegan_motivation_app/features/paywall/onboarding_paywall_funnel.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_data.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_presenter.dart';

import 'support/fake_paywall_presenter.dart';
import 'support/fake_purchase_service.dart';

/// Stands in for the last onboarding slide: a button that runs the funnel.
class _FinishButton extends ConsumerWidget {
  const _FinishButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('finish'),
          onPressed: () => runOnboardingPaywallFunnel(ref),
          child: const Text('finish'),
        ),
      ),
    );
  }
}

Future<PrefsRepository> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return PrefsRepository(await SharedPreferences.getInstance());
}

Widget _app(
  PrefsRepository prefs,
  FakePurchaseService fake,
  FakePaywallPresenter presenter,
) =>
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        purchaseServiceProvider.overrideWithValue(fake),
        paywallPresenterProvider.overrideWithValue(presenter),
      ],
      child: const MaterialApp(home: _FinishButton()),
    );

void main() {
  testWidgets('free user: funnel presents the onboarding paywall only',
      (tester) async {
    final prefs = await _prefs({});
    final fake = FakePurchaseService(initialPremium: false);
    final presenter = FakePaywallPresenter();
    await tester.pumpWidget(_app(prefs, fake, presenter));

    await tester.tap(find.byKey(const Key('finish')));
    await tester.pump();

    // Only the onboarding (trial) paywall is presented — no exit discount.
    expect(presenter.presented, [PaywallVariant.onboarding]);
    // The funnel doesn't touch the one-time discount flag (the banner owns it).
    expect(prefs.discountOfferShown, isFalse);
  });

  testWidgets('premium user: funnel presents nothing', (tester) async {
    final prefs = await _prefs({});
    final fake = FakePurchaseService(initialPremium: true);
    final presenter = FakePaywallPresenter();
    await tester.pumpWidget(_app(prefs, fake, presenter));

    await tester.tap(find.byKey(const Key('finish')));
    await tester.pump();

    expect(presenter.presented, isEmpty);
    expect(prefs.discountOfferShown, isFalse);
  });
}
