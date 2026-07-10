import 'package:flutter/foundation.dart';

/// Adoption status as returned by the Pawmise API.
enum AdoptionStatus { available, pending, adopted }

/// Physical size category as returned by the Pawmise API.
enum PetSize { small, medium, large }

/// Gender as returned by the Pawmise API.
enum PetGender { male, female }

@immutable
abstract class Pet {
  final String id;
  final String name;
  final int age;
  final String breed;
  final bool isAdopted;

  // --- Extended API fields (nullable — in-memory seed data omits them) ---

  /// `small | medium | large`
  final PetSize? size;

  /// `male | female`
  final PetGender? gender;

  final String? description;

  /// Remote image URL; null for pets from the in-memory seed.
  final String? imageUrl;

  /// Base adoption fee in [currency].
  final double? baseFee;

  /// ISO currency code (e.g. "MYR").
  final String? currency;

  /// Whether this pet belongs to a shelter partner.
  final bool shelterPartner;

  /// Whether the pet is classified as senior by the API.
  final bool isSenior;

  const Pet({
    required this.id,
    required this.name,
    required this.age,
    required this.breed,
    this.isAdopted = false,
    this.size,
    this.gender,
    this.description,
    this.imageUrl,
    this.baseFee,
    this.currency,
    this.shelterPartner = false,
    this.isSenior = false,
  });

  String get species;

  Pet copyWith({bool? isAdopted});

  @override
  bool operator ==(Object other) =>
      other is Pet &&
      other.runtimeType == runtimeType &&
      other.id == id &&
      other.isAdopted == isAdopted;

  @override
  int get hashCode => Object.hash(runtimeType, id, isAdopted);
}
