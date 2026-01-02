import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../theme/app_dimens.dart';
import '../widgets/shimmer.dart';

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final baseColor = colors.onSurface.withValues(alpha: 0.1);

    return Shimmer(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        color: context.theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              Container(
                height: 12,
                width: 90,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(AppDimens.xxs),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(AppDimens.xxs),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.xs),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
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
