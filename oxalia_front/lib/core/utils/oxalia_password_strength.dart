import 'package:flutter/material.dart';
import 'package:password_strength_checker/password_strength_checker.dart';

/// OXALIA password policy + strength levels for [PasswordStrengthChecker].
///
/// Policy (all required):
/// - min 8 characters
/// - at least one uppercase, one lowercase, one digit, one special character
enum OxaliaPasswordStrength implements PasswordStrengthItem {
  weak,
  fair,
  strong,
  secure;

  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _lower = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _special = RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/]''');

  static bool hasUppercase(String text) => _upper.hasMatch(text);
  static bool hasLowercase(String text) => _lower.hasMatch(text);
  static bool hasDigit(String text) => _digit.hasMatch(text);
  static bool hasSpecial(String text) => _special.hasMatch(text);
  static bool hasMinLength(String text) => text.length >= 8;

  /// Returns null when every policy rule is satisfied.
  static String? validatePolicy(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password is required';
    if (!hasMinLength(text)) {
      return 'Password must be at least 8 characters';
    }
    if (!hasUppercase(text)) {
      return 'Include at least one uppercase letter';
    }
    if (!hasLowercase(text)) {
      return 'Include at least one lowercase letter';
    }
    if (!hasDigit(text)) {
      return 'Include at least one number';
    }
    if (!hasSpecial(text)) {
      return 'Include at least one special character';
    }
    return null;
  }

  static bool meetsPolicy(String text) => validatePolicy(text) == null;

  static OxaliaPasswordStrength? calculate({required String text}) {
    if (text.isEmpty) return null;
    if (commonDictionary[text] == true) return weak;

    final rulesMet = [
      hasMinLength(text),
      hasUppercase(text),
      hasLowercase(text),
      hasDigit(text),
      hasSpecial(text),
    ].where((ok) => ok).length;

    if (rulesMet < 5) return weak;
    if (text.length < 12) return fair;
    if (text.length < 16) return strong;
    return secure;
  }

  @override
  Color get statusColor => switch (this) {
        weak => const Color(0xFFE5484D),
        fair => const Color(0xFFF59E0B),
        strong => const Color(0xFF0D9488),
        secure => const Color(0xFF06B6D4),
      };

  @override
  Widget? get statusWidget => Text(
        switch (this) {
          weak => 'Weak — keep improving',
          fair => 'Fair — policy met',
          strong => 'Strong',
          secure => 'Secure',
        },
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );

  @override
  double get widthPerc => switch (this) {
        weak => 0.25,
        fair => 0.5,
        strong => 0.75,
        secure => 1,
      };
}
