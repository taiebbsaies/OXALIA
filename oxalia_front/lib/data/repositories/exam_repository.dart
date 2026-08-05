import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/errors/api_exception.dart';
import '../models/exam.dart';
import '../models/exam_stats.dart';
import '../models/inference_result.dart';
import '../services/exam_service.dart';

/// Business-facing exams API consumed by ViewModels.
///
/// Owns two transport concerns the service deliberately ignores:
/// - **Upload retry**: mobile networks drop; transient failures are retried
///   with exponential backoff. Client errors (4xx) fail immediately.
/// - **Result polling**: inference is asynchronous and can take minutes,
///   so the repository polls the exam status until it resolves or times out.
class ExamRepository {
  ExamRepository({required ExamService examService})
    : _examService = examService;

  final ExamService _examService;

  static const int maxUploadAttempts = 3;
  static const Duration _initialBackoff = Duration(seconds: 1);

  static const Duration pollInterval = Duration(seconds: 2);
  static const Duration pollTimeout = Duration(minutes: 3);

  Future<Exam> uploadExam({
    required Uint8List imageBytes,
    required String filename,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    DioException? lastError;

    for (var attempt = 0; attempt < maxUploadAttempts; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(_initialBackoff * (1 << (attempt - 1)));
      }
      try {
        return await _examService.uploadExam(
          imageBytes: imageBytes,
          filename: filename,
          onSendProgress: onSendProgress,
        );
      } on DioException catch (e) {
        if (!_isRetryable(e)) {
          throw ApiException.fromDioException(e);
        }
        lastError = e;
      }
    }
    throw ApiException.fromDioException(lastError!);
  }

  /// Polls the exam until inference completes. Returns the updated exam.
  /// Throws [ApiException] on failure status or timeout — the ViewModel
  /// maps those to user-facing messages.
  Future<Exam> waitForCompletion(
    String examId, {
    bool Function()? isCancelled,
  }) async {
    final deadline = DateTime.now().add(pollTimeout);

    while (DateTime.now().isBefore(deadline)) {
      if (isCancelled?.call() ?? false) {
        throw const ApiException('Analysis cancelled');
      }

      await Future<void>.delayed(pollInterval);

      final Exam exam;
      try {
        exam = await _examService.getExam(examId);
      } on DioException {
        // A dropped poll request must not abort the wait; inference is
        // still running server-side. Retry on the next tick.
        continue;
      }

      switch (exam.status) {
        case ExamStatus.completed:
          return exam;
        case ExamStatus.failed:
          throw const ApiException(
            'Inference failed on the server. Please try again.',
          );
        case ExamStatus.pending:
        case ExamStatus.processing:
          break;
      }
    }

    throw const ApiException(
      'Analysis is taking longer than expected. Check History later.',
    );
  }

  Future<Exam> getExam(String examId) async {
    try {
      return await _examService.getExam(examId);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<InferenceResult> getResult(String examId) async {
    try {
      return await _examService.getResult(examId);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Exam>> listExams({int limit = 50, int offset = 0}) async {
    try {
      return await _examService.listExams(limit: limit, offset: offset);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ExamStats> getStats() async {
    try {
      return await _examService.getStats();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Uint8List> getExamImage(String examId) async {
    try {
      return await _examService.getExamImage(examId);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Retry on network-level failures and 5xx; never on 4xx, where the
  /// payload itself was rejected and resending would fail identically.
  bool _isRetryable(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == null) return true; // no response: connection dropped
    return statusCode >= 500;
  }
}
