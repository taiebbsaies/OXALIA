import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Decorative ECG heartbeat trace drawn along the bottom of auth screens.
/// Static for now; will be replaced by an animated version later.
class EcgLine extends StatelessWidget {
  const EcgLine({super.key, this.height = 64});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _EcgPainter(context.palette.teal)),
    );
  }
}

class _EcgPainter extends CustomPainter {
  _EcgPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height * 0.55;
    final path = Path()
      ..moveTo(0, baseline)
      ..lineTo(size.width * 0.28, baseline)
      // P wave (small bump)
      ..quadraticBezierTo(
        size.width * 0.31,
        baseline - size.height * 0.18,
        size.width * 0.34,
        baseline,
      )
      ..lineTo(size.width * 0.40, baseline)
      // QRS complex (sharp spike)
      ..lineTo(size.width * 0.425, baseline + size.height * 0.15)
      ..lineTo(size.width * 0.45, baseline - size.height * 0.42)
      ..lineTo(size.width * 0.475, baseline + size.height * 0.28)
      ..lineTo(size.width * 0.50, baseline)
      ..lineTo(size.width * 0.58, baseline)
      // T wave (rounded bump)
      ..quadraticBezierTo(
        size.width * 0.62,
        baseline - size.height * 0.25,
        size.width * 0.66,
        baseline,
      )
      ..lineTo(size.width, baseline);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, glowPaint);

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_EcgPainter oldDelegate) => color != oldDelegate.color;
}
