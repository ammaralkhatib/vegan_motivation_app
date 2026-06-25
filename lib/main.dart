import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'core/db/database.dart';
import 'core/notifications/notification_service.dart';
import 'core/prefs/prefs_repository.dart';
import 'core/purchases/purchase_providers.dart';
import 'core/purchases/purchase_service.dart';
import 'data/content_importer.dart';

bool get _isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_isDesktop) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1100, 800),
      minimumSize: Size(380, 650),
      center: true,
      title: 'Stay Vegan',
    );
    unawaited(windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    }));
  }

  final sharedPrefs = await SharedPreferences.getInstance();
  final prefs = PrefsRepository(sharedPrefs);
  final db = AppDatabase();

  await _importContentIfNeeded(db, prefs);
  await NotificationService.instance.init();

  // Purchases: seeded from the on-device cache immediately; the SDK is
  // configured in the background so the first frame never waits on the network.
  final purchaseService = RevenueCatPurchaseService(prefs);
  unawaited(
    purchaseService.init().catchError(
      (Object e) => debugPrint('Purchase init error: $e'),
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        purchaseServiceProvider.overrideWithValue(purchaseService),
      ],
      child: const VeggieApp(),
    ),
  );
}

Future<void> _importContentIfNeeded(
  AppDatabase db,
  PrefsRepository prefs,
) async {
  final jsonString = await rootBundle.loadString('assets/content/quotes_v1.json');
  final imported = await ContentImporter(db).import(
    jsonString: jsonString,
    lastImportedVersion: prefs.contentVersion,
  );
  if (imported != null) {
    await prefs.setContentVersion(imported);
  }
}
