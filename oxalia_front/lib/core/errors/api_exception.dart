import 'package:dio/dio.dart';

/// Domain-friendly wrapper around HTTP failures.
///
/// Services translate [DioException] into this type so ViewModels never
/// depend on the HTTP layer and the UI can display `message` directly.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDioException(DioException error) {
    final response = error.response;
    if (response != null) {
      final data = response.data;
      final detail = data is Map<String, dynamic> ? data['detail'] : null;
      return ApiException(
        detail is String ? detail : 'Request failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    return const ApiException('Network error. Check your connection.');
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
