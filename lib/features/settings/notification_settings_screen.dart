import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_service.dart';
import 'notification_prefs.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  String _formatMinutes(BuildContext context, int minutes) {
    final tod = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    return tod.format(context);
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref, {
    required bool isStart,
  }) async {
    final settings = ref.read(notifSettingsProvider);
    final current = isStart ? settings.windowStartMin : settings.windowEndMin;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;

    var start = isStart ? minutes : settings.windowStartMin;
    var end = isStart ? settings.windowEndMin : minutes;
    // Keep at least a 2-hour window, in order.
    if (end - start < 120) {
      if (isStart) {
        end = (start + 120).clamp(0, 24 * 60 - 1);
      } else {
        start = (end - 120).clamp(0, end);
      }
    }
    await ref.read(notifSettingsProvider.notifier).setWindow(start, end);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(notifSettingsProvider);
    final notifier = ref.read(notifSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          SwitchListTile(
            value: settings.enabled,
            onChanged: (enabled) async {
              if (enabled) {
                await NotificationService.instance.requestPermission();
              }
              await notifier.setEnabled(enabled);
            },
            title: const Text('Daily motivation'),
            subtitle: const Text(
              'Full quotes in every notification — they show on your watch too.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          if (settings.enabled) ...[
            const SizedBox(height: 16),
            Text('How many per day', style: theme.textTheme.titleMedium),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: settings.perDay.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${settings.perDay}×',
                    onChanged: (v) => notifier.setPerDay(v.round()),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text('${settings.perDay}×',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Between', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(context, ref, isStart: true),
                    icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                    label: Text(
                        _formatMinutes(context, settings.windowStartMin)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('to'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(context, ref, isStart: false),
                    icon: const Icon(Icons.nights_stay_outlined, size: 18),
                    label:
                        Text(_formatMinutes(context, settings.windowEndMin)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Quotes come from the categories in your mix. '
              'Times vary a little day to day, on purpose — surprise is part '
              'of the charm.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
