import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/backgrounds/background_manifest.dart';

BackgroundManifest parse(String raw) =>
    BackgroundManifest.fromJson(json.decode(raw) as Map<String, dynamic>);

void main() {
  group('BackgroundManifest.fromJson', () {
    test('reads category lists and builds full asset paths', () {
      final m = parse('''
        {"version": 1, "categories": {"why_vegan": ["why_vegan_01.webp"]}}
      ''');

      expect(m.version, 1);
      expect(m.pathsForCategory('why_vegan'),
          ['assets/images/backgrounds/why_vegan/why_vegan_01.webp']);
    });

    test('empty and missing category lists yield no paths', () {
      final m = parse('{"version": 1, "categories": {"quick_tips": []}}');

      expect(m.pathsForCategory('quick_tips'), isEmpty);
      expect(m.pathsForCategory('facts'), isEmpty); // missing key
    });

    test('tolerates a missing categories block', () {
      final m = parse('{"version": 2}');
      expect(m.version, 2);
      expect(m.pathsForCategory('why_vegan'), isEmpty);
    });

    test('the empty constant has no images', () {
      expect(BackgroundManifest.empty.pathsForCategory('why_vegan'), isEmpty);
    });
  });

  group('deterministic selection', () {
    final m = parse('''
      {"version": 1, "categories": {
        "why_vegan": ["why_vegan_01.webp", "why_vegan_02.webp", "why_vegan_03.webp"]
      }}
    ''');

    test('same quote id always maps to the same path', () {
      final a = m.pathForQuote('why_vegan', 7);
      final b = m.pathForQuote('why_vegan', 7);
      expect(a, b);
      // id % length → 7 % 3 = 1 → second image.
      expect(a, 'assets/images/backgrounds/why_vegan/why_vegan_02.webp');
    });

    test('different ids cycle through the pack by modulo', () {
      expect(m.pathForQuote('why_vegan', 0),
          'assets/images/backgrounds/why_vegan/why_vegan_01.webp');
      expect(m.pathForQuote('why_vegan', 3),
          'assets/images/backgrounds/why_vegan/why_vegan_01.webp');
    });

    test('a category with no images returns null', () {
      expect(m.pathForQuote('facts', 1), isNull);
    });
  });
}
