import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/adoption_repository.dart';
import '../data/api_pet_repository.dart';
import '../domain/adoption_result.dart';
import '../domain/cat.dart';
import '../domain/dog.dart';
import '../domain/pet.dart';
import '../domain/pet_repository.dart';
import 'pet_filter.dart';

// ---------------------------------------------------------------------------
// Repository providers
// ---------------------------------------------------------------------------

/// Provides the active [PetRepository].
///
/// The default implementation is [ApiPetRepository] which calls the live
/// Pawmise API. Override this provider in tests with a fake (e.g.
/// `InMemoryPetRepository`) to avoid hitting the network.
final petRepositoryProvider = Provider<PetRepository>((ref) {
  // ApiPetRepository owns its own http.Client — dispose it when the provider
  // is torn down to avoid socket leaks.
  final repo = ApiPetRepository();
  ref.onDispose(repo.client.close);
  return repo;
});

/// Provides the [AdoptionRepository] wired to the shared HTTP client.
final adoptionRepositoryProvider = Provider<AdoptionRepository>((ref) {
  return AdoptionRepository(client: ref.watch(httpClientProvider));
});

/// Sealed result type for [PetListController.adoptOnServer] — the UI decides
/// how to surface each outcome.
sealed class AdoptServerResult {}

final class AdoptServerSuccess extends AdoptServerResult {
  final AdoptionResult result;
  AdoptServerSuccess(this.result);
}

final class AdoptServerAlreadyAdopted extends AdoptServerResult {}

final class AdoptServerOffline extends AdoptServerResult {}

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
  /// This mirrors the status change that the API returns on a successful
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

  /// Calls the live API to record the adoption, handling auth bootstrapping.
  ///
  /// Returns an [AdoptServerResult] so the UI can decide how to surface the
  /// outcome — it never throws.
  Future<AdoptServerResult> adoptOnServer(String petId) async {
    try {
      final token =
          await ref.read(authNotifierProvider.notifier).ensureAuthenticated();
      final result =
          await ref.read(adoptionRepositoryProvider).adopt(petId, token);
      return AdoptServerSuccess(result);
    } on AlreadyAdoptedException {
      return AdoptServerAlreadyAdopted();
    } on UnauthenticatedException {
      // Token was rejected — clear it so the next call re-authenticates.
      ref.read(authNotifierProvider.notifier).clearToken();
      return AdoptServerOffline();
    } catch (_) {
      // Network error, timeout, or any other unexpected exception → offline
      // fallback; never crash the UI.
      return AdoptServerOffline();
    }
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
