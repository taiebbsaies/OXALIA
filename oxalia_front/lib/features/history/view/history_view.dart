import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Exam history. Empty placeholder until the exams API lands.
class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 56, color: palette.hint),
            const SizedBox(height: 12),
            Text(
              'No history yet',
              style: TextStyle(color: palette.textSecondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
