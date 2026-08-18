import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/admin_stats.dart';
import '../models/admin_user.dart';

/// Raw HTTP calls against the /admin endpoints (admin-only).
class AdminService {
  AdminService(this._apiClient);

  final ApiClient _apiClient;

  Future<AdminStats> getStats() async {
    final response = await _apiClient.dio.get(ApiEndpoints.adminStats);
    return AdminStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AdminUser>> listUsers() async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.adminUsers,
      queryParameters: {'limit': 500},
    );
    return (response.data as List<dynamic>)
        .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminUser> updateUser({
    required String userId,
    String? role,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    data['role'] = role;
    data['is_active'] = isActive;
    data.removeWhere((_, value) => value == null);

    final response = await _apiClient.dio.patch(
      ApiEndpoints.adminUserById(userId),
      data: data,
    );
    return AdminUser.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteUser(String userId) async {
    await _apiClient.dio.delete(ApiEndpoints.adminUserById(userId));
  }
}
