import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/db/database.dart';
import '../core/locale/locale_provider.dart';
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

    // Notification taps → habit reminder opens Habits; everything else is a
    // quote id and opens that quote.
    service.onTap = (payload) => _routeNotification(router, payload);

    // App launched from a notification while terminated?
    final launchPayload = await service.launchPayload();
    if (launchPayload != null && launchPayload.isNotEmpty) {
      _routeNotification(router, launchPayload);
    }

    // Activates the settings listener + does the daily refresh.
    final coordinator = ref.read(notificationCoordinatorProvider);
    await coordinator.reschedule();
    await coordinator.rescheduleHabits();

    // Refresh the home-screen widget queue (no-op on desktop).
    await HomeWidgetService.pushQueue(
      ref.read(databaseProvider),
      unlockedCategoryIds: ref.read(unlockedCategoryIdsProvider),
      languageOverride: ref.read(languageOverrideProvider),
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
      final coordinator = ref.read(notificationCoordinatorProvider);
      coordinator.reschedule();
      coordinator.rescheduleHabits();
    }
  }

  /// A `habit:<id>` payload opens the Habits screen; any other payload is a
  /// quote id (never parse a habit payload as one).
  void _routeNotification(GoRouter router, String payload) {
    if (payload.startsWith('habit:')) {
      router.go('/habits');
    } else {
      router.go('/quote/$payload');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);
    final locale = ref.watch(appLocaleProvider);

    return MaterialApp.router(
      title: 'Stay Vegan',
      debugShowCheckedModeBanner: false,
      theme: VeggieTheme.light(),
      darkTheme: VeggieTheme.dark(),
      themeMode: themeMode,
      // null = follow the device language; a non-null override flips the whole
      // app (UI + quote text via the locale sync below) immediately.
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      // Keep the quote-text locale in sync with the resolved UI locale, so an
      // OS language switch re-resolves quote text live (translations already
      // live in the DB — no re-import).
      builder: (context, child) {
        _syncLocale(Localizations.localeOf(context).languageCode);
        return child ?? const SizedBox.shrink();
      },
    );
  }

  void _syncLocale(String code) {
    if (ref.read(localeCodeProvider) == code) return;
    // Defer the state write out of the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(localeCodeProvider.notifier).state = code;
    });
  }
}
