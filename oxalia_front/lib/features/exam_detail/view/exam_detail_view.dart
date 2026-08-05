import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/exam.dart';
import '../../../data/models/inference_result.dart';
import '../viewmodel/exam_detail_viewmodel.dart';

/// Full exam detail: the stored X-ray, its metadata, and the model's
/// findings once inference completed.
class ExamDetailView extends StatelessWidget {
  const ExamDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExamDetailViewModel>();
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Exam Details')),
      body: switch (viewModel.status) {
        ExamDetailStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        ExamDetailStatus.error => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_outlined, size: 56, color: palette.hint),
                const SizedBox(height: 12),
                Text(
                  viewModel.errorMessage ?? 'Failed to load exam',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textSecondary),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: viewModel.load,
                  icon: Icon(Icons.refresh, color: palette.teal),
                  label: Text('Retry', style: TextStyle(color: palette.teal)),
                ),
              ],
            ),
          ),
        ),
        ExamDetailStatus.loaded => _DetailBody(viewModel: viewModel),
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.viewModel});

  final ExamDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final exam = viewModel.exam!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ImageSection(viewModel: viewModel),
          const SizedBox(height: 16),
          _MetadataCard(exam: exam),
          const SizedBox(height: 16),
          if (exam.status == ExamStatus.completed &&
              viewModel.result != null)
            _FindingsSection(result: viewModel.result!)
          else if (exam.status == ExamStatus.failed)
            _NoteCard(
              icon: Icons.error_outline,
              color: palette.error,
              text: 'Inference failed for this exam.',
            )
          else
            _NoteCard(
              icon: Icons.hourglass_top_outlined,
              color: palette.cyan,
              text: 'Analysis still in progress. Check back shortly.',
            ),
        ],
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({required this.viewModel});

  final ExamDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bytes = viewModel.imageBytes;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes != null
          ? InteractiveViewer(
              maxScale: 4,
              child: Image.memory(bytes, fit: BoxFit.contain),
            )
          : Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: palette.hint,
              ),
            ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.exam});

  final Exam exam;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          _row(palette, 'File', exam.originalFilename),
          _row(palette, 'Status', exam.status.name),
          _row(palette, 'Size', _formatSize(exam.sizeBytes)),
          _row(palette, 'Date', _formatDate(exam.createdAt)),
        ],
      ),
    );
  }

  Widget _row(AppPalette palette, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(color: palette.hint, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _FindingsSection extends StatelessWidget {
  const _FindingsSection({required this.result});

  final InferenceResult result;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final sorted = [...result.findings]
      ..sort((a, b) => b.probability.compareTo(a.probability));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.teal.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, color: palette.teal, size: 20),
              const SizedBox(width: 8),
              Text(
                'Findings',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                result.modelVersion,
                style: TextStyle(color: palette.hint, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final finding in sorted) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    finding.label,
                    style: TextStyle(color: palette.textPrimary, fontSize: 13),
                  ),
                ),
                Text(
                  '${(finding.probability * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: palette.textSecondary, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: finding.probability,
                minHeight: 6,
                backgroundColor: palette.border,
                valueColor: AlwaysStoppedAnimation(palette.teal),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
