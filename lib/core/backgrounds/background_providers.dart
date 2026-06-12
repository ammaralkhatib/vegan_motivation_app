import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs/prefs_repository.dart';
import 'background_manifest.dart';

/// Loads the background manifest once from the bundled JSON. Any failure (file
/// missing, bad JSON) degrades to an empty manifest → the feed shows gradients.
final backgroundManifestProvider =
    FutureProvider<BackgroundManifest>((ref) async {
  try {
    final raw =
        await rootBundle.loadString('assets/content/backgrounds_v1.json');
    return BackgroundManifest.fromJson(
      json.decode(raw) as Map<String, dynamic>,
    );
  } catch (_) {
    return BackgroundManifest.empty;
  }
});

/// Synchronous view of the manifest for widgets — [BackgroundManifest.empty]
/// until it has loaded (and on any error).
final backgroundManifestValueProvider = Provider<BackgroundManifest>((ref) {
  return ref.watch(backgroundManifestProvider).valueOrNull ??
      BackgroundManifest.empty;
});

/// "Photo backgrounds" toggle (premium only), persisted. Default on.
class PhotoBackgroundsNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(prefsProvider).photoBackgrounds;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(prefsProvider).setPhotoBackgrounds(value);
  }
}

final photoBackgroundsProvider =
    NotifierProvider<PhotoBackgroundsNotifier, bool>(
        PhotoBackgroundsNotifier.new);
