import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Small uppercase caption shown above auth form fields.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: context.palette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}
