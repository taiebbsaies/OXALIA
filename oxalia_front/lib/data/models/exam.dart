/// Mirrors the backend `ExamOut` schema and `ExamStatus` enum.
enum ExamStatus {
  pending,
  processing,
  completed,
  failed;

  static ExamStatus fromString(String value) {
    return ExamStatus.values.asNameMap()[value] ?? ExamStatus.pending;
  }
}

class Exam {
  const Exam({
    required this.id,
    required this.originalFilename,
    required this.contentType,
    required this.sizeBytes,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String originalFilename;
  final String contentType;
  final int sizeBytes;
  final ExamStatus status;
  final DateTime createdAt;

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String,
      originalFilename: json['original_filename'] as String,
      contentType: json['content_type'] as String,
      sizeBytes: json['size_bytes'] as int,
      status: ExamStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
