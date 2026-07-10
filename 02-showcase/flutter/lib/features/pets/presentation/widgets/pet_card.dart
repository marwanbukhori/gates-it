import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/cat.dart';
import '../../domain/dog.dart';
import '../../domain/pet.dart';

class PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onAdopt;

  const PetCard({
    super.key,
    required this.pet,
    required this.onAdopt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = _speciesSurface(pet);
    final accent = _speciesAccent(pet);
    final trait = _traitLabel(pet);

    return Semantics(
      label: '${pet.name}, ${pet.age} year old ${pet.breed}, ${pet.species}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Portrait(species: pet.species, surface: surface, accent: accent),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pet.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            decoration: pet.isAdopted
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppColors.textMuted,
                          ),
                        ),
                      ),
                      _AgeBadge(age: pet.age),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    pet.breed,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _Tag(label: pet.species, background: accent.withValues(alpha: 0.12), color: accent),
                      _Tag(label: trait, background: AppColors.surfaceVariant, color: AppColors.textMuted),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: pet.isAdopted
                        ? const _AdoptedPill(key: ValueKey('adopted'))
                        : _AdoptButton(key: const ValueKey('adopt'), onPressed: onAdopt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _speciesSurface(Pet pet) => switch (pet) {
        Dog() => AppColors.dogSurface,
        Cat() => AppColors.catSurface,
        _ => AppColors.surfaceVariant,
      };

  static Color _speciesAccent(Pet pet) => switch (pet) {
        Dog() => AppColors.dogAccent,
        Cat() => AppColors.catAccent,
        _ => AppColors.textMuted,
      };

  static String _traitLabel(Pet pet) => switch (pet) {
        Dog(:final isTrained) => isTrained ? 'Trained' : 'Untrained',
        Cat(:final isIndoor) => isIndoor ? 'Indoor' : 'Outdoor',
        _ => '',
      };
}

class _Portrait extends StatelessWidget {
  final String species;
  final Color surface;
  final Color accent;

  const _Portrait({
    required this.species,
    required this.surface,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final glyph = species == 'Dog' ? '🐶' : '🐱';
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    surface,
                    Color.lerp(surface, accent, 0.08) ?? surface,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -20,
            top: -10,
            child: _Blob(color: accent.withValues(alpha: 0.10), size: 140),
          ),
          Positioned(
            left: -30,
            bottom: -40,
            child: _Blob(color: accent.withValues(alpha: 0.07), size: 180),
          ),
          Center(
            child: Text(
              glyph,
              style: const TextStyle(fontSize: 68),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _AgeBadge extends StatelessWidget {
  final int age;
  const _AgeBadge({required this.age});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        age == 1 ? '1 yr' : '$age yrs',
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppColors.textStrong,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color background;
  final Color color;
  const _Tag({
    required this.label,
    required this.background,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AdoptButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AdoptButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.favorite_rounded, size: 18),
        label: const Text('Adopt me'),
      ),
    );
  }
}

class _AdoptedPill extends StatelessWidget {
  const _AdoptedPill({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'Adopted — going home',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
