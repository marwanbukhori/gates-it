import 'pet.dart';

final class Dog extends Pet {
  final bool isTrained;

  const Dog({
    required super.id,
    required super.name,
    required super.age,
    required super.breed,
    this.isTrained = false,
    super.isAdopted,
    super.size,
    super.gender,
    super.description,
    super.imageUrl,
    super.baseFee,
    super.currency,
    super.shelterPartner,
    super.isSenior,
  });

  @override
  String get species => 'Dog';

  @override
  Dog copyWith({bool? isAdopted, bool? isTrained}) {
    return Dog(
      id: id,
      name: name,
      age: age,
      breed: breed,
      isTrained: isTrained ?? this.isTrained,
      isAdopted: isAdopted ?? this.isAdopted,
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
}
