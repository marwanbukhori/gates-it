import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/in_memory_pet_repository.dart';
import '../domain/cat.dart';
import '../domain/dog.dart';
import '../domain/pet.dart';
import '../domain/pet_repository.dart';
import 'pet_filter.dart';

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return const InMemoryPetRepository();
});

class PetListController extends AsyncNotifier<List<Pet>> {
  @override
  Future<List<Pet>> build() {
    return ref.read(petRepositoryProvider).fetchAll();
  }

  void adopt(String id) {
    final current = state.asData?.value;
    if (current == null) return;

    state = AsyncData([
      for (final pet in current)
        pet.id == id ? _withAdopted(pet) : pet,
    ]);
  }

  Pet _withAdopted(Pet pet) => switch (pet) {
        Dog() => pet.copyWith(isAdopted: true),
        Cat() => pet.copyWith(isAdopted: true),
        _ => throw UnimplementedError('Unknown pet subtype: ${pet.runtimeType}'),
      };
}

final petListControllerProvider =
    AsyncNotifierProvider<PetListController, List<Pet>>(PetListController.new);

class PetFilterController extends Notifier<PetFilter> {
  @override
  PetFilter build() => PetFilter.all;

  void set(PetFilter filter) => state = filter;
}

final petFilterProvider =
    NotifierProvider<PetFilterController, PetFilter>(PetFilterController.new);

final visiblePetsProvider = Provider<AsyncValue<List<Pet>>>((ref) {
  final asyncPets = ref.watch(petListControllerProvider);
  final filter = ref.watch(petFilterProvider);

  return asyncPets.whenData((pets) => switch (filter) {
        PetFilter.all => pets,
        PetFilter.dogs => pets.whereType<Dog>().toList(),
        PetFilter.cats => pets.whereType<Cat>().toList(),
      });
});
