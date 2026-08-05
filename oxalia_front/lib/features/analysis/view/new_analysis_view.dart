import 'package:fluid_progress_indicator/fluid_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/analysis_result_card.dart';
import '../../../shared/widgets/scanner_viewport.dart';
import '../viewmodel/analysis_viewmodel.dart';

/// Scanner-style capture screen: pick → auto-upload → result card.
class NewAnalysisView extends StatelessWidget {
  const NewAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AnalysisViewModel>();
    final palette = context.palette;

    if (viewModel.step == AnalysisStep.completed &&
        viewModel.exam != null &&
        viewModel.result != null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AnalysisResultCard(
              exam: viewModel.exam!,
              result: viewModel.result!,
              imageBytes: viewModel.imageBytes,
              onBack: () => context.pop(),
              onNewAnalysis: viewModel.reset,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            _ScannerHeader(onBack: () => context.pop()),
            const SizedBox(height: 8),
            _AiReadyBadge(pulse: viewModel.step == AnalysisStep.idle),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: ScannerViewport(
                  showScanLine: viewModel.step == AnalysisStep.idle ||
                      viewModel.step == AnalysisStep.scanning,
                  child: _ViewportContent(viewModel: viewModel),
                ),
              ),
            ),
            if (viewModel.step == AnalysisStep.uploading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _UploadBar(progress: viewModel.uploadProgress),
              ),
            if (viewModel.step == AnalysisStep.failed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  viewModel.errorMessage ?? 'Analysis failed',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.error, fontSize: 13),
                ),
              ),
            _BottomSheet(
              enabled: !viewModel.isBusy,
              onGallery: () => viewModel.pickImage(ImageSource.gallery),
              onCapture: () => viewModel.pickImage(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerHeader extends StatelessWidget {
  const _ScannerHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        children: [
          _CircleBtn(icon: Icons.arrow_back, onPressed: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Analysis',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Chest X-Ray · AI Mode',
                  style: TextStyle(color: palette.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          _CircleBtn(
            icon: Icons.bolt_outlined,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Flash control coming soon.')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: palette.textPrimary, size: 20),
        ),
      ),
    );
  }
}

class _AiReadyBadge extends StatefulWidget {
  const _AiReadyBadge({required this.pulse});

  final bool pulse;

  @override
  State<_AiReadyBadge> createState() => _AiReadyBadgeState();
}

class _AiReadyBadgeState extends State<_AiReadyBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.pulse) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_AiReadyBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulse && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF10B981);

    return FadeTransition(
      opacity: widget.pulse
          ? Tween(begin: 0.55, end: 1.0).animate(_controller)
          : const AlwaysStoppedAnimation(1),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: green.withValues(alpha: 0.45)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: green),
            SizedBox(width: 8),
            Text(
              'AI READY',
              style: TextStyle(
                color: green,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewportContent extends StatelessWidget {
  const _ViewportContent({required this.viewModel});

  final AnalysisViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bytes = viewModel.imageBytes;

    switch (viewModel.step) {
      case AnalysisStep.idle:
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: palette.background.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_camera_outlined, color: palette.cyan, size: 28),
                const SizedBox(height: 8),
                Text(
                  'Position X-ray within frame',
                  style: TextStyle(color: palette.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      case AnalysisStep.scanning:
        return Center(
          child: Lottie.asset(
            'assets/animations/scanner.json',
            height: 140,
            fit: BoxFit.contain,
          ),
        );
      case AnalysisStep.uploading:
      case AnalysisStep.processing:
      case AnalysisStep.failed:
      case AnalysisStep.completed:
        if (bytes == null) {
          return Center(
            child: Icon(Icons.image_outlined, size: 48, color: palette.hint),
          );
        }
        return Stack(
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
        );
    }
  }
}

class _UploadBar extends StatelessWidget {
  const _UploadBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final percent = (progress * 100).clamp(0, 100).toInt();

    return Column(
      children: [
        Row(
          children: [
            Text(
              'Uploading…',
              style: TextStyle(color: palette.textSecondary, fontSize: 12),
            ),
            const Spacer(),
            Text(
              '$percent%',
              style: TextStyle(color: palette.teal, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 28,
          child: FluidProgressIndicator(
            maxProgress: 100,
            progress: percent,
            fillGradient: LinearGradient(colors: [palette.teal, palette.cyan]),
            backgroundConfig: IndicatorBackgroundConfig(
              color: palette.border.withValues(alpha: 0.3),
            ),
            borderRadius: 8,
            heightAnimationDuration: const Duration(milliseconds: 300),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _BottomSheet extends StatelessWidget {
  const _BottomSheet({
    required this.enabled,
    required this.onGallery,
    required this.onCapture,
  });

  final bool enabled;
  final VoidCallback onGallery;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final width = MediaQuery.sizeOf(context).width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ensure good lighting and full image visibility for best AI results.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: enabled ? onGallery : null,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Open Gallery', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: Opacity(
                  opacity: enabled ? 1 : 0.5,
                  child: AnimatedButton(
                    width: (width - 42) / 2,
                    height: 52,
                    text: 'Capture Photo',
                    onPress: enabled ? onCapture : null,
                    transitionType: TransitionType.LEFT_TO_RIGHT,
                    backgroundColor: palette.teal,
                    selectedBackgroundColor: palette.cyan,
                    borderRadius: 12,
                    borderWidth: 0,
                    isReverse: true,
                    animationDuration: const Duration(milliseconds: 400),
                    textStyle: TextStyle(
                      color: palette.onAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    selectedTextColor: palette.onAccent,
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
