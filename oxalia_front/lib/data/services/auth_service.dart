import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/token_pair.dart';
import '../models/user.dart';

/// Raw HTTP calls against the /auth endpoints. No business logic here —
/// token persistence and error translation belong to the repository.
class AuthService {
  AuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<TokenPair> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return TokenPair.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.register,
      data: {'email': email, 'password': password, 'full_name': fullName},
    );
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout({required String refreshToken}) async {
    await _apiClient.dio.post(
      ApiEndpoints.logout,
      data: {'refresh_token': refreshToken},
    );
  }

  Future<User> me() async {
    final response = await _apiClient.dio.get(ApiEndpoints.me);
    return User.fromJson(response.data as Map<String, dynamic>);
  }
}
