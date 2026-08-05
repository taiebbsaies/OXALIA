import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../../data/models/exam.dart';
import '../../../data/models/exam_stats.dart';
import '../../../data/repositories/exam_repository.dart';

enum HomeStatsStatus { loading, loaded, error }

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._repository);

  final ExamRepository _repository;

  static const int recentCount = 3;

  HomeStatsStatus _status = HomeStatsStatus.loading;
  ExamStats? _stats;
  List<Exam> _recentExams = const [];
  String? _errorMessage;

  HomeStatsStatus get status => _status;
  ExamStats? get stats => _stats;
  List<Exam> get recentExams => _recentExams;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _status = HomeStatsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final (stats, recent) = await (
        _repository.getStats(),
        _repository.listExams(limit: recentCount),
      ).wait;
      _stats = stats;
      _recentExams = recent;
      _status = HomeStatsStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = HomeStatsStatus.error;
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      final (stats, recent) = await (
        _repository.getStats(),
        _repository.listExams(limit: recentCount),
      ).wait;
      _stats = stats;
      _recentExams = recent;
      _status = HomeStatsStatus.loaded;
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    }
    notifyListeners();
  }
}
