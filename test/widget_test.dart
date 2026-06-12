import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegan_motivation_app/app/app.dart';
import 'package:vegan_motivation_app/core/prefs/prefs_repository.dart';
import 'package:vegan_motivation_app/features/explore/explore_screen.dart';
import 'package:vegan_motivation_app/features/explore/favorites_screen.dart';
import 'package:vegan_motivation_app/features/habits/habits_screen.dart';

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
  testWidgets('onboarded users land on the full-screen feed with four '
      'corner buttons', (tester) async {
    disableCritterAnimations(tester);
    await tester.pumpWidget(await appWith(onboarded: true));
    await tester.pumpAndSettle();

    // One round button per corner, found by its tooltip/semantics label.
    expect(find.byTooltip('Journey'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.byTooltip('Habits'), findsOneWidget);
    expect(find.byTooltip('Explore'), findsOneWidget);

    await unmountAndFlush(tester);
  });

  testWidgets('a corner button opens its screen as a sheet with a close '
      'button that returns to the feed', (tester) async {
    disableCritterAnimations(tester);
    await tester.pumpWidget(await appWith(onboarded: true));
    await tester.pumpAndSettle();

    // Tapping the Habits corner button slides HabitsScreen up.
    await tester.tap(find.byTooltip('Habits'));
    await tester.pumpAndSettle();
    expect(find.byType(HabitsScreen), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    // The X closes it and lands back on the feed.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(HabitsScreen), findsNothing);
    expect(find.byTooltip('Habits'), findsOneWidget);

    await unmountAndFlush(tester);
  });

  testWidgets('Explore → Favorites → back → X still returns to the feed '
      '(no navigation dead end)', (tester) async {
    disableCritterAnimations(tester);
    await tester.pumpWidget(await appWith(onboarded: true));
    await tester.pumpAndSettle();

    // Feed → Explore sheet.
    await tester.tap(find.byTooltip('Explore'));
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);

    // Explore → Favorites (pushed, so /today stays underneath).
    await tester.tap(find.byTooltip('Favorites'));
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesScreen), findsOneWidget);

    // Back to Explore.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesScreen), findsNothing);
    expect(find.byType(ExploreScreen), findsOneWidget);

    // The X is not a dead end any more — it lands back on the feed.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsNothing);
    expect(find.byTooltip('Explore'), findsOneWidget);

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
