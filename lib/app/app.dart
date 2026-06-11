import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/prefs/prefs_repository.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class VeggieApp extends ConsumerWidget {
  const VeggieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Veggie',
      debugShowCheckedModeBanner: false,
      theme: VeggieTheme.light(),
      darkTheme: VeggieTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
