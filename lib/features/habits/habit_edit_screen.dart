import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';

const _emojiChoices = [
  '🌱', '🥦', '🍎', '🍲', '💊', '💧', '🏃', '🧘', '📖', '🤝', '☀️', '✨',
];

/// Create ('new') or edit/archive an existing habit.
class HabitEditScreen extends ConsumerStatefulWidget {
  const HabitEditScreen({super.key, required this.habitId});

  /// 'new' or an existing habit id.
  final String habitId;

  @override
  ConsumerState<HabitEditScreen> createState() => _HabitEditScreenState();
}

class _HabitEditScreenState extends ConsumerState<HabitEditScreen> {
  final _nameController = TextEditingController();
  String _emoji = '🌱';
  Habit? _existing;
  bool _loaded = false;

  bool get _isNew => widget.habitId == 'new';

  @override
  void initState() {
    super.initState();
    if (_isNew) {
      _loaded = true;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final id = int.tryParse(widget.habitId);
    if (id != null) {
      final db = ref.read(databaseProvider);
      _existing = await (db.select(db.habits)
            ..where((h) => h.id.equals(id)))
          .getSingleOrNull();
      if (_existing != null) {
        _nameController.text = _existing!.name;
        _emoji = _existing!.emoji;
      }
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final dao = ref.read(databaseProvider).habitDao;
    if (_existing == null) {
      await dao.insertHabit(name: name, emoji: _emoji, sortOrder: 99);
    } else {
      await dao.renameHabit(_existing!.id, name, _emoji);
    }
    if (mounted) context.pop();
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive habit?'),
        content: const Text(
          'Its history is kept, but it disappears from your daily list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed == true && _existing != null) {
      await ref.read(databaseProvider).habitDao.archiveHabit(_existing!.id);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_isNew ? 'New habit' : 'Edit habit'),
        actions: [
          if (!_isNew && _existing != null)
            IconButton(
              onPressed: _archive,
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Archive',
            ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                TextField(
                  controller: _nameController,
                  autofocus: _isNew,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Habit name',
                    hintText: 'e.g. Cooked dinner at home',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 24),
                Text('Pick an emoji', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final emoji in _emojiChoices)
                      ChoiceChip(
                        label: Text(emoji,
                            style: const TextStyle(fontSize: 22)),
                        selected: _emoji == emoji,
                        onSelected: (_) => setState(() => _emoji = emoji),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _save,
                  child: Text(_isNew ? 'Add habit' : 'Save changes'),
                ),
              ],
            ),
    );
  }
}
