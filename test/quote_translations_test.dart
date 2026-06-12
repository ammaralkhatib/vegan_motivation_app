import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/db/database.dart';
import 'package:vegan_motivation_app/data/content_importer.dart';

/// Small inline fixture: two quotes in one category; quote 1 has a German
/// translation, quote 2 does not.
String contentJson({
  int version = 1,
  String text1 = 'Compassion',
  Map<String, Map<String, String>>? translations,
}) {
  return json.encode({
    'version': version,
    'categories': [
      {'id': 'why_vegan', 'name': 'Why Vegan', 'emoji': '🌍', 'sortOrder': 0},
    ],
    'quotes': [
      {'id': 1, 'category': 'why_vegan', 'text': text1},
      {'id': 2, 'category': 'why_vegan', 'text': 'Kindness'},
    ],
    'translations': ?translations,
  });
}

const _withDe = {
  'de': {'1': 'Mitgefühl'},
};

void main() {
  group('content importer — translations', () {
    late AppDatabase db;
    late ContentImporter importer;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      importer = ContentImporter(db);
    });
    tearDown(() => db.close());

    test('imports the translations block', () async {
      await importer.import(
        jsonString: contentJson(translations: _withDe),
        lastImportedVersion: 0,
      );

      final rows = await db.select(db.quoteTranslations).get();
      expect(rows, hasLength(1));
      expect(rows.single.quoteId, 1);
      expect(rows.single.locale, 'de');
      expect(rows.single.body, 'Mitgefühl');
    });

    test('a missing translations block is fine', () async {
      await importer.import(
        jsonString: contentJson(),
        lastImportedVersion: 0,
      );
      expect(await db.select(db.quoteTranslations).get(), isEmpty);
    });

    test('re-import refreshes translation text but preserves user state',
        () async {
      await importer.import(
        jsonString: contentJson(translations: _withDe),
        lastImportedVersion: 0,
      );
      await db.quoteDao.setFavorite(1, true);
      await db.quoteDao.incrementShownCount(1);

      final version = await importer.import(
        jsonString: contentJson(
          version: 2,
          translations: {
            'de': {'1': 'Mitgefühl (neu)'},
          },
        ),
        lastImportedVersion: 1,
      );
      expect(version, 2);

      // User state on the quote row survives untouched.
      final quote = await db.quoteDao.getQuoteById(1);
      expect(quote!.isFavorite, isTrue);
      expect(quote.shownCount, 1);

      // Translation text was refreshed (upsert), not duplicated.
      final rows = await db.select(db.quoteTranslations).get();
      expect(rows, hasLength(1));
      expect(rows.single.body, 'Mitgefühl (neu)');
    });
  });

  group('DAO — locale-aware resolution', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await ContentImporter(db).import(
        jsonString: contentJson(translations: _withDe),
        lastImportedVersion: 0,
      );
    });
    tearDown(() => db.close());

    test('locale de → German text where present, English fallback otherwise',
        () async {
      final list = await db.quoteDao
          .watchQuotesByCategory('why_vegan', locale: 'de')
          .first;
      final byId = {for (final q in list) q.id: q.body};
      expect(byId[1], 'Mitgefühl'); // translated
      expect(byId[2], 'Kindness'); // no de translation → English
    });

    test('English locale reads the base body (unchanged)', () async {
      final en =
          await db.quoteDao.watchQuotesByCategory('why_vegan', locale: 'en').first;
      expect({for (final q in en) q.id: q.body}, {1: 'Compassion', 2: 'Kindness'});

      // null locale behaves the same as English.
      final none = await db.quoteDao.watchQuotesByCategory('why_vegan').first;
      expect(
          {for (final q in none) q.id: q.body}, {1: 'Compassion', 2: 'Kindness'});
    });

    test('getQuoteById and getQuotesInMix resolve too', () async {
      final q1 = await db.quoteDao.getQuoteById(1, locale: 'de');
      expect(q1!.body, 'Mitgefühl');

      final mix = await db.quoteDao.getQuotesInMix(locale: 'de');
      expect(mix.firstWhere((q) => q.id == 1).body, 'Mitgefühl');
      expect(mix.firstWhere((q) => q.id == 2).body, 'Kindness');
    });

    test('a locale with no translations at all falls back fully to English',
        () async {
      final fr = await db.quoteDao
          .watchQuotesByCategory('why_vegan', locale: 'fr')
          .first;
      expect(
          {for (final q in fr) q.id: q.body}, {1: 'Compassion', 2: 'Kindness'});
    });
  });

  test('v1 → v2 upgrades in place: adds translations, keeps user data',
      () async {
    final dir = await Directory.systemTemp.createTemp('veggie_migr');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    // First open creates the full v2 schema; seed content + a favorite.
    var db = AppDatabase.forTesting(NativeDatabase(file));
    await ContentImporter(db).import(
      jsonString: contentJson(),
      lastImportedVersion: 0,
    );
    await db.quoteDao.setFavorite(1, true);

    // Roll the database back to a v1 state: drop the new table, reset version.
    await db.customStatement('DROP TABLE quote_translations');
    await db.customStatement('PRAGMA user_version = 1');
    await db.close();

    // Reopen: drift sees user_version 1 < schemaVersion 2 → runs onUpgrade.
    db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    // User data survived the migration.
    final quote = await db.quoteDao.getQuoteById(1);
    expect(quote!.isFavorite, isTrue);

    // The recreated table works end-to-end with locale resolution.
    await db.into(db.quoteTranslations).insert(
          QuoteTranslationsCompanion.insert(
              quoteId: 1, locale: 'de', body: 'Mitgefühl'),
        );
    final resolved = await db.quoteDao.getQuoteById(1, locale: 'de');
    expect(resolved!.body, 'Mitgefühl');
  });
}
