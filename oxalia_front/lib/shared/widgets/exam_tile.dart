import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/exam.dart';
import '../../routing/app_router.dart';

/// Compact exam list row shared by Home (recent analyses) and History:
/// thumbnail placeholder, filename, date, and a colored status chip.
class ExamTile extends StatelessWidget {
  const ExamTile({super.key, required this.exam});

  final Exam exam;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(AppRoutes.examDetail(exam.id)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: palette.teal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.originalFilename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatExamDate(exam.createdAt),
                      style: TextStyle(color: palette.hint, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ExamStatusChip(status: exam.status),
            ],
          ),
        ),
      ),
    );
  }
}

/// Colored pill showing the exam lifecycle status.
class ExamStatusChip extends StatelessWidget {
  const ExamStatusChip({super.key, required this.status});

  final ExamStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final (label, color) = switch (status) {
      ExamStatus.completed => ('Completed', palette.teal),
      ExamStatus.failed => ('Failed', palette.error),
      ExamStatus.processing => ('Analyzing', palette.cyan),
      ExamStatus.pending => ('Pending', palette.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// dd/MM/yyyy HH:mm in local time.
String formatExamDate(DateTime date) {
  final local = date.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
