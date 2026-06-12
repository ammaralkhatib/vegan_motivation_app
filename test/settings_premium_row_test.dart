import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegan_motivation_app/core/prefs/prefs_repository.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_providers.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/features/settings/settings_screen.dart';

import 'support/fake_purchase_service.dart';

Future<Widget> settingsApp({required bool premium}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = PrefsRepository(await SharedPreferences.getInstance());
  return ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      purchaseServiceProvider
          .overrideWithValue(FakePurchaseService(initialPremium: premium)),
    ],
    child: MaterialApp(
      theme: VeggieTheme.light(),
      home: const SettingsScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('free user sees the Veggie Premium row', (tester) async {
    await tester.pumpWidget(await settingsApp(premium: false));
    await tester.pumpAndSettle();

    expect(find.text('Veggie Premium'), findsOneWidget);
  });

  testWidgets('premium user does not see the Veggie Premium row',
      (tester) async {
    await tester.pumpWidget(await settingsApp(premium: true));
    await tester.pumpAndSettle();

    expect(find.text('Veggie Premium'), findsNothing);
  });
}
