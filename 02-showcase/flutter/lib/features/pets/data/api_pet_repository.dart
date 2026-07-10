import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../app/config/api_config.dart';
import '../domain/cat.dart';
import '../domain/dog.dart';
import '../domain/pet.dart';
import '../domain/pet_repository.dart';

/// HTTP-backed implementation of [PetRepository] that talks to the Pawmise
/// Laravel API at [ApiConfig.baseUrl].
///
/// All pages are fetched and merged so the caller receives a flat list —
/// consistent with the [InMemoryPetRepository] contract while staying simple
/// for the showcase. Pagination support can be added via a streaming/cursor
/// API in a follow-up.
class ApiPetRepository implements PetRepository {
  /// Injected HTTP client — defaults to a real [http.Client].
  /// Pass a fake in tests to avoid hitting the network.
  // ignore: library_private_types_in_public_api
  final http.Client client;

  /// Base URL for the API (e.g. `http://127.0.0.1:8000/api/v1`).
  final String _baseUrl;

  ApiPetRepository({
    http.Client? client,
    String? baseUrl,
  })  : client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  // ---------------------------------------------------------------------------
  // PetRepository implementation
  // ---------------------------------------------------------------------------

  @override
  Future<List<Pet>> fetchAll({String? species}) async {
    final pets = <Pet>[];
    var page = 1;
    int? lastPage;

    do {
      final queryParams = <String, String>{
        'page': '$page',
        if (species != null && species.isNotEmpty) 'species': species,
      };

      final uri = Uri.parse('$_baseUrl/pets').replace(queryParameters: queryParams);
      final response = await client
          .get(uri, headers: _defaultHeaders)
          .timeout(ApiConfig.requestTimeout);

      _assertSuccess(response);

      final body = _decode(response);
      final data = body['data'] as List<dynamic>;
      pets.addAll(data.map((json) => _petFromJson(json as Map<String, dynamic>)));

      // Derive total pages from the Laravel paginator meta block.
      final meta = body['meta'] as Map<String, dynamic>?;
      lastPage = meta?['last_page'] as int? ?? 1;
      page++;
    } while (page <= lastPage);

    return pets;
  }

  @override
  Future<Pet> fetchById(String id) async {
    final uri = Uri.parse('$_baseUrl/pets/$id');
    final response = await client
        .get(uri, headers: _defaultHeaders)
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 404) throw PetNotFoundException(id);
    _assertSuccess(response);

    final body = _decode(response);
    return _petFromJson(body['data'] as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static const Map<String, String> _defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// Throws [PetApiException] for non-2xx responses.
  void _assertSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PetApiException(
        statusCode: response.statusCode,
        message: 'Unexpected response: ${response.body}',
      );
    }
  }

  /// Decodes a [http.Response] body as a JSON map.
  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw PetApiException(message: 'Invalid JSON response: $e');
    }
  }

  /// Maps a single API pet JSON object → the appropriate [Pet] subclass.
  ///
  /// The domain uses [Dog] / [Cat] subclasses; any unknown species falls back
  /// to [Dog] to remain non-fatal.
  Pet _petFromJson(Map<String, dynamic> json) {
    final id = json['id'].toString();
    final name = json['name'] as String;
    final breed = json['breed'] as String? ?? '';
    final age = (json['age_years'] as num?)?.round() ?? 0;
    final species = (json['species'] as String? ?? '').toLowerCase();

    final status = _parseStatus(json['status'] as String?);
    final size = _parseSize(json['size'] as String?);
    final gender = _parseGender(json['gender'] as String?);
    final isAdopted = status == AdoptionStatus.adopted;
    final baseFee = (json['base_fee'] as num?)?.toDouble();
    final currency = json['currency'] as String?;
    final description = json['description'] as String?;
    final imageUrl = json['image_url'] as String?;
    final shelterPartner = (json['shelter_partner'] as bool?) ?? false;
    final isSenior = (json['is_senior'] as bool?) ?? false;

    if (species == 'cat') {
      return Cat(
        id: id,
        name: name,
        age: age,
        breed: breed,
        isAdopted: isAdopted,
        size: size,
        gender: gender,
        description: description,
        imageUrl: imageUrl,
        baseFee: baseFee,
        currency: currency,
        shelterPartner: shelterPartner,
        isSenior: isSenior,
      );
    }

    // dog (or unknown species — default to Dog)
    return Dog(
      id: id,
      name: name,
      age: age,
      breed: breed,
      isAdopted: isAdopted,
      size: size,
      gender: gender,
      description: description,
      imageUrl: imageUrl,
      baseFee: baseFee,
      currency: currency,
      shelterPartner: shelterPartner,
      isSenior: isSenior,
    );
  }

  static AdoptionStatus _parseStatus(String? raw) => switch (raw) {
        'pending' => AdoptionStatus.pending,
        'adopted' => AdoptionStatus.adopted,
        _ => AdoptionStatus.available,
      };

  static PetSize? _parseSize(String? raw) => switch (raw) {
        'small' => PetSize.small,
        'medium' => PetSize.medium,
        'large' => PetSize.large,
        _ => null,
      };

  static PetGender? _parseGender(String? raw) => switch (raw) {
        'male' => PetGender.male,
        'female' => PetGender.female,
        _ => null,
      };
}
