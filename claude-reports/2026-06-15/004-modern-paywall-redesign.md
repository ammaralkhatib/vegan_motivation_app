# Modern paywall redesign (clean light cards)

**Prompt:** `claude-prompts/2026-06-15/004-modern-paywall-redesign.md`
**Completed:** 2026-06-15 · **Status:** done

## Summary

The paywall was a plain centered column (icon, title, flat checklist, price,
button, restore link, footnote). I redesigned `PaywallView` into a card-based
layout that matches the rest of the app: the eco hero icon now sits in a soft
circular tinted badge, the four benefits are soft rounded cards, the price sits
in its own highlighted bordered card, and the primary CTA is pinned to a bottom
bar that stays visible while the content above scrolls. This was a
presentation-only change — no pricing, purchase, restore, navigation, close
timing, or provider logic was touched. All existing text and the `PaywallView`
constructor are unchanged, so the existing tests pass without edits.

## Files touched

- `lib/features/paywall/paywall_screen.dart` — rebuilt `PaywallView` as a
  scroll-area-over-sticky-bar layout; added private `_BenefitCard` and `_CtaBar`
  widgets; wrapped `_PriceBlock`'s contents in a highlighted card container. No
  other widgets in the file were changed.

## Decisions

- **Price card uses `surfaceContainerHighest` + a 1.5px `primary` border** rather
  than a `primaryContainer` fill — the prompt allowed either. A surface color
  keeps the existing price text (which uses `onSurface` / `onSurfaceVariant`)
  readable in both light and dark mode; a `primaryContainer` fill would have
  risked low contrast on those text colors in dark mode. The strong primary
  border makes it clearly stand out from the benefit cards.
- **Benefit cards use `surfaceContainer` + `outlineVariant` border, 20px radius**
  to match the app's `cardTheme`, kept visually lighter than the price card so
  the price reads as the highlighted element.
- **Hero badge uses `primaryContainer` / `onPrimaryContainer`** — calm, on-theme,
  no gradient or dark override. Centered, so it never overlaps the top-left close
  X.
- **CTA bar** uses `surfaceContainerLow` with an `outlineVariant` top border for
  the requested separation from scrolling content. It sits below the scroll
  `Expanded`, so it never scrolls off; the screen already wraps `PaywallView` in
  `SafeArea`, so the bar clears the home indicator.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.1s)

$ flutter test
All tests passed! (166 tests)
# paywall_view_test.dart and paywall_screen_test.dart both pass unmodified.
```

Self-correction: none — clean on first run.
Manual click-path (Ammar runs on device):
- [ ] Onboarding variant: trial line + "Start free trial" CTA, benefit cards,
      price card stands out, CTA pinned while content scrolls, X closes.
- [ ] Default variant: 50% badge + crossed-out anchor in the price card.
- [ ] Discount variant: 80% one-time badge + urgency copy.
- [ ] Purchase still fires confetti and dismisses.

## Commit & push

- **Commit:** `f373d49` — `feat(paywall): modern card-based redesign with sticky CTA`
- **Push:** `origin/main` — ok

## Deviations from prompt

None. No new strings, no theme edits, no behavior changes, and no test edits were
needed (existing tests assert text + a `FilledButton` with the CTA label, all of
which still hold).
