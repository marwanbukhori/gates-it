import '../domain/cat.dart';
import '../domain/dog.dart';
import '../domain/pet.dart';
import '../domain/pet_repository.dart';

class InMemoryPetRepository implements PetRepository {
  final Duration simulatedLatency;

  const InMemoryPetRepository({
    this.simulatedLatency = const Duration(milliseconds: 400),
  });

  @override
  Future<List<Pet>> fetchAll() async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }
    return const [
      Dog(id: 'rex', name: 'Rex', age: 2, breed: 'Labrador', isTrained: true),
      Dog(id: 'buddy', name: 'Buddy', age: 1, breed: 'Beagle'),
      Cat(id: 'mittens', name: 'Mittens', age: 3, breed: 'Siamese', isIndoor: false),
      Cat(id: 'whiskers', name: 'Whiskers', age: 4, breed: 'Persian'),
    ];
  }
}
