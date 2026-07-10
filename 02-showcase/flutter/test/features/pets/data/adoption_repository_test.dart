import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_adoption/features/pets/data/adoption_repository.dart';

void main() {
  const baseUrl = 'http://test.local/api/v1';

  AdoptionRepository makeRepo(MockClient client) =>
      AdoptionRepository(client: client, baseUrl: baseUrl);

  group('AdoptionRepository.adopt', () {
    test('returns AdoptionResult with fee breakdown on HTTP 201', () async {
      final payload = {
        'data': {
          'id': '7',
          'pet': {'id': 'rex', 'name': 'Rex'},
          'base_fee': 150.0,
          'discount_type': 'loyalty',
          'discount_amount': 15.0,
          'final_fee': 135.0,
          'currency': 'MYR',
          'adopted_at': '2026-07-11T10:00:00Z',
        },
      };

      final client = MockClient(
        (_) async => http.Response(jsonEncode(payload), 201),
      );

      final result = await makeRepo(client).adopt('rex', 'tok-test');

      expect(result.finalFee, 135.0);
      expect(result.baseFee, 150.0);
      expect(result.discountType, 'loyalty');
      expect(result.discountAmount, 15.0);
      expect(result.currency, 'MYR');
    });

    test('throws AlreadyAdoptedException on HTTP 409', () async {
      final client = MockClient(
        (_) async => http.Response('{"message":"Already adopted"}', 409),
      );

      await expectLater(
        () => makeRepo(client).adopt('rex', 'tok-test'),
        throwsA(isA<AlreadyAdoptedException>()),
      );
    });

    test('throws UnauthenticatedException on HTTP 401', () async {
      final client = MockClient(
        (_) async => http.Response('{"message":"Unauthenticated"}', 401),
      );

      await expectLater(
        () => makeRepo(client).adopt('rex', 'bad-token'),
        throwsA(isA<UnauthenticatedException>()),
      );
    });

    test('sends Authorization header with bearer token', () async {
      String? capturedAuth;

      final client = MockClient((request) async {
        capturedAuth = request.headers['Authorization'];
        return http.Response(
          jsonEncode({
            'data': {
              'id': '1',
              'pet': {'id': 'rex'},
              'base_fee': 100.0,
              'discount_type': null,
              'discount_amount': 0.0,
              'final_fee': 100.0,
              'currency': 'MYR',
              'adopted_at': '2026-07-11T10:00:00Z',
            },
          }),
          201,
        );
      });

      await makeRepo(client).adopt('rex', 'my-secret-token');

      expect(capturedAuth, 'Bearer my-secret-token');
    });

    test('throws generic Exception on unexpected HTTP status', () async {
      final client = MockClient(
        (_) async => http.Response('{"message":"Server Error"}', 500),
      );

      await expectLater(
        () => makeRepo(client).adopt('rex', 'tok'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
