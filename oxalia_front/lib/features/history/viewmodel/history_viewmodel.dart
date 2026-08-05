import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../../data/models/exam.dart';
import '../../../data/repositories/exam_repository.dart';

enum HistoryStatus { loading, loaded, error }

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel(this._repository);

  final ExamRepository _repository;

  HistoryStatus _status = HistoryStatus.loading;
  List<Exam> _exams = const [];
  String? _errorMessage;

  HistoryStatus get status => _status;
  List<Exam> get exams => _exams;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _status = HistoryStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _exams = await _repository.listExams();
      _status = HistoryStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = HistoryStatus.error;
    }
    notifyListeners();
  }

  /// Pull-to-refresh entry point; keeps the current list visible while
  /// refetching instead of flashing a spinner.
  Future<void> refresh() async {
    try {
      _exams = await _repository.listExams();
      _status = HistoryStatus.loaded;
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    }
    notifyListeners();
  }
}
