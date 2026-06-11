import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/db/database.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/data/content_importer.dart';
import 'package:vegan_motivation_app/features/quotes/feed_screen.dart';

import 'helpers.dart';

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

Widget app(AppDatabase db) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      theme: VeggieTheme.light(),
      home: const FeedScreen(),
    ),
  );
}

void main() {
  testWidgets('feed renders quote with category chip', (tester) async {
    final db = await seededDb();
    addTearDown(db.close);

    await tester.pumpWidget(app(db));
    await tester.pumpAndSettle();

    expect(find.text('Single test quote'), findsOneWidget);
    expect(find.textContaining('Why Vegan'), findsOneWidget);

    await unmountAndFlush(tester);
  });

  testWidgets('heart toggle persists favorite to the database',
      (tester) async {
    final db = await seededDb();
    addTearDown(db.close);

    await tester.pumpWidget(app(db));
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
