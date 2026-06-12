import '../../l10n/app_localizations.dart';

/// Localized display name for a quote category id. Category ids and emojis live
/// in the DB/content JSON (untouched); only the visible name is localized here.
/// Unknown ids fall back to the raw DB [name] so future content can't crash the
/// UI (CLAUDE.md §1 — UI-strings-only l10n).
String categoryDisplayName(AppLocalizations l, String id, String name) =>
    switch (id) {
      'why_vegan' => l.categoryNameWhyVegan,
      'quick_tips' => l.categoryNameQuickTips,
      'youre_awesome' => l.categoryNameYoureAwesome,
      'facts' => l.categoryNameFacts,
      'staying_strong' => l.categoryNameStayingStrong,
      'milestones' => l.categoryNameMilestones,
      _ => name,
    };
