import 'package:flutter/material.dart';

/// Holds the app's [ThemeMode]. Defaults to following the phone's
/// system theme; the user can override it from the profile settings.
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}
