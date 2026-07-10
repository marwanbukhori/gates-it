import 'pet.dart';

class Cat extends Pet {
  final bool isIndoor;

  Cat({
    required super.name,
    required super.age,
    required super.breed,
    this.isIndoor = true,
    super.isAdopted,
  });

  @override
  String get type => 'Cat';
}
