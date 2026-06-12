# Inline lane — small tweaks (2026-06-12)

- Ken Burns photo motion 14s→9s (faster drift); Today bottom-bar surface alpha 0.7→0.45 (more transparent). analyze clean, 133 tests green.
- Reverted Today bottom-bar surface alpha 0.45→0.7. analyze clean, 133 tests green.
- ChoiceCard wraps its Card in Padding(bottom: 12) so onboarding option lists get a gap (global cardTheme untouched). analyze clean, 142 tests green.
