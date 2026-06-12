import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs/prefs_repository.dart';

/// Active language code (e.g. 'en', 'de') used to resolve quote display text.
///
/// Defaults to the device locale and is kept in sync by the app root with the
/// resolved UI locale (see `VeggieApp`). Because `MaterialApp` now applies the
/// user's language override via `locale:`, the resolved UI locale already
/// reflects the override (or the system locale when none is set), so this
/// provider follows the override automatically. Quote text lives in the DB per
/// language, so switching language just re-resolves on read — no re-import and
/// no reinstall.
final localeCodeProvider = StateProvider<String>(
  (ref) => PlatformDispatcher.instance.locale.languageCode,
);

/// Resolves the effective language code for background paths (notifications,
/// home widget) which have no `BuildContext` and therefore can't read the
/// resolved UI locale. The user's [override] wins when set; otherwise we follow
/// the device locale. Unsupported codes are handled downstream (the quote DAO
/// falls back to English text, `lookupAppLocalizations` falls back to English
/// strings), so when [override] is null this returns the exact same value the
/// background paths used before — system-locale behavior stays byte-identical.
String resolveLanguageCode(String? override) =>
    override ?? PlatformDispatcher.instance.locale.languageCode;

/// User's app-language override, persisted. null = follow the device language.
class LanguageOverrideNotifier extends Notifier<String?> {
  @override
  String? build() => ref.read(prefsProvider).languageOverride;

  Future<void> set(String? code) async {
    state = code;
    await ref.read(prefsProvider).setLanguageOverride(code);
  }
}

final languageOverrideProvider =
    NotifierProvider<LanguageOverrideNotifier, String?>(
  LanguageOverrideNotifier.new,
);

/// Locale handed to `MaterialApp.router`'s `locale:`. null lets Flutter follow
/// the device language exactly as before.
final appLocaleProvider = Provider<Locale?>((ref) {
  final code = ref.watch(languageOverrideProvider);
  return code == null ? null : Locale(code);
});
