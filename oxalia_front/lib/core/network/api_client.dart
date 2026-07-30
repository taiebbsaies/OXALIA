import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// Single configured Dio instance for the whole app.
///
/// Services receive this through their repository instead of creating
/// their own HTTP clients, keeping headers, base URL and interceptors
/// consistent everywhere.
class ApiClient {
  ApiClient({TokenStorage? tokenStorage})
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            headers: {'Accept': 'application/json'},
          ),
        ) {
    dio.interceptors.add(AuthInterceptor(tokenStorage ?? TokenStorage()));
  }

  final Dio dio;
}
