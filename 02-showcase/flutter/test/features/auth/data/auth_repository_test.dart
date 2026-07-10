import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_adoption/features/auth/data/auth_repository.dart';

void main() {
  const baseUrl = 'http://test.local/api/v1';

  AuthRepository makeRepo(MockClient client) =>
      AuthRepository(client: client, baseUrl: baseUrl);

  group('AuthRepository.login', () {
    test('returns AuthResult with token on HTTP 200', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({
              'token': 'tok-abc',
              'user': {'id': 42, 'name': 'Demo'},
            }),
            200,
          ));

      final result = await makeRepo(client).login(
        email: 'demo@example.com',
        password: 'secret',
      );

      expect(result.token, 'tok-abc');
      expect(result.userId, '42');
    });

    test('throws AuthException on HTTP 401', () async {
      final client = MockClient(
        (_) async => http.Response('{"message":"Unauthorized"}', 401),
      );

      await expectLater(
        () => makeRepo(client).login(email: 'bad@x.com', password: 'wrong'),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws AuthException on HTTP 422', () async {
      final client = MockClient(
        (_) async => http.Response('{"message":"Validation error"}', 422),
      );

      await expectLater(
        () => makeRepo(client).login(email: 'x', password: ''),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthRepository.register', () {
    test('returns AuthResult with token on HTTP 201', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({
              'token': 'tok-new',
              'user': {'id': 99, 'name': 'New User'},
            }),
            201,
          ));

      final result = await makeRepo(client).register(
        name: 'New User',
        email: 'new@example.com',
        password: 'password',
      );

      expect(result.token, 'tok-new');
      expect(result.userId, '99');
    });

    test('throws AuthException on HTTP 422 (duplicate email)', () async {
      final client = MockClient(
        (_) async => http.Response('{"message":"Email taken"}', 422),
      );

      await expectLater(
        () => makeRepo(client).register(
          name: 'X',
          email: 'taken@example.com',
          password: 'pass',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
