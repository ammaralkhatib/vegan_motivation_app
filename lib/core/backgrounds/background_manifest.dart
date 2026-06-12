/// Maps quote categories to bundled background image files.
///
/// Convention: `assets/images/backgrounds/<categoryId>/<filename>`, where the
/// manifest lists just the filenames per category. A versioned JSON manifest
/// (`assets/content/backgrounds_v1.json`) is the single source of truth, so a
/// future move to CDN-hosted packs only changes where the manifest comes from —
/// the rendering code is unaffected.
class BackgroundManifest {
  const BackgroundManifest({required this.version, required this.byCategory});

  final int version;

  /// Category id → list of image filenames (e.g. `why_vegan_01.webp`).
  final Map<String, List<String>> byCategory;

  /// Root asset directory for background packs.
  static const assetDir = 'assets/images/backgrounds';

  /// Empty manifest — the safe fallback when nothing loads or no images exist.
  static const empty = BackgroundManifest(version: 1, byCategory: {});

  factory BackgroundManifest.fromJson(Map<String, dynamic> json) {
    final cats = (json['categories'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final byCategory = <String, List<String>>{
      for (final entry in cats.entries)
        entry.key: [
          for (final f in (entry.value as List? ?? const []))
            f as String,
        ],
    };
    return BackgroundManifest(
      version: (json['version'] as num?)?.toInt() ?? 1,
      byCategory: byCategory,
    );
  }

  /// Full asset paths for a category, e.g.
  /// `assets/images/backgrounds/why_vegan/why_vegan_01.webp`. Empty when the
  /// category is missing or has no images.
  List<String> pathsForCategory(String categoryId) {
    final files = byCategory[categoryId];
    if (files == null || files.isEmpty) return const [];
    return [for (final f in files) '$assetDir/$categoryId/$f'];
  }

  /// Deterministic image for a quote — the same quote always gets the same
  /// picture. Returns null when the category has no images.
  String? pathForQuote(String categoryId, int quoteId) {
    final paths = pathsForCategory(categoryId);
    if (paths.isEmpty) return null;
    return paths[quoteId % paths.length];
  }
}
