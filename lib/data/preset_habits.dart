/// Built-in vegan-relevant habit presets offered on first visit.
class PresetHabit {
  const PresetHabit({
    required this.key,
    required this.name,
    required this.emoji,
    this.suggested = false,
  });

  final String key;
  final String name;
  final String emoji;

  /// Pre-checked in the picker.
  final bool suggested;
}

const presetHabits = [
  PresetHabit(
    key: 'plant_based_day',
    name: 'Ate fully plant-based today',
    emoji: '🌱',
    suggested: true,
  ),
  PresetHabit(
    key: 'new_recipe',
    name: 'Tried a new vegan recipe',
    emoji: '🍲',
  ),
  PresetHabit(
    key: 'b12',
    name: 'Took B12',
    emoji: '💊',
    suggested: true,
  ),
  PresetHabit(
    key: 'five_servings',
    name: '5 servings of fruit & veg',
    emoji: '🥦',
    suggested: true,
  ),
  PresetHabit(
    key: 'water',
    name: 'Drank enough water',
    emoji: '💧',
  ),
  PresetHabit(
    key: 'shared',
    name: 'Shared a vegan meal or idea',
    emoji: '🤝',
  ),
];
