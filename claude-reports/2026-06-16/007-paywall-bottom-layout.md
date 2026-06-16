# Paywall: move "cancel anytime" + one-line legal links

**Prompt:** `claude-prompts/2026-06-16/007-paywall-bottom-layout.md`
**Completed:** 2026-06-16 · **Status:** done

## Summary

Two layout tweaks in `paywall_screen.dart`. Moved the "Cancel anytime…" line out
of the price card so it now sits under the benefit cards in the scrolling
content. Replaced the standalone Restore button + separate Privacy · Terms row
with a single centered row holding all three links — `Restore Purchases · Privacy
· Terms` — hardcoded in English. Analyze clean, all tests green.

## Files touched

- `lib/features/paywall/paywall_screen.dart` — moved `paywallCancelAnytime` from
  `_PriceBlock` into `PaywallView` below the benefit cards; rebuilt the
  `_CtaBar` secondary links into one `Wrap`; made `_LegalLink.onTap` nullable so
  Restore disables while busy; added a small `_LegalDot` separator widget;
  removed a now-unused `l` variable.
- `test/paywall_view_test.dart` — updated the assertion from `'Restore
  purchases'` to the new hardcoded `'Restore Purchases'` label.

## Decisions

- **One row via `Wrap` (not `Row`).** The prompt allowed wrapping on narrow
  screens; `Wrap(alignment: center)` keeps all three on one line normally but
  lets them flow to a second line instead of overflowing on small widths.
- **Reused `_LegalLink` for all three links**, including Restore — cleanest way
  to keep them visually identical on one line. Made `onTap` nullable so passing
  `busy ? null : onRestore` disables Restore while a purchase/restore is running
  (same behavior as the old button).
- **English labels hardcoded as literals** (`'Restore Purchases'`, `'Privacy'`,
  `'Terms'`) with a code comment marking the intentional paywall-only l10n
  exception. ARB keys `paywallRestore`/`paywallPrivacy`/`paywallTerms` left in
  place, just not read here.
- **`paywallCancelAnytime` stays localized** and keeps its small/muted/centered
  styling, with a 4px top gap above the last benefit card's existing 12px.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.3s)

$ flutter test
All tests passed! (176)
```

Test update needed: yes — `paywall_view_test.dart` asserted the old lowercase
`'Restore purchases'`; updated to `'Restore Purchases'`. The "Cancel anytime"
assertion still passes (the text just moved, `find.text` is location-agnostic).
The `legal_screen_test.dart` Privacy/Terms taps still pass — the hardcoded labels
match the previous text. Settings-screen restore tests are unaffected (different
file/string).

Self-correction: fixed an unused-variable lint warning (removed `l` from
`_CtaBar`) before committing — analyze then clean.
Manual click-path: [ ] not run by Claude Code — Ammar to open a paywall and
confirm "Cancel anytime…" sits under the benefit cards and that Restore Purchases
· Privacy · Terms are on one English line, each tap working.

## Commit & push

- **Commit:** `1d9c2ef` — `style(paywall): relocate cancel-anytime + single-line english legal links`
- **Push:** `origin/main` — ok

## Open items for the owner

- Visual click-path verification (cancel line placement + one-line links + taps).

## Deviations from prompt

None.
