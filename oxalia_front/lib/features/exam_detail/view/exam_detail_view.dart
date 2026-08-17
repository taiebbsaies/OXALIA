import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/exam.dart';
import '../../../routing/app_router.dart';
import '../../../shared/widgets/analysis_result_card.dart';
import '../viewmodel/exam_detail_viewmodel.dart';

void _safeBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.home);
  }
}

/// Full exam detail — reuses the same result card as the post-analysis
/// screen when inference completed; otherwise shows status notes.
class ExamDetailView extends StatelessWidget {
  const ExamDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExamDetailViewModel>();
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: switch (viewModel.status) {
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
          ExamDetailStatus.loaded => _LoadedBody(viewModel: viewModel),
        },
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.viewModel});

  final ExamDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final exam = viewModel.exam!;

    if (exam.status == ExamStatus.completed && viewModel.result != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: AnalysisResultCard(
          exam: exam,
          result: viewModel.result!,
          imageBytes: viewModel.imageBytes,
          onBack: () => _safeBack(context),
          onNewAnalysis: () => context.push(AppRoutes.newAnalysis),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _safeBack(context),
                icon: Icon(Icons.arrow_back, color: palette.textPrimary),
              ),
              Text(
                'Exam Details',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: viewModel.imageBytes != null
                ? Image.memory(viewModel.imageBytes!, fit: BoxFit.contain)
                : Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: palette.hint,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: exam.status == ExamStatus.failed
                    ? palette.error.withValues(alpha: 0.4)
                    : palette.cyan.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  exam.status == ExamStatus.failed
                      ? Icons.error_outline
                      : Icons.hourglass_top_outlined,
                  color: exam.status == ExamStatus.failed
                      ? palette.error
                      : palette.cyan,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    exam.status == ExamStatus.failed
                        ? 'Inference failed for this exam.'
                        : 'Analysis still in progress. Check back shortly.',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 13,
                    ),
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
