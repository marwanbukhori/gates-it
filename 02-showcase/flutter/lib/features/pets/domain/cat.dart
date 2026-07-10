import 'pet.dart';

final class Cat extends Pet {
  final bool isIndoor;

  const Cat({
    required super.id,
    required super.name,
    required super.age,
    required super.breed,
    this.isIndoor = true,
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
  String get species => 'Cat';

  @override
  Cat copyWith({bool? isAdopted, bool? isIndoor}) {
    return Cat(
      id: id,
      name: name,
      age: age,
      breed: breed,
      isIndoor: isIndoor ?? this.isIndoor,
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
