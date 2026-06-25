import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegan_motivation_app/core/prefs/prefs_repository.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_providers.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_service.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/features/settings/settings_screen.dart';
import 'package:vegan_motivation_app/l10n/app_localizations.dart';

import 'support/fake_purchase_service.dart';

Future<Widget> settingsApp({
  required bool premium,
  SubscriptionDetails? subscriptionDetails,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = PrefsRepository(await SharedPreferences.getInstance());
  return ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      purchaseServiceProvider.overrideWithValue(
        FakePurchaseService(
          initialPremium: premium,
          subscriptionDetails: subscriptionDetails,
        ),
      ),
    ],
    child: MaterialApp(
      theme: VeggieTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('free user sees the Stay Vegan Premium row', (tester) async {
    await tester.pumpWidget(await settingsApp(premium: false));
    await tester.pumpAndSettle();

    expect(find.text('Stay Vegan Premium'), findsOneWidget);
  });

  testWidgets('premium user sees the Subscription card, not the upsell', (
    tester,
  ) async {
    await tester.pumpWidget(
      await settingsApp(
        premium: true,
        subscriptionDetails: SubscriptionDetails(
          willRenew: true,
          expirationDate: DateTime(2027, 6, 15),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The upsell / restore card is gone.
    expect(find.text('Stay Vegan Premium'), findsNothing);
    expect(find.text('Restore purchases'), findsNothing);
    // The subscription card is shown with its manage button.
    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('Manage subscription'), findsOneWidget);
  });

  testWidgets('premium user with no details still sees Active, no crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      await settingsApp(premium: true, subscriptionDetails: null),
    );
    await tester.pumpAndSettle();

    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Manage subscription'), findsOneWidget);
  });
}
