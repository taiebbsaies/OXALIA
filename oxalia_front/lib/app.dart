import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

/// Root widget. Providers live above this in `main.dart`.
class OxaliaApp extends StatelessWidget {
  const OxaliaApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp.router(
      title: 'OXALIA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.mode,
      routerConfig: router,
    );
  }
}
