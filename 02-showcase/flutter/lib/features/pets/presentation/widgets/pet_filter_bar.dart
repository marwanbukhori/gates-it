import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../application/pet_filter.dart';
import '../../application/pet_providers.dart';

class PetFilterBar extends ConsumerWidget {
  const PetFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(petFilterProvider);
    final asyncPets = ref.watch(petListControllerProvider);
    final counts = _countsFor(asyncPets.asData?.value ?? const []);

    return Semantics(
      label: 'Filter pets by species',
      container: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            for (final filter in PetFilter.values) ...[
              _FilterChip(
                filter: filter,
                selected: filter == current,
                count: counts[filter] ?? 0,
                onTap: () =>
                    ref.read(petFilterProvider.notifier).set(filter),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }

  Map<PetFilter, int> _countsFor(List<dynamic> pets) {
    final dogs = pets.where((p) => p.species == 'Dog').length;
    final cats = pets.where((p) => p.species == 'Cat').length;
    return {
      PetFilter.all: pets.length,
      PetFilter.dogs: dogs,
      PetFilter.cats: cats,
    };
  }
}

class _FilterChip extends StatelessWidget {
  final PetFilter filter;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  const _FilterChip({
    required this.filter,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '${filter.label}, $count pets',
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outline,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: selected
                          ? AppColors.onPrimary
                          : AppColors.textStrong,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.onPrimary.withValues(alpha: 0.16)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: Text(
                      '$count',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: selected
                            ? AppColors.onPrimary
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
