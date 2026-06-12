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
import 'package:vegan_motivation_app/l10n/app_localizations.dart';
import 'package:vegan_motivation_app/core/critters/animated_critter.dart';
import 'package:vegan_motivation_app/data/content_importer.dart';
import 'package:vegan_motivation_app/features/quotes/quote_card.dart';

import 'helpers.dart';
import 'support/fake_purchase_service.dart';

const _photoKey = Key('quoteCardPhoto');
const _quoteText = 'Compassion on a plate';

final _withImages = BackgroundManifest(version: 1, byCategory: const {
  'why_vegan': ['why_vegan_01.webp'],
});

Future<AppDatabase> seededDb() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await ContentImporter(db).import(
    jsonString: json.encode({
      'version': 1,
      'categories': [
        {'id': 'why_vegan', 'name': 'Why Vegan', 'emoji': '🌍', 'sortOrder': 0},
      ],
      'quotes': [
        {'id': 1, 'category': 'why_vegan', 'text': _quoteText},
      ],
    }),
    lastImportedVersion: 0,
  );
  return db;
}

Future<Widget> card({
  required AppDatabase db,
  required bool premium,
  required bool photoOn,
  required BackgroundManifest manifest,
}) async {
  SharedPreferences.setMockInitialValues({'photoBackgrounds': photoOn});
  final prefs = PrefsRepository(await SharedPreferences.getInstance());
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      prefsProvider.overrideWithValue(prefs),
      purchaseServiceProvider
          .overrideWithValue(FakePurchaseService(initialPremium: premium)),
      backgroundManifestValueProvider.overrideWithValue(manifest),
    ],
    child: MaterialApp(
      theme: VeggieTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: QuoteCard(quoteId: 1)),
    ),
  );
}

void main() {
  testWidgets('premium + toggle on + images → photo background, light text',
      (tester) async {
    disableCritterAnimations(tester);
    final db = await seededDb();
    addTearDown(db.close);

    await tester.pumpWidget(await card(
      db: db,
      premium: true,
      photoOn: true,
      manifest: _withImages,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(_photoKey), findsOneWidget);
    final body = tester.widget<Text>(find.text(_quoteText));
    expect(body.style?.color, Colors.white);

    await unmountAndFlush(tester);
  });

  testWidgets('free user never gets a photo (gradient)', (tester) async {
    disableCritterAnimations(tester);
    final db = await seededDb();
    addTearDown(db.close);

    await tester.pumpWidget(await card(
      db: db,
      premium: false,
      photoOn: true,
      manifest: _withImages,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(_photoKey), findsNothing);
    // Free users keep the normal theme text colour (not the photo white).
    expect(tester.widget<Text>(find.text(_quoteText)).style?.color,
        isNot(Colors.white));

    await unmountAndFlush(tester);
  });

  testWidgets('premium but toggle off → gradient', (tester) async {
    disableCritterAnimations(tester);
    final db = await seededDb();
    addTearDown(db.close);

    await tester.pumpWidget(await card(
      db: db,
      premium: true,
      photoOn: false,
      manifest: _withImages,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(_photoKey), findsNothing);

    await unmountAndFlush(tester);
  });

  testWidgets('photo card hides the critter; gradient card keeps it + no shadow',
      (tester) async {
    disableCritterAnimations(tester);
    final db = await seededDb();
    addTearDown(db.close);

    // Photo card: no critter, and the quote text carries a shadow.
    await tester.pumpWidget(await card(
      db: db,
      premium: true,
      photoOn: true,
      manifest: _withImages,
    ));
    await tester.pumpAndSettle();
    expect(find.byType(AnimatedCritter), findsNothing);
    expect(tester.widget<Text>(find.text(_quoteText)).style?.shadows,
        isNotEmpty);
    await unmountAndFlush(tester);

    // Gradient card: critter present, and no shadow on the text.
    await tester.pumpWidget(await card(
      db: db,
      premium: true,
      photoOn: false,
      manifest: _withImages,
    ));
    await tester.pumpAndSettle();
    expect(find.byType(AnimatedCritter), findsOneWidget);
    expect(tester.widget<Text>(find.text(_quoteText)).style?.shadows, isNull);
    await unmountAndFlush(tester);
  });

  testWidgets('premium + toggle on but no images → gradient', (tester) async {
    disableCritterAnimations(tester);
    final db = await seededDb();
    addTearDown(db.close);

    await tester.pumpWidget(await card(
      db: db,
      premium: true,
      photoOn: true,
      manifest: BackgroundManifest.empty,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(_photoKey), findsNothing);

    await unmountAndFlush(tester);
  });
}
