import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active language code (e.g. 'en', 'de') used to resolve quote display text.
///
/// Defaults to the device locale and is kept in sync by the app root with the
/// resolved UI locale (see `VeggieApp`). Quote text lives in the DB per
/// language, so switching language just re-resolves on read — no re-import and
/// no reinstall. Background paths (widget refresh, notifications) read the
/// device locale directly via `PlatformDispatcher` instead of this provider.
final localeCodeProvider = StateProvider<String>(
  (ref) => PlatformDispatcher.instance.locale.languageCode,
);
