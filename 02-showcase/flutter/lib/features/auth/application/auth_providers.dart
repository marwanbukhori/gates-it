import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/auth_repository.dart';

/// Provides a shared [http.Client] that is closed when the container is
/// disposed.  Override in tests with a [MockClient].
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Provides the [AuthRepository] wired to the shared HTTP client.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(client: ref.watch(httpClientProvider));
});

/// Holds the current bearer token, or null when not authenticated.
///
/// [AuthNotifier] handles the demo-bootstrap flow:
///   1. Try login with the fixed demo credentials.
///   2. If that fails (401/422 → AuthException), register the account first,
///      then succeed with the new token.
///
/// This is intentionally a simple in-memory state (no secure storage) because
/// it is a demo bootstrap, not a real user session.
class AuthNotifier extends Notifier<String?> {
  // ---------------------------------------------------------------------------
  // Demo bootstrap credentials — NOT real user data; used only to obtain a
  // valid token for the assessment demo.  Replace with a real auth flow before
  // shipping to production.
  // ---------------------------------------------------------------------------
  static const _demoName     = 'Pawmise Demo';
  static const _demoEmail    = 'app-demo@pawmise.test';
  static const _demoPassword = 'pawmise-demo-1234';

  @override
  String? build() => null; // unauthenticated initially

  /// Returns the current token if one is stored, otherwise performs the
  /// demo-bootstrap and returns the newly acquired token.
  Future<String> ensureAuthenticated() async {
    final current = state;
    if (current != null) return current;

    final repo = ref.read(authRepositoryProvider);
    try {
      final result = await repo.login(
        email: _demoEmail,
        password: _demoPassword,
      );
      state = result.token;
      return result.token;
    } on AuthException {
      // Account may not exist yet — register it, then log in.
      await repo.register(
        name: _demoName,
        email: _demoEmail,
        password: _demoPassword,
      );
      final result = await repo.login(
        email: _demoEmail,
        password: _demoPassword,
      );
      state = result.token;
      return result.token;
    }
  }

  /// Clears the stored token (e.g. on 401 from the adoption endpoint).
  void clearToken() => state = null;
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, String?>(AuthNotifier.new);
