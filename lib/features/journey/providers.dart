import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/prefs/prefs_repository.dart';

/// Reactive view over the journey-related prefs.
class JourneyState {
  const JourneyState({
    required this.veganSince,
    required this.curiousMode,
    required this.userName,
  });

  final DateTime? veganSince;
  final bool curiousMode;
  final String? userName;

  /// Whole days since going vegan, counting the start day as day 1.
  /// Future-dated picks clamp to day 1.
  int get daysVegan {
    final since = veganSince;
    if (since == null) return 0;
    final today = DateTime.now();
    final start = DateTime(since.year, since.month, since.day);
    final end = DateTime(today.year, today.month, today.day);
    final diff = end.difference(start).inDays + 1;
    return diff < 1 ? 1 : diff;
  }
}

class JourneyNotifier extends Notifier<JourneyState> {
  @override
  JourneyState build() {
    final prefs = ref.read(prefsProvider);
    return JourneyState(
      veganSince: prefs.veganSince,
      curiousMode: prefs.curiousMode,
      userName: prefs.userName,
    );
  }

  Future<void> setVeganSince(DateTime date) async {
    final prefs = ref.read(prefsProvider);
    await prefs.setVeganSince(date);
    await prefs.setCuriousMode(false);
    ref.invalidateSelf();
  }

  Future<void> setCurious() async {
    final prefs = ref.read(prefsProvider);
    await prefs.setVeganSince(null);
    await prefs.setCuriousMode(true);
    ref.invalidateSelf();
  }

  Future<void> setUserName(String? name) async {
    await ref.read(prefsProvider).setUserName(name);
    ref.invalidateSelf();
  }
}

final journeyProvider =
    NotifierProvider<JourneyNotifier, JourneyState>(JourneyNotifier.new);
