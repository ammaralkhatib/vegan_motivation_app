import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/db/database.dart';
import 'package:vegan_motivation_app/data/content_importer.dart';

String contentJson({int version = 1, String text1 = 'Quote one'}) {
  return json.encode({
    'version': version,
    'categories': [
      {'id': 'why_vegan', 'name': 'Why Vegan', 'emoji': '🌍', 'sortOrder': 0},
      {'id': 'facts', 'name': 'Facts', 'emoji': '📊', 'sortOrder': 1},
    ],
    'quotes': [
      {'id': 1, 'category': 'why_vegan', 'text': text1},
      {'id': 2, 'category': 'facts', 'text': 'Quote two'},
    ],
  });
}

void main() {
  late AppDatabase db;
  late ContentImporter importer;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    importer = ContentImporter(db);
  });

  tearDown(() => db.close());

  test('imports categories and quotes on first run', () async {
    final version = await importer.import(
      jsonString: contentJson(),
      lastImportedVersion: 0,
    );

    expect(version, 1);
    expect((await db.select(db.categories).get()).length, 2);
    expect((await db.select(db.quotes).get()).length, 2);
  });

  test('skips import when version is not newer', () async {
    await importer.import(jsonString: contentJson(), lastImportedVersion: 0);
    final second = await importer.import(
      jsonString: contentJson(version: 1),
      lastImportedVersion: 1,
    );
    expect(second, isNull);
  });

  test('version bump updates content but preserves user state', () async {
    await importer.import(jsonString: contentJson(), lastImportedVersion: 0);

    await db.quoteDao.setFavorite(1, true);
    await db.quoteDao.incrementShownCount(1);
    await db.quoteDao.setCategoryInMix('facts', false);

    final version = await importer.import(
      jsonString: contentJson(version: 2, text1: 'Quote one, revised'),
      lastImportedVersion: 1,
    );
    expect(version, 2);

    final quote = await db.quoteDao.getQuoteById(1);
    expect(quote!.body, 'Quote one, revised');
    expect(quote.isFavorite, isTrue);
    expect(quote.shownCount, 1);

    final facts = await (db.select(db.categories)
          ..where((c) => c.id.equals('facts')))
        .getSingle();
    expect(facts.inMix, isFalse);
  });

  test('refuses to remove the last category from the mix', () async {
    await importer.import(jsonString: contentJson(), lastImportedVersion: 0);

    expect(await db.quoteDao.setCategoryInMix('facts', false), isTrue);
    expect(await db.quoteDao.setCategoryInMix('why_vegan', false), isFalse);

    final stillInMix = await (db.select(db.categories)
          ..where((c) => c.inMix.equals(true)))
        .get();
    expect(stillInMix.length, 1);
  });

  test('real bundled asset imports and parses', () async {
    final jsonString =
        await File('assets/content/quotes_v1.json').readAsString();
    final version = await importer.import(
      jsonString: jsonString,
      lastImportedVersion: 0,
    );
    expect(version, 1);

    final quotes = await db.select(db.quotes).get();
    expect(quotes.length, greaterThanOrEqualTo(60));

    final categories = await db.select(db.categories).get();
    expect(categories.length, 6);
  });
}
