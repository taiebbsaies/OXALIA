import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_bar/nav_bar.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

/// Shell hosting the main tabs (Home / History / Profile[/ Admin]) with the
/// animated bottom navigation bar. The Admin tab (last branch) is only
/// rendered for users with the admin role — its branch index never shifts
/// the indices of the other tabs.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = context.watch<AuthViewModel>().currentUser?.role == 'admin';

    return Scaffold(
      // Keeps the nav bar's constant repaints from touching the body.
      body: RepaintBoundary(child: navigationShell),
      bottomNavigationBar: FuturisticNavBar(
        selectedIndex: navigationShell.currentIndex,
        onItemSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        style: NavBarStyle.obsidian,
        blurSigma: 12, // glassmorphism blur intensity (keep ≤ 15 on Android)
        iconAnimationType: IconAnimationType.scale,
        showGlow: true,
        barBackgroundColor: palette.surface,
        // The package hardcodes white icons/labels and a near-black
        // Obsidian base — these make the bar follow the light theme too.
        textStyle: TextStyle(
          color: palette.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        theme: FuturisticTheme(
          name: 'oxalia',
          accentColor: palette.teal,
          baseColor: palette.textSecondary,
          backgroundColor: palette.surface,
          glowGradient: LinearGradient(colors: [palette.teal, palette.cyan]),
          particleColor: palette.teal,
          customColors: {
            'baseColor': palette.surface,
            'baseAccentColor': palette.background,
            'gridColor': palette.textPrimary,
            'podBorderColor': palette.teal,
            'podShadowColor': isDark ? Colors.black : palette.teal,
          },
        ),
        items: [
          NavBarItem(
            icon: Icons.home_outlined,
            label: 'HOME',
            customIcon: Icon(Icons.home_outlined, color: palette.textPrimary),
          ),
          NavBarItem(
            icon: Icons.history,
            label: 'HISTORY',
            customIcon: Icon(Icons.history, color: palette.textPrimary),
          ),
          NavBarItem(
            icon: Icons.person_outline,
            label: 'PROFILE',
            customIcon: Icon(Icons.person_outline, color: palette.textPrimary),
          ),
          if (isAdmin)
            NavBarItem(
              icon: Icons.admin_panel_settings_outlined,
              label: 'ADMIN',
              customIcon: Icon(
                Icons.admin_panel_settings_outlined,
                color: palette.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
