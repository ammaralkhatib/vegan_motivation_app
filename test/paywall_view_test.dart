import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_data.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_screen.dart';
import 'package:vegan_motivation_app/l10n/app_localizations.dart';

import 'support/paywall_fixtures.dart';

Widget host(PaywallData data) => MaterialApp(
      theme: VeggieTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: PaywallView(data: data)),
    );

void main() {
  testWidgets('onboarding variant shows trial line and trial CTA',
      (tester) async {
    await tester.pumpWidget(host(testPaywallData(
      variant: PaywallVariant.onboarding,
      priceString: r'$49.99',
      trialPeriodCount: 7,
      trialPeriodUnit: TrialPeriodUnit.day,
    )));

    expect(find.text('Start free trial'), findsOneWidget);
    expect(find.text(r'7 days free, then $49.99/year'), findsOneWidget);
    // No discount chrome on the trial paywall.
    expect(find.text('50% OFF'), findsNothing);
  });

  testWidgets('defaultOffer shows 50% badge + crossed-out anchor',
      (tester) async {
    await tester.pumpWidget(host(testPaywallData(
      variant: PaywallVariant.defaultOffer,
      priceString: r'$24.99',
      anchorPriceString: r'$49.99',
    )));

    expect(find.text('50% OFF'), findsOneWidget);
    expect(find.text(r'$49.99'), findsOneWidget); // the anchor
    expect(find.text('Unlock Veggie Premium'), findsWidgets);
  });

  testWidgets('discount shows the one-time badge and urgency copy',
      (tester) async {
    await tester.pumpWidget(host(testPaywallData(
      variant: PaywallVariant.discount,
      priceString: r'$9.99',
      anchorPriceString: r'$49.99',
    )));

    expect(find.text('80% OFF — one-time offer'), findsOneWidget);
    expect(find.text("This offer won't come back."), findsOneWidget);
    expect(find.text('Claim my offer'), findsOneWidget);
  });

  testWidgets('always shows benefits, restore and the cancel footnote',
      (tester) async {
    await tester.pumpWidget(host(testPaywallData()));

    expect(find.text('All 6 quote categories'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);
    expect(
      find.text('Cancel anytime in your store settings.'),
      findsOneWidget,
    );
  });
}
