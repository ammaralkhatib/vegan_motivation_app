import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegan_motivation_app/core/prefs/prefs_repository.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_providers.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/features/paywall/onboarding_paywall_funnel.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_data.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_screen.dart';
import 'package:vegan_motivation_app/l10n/app_localizations.dart';

import 'helpers.dart';
import 'support/fake_purchase_service.dart';
import 'support/paywall_fixtures.dart';

/// Stands in for the last onboarding slide: a button that runs the funnel then
/// navigates to /today — exactly what `_finish()` does.
class _FinishButton extends ConsumerWidget {
  const _FinishButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('finish'),
          onPressed: () async {
            await runOnboardingPaywallFunnel(context, ref);
            if (context.mounted) context.go('/today');
          },
          child: const Text('finish'),
        ),
      ),
    );
  }
}

GoRouter _router() => GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(path: '/start', builder: (c, s) => const _FinishButton()),
        GoRoute(
          path: '/paywall/:variant',
          builder: (c, s) => PaywallScreen(
            variant: PaywallVariant.fromName(s.pathParameters['variant']),
          ),
        ),
        GoRoute(
          path: '/today',
          builder: (c, s) => const Scaffold(body: Text('TODAY HOME')),
        ),
      ],
    );

Map<String, Offering> _offerings() => {
      'onboarding': testOffering(
        'onboarding',
        package: testPackage(product: testStoreProduct(intro: trial7Days)),
      ),
      'default': testOffering('default'),
      'discount': testOffering(
        'discount',
        package: testPackage(
          product: testStoreProduct(priceString: r'$9.99', price: 9.99),
        ),
      ),
    };

Future<PrefsRepository> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return PrefsRepository(await SharedPreferences.getInstance());
}

Widget _app(PrefsRepository prefs, FakePurchaseService fake) => ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        purchaseServiceProvider.overrideWithValue(fake),
      ],
      child: MaterialApp.router(
        theme: VeggieTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router(),
      ),
    );

void main() {
  testWidgets('free user: trial paywall, then discount, then Today',
      (tester) async {
    disableCritterAnimations(tester); // close button shows immediately
    final prefs = await _prefs({});
    final fake = FakePurchaseService(initialPremium: false, offerings: _offerings());
    await tester.pumpWidget(_app(prefs, fake));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('finish')));
    await tester.pumpAndSettle();

    // Trial paywall first; the one-time flag is NOT set yet.
    expect(find.text('Start free trial'), findsOneWidget);
    expect(prefs.discountOfferShown, isFalse);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Discount paywall second; the flag is now set (before it was shown).
    expect(find.text('Claim my offer'), findsOneWidget);
    expect(prefs.discountOfferShown, isTrue);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('TODAY HOME'), findsOneWidget);
  });

  testWidgets('discount paywall never shows again once the flag is set',
      (tester) async {
    disableCritterAnimations(tester); // close button shows immediately
    final prefs = await _prefs({'discountOfferShown': true});
    final fake = FakePurchaseService(initialPremium: false, offerings: _offerings());
    await tester.pumpWidget(_app(prefs, fake));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('finish')));
    await tester.pumpAndSettle();

    // Trial still shows; closing it goes straight to Today — no discount.
    expect(find.text('Start free trial'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Claim my offer'), findsNothing);
    expect(find.text('TODAY HOME'), findsOneWidget);
  });

  testWidgets('premium user sees no paywalls and lands on Today',
      (tester) async {
    final prefs = await _prefs({});
    final fake = FakePurchaseService(initialPremium: true, offerings: _offerings());
    await tester.pumpWidget(_app(prefs, fake));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('finish')));
    await tester.pumpAndSettle();

    expect(find.text('Start free trial'), findsNothing);
    expect(find.text('Claim my offer'), findsNothing);
    expect(find.text('TODAY HOME'), findsOneWidget);
    expect(prefs.discountOfferShown, isFalse); // nothing was offered
  });
}
