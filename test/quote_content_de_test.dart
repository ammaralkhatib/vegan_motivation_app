import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Coverage guard for the bundled German quote translations (content v3).
///
/// Asserts the asset's `translations.de` block covers exactly the set of quote
/// ids — no missing, no orphans — with non-empty values, and that the content
/// version has been bumped so existing users re-import.
void main() {
  late Map<String, dynamic> data;

  setUpAll(() async {
    final raw = await File('assets/content/quotes_v1.json').readAsString();
    data = json.decode(raw) as Map<String, dynamic>;
  });

  test('content version is at least 3', () {
    expect(data['version'] as int, greaterThanOrEqualTo(3));
  });

  test('translations.de covers exactly the quote id set', () {
    final quoteIds = {
      for (final q in (data['quotes'] as List)) (q as Map)['id'] as int,
    };

    final de = ((data['translations'] as Map)['de'] as Map)
        .cast<String, dynamic>();
    final translatedIds = {for (final key in de.keys) int.parse(key)};

    final missing = quoteIds.difference(translatedIds);
    final orphans = translatedIds.difference(quoteIds);

    expect(missing, isEmpty, reason: 'quotes missing a German translation');
    expect(orphans, isEmpty, reason: 'translations with no matching quote');
    // Redundant with the two above, but pins the headline number.
    expect(translatedIds.length, quoteIds.length);
    expect(quoteIds.length, 508);
  });

  test('every German translation is a non-empty string', () {
    final de = ((data['translations'] as Map)['de'] as Map)
        .cast<String, dynamic>();
    for (final entry in de.entries) {
      expect(entry.value, isA<String>(),
          reason: 'id ${entry.key} is not a string');
      expect((entry.value as String).trim(), isNotEmpty,
          reason: 'id ${entry.key} is empty');
    }
  });
}
