import 'package:flutter_test/flutter_test.dart';
import 'package:pet_adoption/features/pets/data/in_memory_pet_repository.dart';
import 'package:pet_adoption/features/pets/domain/cat.dart';
import 'package:pet_adoption/features/pets/domain/dog.dart';

void main() {
  const repo = InMemoryPetRepository(simulatedLatency: Duration.zero);

  test('returns the seed dataset described in the assessment', () async {
    final pets = await repo.fetchAll();

    expect(pets, hasLength(4));
    expect(pets.whereType<Dog>(), hasLength(2));
    expect(pets.whereType<Cat>(), hasLength(2));

    final rex = pets.whereType<Dog>().singleWhere((d) => d.name == 'Rex');
    expect(rex.isTrained, isTrue);

    final buddy = pets.whereType<Dog>().singleWhere((d) => d.name == 'Buddy');
    expect(buddy.isTrained, isFalse);

    final mittens = pets.whereType<Cat>().singleWhere((c) => c.name == 'Mittens');
    expect(mittens.isIndoor, isFalse);

    final whiskers = pets.whereType<Cat>().singleWhere((c) => c.name == 'Whiskers');
    expect(whiskers.isIndoor, isTrue);

    expect(pets.every((p) => !p.isAdopted), isTrue);
  });
}
