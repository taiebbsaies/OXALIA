import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final user = context.watch<AuthViewModel>().currentUser;
    final themeController = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: palette.teal,
                  child: Icon(Icons.person, color: palette.onAccent, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Clinician',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'APPEARANCE',
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedToggleSwitch<ThemeMode>.rolling(
            current: themeController.mode,
            values: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
            onChanged: (mode) =>
                context.read<ThemeController>().setMode(mode),
            iconBuilder: (mode, foreground) => Icon(
              switch (mode) {
                ThemeMode.system => Icons.brightness_auto,
                ThemeMode.light => Icons.light_mode,
                ThemeMode.dark => Icons.dark_mode,
              },
              color: foreground ? palette.onAccent : palette.textSecondary,
            ),
            height: 48,
            indicatorSize: const Size.fromWidth(56),
            style: ToggleStyle(
              backgroundColor: palette.surface,
              borderColor: palette.border,
              borderRadius: BorderRadius.circular(14),
              indicatorBorderRadius: BorderRadius.circular(10),
            ),
            styleBuilder: (mode) =>
                ToggleStyle(indicatorColor: palette.teal),
          ),
          const SizedBox(height: 8),
          Text(
            switch (themeController.mode) {
              ThemeMode.system =>
                'Following your phone theme automatically',
              ThemeMode.light => 'Light theme',
              ThemeMode.dark => 'Dark theme',
            },
            style: TextStyle(color: palette.hint, fontSize: 12),
          ),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            onPressed: () => context.read<AuthViewModel>().logout(),
            icon: Icon(Icons.logout, color: palette.error),
            label: Text(
              'Sign out',
              style: TextStyle(color: palette.error),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: palette.error.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
