import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/pet.dart';
import 'pet_card.dart';

class PetGrid extends StatelessWidget {
  final List<Pet> pets;
  final void Function(Pet) onAdopt;

  const PetGrid({super.key, required this.pets, required this.onAdopt});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = switch (width) {
          > 1200 => 4,
          > 900  => 3,
          > 620  => 2,
          _      => 1,
        };
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            mainAxisExtent: 440,
          ),
          itemCount: pets.length,
          itemBuilder: (context, index) {
            final pet = pets[index];
            return _EnterAnimation(
              index: index,
              child: PetCard(pet: pet, onAdopt: () => onAdopt(pet)),
            );
          },
        );
      },
    );
  }
}

class _EnterAnimation extends StatefulWidget {
  final int index;
  final Widget child;
  const _EnterAnimation({required this.index, required this.child});

  @override
  State<_EnterAnimation> createState() => _EnterAnimationState();
}

class _EnterAnimationState extends State<_EnterAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future<void>.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
