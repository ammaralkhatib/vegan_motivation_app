import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegan_motivation_app/app/app.dart';
import 'package:vegan_motivation_app/core/prefs/prefs_repository.dart';

import 'feed_widget_test.dart' show seededDb;
import 'helpers.dart';
import 'support/fake_purchase_service.dart';
import 'package:vegan_motivation_app/core/db/database.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_providers.dart';

Future<ProviderScope> appWith({required bool onboarded}) async {
  SharedPreferences.setMockInitialValues({'onboardingDone': onboarded});
  final prefs = PrefsRepository(await SharedPreferences.getInstance());
  final db = await seededDb();
  return ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
      purchaseServiceProvider
          .overrideWithValue(FakePurchaseService(initialPremium: true)),
    ],
    child: const VeggieApp(),
  );
}

void main() {
  testWidgets('onboarded users land on the shell with four tabs',
      (tester) async {
    disableCritterAnimations(tester);
    await tester.pumpWidget(await appWith(onboarded: true));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);

    await unmountAndFlush(tester);
  });

  testWidgets('fresh installs are redirected to onboarding', (tester) async {
    await tester.pumpWidget(await appWith(onboarded: false));
    await tester.pumpAndSettle();

    expect(find.text('Veggie'), findsOneWidget);
    expect(find.text('your daily dose of vegan motivation'), findsOneWidget);

    await unmountAndFlush(tester);
  });
}
