/// Mirrors the backend `ExamStatsOut` schema (GET /exams/stats).
class ExamStats {
  const ExamStats({
    required this.total,
    required this.completed,
    required this.processing,
    required this.failed,
    required this.modelVersions,
  });

  final int total;
  final int completed;

  /// Exams still in flight (pending + processing server-side).
  final int processing;
  final int failed;

  /// model_version -> number of analyses run on it.
  final Map<String, int> modelVersions;

  double get successRate {
    if (total == 0) return 0;
    return completed / total;
  }

  factory ExamStats.fromJson(Map<String, dynamic> json) {
    final rawVersions = json['model_versions'] as Map<String, dynamic>;
    return ExamStats(
      total: json['total'] as int,
      completed: json['completed'] as int,
      processing: json['processing'] as int,
      failed: json['failed'] as int,
      modelVersions: rawVersions.map(
        (key, value) => MapEntry(key, value as int),
      ),
    );
  }
}
