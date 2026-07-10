import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_pet_repository.dart';
import '../domain/cat.dart';
import '../domain/dog.dart';
import '../domain/pet.dart';
import '../domain/pet_repository.dart';
import 'pet_filter.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the active [PetRepository].
///
/// The default implementation is [ApiPetRepository] which calls the live
/// Pawmise API. Override this provider in tests with [InMemoryPetRepository]
/// (or any other fake) to avoid hitting the network:
///
/// ```dart
/// ProviderContainer(
///   overrides: [
///     petRepositoryProvider.overrideWithValue(
///       InMemoryPetRepository(simulatedLatency: Duration.zero),
///     ),
///   ],
/// )
/// ```
final petRepositoryProvider = Provider<PetRepository>((ref) {
  // ApiPetRepository owns its own http.Client — dispose it when the provider
  // is torn down to avoid socket leaks.
  final repo = ApiPetRepository();
  ref.onDispose(repo.client.close);
  return repo;
});

// ---------------------------------------------------------------------------
// Pet list controller
// ---------------------------------------------------------------------------

class PetListController extends AsyncNotifier<List<Pet>> {
  @override
  Future<List<Pet>> build() {
    return ref.read(petRepositoryProvider).fetchAll();
  }

  /// Optimistically marks a pet as adopted in the local list.
  ///
  /// This mirrors the status change that the API would return on a successful
  /// `POST /pets/{id}/adopt` call.
  void adopt(String id) {
    final current = state.asData?.value;
    if (current == null) return;

    state = AsyncData([
      for (final pet in current)
        pet.id == id ? _withAdopted(pet) : pet,
    ]);
  }

  /// Reloads the list from the repository (e.g. on pull-to-refresh or error
  /// retry).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(petRepositoryProvider).fetchAll(),
    );
  }

  Pet _withAdopted(Pet pet) => switch (pet) {
        Dog() => pet.copyWith(isAdopted: true),
        Cat() => pet.copyWith(isAdopted: true),
        _ => throw UnimplementedError('Unknown pet subtype: ${pet.runtimeType}'),
      };
}

final petListControllerProvider =
    AsyncNotifierProvider<PetListController, List<Pet>>(PetListController.new);

// ---------------------------------------------------------------------------
// Filter
// ---------------------------------------------------------------------------

class PetFilterController extends Notifier<PetFilter> {
  @override
  PetFilter build() => PetFilter.all;

  void set(PetFilter filter) => state = filter;
}

final petFilterProvider =
    NotifierProvider<PetFilterController, PetFilter>(PetFilterController.new);

// ---------------------------------------------------------------------------
// Derived: visible pets (filter applied locally after fetch)
// ---------------------------------------------------------------------------

final visiblePetsProvider = Provider<AsyncValue<List<Pet>>>((ref) {
  final asyncPets = ref.watch(petListControllerProvider);
  final filter = ref.watch(petFilterProvider);

  return asyncPets.whenData((pets) => switch (filter) {
        PetFilter.all => pets,
        PetFilter.dogs => pets.whereType<Dog>().toList(),
        PetFilter.cats => pets.whereType<Cat>().toList(),
      });
});
