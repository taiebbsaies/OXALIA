import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/exam.dart';
import '../models/exam_stats.dart';
import '../models/inference_result.dart';

/// Raw HTTP calls against the /exams endpoints. Retry policy and polling
/// live in the repository; this class only knows the wire format.
class ExamService {
  ExamService(this._apiClient);

  final ApiClient _apiClient;

  /// Multipart upload of a preprocessed image. The send timeout is raised
  /// because mobile connections can be slow with multi-MB payloads.
  /// [onSendProgress] reports (sent, total) bytes for the progress UI.
  Future<Exam> uploadExam({
    required Uint8List imageBytes,
    required String patientName,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'patient_name': patientName,
      'file': MultipartFile.fromBytes(
        imageBytes,
        filename: '${patientName.replaceAll(RegExp(r"\s+"), "_")}.jpg',
        contentType: DioMediaType('image', 'jpeg'),
      ),
    });

    final response = await _apiClient.dio.post(
      ApiEndpoints.examUpload,
      data: formData,
      onSendProgress: onSendProgress,
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return Exam.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Exam> getExam(String examId) async {
    final response = await _apiClient.dio.get(ApiEndpoints.examById(examId));
    return Exam.fromJson(response.data as Map<String, dynamic>);
  }

  Future<InferenceResult> getResult(String examId) async {
    final response = await _apiClient.dio.get(ApiEndpoints.examResult(examId));
    return InferenceResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Exam>> listExams({int limit = 50, int offset = 0}) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.exams,
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return (response.data as List<dynamic>)
        .map((e) => Exam.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExamStats> getStats() async {
    final response = await _apiClient.dio.get(ApiEndpoints.examStats);
    return ExamStats.fromJson(response.data as Map<String, dynamic>);
  }

  /// Raw bytes of the stored exam image, for `Image.memory`.
  Future<Uint8List> getExamImage(String examId) async {
    final response = await _apiClient.dio.get<List<int>>(
      ApiEndpoints.examImage(examId),
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }
}
