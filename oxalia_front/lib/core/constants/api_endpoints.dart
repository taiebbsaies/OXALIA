/// REST endpoint paths, kept in one place so the API contract is explicit
/// and a backend route change touches a single file.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Devices / push
  static const String fcmToken = '/devices/fcm-token';

  // Exams
  static const String examUpload = '/exams/upload';
  static const String exams = '/exams';
  static const String examStats = '/exams/stats';
  static String examById(String examId) => '/exams/$examId';
  static String examResult(String examId) => '/exams/$examId/result';
  static String examImage(String examId) => '/exams/$examId/image';

  // Admin
  static const String adminStats = '/admin/stats';
  static const String adminUsers = '/admin/users';
  static String adminUserById(String userId) => '/admin/users/$userId';
}
