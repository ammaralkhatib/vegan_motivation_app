import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Coverage guard for the bundled quote translations (content v4+).
///
/// Generalized across every locale present under `translations`: each must
/// cover exactly the set of quote ids (no missing, no orphans) with non-empty
/// string values. Also asserts the expected locales are present and the
/// content version has been bumped so existing users re-import.
void main() {
  late Map<String, dynamic> data;
  late Set<int> quoteIds;
  late Map<String, dynamic> translations;

  setUpAll(() async {
    final raw = await File('assets/content/quotes_v1.json').readAsString();
    data = json.decode(raw) as Map<String, dynamic>;
    quoteIds = {
      for (final q in (data['quotes'] as List)) (q as Map)['id'] as int,
    };
    translations = (data['translations'] as Map).cast<String, dynamic>();
  });

  test('content version is at least 4', () {
    expect(data['version'] as int, greaterThanOrEqualTo(4));
  });

  test('expected locales are present', () {
    expect(translations.keys, containsAll(<String>['de', 'fr']));
  });

  test('the library has 508 quotes', () {
    expect(quoteIds.length, 508);
  });

  test('every locale covers exactly the quote id set', () {
    for (final locale in translations.keys) {
      final block = (translations[locale] as Map).cast<String, dynamic>();
      final translatedIds = {for (final key in block.keys) int.parse(key)};

      final missing = quoteIds.difference(translatedIds);
      final orphans = translatedIds.difference(quoteIds);

      expect(missing, isEmpty,
          reason: 'locale "$locale" is missing translations for $missing');
      expect(orphans, isEmpty,
          reason: 'locale "$locale" has orphan ids $orphans');
      expect(translatedIds.length, quoteIds.length,
          reason: 'locale "$locale" count mismatch');
    }
  });

  test('every translation value is a non-empty string', () {
    for (final locale in translations.keys) {
      final block = (translations[locale] as Map).cast<String, dynamic>();
      for (final entry in block.entries) {
        expect(entry.value, isA<String>(),
            reason: '$locale/${entry.key} is not a string');
        expect((entry.value as String).trim(), isNotEmpty,
            reason: '$locale/${entry.key} is empty');
      }
    }
  });
}
