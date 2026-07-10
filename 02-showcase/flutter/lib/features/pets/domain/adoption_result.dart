import 'package:flutter/foundation.dart';

/// Fee breakdown returned by `POST /pets/{id}/adopt`.
@immutable
final class AdoptionResult {
  final String petId;
  final double baseFee;
  final String? discountType;
  final double discountAmount;
  final double finalFee;
  final String currency;
  final String adoptedAt;

  const AdoptionResult({
    required this.petId,
    required this.baseFee,
    this.discountType,
    required this.discountAmount,
    required this.finalFee,
    required this.currency,
    required this.adoptedAt,
  });
}
