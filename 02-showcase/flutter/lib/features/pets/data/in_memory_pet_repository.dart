import '../domain/cat.dart';
import '../domain/dog.dart';
import '../domain/pet.dart';
import '../domain/pet_repository.dart';

class InMemoryPetRepository implements PetRepository {
  final Duration simulatedLatency;

  const InMemoryPetRepository({
    this.simulatedLatency = const Duration(milliseconds: 400),
  });

  static const _seed = <Pet>[
    Dog(id: 'rex', name: 'Rex', age: 2, breed: 'Labrador', isTrained: true),
    Dog(id: 'buddy', name: 'Buddy', age: 1, breed: 'Beagle'),
    Cat(id: 'mittens', name: 'Mittens', age: 3, breed: 'Siamese', isIndoor: false),
    Cat(id: 'whiskers', name: 'Whiskers', age: 4, breed: 'Persian'),
  ];

  @override
  Future<List<Pet>> fetchAll({String? species}) async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }
    if (species == null || species.isEmpty) return List.unmodifiable(_seed);

    // Filter locally by species label (case-insensitive)
    final lower = species.toLowerCase();
    return _seed.where((p) => p.species.toLowerCase() == lower).toList();
  }

  @override
  Future<Pet> fetchById(String id) async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }
    final pet = _seed.where((p) => p.id == id).firstOrNull;
    if (pet == null) throw PetNotFoundException(id);
    return pet;
  }
}
