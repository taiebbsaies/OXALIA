/// One bucket in a time-series chart (signups or exam volume).
class TrendPoint {
  const TrendPoint({required this.date, required this.count});

  final String date;
  final int count;

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(date: json['date'] as String, count: json['count'] as int);
  }
}

/// Mirrors the backend `AdminStatsOut` schema — platform-wide statistics
/// shown on the admin dashboard.
class AdminStats {
  const AdminStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.adminCount,
    required this.clinicianCount,
    required this.newUsers7d,
    required this.newUsers30d,
    required this.totalExams,
    required this.completedExams,
    required this.processingExams,
    required this.failedExams,
    required this.pendingExams,
    required this.newExams7d,
    required this.newExams30d,
    required this.failureRatePct,
    required this.modelVersions,
    required this.avgProcessingSeconds,
    required this.userGrowth,
    required this.examVolume,
  });

  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int adminCount;
  final int clinicianCount;
  final int newUsers7d;
  final int newUsers30d;

  final int totalExams;
  final int completedExams;
  final int processingExams;
  final int failedExams;
  final int pendingExams;
  final int newExams7d;
  final int newExams30d;
  final double failureRatePct;

  final Map<String, int> modelVersions;
  final double? avgProcessingSeconds;

  final List<TrendPoint> userGrowth;
  final List<TrendPoint> examVolume;

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['total_users'] as int,
      activeUsers: json['active_users'] as int,
      inactiveUsers: json['inactive_users'] as int,
      adminCount: json['admin_count'] as int,
      clinicianCount: json['clinician_count'] as int,
      newUsers7d: json['new_users_7d'] as int,
      newUsers30d: json['new_users_30d'] as int,
      totalExams: json['total_exams'] as int,
      completedExams: json['completed_exams'] as int,
      processingExams: json['processing_exams'] as int,
      failedExams: json['failed_exams'] as int,
      pendingExams: json['pending_exams'] as int,
      newExams7d: json['new_exams_7d'] as int,
      newExams30d: json['new_exams_30d'] as int,
      failureRatePct: (json['failure_rate_pct'] as num).toDouble(),
      modelVersions: Map<String, int>.from(json['model_versions'] as Map),
      avgProcessingSeconds: (json['avg_processing_seconds'] as num?)?.toDouble(),
      userGrowth: (json['user_growth'] as List<dynamic>)
          .map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      examVolume: (json['exam_volume'] as List<dynamic>)
          .map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
