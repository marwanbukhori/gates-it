import 'pet.dart';

class Dog extends Pet {
  final bool isTrained;

  Dog({
    required super.name,
    required super.age,
    required super.breed,
    this.isTrained = false,
    super.isAdopted,
  });

  @override
  String get type => 'Dog';
}
