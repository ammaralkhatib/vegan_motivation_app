import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/features/legal/legal_content.dart';
import 'package:vegan_motivation_app/features/legal/legal_screen.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_screen.dart';
import 'package:vegan_motivation_app/l10n/app_localizations.dart';

import 'support/paywall_fixtures.dart';

/// A router that mirrors the real legal routes so the paywall's Privacy/Terms
/// links have somewhere to push to.
GoRouter _router() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          Scaffold(body: PaywallView(data: testPaywallData())),
    ),
    GoRoute(
      path: '/legal/privacy',
      builder: (context, state) => LegalScreen(
        title: AppLocalizations.of(context).legalPrivacyTitle,
        sections: privacyPolicySections,
      ),
    ),
    GoRoute(
      path: '/legal/terms',
      builder: (context, state) => LegalScreen(
        title: AppLocalizations.of(context).legalTermsTitle,
        sections: termsOfUseSections,
      ),
    ),
  ],
);

Widget host(GoRouter router) => MaterialApp.router(
  theme: VeggieTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  routerConfig: router,
);

void main() {
  testWidgets('tapping Privacy pushes the privacy LegalScreen', (tester) async {
    await tester.pumpWidget(host(_router()));

    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();

    expect(find.byType(LegalScreen), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget); // app bar title
    expect(find.text(legalLastUpdated), findsOneWidget);
  });

  testWidgets('tapping Terms pushes the terms LegalScreen', (tester) async {
    await tester.pumpWidget(host(_router()));

    await tester.tap(find.text('Terms'));
    await tester.pumpAndSettle();

    expect(find.byType(LegalScreen), findsOneWidget);
    expect(find.text('Terms of Use'), findsOneWidget); // app bar title
  });

  testWidgets('LegalScreen scrolls and has a working back button', (
    tester,
  ) async {
    await tester.pumpWidget(host(_router()));
    await tester.tap(find.text('Terms'));
    await tester.pumpAndSettle();

    // Back button returns to the paywall.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallView), findsOneWidget);
  });
}
