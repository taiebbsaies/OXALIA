import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to environment configuration.
///
/// Values are loaded from the `.env` asset at startup (see `main.dart`).
/// `10.0.2.2` is the Android emulator alias for the host machine's localhost.
class AppConfig {
  AppConfig._();

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';
}
