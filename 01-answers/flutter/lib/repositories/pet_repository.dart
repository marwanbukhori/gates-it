import '../models/cat.dart';
import '../models/dog.dart';
import '../models/pet.dart';

class PetRepository {
  List<Pet> getAll() {
    return [
      Dog(name: 'Rex', age: 2, breed: 'Labrador', isTrained: true),
      Dog(name: 'Buddy', age: 1, breed: 'Beagle'),
      Cat(name: 'Mittens', age: 3, breed: 'Siamese', isIndoor: false),
      Cat(name: 'Whiskers', age: 4, breed: 'Persian'),
    ];
  }
}
