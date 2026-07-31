import 'package:dio/dio.dart';

import '../../core/errors/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Business-facing auth API consumed by ViewModels.
///
/// Owns token persistence and translates HTTP failures into [ApiException]
/// so the presentation layer never touches Dio.
class AuthRepository {
  AuthRepository({required AuthService authService, required TokenStorage tokenStorage})
    : _authService = authService,
      _tokenStorage = tokenStorage;

  final AuthService _authService;
  final TokenStorage _tokenStorage;

  Future<User> login({required String email, required String password}) async {
    try {
      final tokens = await _authService.login(email: email, password: password);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return _authService.me();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<User> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      return await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Revokes the refresh token server-side, then clears local storage.
  /// Local tokens are removed even if the network call fails — the user
  /// must never stay "logged in" on the device after an explicit logout.
  Future<void> logout() async {
    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken != null) {
        await _authService.logout(refreshToken: refreshToken);
      }
    } on DioException {
      // Server-side revocation failed; local logout still proceeds.
    } finally {
      await _tokenStorage.clear();
    }
  }

  /// Returns the current user if a valid session exists, null otherwise.
  Future<User?> getCurrentUser() async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null) return null;

    try {
      return await _authService.me();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await _tokenStorage.clear();
        return null;
      }
      throw ApiException.fromDioException(e);
    }
  }
}
