import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../db/database.dart';
import '../utils/date_utils.dart';
import '../utils/seeded_shuffle.dart';

/// Pushes a 14-day, date-indexed quote queue to the home-screen widgets.
///
/// Native side (Android AppWidgetProvider / iOS TimelineProvider) picks the
/// entry matching the current local epoch-day, so even a stale refresh shows
/// the right quote for the day.
class HomeWidgetService {
  static const _appGroupId = 'group.com.ammarkhatib.veggie';
  static const _androidProvider = 'VeggieWidgetProvider';
  static const _iosWidgetName = 'VeggieWidget';
  static const queueKey = 'quote_queue';

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Builds the queue from the quotes currently in the mix and hands it to
  /// the native widgets. Call on app start and whenever the mix changes.
  static Future<void> pushQueue(AppDatabase db) async {
    if (!isSupported) return;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await HomeWidget.setAppGroupId(_appGroupId);
    }

    final quotes = await db.quoteDao.getQuotesInMix();
    if (quotes.isEmpty) return;
    final categories = {
      for (final c in await db.select(db.categories).get()) c.id: c,
    };

    final today = todayEpochDay();
    final queue = <Map<String, Object?>>[];
    for (var offset = 0; offset < 14; offset++) {
      final day = today + offset;
      // Same day-seeded order the feed uses; widget shows that day's first.
      final dayQuote = seededShuffle(quotes, day).first;
      final category = categories[dayQuote.categoryId];
      queue.add({
        'day': day,
        'text': dayQuote.body,
        'category': category?.name ?? '',
        'emoji': category?.emoji ?? '🌱',
      });
    }

    try {
      await HomeWidget.saveWidgetData(queueKey, json.encode(queue));
      await HomeWidget.updateWidget(
        androidName: _androidProvider,
        iOSName: _iosWidgetName,
      );
    } on Exception {
      // Plugin unavailable (tests, or platforms without widgets) — fine.
    }
  }
}
