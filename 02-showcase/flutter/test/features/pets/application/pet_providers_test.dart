import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_adoption/features/pets/application/pet_filter.dart';
import 'package:pet_adoption/features/pets/application/pet_providers.dart';
import 'package:pet_adoption/features/pets/data/in_memory_pet_repository.dart';
import 'package:pet_adoption/features/pets/domain/cat.dart';
import 'package:pet_adoption/features/pets/domain/dog.dart';

void main() {
  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          petRepositoryProvider.overrideWithValue(
            const InMemoryPetRepository(simulatedLatency: Duration.zero),
          ),
        ],
      );

  test('loads the initial dataset from the repository', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    final pets = await container.read(petListControllerProvider.future);
    expect(pets, hasLength(4));
  });

  test('adopt() marks a pet as adopted without mutating the list identity', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(petListControllerProvider.future);
    container.read(petListControllerProvider.notifier).adopt('rex');

    final refreshed = container.read(petListControllerProvider).asData!.value;
    final rex = refreshed.singleWhere((p) => p.name == 'Rex');
    expect(rex.isAdopted, isTrue);
    final others = refreshed.where((p) => p.name != 'Rex');
    expect(others.every((p) => !p.isAdopted), isTrue);
  });

  test('filter provider narrows visible pets by species', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(petListControllerProvider.future);

    container.read(petFilterProvider.notifier).set(PetFilter.dogs);
    final dogs = container.read(visiblePetsProvider).asData!.value;
    expect(dogs, everyElement(isA<Dog>()));
    expect(dogs, hasLength(2));

    container.read(petFilterProvider.notifier).set(PetFilter.cats);
    final cats = container.read(visiblePetsProvider).asData!.value;
    expect(cats, everyElement(isA<Cat>()));
    expect(cats, hasLength(2));

    container.read(petFilterProvider.notifier).set(PetFilter.all);
    final all = container.read(visiblePetsProvider).asData!.value;
    expect(all, hasLength(4));
  });
}
