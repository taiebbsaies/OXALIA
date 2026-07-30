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

  // Exams
  static const String examUpload = '/exams/upload';
  static String examById(String examId) => '/exams/$examId';
  static String examResult(String examId) => '/exams/$examId/result';
}
