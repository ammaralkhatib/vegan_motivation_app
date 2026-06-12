import '../l10n/app_localizations.dart';

/// Built-in vegan-relevant habit presets offered on first visit. The visible
/// name is resolved via [presetHabitName]; only the stable [key] and [emoji]
/// live here (UI-strings-only l10n, CLAUDE.md §1).
class PresetHabit {
  const PresetHabit({
    required this.key,
    required this.emoji,
    this.suggested = false,
  });

  final String key;
  final String emoji;

  /// Pre-checked in the picker.
  final bool suggested;
}

const presetHabits = [
  PresetHabit(key: 'plant_based_day', emoji: '🌱', suggested: true),
  PresetHabit(key: 'new_recipe', emoji: '🍲'),
  PresetHabit(key: 'b12', emoji: '💊', suggested: true),
  PresetHabit(key: 'five_servings', emoji: '🥦', suggested: true),
  PresetHabit(key: 'water', emoji: '💧'),
  PresetHabit(key: 'shared', emoji: '🤝'),
];

/// Localized display name for a preset habit. The picker saves this exact
/// string as the habit name at pick time, so habits keep the language they were
/// created in (saved habits are user data — never migrated).
String presetHabitName(AppLocalizations l, String key) => switch (key) {
      'plant_based_day' => l.habitsPresetPlantBasedDay,
      'new_recipe' => l.habitsPresetNewRecipe,
      'b12' => l.habitsPresetB12,
      'five_servings' => l.habitsPresetFiveServings,
      'water' => l.habitsPresetWater,
      _ => l.habitsPresetShared,
    };
