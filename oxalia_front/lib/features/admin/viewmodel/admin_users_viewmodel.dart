import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../../data/models/admin_user.dart';
import '../../../data/repositories/admin_repository.dart';

enum AdminUsersStatus { loading, loaded, error }

/// Manages the admin user-management table: listing, role changes,
/// activation toggles, and deletion. Tracks a per-row [busyUserId] so the
/// UI can disable actions on the row currently being mutated.
class AdminUsersViewModel extends ChangeNotifier {
  AdminUsersViewModel(this._repository, {required String currentUserId})
    : _currentUserId = currentUserId;

  final AdminRepository _repository;
  final String _currentUserId;

  AdminUsersStatus _status = AdminUsersStatus.loading;
  List<AdminUser> _users = const [];
  String? _errorMessage;
  String? _busyUserId;
  String? _actionError;

  AdminUsersStatus get status => _status;
  List<AdminUser> get users => _users;
  String? get errorMessage => _errorMessage;
  String? get busyUserId => _busyUserId;
  String? get actionError => _actionError;
  String get currentUserId => _currentUserId;

  Future<void> load() async {
    _status = AdminUsersStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _repository.listUsers();
      _status = AdminUsersStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AdminUsersStatus.error;
    }
    notifyListeners();
  }

  Future<bool> changeRole(AdminUser user, String newRole) async {
    return _mutate(user.id, () async {
      final updated = await _repository.updateUserRole(user.id, newRole);
      _replaceUser(updated);
    });
  }

  Future<bool> toggleActive(AdminUser user) async {
    return _mutate(user.id, () async {
      final updated = await _repository.setUserActive(user.id, !user.isActive);
      _replaceUser(updated);
    });
  }

  Future<bool> deleteUser(AdminUser user) async {
    return _mutate(user.id, () async {
      await _repository.deleteUser(user.id);
      _users = _users.where((u) => u.id != user.id).toList();
    });
  }

  Future<bool> _mutate(String userId, Future<void> Function() action) async {
    _busyUserId = userId;
    _actionError = null;
    notifyListeners();

    var succeeded = true;
    try {
      await action();
    } on ApiException catch (e) {
      _actionError = e.message;
      succeeded = false;
    }
    _busyUserId = null;
    notifyListeners();
    return succeeded;
  }

  void _replaceUser(AdminUser updated) {
    _users = [for (final u in _users) if (u.id == updated.id) updated else u];
  }
}
