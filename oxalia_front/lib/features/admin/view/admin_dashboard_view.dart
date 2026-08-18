import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/admin_stats.dart';
import '../../../routing/app_router.dart';
import '../viewmodel/admin_dashboard_viewmodel.dart';

/// Platform-wide statistics dashboard, visible to admins only.
class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminDashboardViewModel>();
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Manage users',
            icon: const Icon(Icons.manage_accounts_outlined),
            onPressed: () => context.push(AppRoutes.adminUsers),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: palette.teal,
        onRefresh: viewModel.refresh,
        child: switch (viewModel.status) {
          AdminDashboardStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          AdminDashboardStatus.error => _DashboardError(
            message: viewModel.errorMessage ?? 'Failed to load statistics',
            onRetry: viewModel.load,
          ),
          AdminDashboardStatus.loaded => _Dashboard(stats: viewModel.stats!),
        },
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('Users'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.groups_outlined,
                value: '${stats.totalUsers}',
                label: 'Total Users',
                color: palette.teal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.person_add_alt_outlined,
                value: '+${stats.newUsers7d}',
                label: 'New (7d)',
                color: palette.cyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.verified_user_outlined,
                value: '${stats.adminCount}',
                label: 'Admins',
                color: palette.teal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.medical_information_outlined,
                value: '${stats.clinicianCount}',
                label: 'Clinicians',
                color: palette.cyan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.block_outlined,
                value: '${stats.inactiveUsers}',
                label: 'Inactive',
                color: palette.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionTitle('Analyses'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.analytics_outlined,
                value: '${stats.totalExams}',
                label: 'Total Analyses',
                color: palette.teal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.upload_file_outlined,
                value: '+${stats.newExams7d}',
                label: 'New (7d)',
                color: palette.cyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline,
                value: '${stats.completedExams}',
                label: 'Completed',
                color: palette.teal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.hourglass_empty,
                value: '${stats.processingExams + stats.pendingExams}',
                label: 'In Progress',
                color: palette.cyan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.error_outline,
                value: '${stats.failedExams}',
                label: 'Failed',
                color: palette.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _InfoRow(
          label: 'Failure rate',
          value: '${stats.failureRatePct.toStringAsFixed(1)}%',
        ),
        if (stats.avgProcessingSeconds != null)
          _InfoRow(
            label: 'Avg. processing time',
            value: _formatDuration(stats.avgProcessingSeconds!),
          ),
        const SizedBox(height: 24),
        if (stats.userGrowth.isNotEmpty) ...[
          _SectionTitle('User Growth (14d)'),
          const SizedBox(height: 12),
          _TrendChart(points: stats.userGrowth, color: palette.teal),
          const SizedBox(height: 24),
        ],
        if (stats.examVolume.isNotEmpty) ...[
          _SectionTitle('Analysis Volume (14d)'),
          const SizedBox(height: 12),
          _TrendChart(points: stats.examVolume, color: palette.cyan),
          const SizedBox(height: 24),
        ],
        if (stats.modelVersions.isNotEmpty) ...[
          _SectionTitle('Model Versions'),
          const SizedBox(height: 12),
          _ModelVersionsList(versions: stats.modelVersions),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  static String _formatDuration(double seconds) {
    if (seconds < 60) return '${seconds.toStringAsFixed(0)}s';
    final minutes = seconds / 60;
    if (minutes < 60) return '${minutes.toStringAsFixed(1)}m';
    return '${(minutes / 60).toStringAsFixed(1)}h';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Text(
      text,
      style: TextStyle(
        color: palette.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: palette.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: palette.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points, required this.color});

  final List<TrendPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final maxY = points.map((p) => p.count).fold<int>(1, (a, b) => a > b ? a : b).toDouble();

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY < 4 ? 4 : maxY + 1,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].count.toDouble()),
              ],
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.15)),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatShare(int value, int total) {
  final pct = total == 0 ? 0 : (value / total * 100).toStringAsFixed(0);
  return '$value ($pct%)';
}

class _ModelVersionsList extends StatelessWidget {
  const _ModelVersionsList({required this.versions});

  final Map<String, int> versions;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final total = versions.values.fold<int>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          for (final entry in versions.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(color: palette.textPrimary, fontSize: 13),
                    ),
                  ),
                  Text(
                    _formatShare(entry.value, total),
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
