import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/notifications/notification_service.dart';
import '../../l10n/app_localizations.dart';

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

  /// Chosen daily reminder, in minutes from local midnight; null = off.
  int? _reminderMinutes;

  /// Default reminder time when the switch is first turned on (9:00 AM).
  static const int _defaultReminderMinutes = 9 * 60;

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
        _reminderMinutes = _existing!.reminderMinutes;
      }
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final current = _reminderMinutes ?? _defaultReminderMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked != null) {
      setState(() => _reminderMinutes = picked.hour * 60 + picked.minute);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final dao = ref.read(databaseProvider).habitDao;
    final service = NotificationService.instance;

    // New habit: insert first to get its id, then attach the reminder.
    final int habitId;
    if (_existing == null) {
      habitId = await dao.insertHabit(name: name, emoji: _emoji, sortOrder: 99);
    } else {
      habitId = _existing!.id;
      await dao.renameHabit(habitId, name, _emoji);
    }

    final hadReminder = _existing?.reminderMinutes != null;
    if (_reminderMinutes != null) {
      await dao.setHabitReminder(habitId, _reminderMinutes);
      // Ask for permission once when a reminder is turned on for the first
      // time. If denied we still keep the time; the OS just won't show it.
      if (!hadReminder) {
        await service.requestPermission();
      }
      await service.scheduleHabitReminder(
        habitId: habitId,
        name: name,
        emoji: _emoji,
        reminderMinutes: _reminderMinutes!,
      );
    } else {
      await dao.setHabitReminder(habitId, null);
      await service.cancelHabitReminder(habitId);
    }

    if (mounted) context.pop();
  }

  Future<void> _archive() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.habitsArchiveConfirmTitle),
        content: Text(l.habitsArchiveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.habitsArchiveCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.habitsArchiveConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && _existing != null) {
      await ref.read(databaseProvider).habitDao.archiveHabit(_existing!.id);
      await NotificationService.instance.cancelHabitReminder(_existing!.id);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l.habitsEditNewTitle : l.habitsEditTitle),
        actions: [
          if (!_isNew && _existing != null)
            IconButton(
              onPressed: _archive,
              icon: const Icon(Icons.archive_outlined),
              tooltip: l.habitsArchiveTooltip,
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
                  decoration: InputDecoration(
                    labelText: l.habitsNameLabel,
                    hintText: l.habitsNameHint,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 24),
                Text(l.habitsPickEmoji, style: theme.textTheme.titleMedium),
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
                const SizedBox(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.habitsReminderSectionTitle),
                  subtitle: Text(l.habitsReminderSubtitle),
                  value: _reminderMinutes != null,
                  onChanged: (on) => setState(() {
                    _reminderMinutes = on ? _defaultReminderMinutes : null;
                  }),
                ),
                if (_reminderMinutes != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        '${l.habitsReminderSetTime} · '
                        '${TimeOfDay(hour: _reminderMinutes! ~/ 60, minute: _reminderMinutes! % 60).format(context)}',
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _save,
                  child: Text(_isNew ? l.habitsAddButton : l.habitsSaveButton),
                ),
              ],
            ),
    );
  }
}
