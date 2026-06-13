# Rename user-facing app name from "Veggie" to "VeganKit"

## Goal
Change the app's **display/brand name** everywhere the user can see it from
**`Veggie`** to **`VeganKit`**. Prompt 001 already renamed the *bundle identifier*
(`io.develooper.vegankit`); this is the separate, complementary change: the human-
readable name shown on the home-screen icon, in the task switcher, in onboarding,
in the paywall/settings copy, on shared quote cards, and in notifications, across
all four locales (en/de/es/fr). "Done" means a user installing the app sees
"VeganKit" — never "Veggie" — anywhere in the UI or on the OS, while all code
identifiers, the Drift DB name, store product ids, and the bundle id stay exactly
as they are. Pre-launch rename — no published listing to preserve.

## Scope
- **In — platform display names:**
  - `ios/Runner/Info.plist` — `CFBundleDisplayName` `Veggie` → `VeganKit`;
    `CFBundleName` `veggie` → `VeganKit`.
  - `android/app/src/main/AndroidManifest.xml` — `android:label="Veggie"` →
    `android:label="VeganKit"`.
  - `macos/Runner/Configs/AppInfo.xcconfig` — `PRODUCT_NAME = Veggie` →
    `PRODUCT_NAME = VeganKit`.
  - `windows/runner/Runner.rc` — `ProductName` value `vegan_motivation_app` →
    `VeganKit` (display string only). Leave `FileDescription`, `InternalName`,
    and `OriginalFilename` untouched — those track the `.exe` name (the Dart
    package name), not the brand.
  - `pubspec.yaml` — the `description:` line: replace the leading `Veggie —` with
    `VeganKit —`. Do **not** change `name: vegan_motivation_app` (the Dart package
    name; renaming it would rewrite every import).
- **In — Android widget text:**
  - `android/app/src/main/res/layout/widget_quote.xml` — `android:text="🌱 Veggie"`
    → `🌱 VeganKit`.
- **In — localized brand strings (the source `.arb` files only):**
  - `lib/l10n/app_en.arb`, `app_de.arb`, `app_es.arb`, `app_fr.arb` — every
    occurrence of the brand word `Veggie`/`veggie` **that refers to the app**
    becomes `VeganKit`. These are the keys (same set in each locale):
    `settingsPremiumTitle`, `settingsPhotoBackgroundsSubtitleFree`,
    `settingsAbout`, `paywallOnboardingTitle`, `paywallDefaultTitle`,
    `paywallDefaultCta`, `onboardingSolutionHeadline`, `onboardingGoalsTitle`,
    `onboardingGoalsReflectionBody`, `onboardingReflectionClose`,
    `onboardingChartLegendWith`, `onboardingSocialTitle`, `onboardingSocialCta`.
    Use the canonical brand casing **`VeganKit`** even where the old string used
    lowercase `veggie` (see Decision note below). Translate nothing else — only
    swap the brand token; keep the surrounding localized wording intact.
  - After editing the `.arb` files, **regenerate** the localizations
    (`flutter gen-l10n`) so `lib/l10n/app_localizations*.dart` (gitignored) rebuild.
    Do not hand-edit the generated `.dart` files.
- **In — hardcoded brand strings in Dart (user-visible):**
  - `lib/main.dart` `title: 'Veggie'` → `'VeganKit'`.
  - `lib/app/app.dart` `title: 'Veggie'` → `'VeganKit'`.
  - `lib/features/onboarding/onboarding_flow.dart` `Text('Veggie', …)` → `'VeganKit'`.
  - `lib/features/quotes/share_card.dart` the `'Veggie'` label → `'VeganKit'`.
  - `lib/features/settings/settings_screen.dart` `applicationName: 'Veggie'` →
    `'VeganKit'`.
  - `lib/core/notifications/notification_service.dart` `appName: 'Veggie'` →
    `'VeganKit'` and the `'Veggie 🌱'` channel/notification string → `'VeganKit 🌱'`.
- **Out (do NOT touch):**
  - **Code identifiers / class & symbol names:** `VeggiePalette`, `VeggieAccents`,
    `VeggieTheme`, `VeggieApp`, and every reference to them; the
    `VeggieWidget` / `VeggieWidgetProvider` names in
    `lib/core/widgetkit/home_widget_service.dart` (`_androidProvider`,
    `_iosWidgetName`) and the matching native classes/filenames. These are
    identifiers that must stay in lock-step with native code — renaming them is a
    separate refactor, not part of an app-name change.
  - **Drift DB name:** `driftDatabase(name: 'veggie')` in `lib/core/db/database.dart`
    — changing it orphans existing user data (same rule as 001).
  - **Store product id:** `trialProductId = 'veggie_yearly_full'` in
    `lib/core/notifications/trial_reminder.dart` — must match RevenueCat/store config.
  - **Bundle identifier:** already `io.develooper.vegankit` (prompt 001) — leave it.
  - **The word "veggie" inside quote *content*** in
    `assets/content/quotes_v1.json` (e.g. "veggie scraps", "veggie skewers") — that
    means *vegetable*, not the brand. Do not touch the content JSON.
  - Internal temp filenames (`veggie_quote_<id>.png` in
    `lib/features/quotes/share_service.dart`) and code comments — not user-facing
    brand; leave them to keep the diff minimal.
  - Generated/build artifacts (`ios/Pods/**`, `**/build/**`, `.dart_tool/**`, etc.).

## Requirements
1. iOS `CFBundleDisplayName` and `CFBundleName`, Android `android:label`, macOS
   `PRODUCT_NAME`, and Windows `ProductName` all read `VeganKit`.
2. All four `.arb` files have the brand token replaced with `VeganKit` for the 13
   keys listed above, and `flutter gen-l10n` has regenerated the `.dart`
   localizations cleanly (no untranslated/placeholder errors introduced).
3. The seven Dart hardcoded brand strings and the Android widget label all read
   `VeganKit` / `🌱 VeganKit`.
4. Searching tracked source for the brand name as an app reference returns nothing
   user-facing left as "Veggie": `grep -rniE "\bveggie\b"` over
   `lib/l10n/*.arb`, `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`,
   `android/app/src/main/res/layout/widget_quote.xml`,
   `macos/Runner/Configs/AppInfo.xcconfig`, and the six Dart files in Scope > In
   returns **zero** matches. (Matches remaining in class names, `database.dart`,
   `trial_reminder.dart`, `share_service.dart`, comments, and `quotes_v1.json` are
   expected and correct — they are out of scope.)
5. No code identifier, the Drift DB name, the store product id, or the bundle id
   changed.

## Constraints
- Locked stack/decisions per CLAUDE.md §3 hold (offline-first; Riverpod/drift/
  go_router; home_widget <0.8; versioned content imports). This is a string/label
  change only — no behavior, schema, or dependency change.
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries per
  CLAUDE.md §2). Some widget/golden tests may assert on the old "Veggie" text — if
  a test fails *only* because it expected "Veggie", update the test's expectation to
  "VeganKit" (that is the intended new value); do not weaken or delete the assertion.
- Keep the diff limited to brand strings + regenerated l10n. Do not reformat files
  beyond the changed lines.

## Decision note (casing) — flag for Ammar in the report
A few onboarding strings used an all-lowercase, stylized `veggie` (e.g.
"what do you want from veggie?", "join veggie 🌱"). This prompt sets them to the
proper brand casing `VeganKit`, which reads correctly as a product name but breaks
the all-lowercase styling on those specific lines. Record the exact lines changed
this way so Ammar can eyeball them on device and tell us if he'd rather have
lowercase `vegankit` in those stylized spots.

## Verify
- `flutter gen-l10n` (or `flutter pub get` which triggers it) succeeds.
- The Requirement-4 grep returns no output.
- `flutter clean && flutter pub get && flutter analyze && flutter test`.
- Manual (Ammar, on device/sim): fresh install, confirm the home-screen icon label,
  app-switcher title, onboarding, paywall, settings "About", a shared quote card,
  and a notification all read "VeganKit". Note this manual pass as pending Ammar.

## Commit & push
- Conventional Commit, e.g. `chore: rename display name to VeganKit`.
- Commit body includes `Prompt: claude-prompts/2026-06-13/002-rename-display-name-vegankit.md`.
- Push to origin/main; on failure, stop and report (never force).

## Report
- Write `claude-reports/2026-06-13/002-rename-display-name-vegankit.md` from
  TEMPLATE.md (`mkdir -p` the folder). Record intent, files touched, the
  Requirement-4 grep result, the lowercase→`VeganKit` lines (Decision note),
  recorded `flutter analyze`/`test` output, commit SHA, push result, and open items
  — especially the pending manual on-device name check and any out-of-repo display-
  name spots (App Store Connect app name, Play Console app title, RevenueCat
  display name).
