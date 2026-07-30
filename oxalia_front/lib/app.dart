import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

/// Root widget. Global providers (AuthViewModel, repositories) will be
/// registered above this in `main.dart` as features land.
class OxaliaApp extends StatelessWidget {
  const OxaliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OXALIA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
