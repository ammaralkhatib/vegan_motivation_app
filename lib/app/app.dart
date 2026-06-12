import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/database.dart';
import '../core/notifications/notification_coordinator.dart';
import '../core/notifications/notification_service.dart';
import '../core/prefs/prefs_repository.dart';
import '../core/purchases/premium_gate.dart';
import '../core/widgetkit/home_widget_service.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';

class VeggieApp extends ConsumerStatefulWidget {
  const VeggieApp({super.key});

  @override
  ConsumerState<VeggieApp> createState() => _VeggieAppState();
}

class _VeggieAppState extends ConsumerState<VeggieApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final router = ref.read(routerProvider);
    final service = NotificationService.instance;

    // Notification taps → the tapped quote.
    service.onTap = (payload) => router.go('/quote/$payload');

    // App launched from a notification while terminated?
    final launchPayload = await service.launchPayload();
    if (launchPayload != null && launchPayload.isNotEmpty) {
      router.go('/quote/$launchPayload');
    }

    // Activates the settings listener + does the daily refresh.
    await ref.read(notificationCoordinatorProvider).reschedule();

    // Refresh the home-screen widget queue (no-op on desktop).
    await HomeWidgetService.pushQueue(
      ref.read(databaseProvider),
      unlockedCategoryIds: ref.read(unlockedCategoryIdsProvider),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Debounced internally to once per day.
      ref.read(notificationCoordinatorProvider).reschedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Veggie',
      debugShowCheckedModeBanner: false,
      theme: VeggieTheme.light(),
      darkTheme: VeggieTheme.dark(),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
