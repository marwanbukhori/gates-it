/// Centralised API configuration for the Pawmise backend.
///
/// The base URL is configurable at build time via `--dart-define`:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=https://your.host/api/v1
/// ```
///
/// If the flag is omitted, [baseUrl] falls back to the local dev server.
abstract final class ApiConfig {
  /// Base URL for all `/api/v1` requests.
  ///
  /// Set via `--dart-define=API_BASE_URL=...` at build time, or leave blank
  /// to use the default local dev address.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  /// Timeout applied to every outbound request.
  static const Duration requestTimeout = Duration(seconds: 15);
}
