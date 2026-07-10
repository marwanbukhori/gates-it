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
    );
  }
}
