/// Mirrors the backend `UserOut` schema.
class User {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.phoneNumber,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final String? phoneNumber;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      phoneNumber: json['phone_number'] as String?,
    );
  }
}
