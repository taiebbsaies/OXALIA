import 'package:flutter/material.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/notifications/notification_inbox.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/exam_stats.dart';
import '../../analysis/viewmodel/active_analysis_tracker.dart';
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
    final inbox = context.watch<NotificationInbox>();
    final activeAnalysis = context.watch<ActiveAnalysisTracker>();
    final palette = context.palette;
    final unread = inbox.unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
              backgroundColor: palette.teal,
              child: const Icon(Icons.notifications_outlined),
            ),
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
            if (activeAnalysis.hasActiveAnalysis) ...[
              const SizedBox(height: 16),
              _ActiveAnalysisCard(tracker: activeAnalysis),
            ],
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

class _ActiveAnalysisCard extends StatelessWidget {
  const _ActiveAnalysisCard({required this.tracker});

  final ActiveAnalysisTracker tracker;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final percent = (tracker.progress * 100).clamp(0, 100).toInt();
    final isUploading = tracker.status == ActiveAnalysisStatus.uploading;
    final title = isUploading ? 'Uploading analysis' : 'Analysis in progress';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cyan.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: palette.cyan.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [palette.teal, palette.cyan]),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tracker.patientName == null
                          ? 'Server-side processing is running'
                          : 'Patient: ${tracker.patientName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  color: palette.cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: tracker.progress,
              minHeight: 8,
              backgroundColor: palette.border.withValues(alpha: 0.35),
              valueColor: AlwaysStoppedAnimation<Color>(palette.cyan),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.phone_android, size: 16, color: palette.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Processing continues in the background. You can keep using the app.',
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Headline counters, matching the Activity Overview design.
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final ExamStats stats;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final successRate = (stats.successRate * 100).round();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _StatCard(
          value: '${stats.total}',
          label: 'Total Scans',
          color: palette.teal,
        ),
        _StatCard(
          value: '${stats.processing}',
          label: 'Pending Reports',
          color: palette.cyan,
        ),
        _StatCard(
          value: '${stats.completed}',
          label: 'Completed',
          color: const Color(0xFF10B981),
        ),
        _StatCard(
          value: '$successRate%',
          label: 'Success Rate',
          color: const Color(0xFF8B5CF6),
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

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final width = (MediaQuery.sizeOf(context).width - 42) / 2;

    return SizedBox(
      width: width,
      child: Container(
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
            value,
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
      ),
    );
  }
}

/// Full-width gradient CTA under the stats — matches PrimaryButton language.
class _NewAnalysisButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: palette.teal.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: AnimatedButton(
        width: double.infinity,
        height: 56,
        text: 'New Analysis',
        onPress: () => context.push(AppRoutes.newAnalysis),
        transitionType: TransitionType.LEFT_TO_RIGHT,
        gradient: LinearGradient(
          colors: [palette.teal, palette.cyan],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        selectedBackgroundColor: palette.cyan,
        borderRadius: 12,
        borderWidth: 0,
        isReverse: true,
        animationDuration: const Duration(milliseconds: 400),
        textStyle: TextStyle(
          color: palette.onAccent,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        selectedTextColor: palette.onAccent,
      ),
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
