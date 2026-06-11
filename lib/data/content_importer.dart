import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/db/database.dart';

/// Imports the bundled content JSON into the database.
///
/// Versioned and idempotent: runs only when the asset's `version` is newer
/// than the last imported version. Re-imports update quote text/category but
/// never touch user state (favorites, shownCount, category mix).
class ContentImporter {
  ContentImporter(this._db);

  final AppDatabase _db;

  /// Returns the imported content version, or null if already up to date.
  Future<int?> import({
    required String jsonString,
    required int lastImportedVersion,
  }) async {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final version = data['version'] as int;
    if (version <= lastImportedVersion) return null;

    final categoryList = (data['categories'] as List).cast<Map<String, dynamic>>();
    final quoteList = (data['quotes'] as List).cast<Map<String, dynamic>>();

    await _db.transaction(() async {
      for (final c in categoryList) {
        await _db.into(_db.categories).insert(
              CategoriesCompanion.insert(
                id: c['id'] as String,
                name: c['name'] as String,
                emoji: c['emoji'] as String,
                sortOrder: c['sortOrder'] as int,
              ),
              onConflict: DoUpdate(
                // Content fields only — preserves the user's inMix choice.
                (old) => CategoriesCompanion(
                  name: Value(c['name'] as String),
                  emoji: Value(c['emoji'] as String),
                  sortOrder: Value(c['sortOrder'] as int),
                ),
              ),
            );
      }
      for (final q in quoteList) {
        await _db.into(_db.quotes).insert(
              QuotesCompanion.insert(
                id: Value(q['id'] as int),
                body: q['text'] as String,
                author: Value(q['author'] as String?),
                categoryId: q['category'] as String,
              ),
              onConflict: DoUpdate(
                // Preserves isFavorite / favoritedAt / shownCount.
                (old) => QuotesCompanion(
                  body: Value(q['text'] as String),
                  author: Value(q['author'] as String?),
                  categoryId: Value(q['category'] as String),
                ),
              ),
            );
      }
    });

    return version;
  }
}
