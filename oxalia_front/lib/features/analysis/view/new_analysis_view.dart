import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:fluid_progress_indicator/fluid_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../routing/app_router.dart';
import '../../../shared/widgets/analysis_result_card.dart';
import '../../../shared/widgets/scanner_viewport.dart';
import '../viewmodel/analysis_viewmodel.dart';

void _safeBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.home);
  }
}

/// Scanner-style capture screen: pick → drag-crop → upload → result.
class NewAnalysisView extends StatelessWidget {
  const NewAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AnalysisViewModel>();
    final palette = context.palette;

    if (viewModel.step == AnalysisStep.completed &&
        viewModel.exam != null &&
        viewModel.result != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, __) => _safeBack(context),
        child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AnalysisResultCard(
              exam: viewModel.exam!,
              result: viewModel.result!,
              imageBytes: viewModel.imageBytes,
              onBack: () => _safeBack(context),
              onNewAnalysis: viewModel.reset,
            ),
          ),
        ),
      ),
      );
    }

    final isCropping = viewModel.step == AnalysisStep.resizing &&
        viewModel.sourceBytes != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _safeBack(context),
      child: Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            _ScannerHeader(onBack: () => _safeBack(context)),
            const SizedBox(height: 8),
            _AiReadyBadge(
              pulse: viewModel.step == AnalysisStep.idle || isCropping,
            ),
            if (isCropping)
              Expanded(
                child: _InteractiveCropPanel(
                  imageBytes: viewModel.sourceBytes!,
                  applying: viewModel.applyingCrop,
                  onDiscard: viewModel.discardImage,
                  onBeginCrop: viewModel.beginCrop,
                  onCropped: viewModel.applyCroppedAndUpload,
                  onCropError: viewModel.setCropError,
                ),
              )
            else ...[
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    viewModel.errorMessage ?? 'Analysis failed',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.error, fontSize: 13),
                  ),
                ),
              _BottomSheet(
                enabled: viewModel.canCapture,
                patientName: viewModel.patientName,
                onPatientNameChanged: viewModel.setPatientName,
                nameEditable: !viewModel.isBusy,
                onGallery: () => viewModel.pickImage(ImageSource.gallery),
                onCapture: () => viewModel.pickImage(ImageSource.camera),
              ),
            ],
          ],
        ),
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
      case AnalysisStep.resizing:
        // Handled by [_InteractiveCropPanel] outside the scanner viewport.
        return const SizedBox.shrink();
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
    required this.patientName,
    required this.onPatientNameChanged,
    required this.nameEditable,
    required this.onGallery,
    required this.onCapture,
  });

  final bool enabled;
  final String patientName;
  final ValueChanged<String> onPatientNameChanged;
  final bool nameEditable;
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
          _PatientNameField(
            patientName: patientName,
            enabled: nameEditable,
            onChanged: onPatientNameChanged,
            accentColor: palette.teal,
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enter the patient name, then capture or pick an X-ray. '
                  'Drag the corners to crop before upload.',
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

class _PatientNameField extends StatefulWidget {
  const _PatientNameField({
    required this.patientName,
    required this.enabled,
    required this.onChanged,
    required this.accentColor,
  });

  final String patientName;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final Color accentColor;

  @override
  State<_PatientNameField> createState() => _PatientNameFieldState();
}

class _PatientNameFieldState extends State<_PatientNameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.patientName);
  }

  @override
  void didUpdateWidget(covariant _PatientNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync after ViewModel.reset() clears the name.
    if (widget.patientName != _controller.text &&
        widget.patientName.isEmpty) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: widget.enabled,
      controller: _controller,
      onChanged: widget.onChanged,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: 'Patient name',
        hintText: 'e.g. Jane Doe',
        prefixIcon: const Icon(Icons.person_outline, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.accentColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}

/// Full-screen crop editor: drag the corner dots to resize the crop area.
class _InteractiveCropPanel extends StatefulWidget {
  const _InteractiveCropPanel({
    required this.imageBytes,
    required this.applying,
    required this.onDiscard,
    required this.onBeginCrop,
    required this.onCropped,
    required this.onCropError,
  });

  final Uint8List imageBytes;
  final bool applying;
  final VoidCallback onDiscard;
  final VoidCallback onBeginCrop;
  final Future<void> Function(Uint8List croppedBytes) onCropped;
  final ValueChanged<String> onCropError;

  @override
  State<_InteractiveCropPanel> createState() => _InteractiveCropPanelState();
}

class _InteractiveCropPanelState extends State<_InteractiveCropPanel> {
  final CropController _controller = CropController();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final width = MediaQuery.sizeOf(context).width;
    final cropError = context.select<AnalysisViewModel, String?>(
      (vm) => vm.errorMessage,
    );

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Crop(
                image: widget.imageBytes,
                controller: _controller,
                baseColor: palette.background,
                maskColor: Colors.black.withValues(alpha: 0.55),
                radius: 4,
                interactive: true,
                initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                  size: 0.85,
                ),
                cornerDotBuilder: (size, edgeAlignment) => DotControl(
                  color: palette.teal,
                  padding: 14,
                ),
                progressIndicator: Center(
                  child: CircularProgressIndicator(color: palette.teal),
                ),
                onCropped: (result) {
                  switch (result) {
                    case CropSuccess(:final croppedImage):
                      widget.onCropped(croppedImage);
                    case CropFailure():
                      widget.onCropError(
                        'Could not crop the image. Try again.',
                      );
                  }
                },
              ),
            ),
          ),
        ),
        Container(
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Crop image',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Drag the corners with your finger to resize the area, '
                'then upload.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              if (cropError != null) ...[
                const SizedBox(height: 8),
                Text(
                  cropError,
                  style: TextStyle(color: palette.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.applying ? null : widget.onDiscard,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Opacity(
                      opacity: widget.applying ? 0.6 : 1,
                      child: AnimatedButton(
                        width: (width - 42) / 2,
                        height: 52,
                        text: widget.applying ? 'Cropping…' : 'Upload',
                        onPress: widget.applying
                            ? null
                            : () {
                                widget.onBeginCrop();
                                _controller.crop();
                              },
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
        ),
      ],
    );
  }
}


