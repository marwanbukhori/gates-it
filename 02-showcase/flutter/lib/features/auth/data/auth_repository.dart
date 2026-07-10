import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../app/config/api_config.dart';

/// Thrown when credentials are invalid (HTTP 401 / 422).
final class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

/// Result of a successful login or register call.
final class AuthResult {
  final String token;
  final String userId;

  const AuthResult({required this.token, required this.userId});
}

/// Communicates with the Pawmise auth endpoints:
///   POST /auth/login    {email, password}   → {token, user}
///   POST /auth/register {name, email, password} → {token, user}
///
/// Accepts an injectable [http.Client] so tests can supply a [MockClient].
class AuthRepository {
  final http.Client _client;
  final String _baseUrl;

  const AuthRepository({
    required this._client,
    this._baseUrl = ApiConfig.baseUrl,
  });

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseAuthResult(response.body);
    }

    throw AuthException(
      'Login failed (HTTP ${response.statusCode}): ${response.body}',
    );
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseAuthResult(response.body);
    }

    throw AuthException(
      'Register failed (HTTP ${response.statusCode}): ${response.body}',
    );
  }

  static AuthResult _parseAuthResult(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    return AuthResult(token: token, userId: user['id'].toString());
  }
}
