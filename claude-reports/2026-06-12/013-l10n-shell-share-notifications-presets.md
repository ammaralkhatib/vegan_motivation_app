# Localize shell, share, notifications + preset habit names

**Prompt:** `claude-prompts/2026-06-12/013-l10n-shell-share-notifications-presets.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Final string-migration batch: bottom-tab labels, the share sheet, notification
text, and preset habit names move to `lib/l10n/app_en.arb`. The whole UI now
reads from ARB — ready for German/French/Spanish next. English is byte-identical.
**20 new ARB keys.** Analyze clean, all 133 tests pass.

## Per-requirement status

1. **Shell** ✅ — `shell.dart` `_destinations` keeps icons + a stable `id` in the
   const; labels resolve per build via `_label(l, id)` → `shellTabToday/Habits/
   Explore/Journey` (011 Requirement-5 pattern).
2. **Share sheet** ✅ — `shareTitle`, `shareStyleCream/Forest/Coral`,
   `shareButton`, and the `shareSubject` line. `shareCardImage()` has no
   BuildContext, so it now takes a `subject` parameter resolved at the call site
   (`_ShareSheet`, which has context).
3. **Notifications** ✅ — see decision below.
4. **Preset habit names** ✅ — see decision below.
5. **main.dart / app_theme.dart** ✅ — nothing user-visible to migrate.
   `main.dart` only had the `'Veggie'` window title (brand) and a `debugPrint`;
   `app_theme.dart`'s grep hit was a font-family name. Both left as-is.
6. **Closing sweep** ✅ — recorded below.

## Notification-locale decision (Requirement 3)

`NotificationService` has no BuildContext and its strings live in (formerly
`const`) `NotificationDetails`. I used the **locale-lookup** option rather than
threading strings through every call site: a private `_notificationL10n()`
calls `lookupAppLocalizations(PlatformDispatcher.instance.locale)`, falling back
to `Locale('en')` for any unsupported locale (only `en` ships today). It's used
in `scheduleAll` (channel name + description) and `scheduleTrialEndReminder`
(channel name + description + trial title + body). The `'Veggie 🌱'` daily title
is brand + emoji with no surrounding words, so it stays literal. The Android
channel **id** (`daily_motivation`) is unchanged — only the visible name/
description strings moved.

**Known limitation:** already-scheduled notifications keep the language they
were scheduled in until rescheduled. Daily notifications **are** rescheduled on
every app launch and resume (`app.dart` bootstrap →
`notificationCoordinator.reschedule()`), so a language change is picked up on the
next relaunch — nothing to add. The one-shot **trial reminder** is scheduled once
at purchase time and not rescheduled; it keeps its language until it fires. Per
the prompt I did **not** add new rescheduling logic — recorded here as the only
open item.

## Preset pick-time-naming decision (Requirement 4)

`PresetHabit` now carries only `key` + `emoji` (+ `suggested`); the English
`name` moved to ARB (`habitsPreset…`), resolved by
`presetHabitName(AppLocalizations, key)`. The picker shows the localized name,
and on confirm it saves **that same localized string** as the habit name
(`dao.insertHabit(name: presetHabitName(l, preset.key), …)`). Saved habits are
user data, so they keep whatever name they were created with — no migration of
existing habits, exactly as specified.

## Closing literal inventory (Requirement 6 sweep)

```
$ grep -rnE "Text\('[A-Za-z]|label: '[A-Za-z]|title: '[A-Za-z]|tooltip: '" lib/
lib/main.dart:33:           title: 'Veggie',          # desktop window title (brand)
lib/app/app.dart:73:        title: 'Veggie',          # MaterialApp title (brand)
lib/features/onboarding/onboarding_flow.dart:291: Text('Veggie', …)  # welcome brand wordmark
```

Only the **`Veggie` brand name** remains across the whole `lib/` tree. (Not
matched by this sweep but intentionally literal elsewhere: emoji, pure
numbers/age-ranges, and `'$interpolations'` of DB/store data — quote content,
category emojis, prices.) This is the closing inventory: the UI is fully
localized apart from the brand.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.1s)

$ flutter test
All tests passed!   (133 tests)
```

New ARB keys: **20** (shell 4, share 6, notification 4, preset names 6).
`app_en.arb` now holds 309 message keys total across 010–013. Generated
`app_localizations*.dart` stay git-ignored; `generate: true` rebuilds them.

Self-correction: none — analyze and the suite were green on the first run. No
test harness needed delegates: the shell renders inside the full `VeggieApp`
(delegates since 010), and no test pumps the share sheet or notification service
directly.

## Open items (for Ammar)

- **Trial reminder language:** a one-shot reminder scheduled before a language
  change keeps its old language until it fires. Acceptable; flagged per the
  prompt, no code added.
- Click through the tab bar, a share sheet, and (on device) a notification to
  confirm text reads identical.
- **Next:** add `app_de.arb` / `app_fr.arb` / `app_es.arb` — the whole UI is now
  ARB-backed.

## Commit & push

- **Commit:** `f0dcff3` — `feat(l10n): migrate shell, share, notifications and preset strings`
- **Push:** `origin/main` — ok (`02d4458..f0dcff3`).

## Deviations from prompt

None.
