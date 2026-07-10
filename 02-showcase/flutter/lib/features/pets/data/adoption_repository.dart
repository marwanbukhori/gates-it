import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../app/config/api_config.dart';
import '../domain/adoption_result.dart';

/// Thrown when a pet has already been adopted (HTTP 409).
final class AlreadyAdoptedException implements Exception {
  final String petId;
  const AlreadyAdoptedException(this.petId);

  @override
  String toString() => 'AlreadyAdoptedException: pet $petId is already adopted';
}

/// Thrown when the request is unauthenticated (HTTP 401).
final class UnauthenticatedException implements Exception {
  const UnauthenticatedException();

  @override
  String toString() => 'UnauthenticatedException: missing or invalid token';
}

/// Communicates with `POST /pets/{id}/adopt`.
///
/// Accepts an injectable [http.Client] so tests can supply a [MockClient].
class AdoptionRepository {
  final http.Client _client;
  final String _baseUrl;

  const AdoptionRepository({
    required this._client,
    this._baseUrl = ApiConfig.baseUrl,
  });

  /// Adopts the pet with [petId] using the supplied bearer [token].
  ///
  /// Returns an [AdoptionResult] containing the fee breakdown on success.
  /// Throws [AlreadyAdoptedException] on HTTP 409.
  /// Throws [UnauthenticatedException] on HTTP 401.
  Future<AdoptionResult> adopt(String petId, String token) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/pets/$petId/adopt'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    switch (response.statusCode) {
      case 200:
      case 201:
        return _parseAdoptionResult(response.body);
      case 409:
        throw AlreadyAdoptedException(petId);
      case 401:
        throw const UnauthenticatedException();
      default:
        throw Exception(
          'Adopt failed (HTTP ${response.statusCode}): ${response.body}',
        );
    }
  }

  static AdoptionResult _parseAdoptionResult(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    return AdoptionResult(
      petId: data['id'].toString(),
      baseFee: _toDouble(data['base_fee']),
      discountType: data['discount_type'] as String?,
      discountAmount: _toDouble(data['discount_amount']),
      finalFee: _toDouble(data['final_fee']),
      currency: (data['currency'] as String?) ?? 'MYR',
      adoptedAt: data['adopted_at'] as String? ?? '',
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
