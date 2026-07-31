import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

/// Home screen shown after authentication. Exam features land here
/// next sprint; for now it proves the auth flow end-to-end.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('My exams')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 56, color: palette.hint),
            const SizedBox(height: 12),
            Text(
              'Welcome, ${user?.fullName ?? 'clinician'}',
              style: TextStyle(color: palette.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'No exams yet',
              style: TextStyle(color: palette.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
