import 'package:fluid_progress_indicator/fluid_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/inference_result.dart';
import '../../../shared/widgets/dashed_border.dart';
import '../../../shared/widgets/field_label.dart';
import '../../../shared/widgets/primary_button.dart';
import '../viewmodel/analysis_viewmodel.dart';

/// "New Analysis" capture screen: pick/preprocess an X-ray, upload it,
/// then poll until the model's findings are ready.
class NewAnalysisView extends StatelessWidget {
  const NewAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AnalysisViewModel>();
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('New Analysis')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    const FieldLabel('PATIENT INFORMATION'),
                    TextFormField(
                      style: TextStyle(color: palette.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Enter patient name or ID',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Patient records are coming soon.'),
                            ),
                          );
                        },
                        child: Text(
                          'Select Existing Patient',
                          style: TextStyle(color: palette.teal, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const FieldLabel('X-RAY IMAGE'),
                    _ImageDropZone(viewModel: viewModel),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _SourceButton(
                            icon: Icons.photo_camera_outlined,
                            label: 'Take a photo',
                            onPressed: viewModel.isBusy
                                ? null
                                : () => viewModel.pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SourceButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Upload from Gallery',
                            onPressed: viewModel.isBusy
                                ? null
                                : () =>
                                      viewModel.pickImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _StatusSection(viewModel: viewModel),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: PrimaryButton(
                label: switch (viewModel.step) {
                  AnalysisStep.uploading => 'Uploading…',
                  AnalysisStep.processing => 'Analyzing…',
                  _ => 'Start Analysis',
                },
                isLoading: viewModel.isBusy,
                onPressed:
                    viewModel.step == AnalysisStep.ready ||
                        viewModel.step == AnalysisStep.failed
                    ? viewModel.startAnalysis
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashed drop zone: X-ray placeholder before picking, scan animation
/// during preprocessing, then the image preview — with the scanning
/// overlay looping on top while the model analyzes.
class _ImageDropZone extends StatelessWidget {
  const _ImageDropZone({required this.viewModel});

  final AnalysisViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bytes = viewModel.imageBytes;

    return DashedBorder(
      color: palette.border,
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: switch (viewModel.step) {
          AnalysisStep.idle => Center(
            child: Icon(Icons.image_outlined, size: 64, color: palette.hint),
          ),
          AnalysisStep.scanning => Center(
            child: Lottie.asset(
              'assets/animations/scanner.json',
              height: 160,
              fit: BoxFit.contain,
            ),
          ),
          _ when bytes != null => Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(bytes, fit: BoxFit.contain),
              if (viewModel.step == AnalysisStep.processing)
                ColoredBox(
                  color: palette.background.withValues(alpha: 0.55),
                  child: Center(
                    child: Lottie.asset(
                      'assets/animations/image scanning.json',
                      height: 180,
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                ),
            ],
          ),
          _ => Center(
            child: Icon(Icons.image_outlined, size: 64, color: palette.hint),
          ),
        },
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.teal,
        side: BorderSide(color: palette.teal, width: 1.5),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Upload progress, polling status, findings, or the error banner —
/// whichever matches the current pipeline step.
class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.viewModel});

  final AnalysisViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    switch (viewModel.step) {
      case AnalysisStep.idle:
      case AnalysisStep.scanning:
      case AnalysisStep.ready:
        return const SizedBox.shrink();

      case AnalysisStep.uploading:
        return _UploadProgressCard(progress: viewModel.uploadProgress);

      case AnalysisStep.processing:
        return _StatusCard(
          icon: Icons.psychology_outlined,
          color: palette.teal,
          title: 'Analysis in progress…',
          subtitle: 'The model is examining the image. This can take a while.',
          trailing: TextButton(
            onPressed: viewModel.cancelWait,
            child: Text(
              'Run in background',
              style: TextStyle(color: palette.textSecondary, fontSize: 12),
            ),
          ),
        );

      case AnalysisStep.failed:
        return _StatusCard(
          icon: Icons.error_outline,
          color: palette.error,
          title: 'Analysis failed',
          subtitle: viewModel.errorMessage ?? 'Unknown error',
        );

      case AnalysisStep.completed:
        final result = viewModel.result;
        if (result == null) return const SizedBox.shrink();
        return _FindingsCard(result: result);
    }
  }
}

/// Liquid-fill upload bar driven by Dio's real send progress.
class _UploadProgressCard extends StatelessWidget {
  const _UploadProgressCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final percent = (progress * 100).clamp(0, 100).toInt();

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
              Icon(Icons.cloud_upload_outlined, color: palette.teal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Uploading image…',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(color: palette.teal, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: FluidProgressIndicator(
              maxProgress: 100,
              progress: percent,
              fillGradient: LinearGradient(
                colors: [palette.teal, palette.cyan],
              ),
              backgroundConfig: IndicatorBackgroundConfig(
                color: palette.border.withValues(alpha: 0.3),
              ),
              borderRadius: 10,
              heightAnimationDuration: const Duration(milliseconds: 400),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Retries automatically if the connection drops.',
            style: TextStyle(color: palette.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;

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
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: palette.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Ranked list of findings with probability bars, shown once inference
/// completes.
class _FindingsCard extends StatelessWidget {
  const _FindingsCard({required this.result});

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
              Icon(Icons.check_circle_outline, color: palette.teal, size: 20),
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
