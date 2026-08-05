import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Attaches the Bearer access token to outgoing requests.
///
/// Public auth endpoints are excluded so a stale token is never sent
/// to login/register/refresh.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  static const Set<String> _publicPaths = {
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_publicPaths.contains(options.path)) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
