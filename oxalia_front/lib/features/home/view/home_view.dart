import 'package:flutter/material.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/exam_stats.dart';
import '../../../routing/app_router.dart';
import '../../../shared/widgets/exam_tile.dart';
import '../viewmodel/home_viewmodel.dart';

/// Home tab: activity stats, the New Analysis entry point, and the
/// three most recent exams.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications are coming soon.')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: palette.teal,
        onRefresh: viewModel.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Activity Overview',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            switch (viewModel.status) {
              HomeStatsStatus.loading => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              HomeStatsStatus.error => _StatsError(
                message: viewModel.errorMessage ?? 'Failed to load stats',
                onRetry: viewModel.load,
              ),
              HomeStatsStatus.loaded => _StatsRow(stats: viewModel.stats!),
            },
            const SizedBox(height: 16),
            _NewAnalysisButton(),
            if (viewModel.status == HomeStatsStatus.loaded) ...[
              const SizedBox(height: 24),
              Text(
                'Recent Analyses',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (viewModel.recentExams.isEmpty)
                Text(
                  'No analyses yet. Start your first one above.',
                  style: TextStyle(color: palette.hint, fontSize: 13),
                )
              else
                for (final exam in viewModel.recentExams) ...[
                  ExamTile(exam: exam),
                  if (exam != viewModel.recentExams.last)
                    const SizedBox(height: 10),
                ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Two headline counters, matching the Activity Overview design.
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final ExamStats stats;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: stats.total,
            label: 'Total Scans',
            color: palette.teal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: stats.processing,
            label: 'Pending Reports',
            color: palette.cyan,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Full-width CTA under the stats. Keeps the mockup's dark surface at
/// rest; a teal sweep plays on press, matching PrimaryButton's behavior.
class _NewAnalysisButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AnimatedButton(
      width: double.infinity,
      height: 52,
      text: 'New Analysis',
      onPress: () => context.push(AppRoutes.newAnalysis),
      transitionType: TransitionType.BOTTOM_CENTER_ROUNDER,
      backgroundColor: palette.surface,
      selectedBackgroundColor: palette.teal,
      borderRadius: 12,
      borderWidth: 1,
      borderColor: palette.border,
      isReverse: true,
      animationDuration: const Duration(milliseconds: 400),
      textStyle: TextStyle(
        color: palette.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      selectedTextColor: palette.onAccent,
    );
  }
}

class _StatsError extends StatelessWidget {
  const _StatsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, size: 44, color: palette.hint),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh, color: palette.teal, size: 18),
            label: Text('Retry', style: TextStyle(color: palette.teal)),
          ),
        ],
      ),
    );
  }
}
