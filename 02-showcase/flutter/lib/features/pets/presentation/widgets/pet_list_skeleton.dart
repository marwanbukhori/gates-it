import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class PetListSkeleton extends StatefulWidget {
  const PetListSkeleton({super.key});

  @override
  State<PetListSkeleton> createState() => _PetListSkeletonState();
}

class _PetListSkeletonState extends State<PetListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (constraints.maxWidth) {
          > 1200 => 4,
          > 900  => 3,
          > 620  => 2,
          _      => 1,
        };
        return GridView.count(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          crossAxisCount: columns,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.72,
          children: List.generate(6, (_) => _ShimmerCard(controller: _controller)),
        );
      },
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final AnimationController controller;
  const _ShimmerCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final base = AppColors.surfaceVariant;
        final highlight = Color.lerp(base, AppColors.surface, 0.6)!;
        final color = Color.lerp(base, highlight, t)!;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusL),
            border: Border.all(color: AppColors.outline, width: 0.6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _bar(color, width: 130, height: 18),
                const SizedBox(height: AppSpacing.xs),
                _bar(color, width: 90, height: 12),
                const Spacer(),
                _bar(color, width: double.infinity, height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bar(Color color, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusS),
      ),
    );
  }
}
