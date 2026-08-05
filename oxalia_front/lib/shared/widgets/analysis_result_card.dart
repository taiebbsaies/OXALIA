import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/report_pdf_builder.dart';
import '../../data/models/exam.dart';
import '../../data/models/inference_result.dart';

/// Premium result layout matching the Analysis Result mockup:
/// dark chrome, X-ray preview, white floating card with prediction /
/// confidence / findings, and Download Report + New Analysis actions.
class AnalysisResultCard extends StatelessWidget {
  const AnalysisResultCard({
    super.key,
    required this.exam,
    required this.result,
    this.imageBytes,
    this.onNewAnalysis,
    this.onBack,
    this.showChrome = true,
  });

  final Exam exam;
  final InferenceResult result;
  final Uint8List? imageBytes;
  final VoidCallback? onNewAnalysis;
  final VoidCallback? onBack;

  /// When false, only the white content card is shown (embedded layouts).
  final bool showChrome;

  @override
  Widget build(BuildContext context) {
    final sorted = [...result.findings]
      ..sort((a, b) => b.probability.compareTo(a.probability));
    final top = sorted.isNotEmpty ? sorted.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showChrome) ...[
          _ResultHeader(
            examId: exam.id,
            onBack: onBack,
          ),
          const SizedBox(height: 12),
          _ImagePreviewCard(imageBytes: imageBytes),
          const SizedBox(height: 16),
        ],
        _WhiteResultPanel(
          top: top,
          findings: sorted,
          exam: exam,
          result: result,
        ),
        const SizedBox(height: 16),
        _ActionRow(
          exam: exam,
          result: result,
          onNewAnalysis: onNewAnalysis,
        ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
      ],
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.examId, this.onBack});

  final String examId;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shortId = examId.length > 8 ? examId.substring(0, 8) : examId;

    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.arrow_back,
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis Result',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'XR-$shortId',
                style: TextStyle(color: palette.hint, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.5),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
              SizedBox(width: 6),
              Text(
                'COMPLETE',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});

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

class _ImagePreviewCard extends StatelessWidget {
  const _ImagePreviewCard({this.imageBytes});

  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageBytes != null)
            Image.memory(imageBytes!, fit: BoxFit.contain)
          else
            Center(
              child: Icon(Icons.image_outlined, size: 48, color: palette.hint),
            ),
          Positioned(
            top: 10,
            left: 10,
            child: _Badge(label: 'CXR', color: palette.cyan),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: _Badge(
              label: 'AI REVIEWED',
              color: palette.cyan,
              showDot: true,
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Text(
              'AI-assisted analysis — Not a clinical diagnosis.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.hint, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.showDot = false,
  });

  final String label;
  final Color color;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Icon(Icons.circle, size: 6, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteResultPanel extends StatelessWidget {
  const _WhiteResultPanel({
    required this.top,
    required this.findings,
    required this.exam,
    required this.result,
  });

  final Finding? top;
  final List<Finding> findings;
  final Exam exam;
  final InferenceResult result;

  @override
  Widget build(BuildContext context) {
    final confidence = top?.probability ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: const Color(0xFFD1FAE5),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF059669), size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analysis Complete',
                        style: TextStyle(
                          color: Color(0xFF064E3B),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Results ready for review',
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PREDICTION',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  top?.label ?? 'No Finding',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _descriptionFor(top?.label),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text(
                      'CONFIDENCE',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: confidence),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF10B981),
                        ),
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Text(
                        'Low',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 10,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'High',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'DETECTED FINDINGS',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                for (final finding in findings) ...[
                  _FindingPill(finding: finding),
                  const SizedBox(height: 8),
                ],
                const Divider(height: 24, color: Color(0xFFE5E7EB)),
                _MetaLine(label: 'Model Version', value: result.modelVersion),
                _MetaLine(
                  label: 'Exam ID',
                  value: exam.id.length > 12
                      ? '${exam.id.substring(0, 12)}…'
                      : exam.id,
                ),
                _MetaLine(label: 'Date', value: _formatDate(exam.createdAt)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _descriptionFor(String? label) {
    if (label == null) {
      return 'No significant pathology detected by the model.';
    }
    return 'Model prediction for "$label". Review by a radiologist '
        'is recommended before clinical decision.';
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _FindingPill extends StatelessWidget {
  const _FindingPill({required this.finding});

  final Finding finding;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, dot) = _severityColors(finding.probability);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: dot),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              finding.label,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${(finding.probability * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, Color, Color) _severityColors(double p) {
    if (p >= 0.7) {
      return (
        const Color(0xFFFEE2E2),
        const Color(0xFF991B1B),
        const Color(0xFFDC2626),
      );
    }
    if (p >= 0.4) {
      return (
        const Color(0xFFFEF3C7),
        const Color(0xFF92400E),
        const Color(0xFFF59E0B),
      );
    }
    return (
      const Color(0xFFD1FAE5),
      const Color(0xFF065F46),
      const Color(0xFF10B981),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF374151), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.exam,
    required this.result,
    this.onNewAnalysis,
  });

  final Exam exam;
  final InferenceResult result;
  final VoidCallback? onNewAnalysis;

  Future<void> _download(BuildContext context) async {
    try {
      final bytes = await ReportPdfBuilder.build(exam: exam, result: result);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'oxalia_report_${exam.id.substring(0, 8)}.pdf',
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate the report.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final width = MediaQuery.sizeOf(context).width;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _download(context),
            icon: Icon(Icons.upload_outlined, color: palette.textPrimary),
            label: Text(
              'Download Report',
              style: TextStyle(color: palette.textPrimary, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: palette.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AnimatedButton(
            width: (width - 42) / 2,
            height: 52,
            text: 'New Analysis',
            onPress: onNewAnalysis,
            transitionType: TransitionType.LEFT_TO_RIGHT,
            backgroundColor: palette.teal,
            selectedBackgroundColor: palette.cyan,
            borderRadius: 12,
            borderWidth: 0,
            isReverse: true,
            animationDuration: const Duration(milliseconds: 400),
            textStyle: TextStyle(
              color: palette.onAccent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            selectedTextColor: palette.onAccent,
          ),
        ),
      ],
    );
  }
}
