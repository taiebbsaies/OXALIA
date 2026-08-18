/// A single entry in the in-app notification inbox.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.examId,
    this.type = 'exam_status',
    this.status,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? examId;
  final String type;
  final String? status;
  final bool read;

  bool get isSuccess => status == 'completed';
  bool get isFailure => status == 'failed';

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      examId: examId,
      type: type,
      status: status,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'exam_id': examId,
        'type': type,
        'status': status,
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      examId: json['exam_id'] as String?,
      type: json['type'] as String? ?? 'exam_status',
      status: json['status'] as String?,
      read: json['read'] as bool? ?? false,
    );
  }
}
