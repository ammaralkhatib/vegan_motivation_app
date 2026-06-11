import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/preset_habits.dart';
import 'habit_tile.dart';
import 'month_heatmap.dart';
import 'providers.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(milliseconds: 1200));

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _onHabitToggled(
    bool nowCompleted,
    int streak,
    List<Habit> habits,
    Map<int, Set<int>> weekDays,
  ) {
    if (!nowCompleted) return;

    const milestones = {7: 'One week strong 🌱', 30: 'A whole month! 🌿', 100: '100 days. Incredible. 🌳'};
    final milestone = milestones[streak];
    if (milestone != null) {
      _confetti.play();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(milestone)));
      return;
    }

    // All habits done today? Celebrate.
    final today = todayEpochDay();
    final allDone = habits.every(
      (h) => (weekDays[h.id] ?? const <int>{}).contains(today),
    );
    if (allDone && habits.length > 1) {
      _confetti.play();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Everything done today. You showed up 💚')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(activeHabitsProvider);
    final weekDays =
        ref.watch(weekCompletionsProvider).valueOrNull ?? const <int, Set<int>>{};
    final celebration =
        Theme.of(context).extension<VeggieAccents>()!.celebration;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          IconButton(
            onPressed: () => context.go('/habits/edit/new'),
            icon: const Icon(Icons.add),
            tooltip: 'New habit',
          ),
        ],
      ),
      body: Stack(
        children: [
          habits.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Could not load habits: $e')),
            data: (list) {
              if (list.isEmpty) return const _PresetPicker();
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  for (final habit in list) ...[
                    HabitTile(
                      habit: habit,
                      weekDays: weekDays[habit.id] ?? const <int>{},
                      onToggled: (done, streak) =>
                          _onHabitToggled(done, streak, list, weekDays),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                  MonthHeatmap(habitCount: list.length),
                ],
              );
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 24,
              maxBlastForce: 18,
              minBlastForce: 6,
              gravity: 0.25,
              colors: [
                celebration,
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// First-visit experience: pick from vegan-relevant presets.
class _PresetPicker extends ConsumerStatefulWidget {
  const _PresetPicker();

  @override
  ConsumerState<_PresetPicker> createState() => _PresetPickerState();
}

class _PresetPickerState extends ConsumerState<_PresetPicker> {
  late final Set<String> _selected = {
    for (final p in presetHabits)
      if (p.suggested) p.key,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('Build your plant-powered routine',
            style: theme.textTheme.displaySmall),
        const SizedBox(height: 6),
        Text(
          'Pick a few daily habits to track. You can add your own anytime.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        for (final preset in presetHabits) ...[
          Card(
            child: CheckboxListTile(
              value: _selected.contains(preset.key),
              onChanged: (checked) => setState(() {
                checked == true
                    ? _selected.add(preset.key)
                    : _selected.remove(preset.key);
              }),
              title: Text('${preset.emoji}  ${preset.name}'),
              controlAffinity: ListTileControlAffinity.trailing,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () async {
                  final dao = ref.read(databaseProvider).habitDao;
                  var order = 0;
                  for (final preset in presetHabits) {
                    if (_selected.contains(preset.key)) {
                      await dao.insertHabit(
                        name: preset.name,
                        emoji: preset.emoji,
                        presetKey: preset.key,
                        sortOrder: order++,
                      );
                    }
                  }
                },
          child: Text('Start tracking ${_selected.length} habits'),
        ),
      ],
    );
  }
}
