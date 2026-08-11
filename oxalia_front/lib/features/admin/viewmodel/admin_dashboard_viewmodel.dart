import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../../data/models/admin_stats.dart';
import '../../../data/repositories/admin_repository.dart';

enum AdminDashboardStatus { loading, loaded, error }

class AdminDashboardViewModel extends ChangeNotifier {
  AdminDashboardViewModel(this._repository);

  final AdminRepository _repository;

  AdminDashboardStatus _status = AdminDashboardStatus.loading;
  AdminStats? _stats;
  String? _errorMessage;

  AdminDashboardStatus get status => _status;
  AdminStats? get stats => _stats;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _status = AdminDashboardStatus.loading;
    _errorMessage = null;
    notifyListeners();
    await _fetch();
  }

  Future<void> refresh() async {
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      _stats = await _repository.getStats();
      _status = AdminDashboardStatus.loaded;
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AdminDashboardStatus.error;
    }
    notifyListeners();
  }
}
