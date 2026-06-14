# Inline lane — small tweaks (2026-06-14)

- ios/VeganKitWidget/VeganKitWidget.swift: rebrand placeholder/fallback category text "🌱 Veggie" → "🌱 VeganKit" and `?? "Veggie"` → `?? "VeganKit"`, and shorten the `// Veggie cream` comment to `// cream`. Display strings only — no type/kind/struct renames. Swift not covered by analyze/test; verified by grep (3 lines changed). Commit `chore(widget): rebrand placeholder category Veggie → VeganKit`.
