import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Presentation state for the auth feature. Views watch this and stay
/// dumb — all repository calls live here.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authRepository);

  final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.unknown;
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Called once at app start to route the user to login or home.
  /// Bounded by a hard timeout: a hanging network or storage layer must
  /// never leave the router stuck on the intro screen.
  Future<void> checkAuthStatus() async {
    try {
      _currentUser = await _authRepository
          .getCurrentUser()
          .timeout(const Duration(seconds: 15));
      _status = _currentUser != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    } on ApiException {
      // Network down: treat as unauthenticated rather than crash the app.
      _status = AuthStatus.unauthenticated;
    } on TimeoutException {
      _status = AuthStatus.unauthenticated;
    } catch (_) {
      // Storage or unexpected failure: still resolve, never stay unknown.
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _beginAction();
    try {
      _currentUser = await _authRepository.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      _endAction();
      return true;
    } on ApiException catch (e) {
      _endAction(error: e.message);
      return false;
    }
  }

  /// Registration does not authenticate — the user is sent back to login.
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _beginAction();
    try {
      await _authRepository.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      _endAction();
      return true;
    } on ApiException catch (e) {
      _endAction(error: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _beginAction() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _endAction({String? error}) {
    _isLoading = false;
    _errorMessage = error;
    notifyListeners();
  }
}
