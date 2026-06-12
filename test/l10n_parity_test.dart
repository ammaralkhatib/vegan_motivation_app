import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/l10n/app_localizations.dart';

/// Guards every future string addition: all locale ARB files must carry the
/// same message keys, and each key must use the same placeholder set across
/// locales (reordering is fine, omitting/adding a placeholder is not).
const _locales = ['en', 'de', 'fr', 'es'];

Map<String, String> _messages(String locale) {
  final raw = File('lib/l10n/app_$locale.arb').readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return {
    for (final e in json.entries)
      if (!e.key.startsWith('@')) e.key: e.value as String,
  };
}

/// Top-level ICU argument names in a message: `{name}` or `{name, plural, …}`.
/// Excludes plural literals like `{1 day}` (starts with a digit) and the
/// plural/select keywords (they follow the argument name, never precede `{`).
Set<String> _placeholders(String value) => RegExp(r'\{\s*([A-Za-z][A-Za-z0-9_]*)\s*[,}]')
    .allMatches(value)
    .map((m) => m.group(1)!)
    .toSet();

void main() {
  final byLocale = {for (final l in _locales) l: _messages(l)};
  final enKeys = byLocale['en']!.keys.toSet();

  group('ARB parity', () {
    for (final locale in _locales.where((l) => l != 'en')) {
      test('$locale has exactly the same keys as en', () {
        final keys = byLocale[locale]!.keys.toSet();
        expect(keys.difference(enKeys), isEmpty,
            reason: '$locale has extra keys');
        expect(enKeys.difference(keys), isEmpty,
            reason: '$locale is missing keys');
      });

      test('$locale uses the same placeholders as en for every key', () {
        for (final key in enKeys) {
          final enPlaceholders = _placeholders(byLocale['en']![key]!);
          final locPlaceholders = _placeholders(byLocale[locale]![key]!);
          expect(locPlaceholders, enPlaceholders,
              reason: 'placeholder mismatch for "$key" in $locale');
        }
      });
    }
  });

  testWidgets('renders German strings under Locale("de")', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l = AppLocalizations.of(context);
            return Scaffold(
              body: Column(
                children: [Text(l.settingsTitle), Text(l.shellTabToday)],
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Heute'), findsOneWidget);
  });
}
