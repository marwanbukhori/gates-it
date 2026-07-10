abstract final class ApiConfig {
  /// Base URL for the Pawmise Laravel backend.
  /// Override via the `PAWMISE_BASE_URL` environment variable at build time,
  /// e.g. `flutter run --dart-define=PAWMISE_BASE_URL=https://api.example.com/api/v1`
  static const String baseUrl = String.fromEnvironment(
    'PAWMISE_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );
}
