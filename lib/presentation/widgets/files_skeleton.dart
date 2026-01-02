import 'package:flutter/material.dart';
import '../theme/app_dimens.dart';
import '../widgets/shimmer.dart';

class FilesSkeleton extends StatelessWidget {
  const FilesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final cardColor = theme.cardColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
      child: Column(
        children: List.generate(3, (_) {
          return Shimmer(
            child: Container(
              margin: const EdgeInsets.only(bottom: AppDimens.xs),
              padding: const EdgeInsets.all(AppDimens.sm),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 10,
                          width: 120,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
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
