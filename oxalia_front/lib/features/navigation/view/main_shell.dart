import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_bar/nav_bar.dart';

import '../../../core/theme/app_theme.dart';

/// Shell hosting the main tabs (Home / History / Profile) with the
/// animated bottom navigation bar.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      // Keeps the nav bar's constant repaints from touching the body.
      body: RepaintBoundary(child: navigationShell),
      bottomNavigationBar: FuturisticNavBar(
        selectedIndex: navigationShell.currentIndex,
        onItemSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        style: NavBarStyle.floating,
        iconAnimationType: IconAnimationType.scale,
        showGlow: true,
        theme: FuturisticTheme(
          name: 'oxalia',
          accentColor: palette.teal,
          baseColor: palette.border,
          backgroundColor: palette.surface,
          glowGradient:
              LinearGradient(colors: [palette.teal, palette.cyan]),
          particleColor: palette.teal,
        ),
        items: const [
          NavBarItem(icon: Icons.home_outlined, label: 'HOME'),
          NavBarItem(icon: Icons.history, label: 'HISTORY'),
          NavBarItem(icon: Icons.person_outline, label: 'PROFILE'),
        ],
      ),
    );
  }
}
