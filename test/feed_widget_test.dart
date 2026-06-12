import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegan_motivation_app/core/backgrounds/background_manifest.dart';
import 'package:vegan_motivation_app/core/backgrounds/background_providers.dart';
import 'package:vegan_motivation_app/core/db/database.dart';
import 'package:vegan_motivation_app/core/prefs/prefs_repository.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_providers.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/data/content_importer.dart';
import 'package:vegan_motivation_app/features/quotes/feed_screen.dart';

import 'helpers.dart';
import 'support/fake_purchase_service.dart';

Future<AppDatabase> seededDb() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await ContentImporter(db).import(
    jsonString: json.encode({
      'version': 1,
      'categories': [
        {'id': 'why_vegan', 'name': 'Why Vegan', 'emoji': '🌍', 'sortOrder': 0},
      ],
      'quotes': [
        {'id': 1, 'category': 'why_vegan', 'text': 'Single test quote'},
      ],
    }),
    lastImportedVersion: 0,
  );
  return db;
}

Future<Widget> app(AppDatabase db) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = PrefsRepository(await SharedPreferences.getInstance());
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      prefsProvider.overrideWithValue(prefs),
      // The seeded quote is 'why_vegan' (a free category); premium keeps the
      // existing assertions independent of the gate.
      purchaseServiceProvider
          .overrideWithValue(FakePurchaseService(initialPremium: true)),
      // No background images → the feed stays on its gradient.
      backgroundManifestValueProvider
          .overrideWithValue(BackgroundManifest.empty),
    ],
    child: MaterialApp(
      theme: VeggieTheme.light(),
      home: const FeedScreen(),
    ),
  );
}

void main() {
  testWidgets('feed renders quote with category chip', (tester) async {
    disableCritterAnimations(tester);
    final db = await seededDb();
    addTearDown(db.close);

    await tester.pumpWidget(await app(db));
    await tester.pumpAndSettle();

    expect(find.text('Single test quote'), findsOneWidget);
    expect(find.textContaining('Why Vegan'), findsOneWidget);

    await unmountAndFlush(tester);
  });

  testWidgets('heart toggle persists favorite to the database',
      (tester) async {
    disableCritterAnimations(tester);
    final db = await seededDb();
    addTearDown(db.close);

    await tester.pumpWidget(await app(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.favorite_outline));
    await tester.pumpAndSettle();

    final quote = await db.quoteDao.getQuoteById(1);
    expect(quote!.isFavorite, isTrue);

    // Filled heart now shown; tapping again unfavorites.
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();
    expect((await db.quoteDao.getQuoteById(1))!.isFavorite, isFalse);

    await unmountAndFlush(tester);
  });
}
