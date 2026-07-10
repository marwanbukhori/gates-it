import 'package:flutter/foundation.dart';

@immutable
abstract class Pet {
  final String id;
  final String name;
  final int age;
  final String breed;
  final bool isAdopted;

  const Pet({
    required this.id,
    required this.name,
    required this.age,
    required this.breed,
    this.isAdopted = false,
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
