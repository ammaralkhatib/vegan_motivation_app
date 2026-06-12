# Localize shell, share, notifications + preset habit names

## Goal
Final string-migration batch: app shell tabs, share sheet, notification texts,
and preset habit names move to `lib/l10n/app_en.arb` (pattern from 010–012).
After this, the whole UI reads from ARB and we're ready to add German, French,
Spanish in the next prompt. English stays byte-identical.

## Scope
- In: `lib/app/shell.dart`, `lib/features/quotes/share_service.dart`,
  `lib/core/notifications/**`, `lib/data/preset_habits.dart` + the habit
  preset picker UI, `lib/main.dart` (check for user-visible strings),
  `lib/core/theme/app_theme.dart` (had a grep hit — migrate only if
  user-visible), `lib/l10n/app_en.arb`, test harnesses as needed.
- Out: everything already migrated (010–012). Quote content DB untouched
  (locked). Android/iOS native manifest strings (app name) untouched.

## Requirements
1. **Shell** — the 4 bottom-tab labels (`Today`, `Habits`, `Explore`,
   `Journey`) → ARB keys `shellTab…`. The tab list is likely a top-level const;
   apply the 011 Requirement-5 pattern (ids/icons in const, label resolved with
   context).
2. **Share sheet** (`share_service.dart`) — title, palette chip labels
   (Cream/Forest/Coral), Share button, share `subject` line → ARB keys
   `share…`.
3. **Notifications** (`notification_service.dart`) — channel name/description,
   the `Veggie 🌱` title (brand stays, but any surrounding words move), trial
   reminder body, and any other user-facing notification text → ARB keys
   `notification…`. The service has no BuildContext: pass the resolved
   `AppLocalizations` (or the needed strings) in from call sites that have
   context, or load `AppLocalizations` by locale lookup
   (`lookupAppLocalizations(PlatformDispatcher.instance.locale)`) — pick the
   cleaner option for this codebase and explain in the report.
   Note in the report the known limitation: already-scheduled notifications
   keep their language until rescheduled. If notifications are already
   rescheduled on app launch, say so and we're done; if not, do NOT add new
   rescheduling logic in this prompt — just record it as an open item.
4. **Preset habit names** (`preset_habits.dart`) — presets carry a stable `id`
   + emoji; English `name` moves to ARB (`habitsPreset…`). The preset picker
   shows the localized name, and when the user picks one, the **localized**
   name at pick time is saved as the habit name (saved habits are user data —
   they keep whatever name they were created with; no migration of existing
   habits).
5. **`main.dart` / `app_theme.dart`** — migrate only genuinely user-visible
   strings; debug prints and font/family names stay.
6. After migration, run a final sweep:
   `grep -rnE "Text\('[A-Za-z]|label: 'A-Za-z]|title: '[A-Za-z]|tooltip: '" lib/`
   and list any remaining intentional literals (brand, emoji, numbers) in the
   report so we have a closing inventory.

## Constraints
- Locked decisions hold (offline-first, Riverpod/drift/go_router, home_widget
  <0.8, versioned content imports, UI-strings-only l10n).
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries);
  never weaken tests.
- No behavior change beyond text source; notification scheduling logic
  untouched except for how strings are obtained.
- Android notification channel id must NOT change (channels are immutable once
  created) — only the visible channel name/description strings move.

## Verify
- `flutter analyze` + `flutter test` clean/green.
- The Requirement-6 sweep output recorded in the report.
- Record the number of new ARB keys.

## Commit & push
- Conventional Commit, e.g. `feat(l10n): migrate shell, share, notifications and preset strings`.
- Body includes `Prompt: claude-prompts/2026-06-12/013-l10n-shell-share-notifications-presets.md`.
- Push to origin/main; on failure, stop and report (never force).

## Report
- Write `claude-reports/2026-06-12/013-l10n-shell-share-notifications-presets.md`
  from TEMPLATE.md. Record the notification-locale decision, the preset
  pick-time-naming decision, the closing literal inventory, key count,
  verification output, commit SHA, push result, open items.
