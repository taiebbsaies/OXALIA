import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../../data/models/exam.dart';
import '../../../data/models/inference_result.dart';
import '../../../data/repositories/exam_repository.dart';

enum ExamDetailStatus { loading, loaded, error }

class ExamDetailViewModel extends ChangeNotifier {
  ExamDetailViewModel(this._repository, this.examId);

  final ExamRepository _repository;
  final String examId;

  ExamDetailStatus _status = ExamDetailStatus.loading;
  Exam? _exam;
  InferenceResult? _result;
  Uint8List? _imageBytes;
  String? _errorMessage;

  ExamDetailStatus get status => _status;
  Exam? get exam => _exam;
  InferenceResult? get result => _result;
  Uint8List? get imageBytes => _imageBytes;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _status = ExamDetailStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _exam = await _repository.getExam(examId);
      // Image and result load in parallel; a missing result (exam still
      // pending/processing) is not an error — the section just stays hidden.
      await Future.wait([_loadImage(), _loadResult()]);
      _status = ExamDetailStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = ExamDetailStatus.error;
    }
    notifyListeners();
  }

  Future<void> _loadImage() async {
    try {
      _imageBytes = await _repository.getExamImage(examId);
    } on ApiException {
      // Image section degrades to a placeholder.
    }
  }

  Future<void> _loadResult() async {
    if (_exam?.status != ExamStatus.completed) return;
    try {
      _result = await _repository.getResult(examId);
    } on ApiException {
      // Findings section degrades to an informational note.
    }
  }
}
