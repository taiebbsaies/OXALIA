import 'package:dio/dio.dart';

import '../../core/errors/api_exception.dart';
import '../models/admin_stats.dart';
import '../models/admin_user.dart';
import '../services/admin_service.dart';

/// Business-facing admin API consumed by ViewModels. Translates HTTP
/// failures into [ApiException] so the presentation layer never touches Dio.
class AdminRepository {
  AdminRepository({required AdminService adminService}) : _adminService = adminService;

  final AdminService _adminService;

  Future<AdminStats> getStats() async {
    try {
      return await _adminService.getStats();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<AdminUser>> listUsers() async {
    try {
      return await _adminService.listUsers();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AdminUser> updateUserRole(String userId, String role) async {
    try {
      return await _adminService.updateUser(userId: userId, role: role);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AdminUser> setUserActive(String userId, bool isActive) async {
    try {
      return await _adminService.updateUser(userId: userId, isActive: isActive);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _adminService.deleteUser(userId);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
