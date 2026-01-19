import 'package:flutter/material.dart';
import '../theme/app_dimens.dart';

class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDimens.durationShimmer,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (_, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) {
              final shimmerPosition = _controller.value * 2 - 1;
              return LinearGradient(
                begin: Alignment(-1 + shimmerPosition, -1),
                end: Alignment(1 + shimmerPosition, 1),
                colors: [baseColor, highlightColor, baseColor],
                stops: const [0.35, 0.5, 0.65],
              ).createShader(rect);
            },
            child: child,
          );
        },
      ),
    );
  }
}

class SkeletonContainer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonContainer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppDimens.radiusSm,
  });

  const SkeletonContainer.square({
    super.key,
    required double size,
    this.borderRadius = AppDimens.radiusSm,
  }) : width = size,
       height = size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class CategoryChipSkeleton extends StatelessWidget {
  const CategoryChipSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.only(right: AppDimens.sm),
      child: Shimmer(
        child: Container(
          height: AppDimens.chipHeight,
          width: 120,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
            border: Border.all(color: baseColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: AppDimens.iconLg,
                height: AppDimens.iconLg,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppDimens.xs),
              Expanded(
                child: Container(
                  height: AppDimens.skeletonLineHeight,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Shimmer(
      child: Card(
        elevation: AppDimens.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppDimens.radiusMd)),
        ),
        color: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Center(
                  child: SkeletonContainer(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: AppDimens.radiusSm,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              const SkeletonContainer(
                width: AppDimens.skeletonCardWidth,
                height: AppDimens.skeletonLineHeight,
                borderRadius: AppDimens.xxs,
              ),
              const SizedBox(height: 6),
              Row(
                children: const [
                  Expanded(
                    child: SkeletonContainer(
                      width: double.infinity,
                      height: AppDimens.skeletonHeaderHeight,
                      borderRadius: AppDimens.xxs,
                    ),
                  ),
                  SizedBox(width: AppDimens.xs),
                  SkeletonContainer.square(
                    size: AppDimens.skeletonLargeBox,
                    borderRadius: AppDimens.radiusSm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilesSkeleton extends StatelessWidget {
  const FilesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
      child: Column(
        children: List.generate(3, (_) {
          return Shimmer(
            child: Container(
              margin: const EdgeInsets.only(bottom: AppDimens.xs),
              padding: const EdgeInsets.all(AppDimens.sm),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Row(
                children: [
                  const SkeletonContainer.square(
                    size: AppDimens.skeletonMediumBox,
                    borderRadius: 6,
                  ),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonContainer(
                          width: double.infinity,
                          height: AppDimens.skeletonLineHeight,
                          borderRadius: 4,
                        ),
                        SizedBox(height: 6),
                        SkeletonContainer(
                          width: 120,
                          height: AppDimens.skeletonTextHeight,
                          borderRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  const SkeletonContainer.square(
                    size: AppDimens.skeletonLargeBox,
                    borderRadius: AppDimens.radiusSm,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class FilterSkeleton extends StatelessWidget {
  const FilterSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonContainer(
                width: AppDimens.skeletonHeaderWidth,
                height: AppDimens.skeletonHeaderHeight,
                borderRadius: 4,
              ),
              SizedBox(height: AppDimens.gridSpacing),
              SkeletonContainer(
                width: double.infinity,
                height: 50,
                borderRadius: AppDimens.radiusSm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
