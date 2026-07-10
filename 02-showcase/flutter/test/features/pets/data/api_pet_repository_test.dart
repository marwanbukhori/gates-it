import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_adoption/features/pets/data/api_pet_repository.dart';
import 'package:pet_adoption/features/pets/domain/cat.dart';
import 'package:pet_adoption/features/pets/domain/dog.dart';
import 'package:pet_adoption/features/pets/domain/pet.dart';
import 'package:pet_adoption/features/pets/domain/pet_repository.dart';

// ---------------------------------------------------------------------------
// Sample fixture data matching the Pawmise API contract
// ---------------------------------------------------------------------------

const _singlePageResponse = '''{
  "data": [
    {
      "id": 1,
      "name": "Buddy",
      "species": "dog",
      "breed": "Beagle",
      "age_years": 2,
      "size": "medium",
      "gender": "male",
      "description": "Playful and friendly.",
      "image_url": "https://example.com/buddy.jpg",
      "base_fee": 250.0,
      "status": "available",
      "shelter_partner": false,
      "is_senior": false,
      "currency": "MYR"
    },
    {
      "id": 2,
      "name": "Luna",
      "species": "cat",
      "breed": "Persian",
      "age_years": 4,
      "size": "small",
      "gender": "female",
      "description": "Calm and affectionate.",
      "image_url": "https://example.com/luna.jpg",
      "base_fee": 180.0,
      "status": "available",
      "shelter_partner": true,
      "is_senior": false,
      "currency": "MYR"
    },
    {
      "id": 3,
      "name": "Max",
      "species": "dog",
      "breed": "Labrador",
      "age_years": 8,
      "size": "large",
      "gender": "male",
      "description": "Senior dog looking for a quiet home.",
      "image_url": null,
      "base_fee": 100.0,
      "status": "adopted",
      "shelter_partner": false,
      "is_senior": true,
      "currency": "MYR"
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 15,
    "total": 3
  }
}''';

const _emptyResponse = '''{
  "data": [],
  "meta": { "current_page": 1, "last_page": 1, "per_page": 15, "total": 0 }
}''';

const _singlePetResponse = '''{
  "data": {
    "id": 42,
    "name": "Whiskers",
    "species": "cat",
    "breed": "Siamese",
    "age_years": 3,
    "size": "small",
    "gender": "female",
    "description": "Loves to play.",
    "image_url": null,
    "base_fee": 150.0,
    "status": "available",
    "shelter_partner": false,
    "is_senior": false,
    "currency": "MYR"
  }
}''';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ApiPetRepository _repoWith(MockClient client) => ApiPetRepository(
      client: client,
      baseUrl: 'http://test.local/api/v1',
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ApiPetRepository.fetchAll', () {
    test('parses a single-page response into the correct Pet subclasses', () async {
      final client = MockClient((_) async => http.Response(
            _singlePageResponse,
            200,
            headers: {'content-type': 'application/json'},
          ));
      final repo = _repoWith(client);

      final pets = await repo.fetchAll();

      expect(pets, hasLength(3));
      expect(pets[0], isA<Dog>());
      expect(pets[1], isA<Cat>());
      expect(pets[2], isA<Dog>());
    });

    test('maps Dog fields correctly', () async {
      final client = MockClient((_) async => http.Response(
            _singlePageResponse,
            200,
            headers: {'content-type': 'application/json'},
          ));
      final repo = _repoWith(client);

      final pets = await repo.fetchAll();
      final buddy = pets[0] as Dog;

      expect(buddy.id, '1');
      expect(buddy.name, 'Buddy');
      expect(buddy.age, 2);
      expect(buddy.breed, 'Beagle');
      expect(buddy.species, 'Dog');
      expect(buddy.isAdopted, isFalse);
      expect(buddy.size, PetSize.medium);
      expect(buddy.gender, PetGender.male);
      expect(buddy.baseFee, 250.0);
      expect(buddy.currency, 'MYR');
      expect(buddy.shelterPartner, isFalse);
      expect(buddy.isSenior, isFalse);
      expect(buddy.imageUrl, 'https://example.com/buddy.jpg');
    });

    test('maps Cat fields correctly', () async {
      final client = MockClient((_) async => http.Response(
            _singlePageResponse,
            200,
            headers: {'content-type': 'application/json'},
          ));
      final repo = _repoWith(client);

      final pets = await repo.fetchAll();
      final luna = pets[1] as Cat;

      expect(luna.id, '2');
      expect(luna.name, 'Luna');
      expect(luna.species, 'Cat');
      expect(luna.size, PetSize.small);
      expect(luna.gender, PetGender.female);
      expect(luna.shelterPartner, isTrue);
      expect(luna.baseFee, 180.0);
    });

    test('maps adopted status correctly', () async {
      final client = MockClient((_) async => http.Response(
            _singlePageResponse,
            200,
            headers: {'content-type': 'application/json'},
          ));
      final repo = _repoWith(client);

      final pets = await repo.fetchAll();
      final max = pets[2] as Dog;

      expect(max.isAdopted, isTrue);
      expect(max.isSenior, isTrue);
    });

    test('returns an empty list when the API response has no data', () async {
      final client = MockClient((_) async => http.Response(
            _emptyResponse,
            200,
            headers: {'content-type': 'application/json'},
          ));
      final repo = _repoWith(client);

      final pets = await repo.fetchAll();
      expect(pets, isEmpty);
    });

    test('fetches multiple pages and merges them into one list', () async {
      var callCount = 0;

      final page1 = jsonEncode({
        'data': [
          {
            'id': 1, 'name': 'A', 'species': 'dog', 'breed': 'Mix',
            'age_years': 1, 'status': 'available',
          },
        ],
        'meta': {'current_page': 1, 'last_page': 2, 'per_page': 1, 'total': 2},
      });
      final page2 = jsonEncode({
        'data': [
          {
            'id': 2, 'name': 'B', 'species': 'cat', 'breed': 'Mix',
            'age_years': 2, 'status': 'available',
          },
        ],
        'meta': {'current_page': 2, 'last_page': 2, 'per_page': 1, 'total': 2},
      });

      final client = MockClient((request) async {
        callCount++;
        final pageParam = request.url.queryParameters['page'];
        final body = pageParam == '2' ? page2 : page1;
        return http.Response(body, 200,
            headers: {'content-type': 'application/json'});
      });

      final repo = _repoWith(client);
      final pets = await repo.fetchAll();

      expect(callCount, 2);
      expect(pets, hasLength(2));
      expect(pets[0], isA<Dog>());
      expect(pets[1], isA<Cat>());
    });

    test('throws PetApiException on a non-2xx response', () async {
      final client = MockClient((_) async => http.Response('{"error":"server error"}', 500));
      final repo = _repoWith(client);

      expect(
        () => repo.fetchAll(),
        throwsA(isA<PetApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        )),
      );
    });
  });

  group('ApiPetRepository.fetchById', () {
    test('parses a single pet response correctly', () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/42')) {
          return http.Response(_singlePetResponse, 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 404);
      });
      final repo = _repoWith(client);

      final pet = await repo.fetchById('42');

      expect(pet, isA<Cat>());
      expect(pet.id, '42');
      expect(pet.name, 'Whiskers');
      expect(pet.breed, 'Siamese');
      expect(pet.age, 3);
      expect(pet.isAdopted, isFalse);
    });

    test('throws PetNotFoundException on a 404 response', () async {
      final client = MockClient((_) async => http.Response('{"error":"not found"}', 404));
      final repo = _repoWith(client);

      expect(
        () => repo.fetchById('999'),
        throwsA(isA<PetNotFoundException>().having((e) => e.id, 'id', '999')),
      );
    });
  });
}
