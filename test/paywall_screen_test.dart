import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_providers.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_service.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_data.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_providers.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_screen.dart';
import 'package:vegan_motivation_app/l10n/app_localizations.dart';

import 'support/fake_purchase_service.dart';
import 'support/paywall_fixtures.dart';

const _variant = PaywallVariant.defaultOffer;

/// Wraps the paywall behind a launcher route so `pop` has somewhere to go.
Widget harness({
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: VeggieTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PaywallScreen(variant: _variant),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> openPaywall(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('offering unavailable shows the retry state; close still works',
      (tester) async {
    await tester.pumpWidget(harness(overrides: [
      paywallDataProvider(_variant).overrideWith((ref) async => null),
    ]));
    await openPaywall(tester);

    expect(
      find.text("Can't load offers right now — check your connection."),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    // X closes the paywall even with no offer loaded.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('successful purchase confettis and auto-closes', (tester) async {
    final fake = FakePurchaseService(initialPremium: false);
    await tester.pumpWidget(harness(overrides: [
      purchaseServiceProvider.overrideWithValue(fake),
      paywallDataProvider(_variant)
          .overrideWith((ref) async => testPaywallData()),
    ]));
    await openPaywall(tester);

    await tester.tap(
      find.widgetWithText(FilledButton, 'Unlock VeganKit Premium'),
    );
    await tester.pump(); // purchase() future
    await tester.pump(); // outcome handled, confetti starts
    await tester.pump(const Duration(milliseconds: 1200)); // delayed close
    await tester.pumpAndSettle();

    expect(find.byType(PaywallView), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('cancelled purchase stays open with no message', (tester) async {
    final fake = FakePurchaseService(
      initialPremium: false,
      purchaseResult: PurchaseOutcome.cancelled,
    );
    await tester.pumpWidget(harness(overrides: [
      purchaseServiceProvider.overrideWithValue(fake),
      paywallDataProvider(_variant)
          .overrideWith((ref) async => testPaywallData()),
    ]));
    await openPaywall(tester);

    await tester.tap(
      find.widgetWithText(FilledButton, 'Unlock VeganKit Premium'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(PaywallView), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('onboarding paywall X is tappable on the first frame',
      (tester) async {
    // App Review 5.6: the close button used to fade in after 2 s on the
    // onboarding/discount offers. It's now always live — no delay, no
    // reduce-motion setup needed.
    final fake = FakePurchaseService(initialPremium: false);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        purchaseServiceProvider.overrideWithValue(fake),
        paywallDataProvider(PaywallVariant.onboarding).overrideWith(
          (ref) async => testPaywallData(
            variant: PaywallVariant.onboarding,
            trialPeriodCount: 7,
            trialPeriodUnit: TrialPeriodUnit.day,
          ),
        ),
      ],
      child: MaterialApp(
        theme: VeggieTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const PaywallScreen(variant: PaywallVariant.onboarding),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await openPaywall(tester);

    // The trial paywall is up; close it right away — no waiting on a timer.
    expect(find.text('Start free trial'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('errored purchase shows the not-charged SnackBar',
      (tester) async {
    final fake = FakePurchaseService(
      initialPremium: false,
      purchaseResult: PurchaseOutcome.error,
    );
    await tester.pumpWidget(harness(overrides: [
      purchaseServiceProvider.overrideWithValue(fake),
      paywallDataProvider(_variant)
          .overrideWith((ref) async => testPaywallData()),
    ]));
    await openPaywall(tester);

    await tester.tap(
      find.widgetWithText(FilledButton, 'Unlock VeganKit Premium'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(
      find.text('Something went wrong — you were not charged.'),
      findsOneWidget,
    );
    expect(find.byType(PaywallView), findsOneWidget);
  });
}
