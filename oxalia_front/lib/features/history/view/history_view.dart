import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/exam_tile.dart';
import '../viewmodel/history_viewmodel.dart';

/// Exam history tab: newest-first list with per-status chips.
class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HistoryViewModel>();
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: switch (viewModel.status) {
        HistoryStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        HistoryStatus.error => _ErrorState(
          message: viewModel.errorMessage ?? 'Failed to load history',
          onRetry: viewModel.load,
        ),
        HistoryStatus.loaded when viewModel.exams.isEmpty =>
          const _EmptyState(),
        HistoryStatus.loaded => RefreshIndicator(
          color: palette.teal,
          onRefresh: viewModel.refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.exams.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final exam = viewModel.exams[index];
              return ExamTile(exam: exam);
            },
          ),
        ),
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 56, color: palette.hint),
          const SizedBox(height: 12),
          Text(
            'No analyses yet',
            style: TextStyle(color: palette.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Start your first analysis from the Home tab',
            style: TextStyle(color: palette.hint, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 56, color: palette.hint),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh, color: palette.teal),
            label: Text('Retry', style: TextStyle(color: palette.teal)),
          ),
        ],
      ),
    );
  }
}
