import 'package:flutter/material.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';

import '../../core/theme/app_theme.dart';

/// Full-width gradient action button with a tap sweep animation
/// and a built-in loading state.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onPressed != null && !isLoading;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: palette.teal.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: isLoading
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette.teal, palette.cyan],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: palette.onAccent,
                    ),
                  ),
                ),
              )
            : AnimatedButton(
                width: double.infinity,
                height: 52,
                text: label,
                onPress: enabled ? onPressed : null,
                // Sweep follows the gradient direction: teal -> cyan.
                transitionType: TransitionType.LEFT_TO_RIGHT,
                gradient: LinearGradient(
                  colors: [palette.teal, palette.cyan],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                selectedBackgroundColor: const Color(0xFF67E8F9),
                isReverse: true,
                animationDuration: const Duration(milliseconds: 400),
                borderRadius: 12,
                textStyle: TextStyle(
                  color: palette.onAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
                selectedTextColor: const Color(0xFF06202B),
              ),
      ),
    );
  }
}
