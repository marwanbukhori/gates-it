import 'pet.dart';

abstract interface class PetRepository {
  /// Fetches all pets, optionally filtered by species/filter values.
  ///
  /// Implementations are free to apply filtering locally (in-memory) or
  /// delegate to a remote API via query parameters.
  Future<List<Pet>> fetchAll({String? species});

  /// Fetches a single pet by its [id].
  ///
  /// Throws a [PetNotFoundException] if the pet does not exist.
  Future<Pet> fetchById(String id);
}

/// Thrown when a requested pet ID is not found.
class PetNotFoundException implements Exception {
  final String id;
  const PetNotFoundException(this.id);

  @override
  String toString() => 'PetNotFoundException: No pet found with id "$id"';
}

/// Thrown when a network or HTTP error occurs.
class PetApiException implements Exception {
  final int? statusCode;
  final String message;
  const PetApiException({this.statusCode, required this.message});

  @override
  String toString() =>
      'PetApiException(${statusCode != null ? 'HTTP $statusCode' : 'network error'}): $message';
}
