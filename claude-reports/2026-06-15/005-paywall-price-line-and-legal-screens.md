# Paywall price-row polish + in-app Privacy/Terms screens

**Prompt:** `claude-prompts/2026-06-15/005-paywall-price-line-and-legal-screens.md`
**Completed:** 2026-06-15 · **Status:** done

## Summary

Six paywall/legal changes, all on top of the 004 redesign. The price card now
lives inside the sticky bottom bar (just above the buy button); the crossed-out
anchor and the real price sit on one centered line; the discount badge straddles
the price card's top border as a "notch"; the per-year subtitle is dropped on the
50% (default) paywall; the "Cancel anytime…" footnote moved into the price card
as its last line. Added muted **Privacy** / **Terms** links under "Restore
purchases" that open two new in-app `LegalScreen` routes rendering the VeganKit
policy text. Analyze is clean and all 169 tests pass (added a 3-case legal test).

## Files touched

- `lib/features/paywall/paywall_screen.dart` — moved `_PriceBlock` into `_CtaBar`
  (new `data` field); one-line anchor+price `Row`; notch badge via `Stack`
  (`Clip.none`) + `FractionalTranslation(-0.5)`; default-variant subtitle
  suppressed; cancel footnote relocated into `_PriceBlock`; new `_LegalLink`
  Privacy/Terms row.
- `lib/features/legal/legal_screen.dart` — **new** reusable `LegalScreen`
  (AppBar + back button + scrollable themed sections, `SafeArea`).
- `lib/features/legal/legal_content.dart` — **new** English-only `LegalSection`
  model + `privacyPolicySections` / `termsOfUseSections` constants (verbatim
  Appendix A/B, incl. the "Last updated" stamp and `contact@develooper.io`).
- `lib/app/router.dart` — two new full-screen routes `/legal/privacy` and
  `/legal/terms`; reads localized titles via `AppLocalizations.of(context)`.
- `lib/l10n/app_en.arb` — 4 new keys with `@`-metadata: `paywallPrivacy`,
  `paywallTerms`, `legalPrivacyTitle`, `legalTermsTitle`.
- `lib/l10n/app_de.arb`, `app_fr.arb`, `app_es.arb` — same 4 keys, translated
  (see deviation note).
- `test/legal_screen_test.dart` — **new** widget test: Privacy/Terms push the
  matching `LegalScreen`, and the back button returns to the paywall.

## Decisions

- **Notch badge via `FractionalTranslation(Offset(0,-0.5))`** inside a
  `Stack(clipBehavior: Clip.none, alignment: topCenter)` — lifts the badge by
  exactly half its own height regardless of text length, so the card's top border
  runs through its middle. A 14px `SizedBox` above the price card in the bar gives
  it clearance from the Restore button area below it.
- **One-line price:** anchor (`titleMedium`, strikethrough, muted) + main price
  (`headlineSmall`, bold) in a centered `Row`; the main price is wrapped in
  `Flexible` so the long onboarding trial line ("7 days free, then …") can wrap on
  small screens instead of overflowing. Onboarding (no anchor) shows the single
  line with no leading gap.
- **Legal content as Dart, not ARB** — long-form legal body is treated like quote
  content (locked content decision: not localized this phase). Only the 4 short
  labels/titles go through gen_l10n.
- **`LegalSection` model** (optional heading + paragraph list) keeps `LegalScreen`
  reusable for both documents and easy to extend later.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.3s)

$ flutter test
All tests passed! (169 tests)
# paywall_view_test.dart — pass (anchor + price + cancel text still present)
# paywall_screen_test.dart — pass (FilledButton + CTA label unchanged)
# legal_screen_test.dart — pass (new: Privacy/Terms navigation + back)
```

Self-correction: fixed on attempt 1 of the test stage — adding the 4 keys to
`app_en.arb` alone broke the existing `l10n_parity_test.dart` (enforces identical
keys across en/de/fr/es). Added the translated keys to the three other locale
ARBs; all tests green after that. No test was weakened. No existing test needed a
structural edit — the relocated anchor/cancel text still matches `paywall_view_test`.

Manual click-path (Ammar runs on device):
- [ ] Default: 50% badge on the price-card top border, anchor + price on one
      line, **no** per-year subtitle.
- [ ] Discount: 80% notch badge + urgency line still present.
- [ ] Onboarding: trial line, no anchor, no badge.
- [ ] Price card sits just above the buy button; "Cancel anytime…" is its last line.
- [ ] Privacy + Terms open readable scrollable screens with a working back button.

## Commit & push

- **Commit:** `f773408` — `feat(paywall): one-line price, notch badge, in-app legal screens`
- **Push:** `origin/main` — ok

## Open items for the owner

- None blocking. The legal text is baked in verbatim from the website; if the
  website copy changes, update `legal_content.dart` and the "Last updated" stamp.

## Deviations from prompt

- **Edited `app_de.arb` / `app_fr.arb` / `app_es.arb`** (not listed in Scope,
  which named only `app_en.arb`). Required because `l10n_parity_test.dart`
  enforces identical keys across all four locale ARBs — English-only additions
  fail it. Added the 4 short labels translated (e.g. DE "Datenschutz" /
  "Nutzungsbedingungen", FR "Confidentialité" / "Conditions", ES "Privacidad" /
  "Términos"). This is the minimal change to keep `flutter test` green (a hard
  constraint) and does not touch the long-form legal body, which stays
  English-only Dart per the locked content decision. Worth a quick translation
  sanity-check by a native speaker before the localized release ships.
