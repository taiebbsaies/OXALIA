/// Mirrors the backend `AdminUserOut` schema — a row in the admin
/// user-management table.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.examCount,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final int examCount;

  bool get isAdmin => role == 'admin';

  AdminUser copyWith({String? role, bool? isActive}) {
    return AdminUser(
      id: id,
      email: email,
      fullName: fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      examCount: examCount,
    );
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      examCount: json['exam_count'] as int,
    );
  }
}
