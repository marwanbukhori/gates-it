import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../application/pet_filter.dart';
import '../application/pet_providers.dart';
import '../domain/pet.dart';
import 'widgets/empty_state.dart';
import 'widgets/pet_filter_bar.dart';
import 'widgets/pet_grid.dart';
import 'widgets/pet_list_skeleton.dart';

class PetListScreen extends ConsumerWidget {
  const PetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visiblePets = ref.watch(visiblePetsProvider);
    final allPets = ref.watch(petListControllerProvider);
    final filter = ref.watch(petFilterProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(remaining: _remainingCount(allPets)),
            const SizedBox(height: AppSpacing.sm),
            const PetFilterBar(),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: visiblePets.when(
                data: (pets) => pets.isEmpty
                    ? _emptyFor(filter)
                    : PetGrid(
                        pets: pets,
                        onAdopt: (pet) => _adopt(context, ref, pet),
                      ),
                loading: () => const PetListSkeleton(),
                error: (err, _) => _error(context, err),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _remainingCount(AsyncValue<List<Pet>> pets) =>
      pets.asData?.value.where((p) => !p.isAdopted).length ?? 0;

  Future<void> _adopt(BuildContext context, WidgetRef ref, Pet pet) async {
    final notifier = ref.read(petListControllerProvider.notifier);

    // 1. Optimistic local update — immediate UI feedback.
    notifier.adopt(pet.id);

    // 2. Fire the live API call in the background.
    final serverResult = await notifier.adoptOnServer(pet.id);

    if (!context.mounted) return;

    switch (serverResult) {
      case AdoptServerSuccess(:final result):
        final fee = result.finalFee.toStringAsFixed(2);
        final currency = result.currency;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Adopted \u{1F43E} — fee $currency $fee'),
              duration: const Duration(seconds: 3),
            ),
          );
      case AdoptServerAlreadyAdopted():
        // Pet was already recorded on the server — keep adopted pill.
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Already adopted on the server — keeping it!'),
              duration: Duration(seconds: 2),
            ),
          );
      case AdoptServerOffline():
        // Network unavailable or auth failure — local state is already updated,
        // show a subtle offline notice.
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                '${pet.name} marked as adopted locally (offline or auth error).',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
    }
  }

  Widget _emptyFor(PetFilter filter) => switch (filter) {
        PetFilter.all => const EmptyState(
            title: 'Every paw has a home',
            message:
                'There are no pets waiting right now. Check back in a bit — new furry friends arrive weekly.',
            icon: Icons.home_rounded,
          ),
        PetFilter.dogs => const EmptyState(
            title: 'All dogs adopted',
            message:
                'The pups have all found families. Try filtering by cats, or come back later.',
          ),
        PetFilter.cats => const EmptyState(
            title: 'Every cat is content',
            message:
                'The cats have all been claimed. Try filtering by dogs, or come back later.',
          ),
      };

  Widget _error(BuildContext context, Object err) {
    return EmptyState(
      title: 'Something went wrong',
      message: 'We could not load the pets. Details: $err',
      icon: Icons.error_outline_rounded,
    );
  }
}

class _Header extends StatelessWidget {
  final int remaining;

  const _Header({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: AppColors.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Adoption Home',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Find a friend',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            remaining == 0
                ? 'Everyone has found a home — for now.'
                : '$remaining ${remaining == 1 ? 'friend is' : 'friends are'} waiting for the right family.',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
