import 'package:flutter/material.dart';

/// Theme-aware design tokens for the OXALIA 2D visual identity.
/// Access in widgets via `context.palette`.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.border,
    required this.teal,
    required this.cyan,
    required this.glow,
    required this.textPrimary,
    required this.textSecondary,
    required this.hint,
    required this.error,
    required this.onAccent,
  });

  final Color background;
  final Color surface;
  final Color border;
  final Color teal;
  final Color cyan;

  /// Center color of the radial glow behind auth screens.
  final Color glow;
  final Color textPrimary;
  final Color textSecondary;
  final Color hint;
  final Color error;

  /// Readable color on top of the teal/cyan accent.
  final Color onAccent;

  static const AppPalette dark = AppPalette(
    background: Color(0xFF0A1628),
    surface: Color(0xFF12263A),
    border: Color(0xFF1E3A52),
    teal: Color(0xFF2DD4BF),
    cyan: Color(0xFF06B6D4),
    glow: Color(0xFF10233B),
    textPrimary: Color(0xFFF2F7FA),
    textSecondary: Color(0xFF8A9BAE),
    hint: Color(0xFF5C6F84),
    error: Color(0xFFFF6B6B),
    onAccent: Color(0xFF06202B),
  );

  static const AppPalette light = AppPalette(
    background: Color(0xFFF4F7FA),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFDDE5EC),
    teal: Color(0xFF0D9488),
    cyan: Color(0xFF0891B2),
    glow: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF10233B),
    textSecondary: Color(0xFF5C6F84),
    hint: Color(0xFF9AA9B8),
    error: Color(0xFFE5484D),
    onAccent: Color(0xFFFFFFFF),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? border,
    Color? teal,
    Color? cyan,
    Color? glow,
    Color? textPrimary,
    Color? textSecondary,
    Color? hint,
    Color? error,
    Color? onAccent,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      teal: teal ?? this.teal,
      cyan: cyan ?? this.cyan,
      glow: glow ?? this.glow,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      hint: hint ?? this.hint,
      error: error ?? this.error,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      hint: Color.lerp(hint, other.hint, t)!,
      error: Color.lerp(error, other.error, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

/// Shortcut for `Theme.of(context).extension<AppPalette>()!`.
extension AppPaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

/// Application-wide Material 3 themes (dark-first product design).
class AppTheme {
  AppTheme._();

  static ThemeData _base(AppPalette palette, {required bool dark}) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: palette.border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: palette.background,
      extensions: const <ThemeExtension<dynamic>>[],
      colorScheme: (dark
              ? const ColorScheme.dark()
              : const ColorScheme.light())
          .copyWith(
        primary: palette.teal,
        secondary: palette.cyan,
        surface: palette.surface,
        error: palette.error,
        onPrimary: palette.onAccent,
        onSurface: palette.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: palette.textPrimary,
      ),
      dividerTheme: DividerThemeData(color: palette.border),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surface,
        contentTextStyle: TextStyle(color: palette.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        hintStyle: TextStyle(color: palette.hint),
        prefixIconColor: palette.hint,
        suffixIconColor: palette.hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: palette.teal, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: palette.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: palette.error, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get light =>
      _base(AppPalette.light, dark: false).copyWith(
        extensions: const [AppPalette.light],
      );

  static ThemeData get dark =>
      _base(AppPalette.dark, dark: true).copyWith(
        extensions: const [AppPalette.dark],
      );
}
