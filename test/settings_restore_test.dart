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

Future<Widget> settingsApp(FakePurchaseService fake) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = PrefsRepository(await SharedPreferences.getInstance());
  return ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      purchaseServiceProvider.overrideWithValue(fake),
    ],
    child: MaterialApp(
      theme: VeggieTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsScreen(),
    ),
  );
}

Future<void> tapRestore(WidgetTester tester) async {
  await tester.tap(find.text('Restore purchases'));
  await tester.pump(); // performRestore future
  await tester.pump(const Duration(milliseconds: 700)); // SnackBar appears
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('premium user sees neither premium nor restore row',
      (tester) async {
    await tester.pumpWidget(await settingsApp(
      FakePurchaseService(initialPremium: true),
    ));
    await tester.pumpAndSettle();

    expect(find.text('VeganKit Premium'), findsNothing);
    expect(find.text('Restore purchases'), findsNothing);
  });

  testWidgets('restoring an active subscription says "Welcome back!"',
      (tester) async {
    await tester.pumpWidget(await settingsApp(
      FakePurchaseService(initialPremium: false), // restore grants premium
    ));
    await tester.pumpAndSettle();

    expect(find.text('Restore purchases'), findsOneWidget);
    await tapRestore(tester);

    expect(find.text('Welcome back!'), findsOneWidget);
  });

  testWidgets('restoring with nothing to restore says none found',
      (tester) async {
    await tester.pumpWidget(await settingsApp(
      FakePurchaseService(
        initialPremium: false,
        restoreGrantsPremium: false,
      ),
    ));
    await tester.pumpAndSettle();

    await tapRestore(tester);
    expect(find.text('No previous purchase found.'), findsOneWidget);
  });

  testWidgets('a restore error shows the friendly error message',
      (tester) async {
    await tester.pumpWidget(await settingsApp(
      FakePurchaseService(
        initialPremium: false,
        restoreResult: PurchaseOutcome.error,
        restoreGrantsPremium: false,
      ),
    ));
    await tester.pumpAndSettle();

    await tapRestore(tester);
    expect(find.text('Something went wrong — please try again.'), findsOneWidget);
  });
}
