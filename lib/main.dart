import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/db/database.dart';
import 'core/notifications/notification_service.dart';
import 'core/prefs/prefs_repository.dart';
import 'data/content_importer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPrefs = await SharedPreferences.getInstance();
  final prefs = PrefsRepository(sharedPrefs);
  final db = AppDatabase();

  await _importContentIfNeeded(db, prefs);
  await NotificationService.instance.init();

  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
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
